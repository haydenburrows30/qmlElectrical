import os
import sys
import logging
from pathlib import Path
from typing import Optional

from PySide6.QtQml import qmlRegisterType
from PySide6.QtWidgets import QApplication
from PySide6.QtGui import QIcon
from PySide6.QtQuickControls2 import QQuickStyle

from models.Calculator import PowerCalculator, FaultCurrentCalculator, ChargingCalculator, SineCalculator, ResonantFrequencyCalculator, ConversionCalculator
from models.ThreePhase import ThreePhaseSineWaveModel
from models.ElectricPy import SeriesRLCChart
from models.calculators.CalculatorFactory import ConcreteCalculatorFactory
from models.VoltageDrop import VoltageDrop
from models.ResultsManager import ResultsManager
from models.RealTimeChart import RealTimeChart
from services.interfaces import ICalculatorFactory, IModelFactory, IQmlEngine, ILogger
from services.container import Container
from services.implementations import DefaultLogger, QmlEngineWrapper, ModelFactory
from models.config import app_config

# Add these imports
from models.transformer_calculator import TransformerCalculator
from models.voltage_drop_calculator import VoltageDropCalculator
from models.motor_calculator import MotorCalculator
from models.power_factor_correction import PowerFactorCorrectionCalculator
from models.cable_ampacity import CableAmpacityCalculator
from models.protection_relay import ProtectionRelayCalculator
from models.harmonic_analysis import HarmonicAnalysisCalculator
from models.instrument_transformer import InstrumentTransformerCalculator

# New imports for protection system calculators
from models.relay_coordination import RelayCoordinationCalculator
from models.overcurrent_curves import OvercurrentCurvesCalculator
from models.discrimination_analyzer import DiscriminationAnalyzer

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

import rc_resources as rc_resources

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
        self.config = app_config  # Use the imported config instead of creating new AppConfig
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

        self.setup()
        
    def setup(self):
        """Configure application components and initialize subsystems."""
        self.logger.setup(level=logging.INFO)
        self.setup_app()
        self.load_models()
        self.register_qml_types()
        self.load_qml()

    def setup_app(self):
        """Configure application using loaded config."""
        QQuickStyle.setStyle(self.config.style)
        QApplication.setApplicationName(self.config.app_name)
        QApplication.setOrganizationName(self.config.org_name)
        QApplication.setWindowIcon(QIcon(self.config.icon_path))
        QIcon.setThemeName("gallery")

    def load_models(self):
        """Initialize and configure application models using factories."""
        # Create and configure calculator models
        self.power_calculator = self.calculator_factory.create_calculator("power")
        self.fault_current_calculator = self.calculator_factory.create_calculator("fault")
        self.resonant_freq = self.calculator_factory.create_calculator("resonant")
        self.conversion_calc = self.calculator_factory.create_calculator("conversion")
        self.charging_calc = self.calculator_factory.create_calculator("charging")

        self.transformer_calculator = self.calculator_factory.create_calculator("transformer")
        self.voltage_drop_calculator = self.calculator_factory.create_calculator("voltage_drop")
        self.motor_calculator = self.calculator_factory.create_calculator("motor")
        self.pf_correction_calculator = self.calculator_factory.create_calculator("pf_correction")
        self.cable_ampacity_calculator = self.calculator_factory.create_calculator("cable_ampacity")
        self.protection_relay_calculator = self.calculator_factory.create_calculator("protection_relay")
        self.harmonic_analysis_calculator = self.calculator_factory.create_calculator("harmonic_analysis")
        self.instrument_transformer_calculator = self.calculator_factory.create_calculator("instrument_transformer")
        self.relay_coordination = self.calculator_factory.create_calculator("relay_coordination")
        self.overcurrent_curves = self.calculator_factory.create_calculator("overcurrent_curves")
        self.discrimination_analyzer = self.calculator_factory.create_calculator("discrimination_analyzer")

        # Create and configure other models
        self.sine_calc = self.model_factory.create_model("sine_calc")
        self.sine_wave = self.model_factory.create_model("three_phase")
        self.series_LC_chart = self.model_factory.create_model("series_rlc_chart")
        self.voltage_drop = self.model_factory.create_model("voltage_drop")
        self.results_manager = self.model_factory.create_model("results_manager")
        self.realtime_chart = self.model_factory.create_model("realtime_chart")

    def register_qml_types(self):
        for type_info in self.get_qml_types():
            self.qml_engine.register_type(*type_info)
    
    def get_qml_types(self):
        """Get list of QML types to register.
        
        Returns:
            list: Tuples of (class, uri, major, minor, name) for QML registration
        """
        return [
            (ChargingCalculator, "Charging", 1, 0, "ChargingCalculator"),
            (PowerCalculator, "PCalculator", 1, 0, "PowerCalculator"),
            (FaultCurrentCalculator, "Fault", 1, 0, "FaultCurrentCalculator"),
            (ResonantFrequencyCalculator, "RFreq", 1, 0, "ResonantFrequencyCalculator"),
            (ConversionCalculator, "ConvCalc", 1, 0, "ConversionCalculator"),
            (TransformerCalculator, "Transformer", 1, 0, "TransformerCalculator"),
            (MotorCalculator, "Motor", 1, 0, "MotorCalculator"),
            (MotorCalculator, "MotorStarting", 1, 0, "MotorStartingCalculator"),
            (PowerFactorCorrectionCalculator, "PFCorrection", 1, 0, "PowerFactorCorrection"),
            (CableAmpacityCalculator, "CableAmpacity", 1, 0, "CableAmpacity"),
            (ProtectionRelayCalculator, "ProtectionRelay", 1, 0, "ProtectionRelayCalculator"),
            (HarmonicAnalysisCalculator, "HarmonicAnalysis", 1, 0, "HarmonicAnalysisCalculator"),
            (InstrumentTransformerCalculator, "InstrumentTransformer", 1, 0, "InstrumentTransformerCalculator"),
            (RelayCoordinationCalculator, "RelayCoordination", 1, 0, "RelayCoordinationCalculator"),
            (OvercurrentCurvesCalculator, "OvercurrentCurves", 1, 0, "OvercurrentCurvesCalculator"),
            (DiscriminationAnalyzer, "DiscriminationAnalyzer", 1, 0, "DiscriminationAnalyzer"),
            (SeriesRLCChart, "RLC", 1, 0, "SeriesRLCChart"),
            (VoltageDrop,"VDrop", 1, 0, "VoltageDrop"),
            (ResultsManager, "Results", 1, 0, "ResultsManager"),
            (SineCalculator, "SineCalc", 1, 0, "SineCalculator"),
            (RealTimeChart, "RealTimeChart", 1, 0, "RealTimeChart"),
            (ThreePhaseSineWaveModel, "Sine", 1, 0, "SineWaveModel"),
            (VoltageDropCalculator, "VoltageDrop", 1, 0, "VoltageDropCalculator")
        ]

    def load_qml(self):
        self.qml_engine.load_qml(os.path.join(CURRENT_DIR, "qml", "main.qml"))
        
    def run(self):
        sys.exit(self.app.exec())

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
    main()

