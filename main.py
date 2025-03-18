import os
import sys
import logging
import asyncio
from typing import Optional, Any

from PySide6.QtQml import qmlRegisterType
from PySide6.QtWidgets import QApplication
from PySide6.QtGui import QIcon
from PySide6.QtQuickControls2 import QQuickStyle

from services.interfaces import ICalculatorFactory, IModelFactory, IQmlEngine, ILogger
from services.container import Container
from services.implementations import DefaultLogger, QmlEngineWrapper, ModelFactory
from models.config import app_config

from models.three_phase import ThreePhaseSineWaveModel
from models.rlc import RLCChart
from models.calculators.CalculatorFactory import ConcreteCalculatorFactory
from models.voltdrop.voltage_drop_calculator import VoltageDropCalculator
from models.results_manager import ResultsManager
from models.real_time_chart import RealTimeChart

from models.calculator import ConversionCalculator, PowerCalculator, FaultCurrentCalculator, ChargingCalculator, KwFromCurrentCalculator
from models.transformer_calculator import TransformerCalculator
from models.voltage_drop_calculator import VoltageDropCalc
from models.motor_calculator import MotorCalculator
from models.power_factor_correction import PowerFactorCorrectionCalculator
from models.cable_ampacity import CableAmpacityCalculator
from models.protection_relay import ProtectionRelayCalculator
from models.harmonic_analysis import HarmonicAnalysisCalculator
from models.instrument_transformer import InstrumentTransformerCalculator
from models.discrimination_analyzer import DiscriminationAnalyzer
from models.charging_calculator import ChargingCalculator
from models.battery_calculator import BatteryCalculator
from models.machine_calculator import MachineCalculator
from models.earthing_calculator import EarthingCalculator
from models.transformer_calculator import TransformerCalculator
from models.transmission_calculator import TransmissionLineCalculator
from models.delta_transformer import DeltaTransformerCalculator

from services.loading_manager import LoadingManager
from services.worker_pool import WorkerPool

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

import data.rc_resources as rc_resources
from models.series_helper import SeriesHelper
from models.bar_series_helper import BarSeriesHelper

# Import our calculator
from models.ref_rgf_calculator import RefRgfCalculator

class Application:
    """Main application class implementing dependency injection and component management.
    
    This class serves as the primary application controller, managing:
    - Dependency injection
    - Model initialization
    - QML registration
    - Application lifecycle
    """
    
    def __init__(self, container: Optional[Container] = None):
        """Initialize application with dependency container and configuration."""
        # Load config first
        self.config = app_config
        self.container = container or Container()

        self.app = QApplication(sys.argv)

        self.logger = self.container.resolve(ILogger)
        self.calculator_factory = self.container.resolve(ICalculatorFactory)
        self.qml_engine = self.container.resolve(IQmlEngine)
        self.model_factory = self.container.resolve(IModelFactory)

        self.qml_engine.initialize(self.app)
        
        self.qml_engine.engine.addImportPath(os.path.dirname(CURRENT_DIR))
        self.qml_engine.engine.addImportPath(CURRENT_DIR)

        components_path = os.path.join(CURRENT_DIR, "qml", "components")
        self.qml_engine.engine.addImportPath(os.path.dirname(components_path))

        self.qml_engine.engine.clearComponentCache()

        self.loading_manager = LoadingManager()
        self.qml_engine.engine.rootContext().setContextProperty("loadingManager", self.loading_manager)

        self.worker_pool = WorkerPool()
        self._resource_cache = {}

        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)

        self.setup()
        
    async def load_models_async(self):
        """Load models asynchronously."""
        self.loading_manager._loading = True
        self.loading_manager.statusChanged.emit("Loading core models...")
        
        async def load_model(name, progress):
            model = await self.loading_manager.run_in_thread(
                self.model_factory.create_model, name
            )
            self.loading_manager.update_task("models", progress)
            return model
            
        # Load models concurrently
        [self.sine_wave, self.voltage_drop, self.results_manager] = await asyncio.gather(
            load_model("three_phase", 0.3),
            load_model("voltage_drop", 0.6),
            load_model("results_manager", 1.0)
        )
        
        self.loading_manager._loading = False
        self.loading_manager.loadingChanged.emit()

    async def preload_resources(self):
        """Preload commonly used resources in background."""
        resources = [
            "cable_data_mv.csv",
            "protection_curves.json",
            "motor_starting.csv"
        ]
        
        for resource in resources:
            path = os.path.join(CURRENT_DIR, "data", resource)
            if os.path.exists(path):
                async def load_resource(p):
                    data = await self.worker_pool.execute(self._load_file, p)
                    self._resource_cache[p] = data
                asyncio.create_task(load_resource(path))

    def _load_file(self, path: str) -> Any:
        """Load file contents (runs in worker process)."""
        with open(path, 'r') as f:
            return f.read()

    def setup(self):
        """Configure application components and initialize subsystems."""
        self.logger.setup(level=logging.INFO)

        
        self.setup_app()
        
        # Run async operations in the event loop
        self.loop.run_until_complete(self._setup_async())
        
        self.register_qml_types()
        self.load_qml()

    async def _setup_async(self):
        """Run all async initialization tasks."""
        await asyncio.gather(
            self.preload_resources(),
            self.load_models_async()
        )

    def setup_app(self):
        """Configure application using loaded config."""
        QQuickStyle.setStyle(self.config.style)
        QApplication.setApplicationName(self.config.app_name)
        QApplication.setOrganizationName(self.config.org_name)
        QApplication.setWindowIcon(QIcon(self.config.icon_path))
        QIcon.setThemeName("gallery")

    def load_models(self):
        """Initialize and configure application models using factories."""
        # Load core models immediately
        self.sine_wave = self.model_factory.create_model("three_phase")
        self.voltage_drop = self.model_factory.create_model("voltage_drop")
        self.results_manager = self.model_factory.create_model("results_manager")

        # Defer calculator creation until needed
        self._calculators = {}
    
    def get_calculator(self, name):
        """Lazy load calculators only when requested."""
        if name not in self._calculators:
            self._calculators[name] = self.calculator_factory.create_calculator(name)
        return self._calculators[name]

    def register_qml_types(self):
        """Get list of QML types to register."""
        qml_types = [
            (ChargingCalculator, "Charging", 1, 0, "ChargingCalculator"),
            (PowerCalculator, "PCalculator", 1, 0, "PowerCalculator"),
            (FaultCurrentCalculator, "Fault", 1, 0, "FaultCurrentCalculator"),
            (TransformerCalculator, "Transformer", 1, 0, "TransformerCalculator"),
            (MotorCalculator, "MotorStarting", 1, 0, "MotorStartingCalculator"),
            (PowerFactorCorrectionCalculator, "PFCorrection", 1, 0, "PowerFactorCorrectionCalculator"),
            (CableAmpacityCalculator, "CableAmpacity", 1, 0, "AmpacityCalculator"),
            (ProtectionRelayCalculator, "ProtectionRelay", 1, 0, "ProtectionRelayCalculator"),
            (HarmonicAnalysisCalculator, "HarmonicAnalysis", 1, 0, "HarmonicAnalysisCalculator"),
            (InstrumentTransformerCalculator, "InstrumentTransformer", 1, 0, "InstrumentTransformerCalculator"),
            (DiscriminationAnalyzer, "DiscriminationAnalyzer", 1, 0, "DiscriminationAnalyzer"),
            (RLCChart, "RLC", 1, 0, "RLCChart"),
            (VoltageDropCalculator,"VDrop", 1, 0, "VoltageDrop"),
            (ResultsManager, "Results", 1, 0, "ResultsManager"),
            (RealTimeChart, "RealTimeChart", 1, 0, "RealTimeChart"),
            (ThreePhaseSineWaveModel, "Sine", 1, 0, "SineWaveModel"),
            (VoltageDropCalc, "VoltageDrop", 1, 0, "VoltageDropCalc"),
            (BatteryCalculator, "Battery", 1, 0, "BatteryCalculator"),
            (ConversionCalculator, "Conversion", 1, 0, "ConversionCalculator"),
            (MachineCalculator, "Machine", 1, 0, "MachineCalculator"),
            (EarthingCalculator, "Earthing", 1, 0, "EarthingCalculator"),
            (TransmissionLineCalculator, "Transmission", 1, 0, "TransmissionLineCalculator"),
            (DeltaTransformerCalculator, "DeltaTransformer", 1, 0, "DeltaTransformerCalculator"),
            (SeriesHelper, "SeriesHelper", 1, 0, "SeriesHelper"),
            (BarSeriesHelper, "BarSeriesHelper", 1, 0, "BarSeriesHelper"),
            (RefRgfCalculator, "RefRgf", 1, 0, "RefRgfCalculator"),
            (KwFromCurrentCalculator, "KwFromCurrent", 1, 0, "KwFromCurrentCalculator")
        ]

        for type_info in qml_types:
            self.qml_engine.register_type(*type_info)

    def load_qml(self):
        self.qml_engine.load_qml(os.path.join(CURRENT_DIR, "qml", "main.qml"))
        
        # Add platform helper registration
        from utils.platform_helper import PlatformHelper
        self.qml_engine.engine.rootContext().setContextProperty("PlatformHelper", PlatformHelper())

    def run(self):
        """Run the application."""
        try:
            sys.exit(self.app.exec())
        finally:
            self.loop.close()
            self.worker_pool.shutdown()

def setup_container() -> Container:
    """Create and configure the dependency injection container.
    
    Returns:
        Container: Configured dependency injection container
    """
    container = Container()
    
    # Register services
    container.register(ILogger, DefaultLogger)
    container.register(ICalculatorFactory, ConcreteCalculatorFactory)
    container.register(IQmlEngine, QmlEngineWrapper)
    container.register(IModelFactory, ModelFactory)
    
    return container

def main():
    container = setup_container()
    app = Application(container)
    app.run()

if __name__ == "__main__":
    container = setup_container()
    app = Application(container)
    app.run()

