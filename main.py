import os
import sys
import logging
from pathlib import Path
from typing import Optional
from dataclasses import dataclass

from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide6.QtWidgets import QApplication
from PySide6.QtGui import QIcon
from PySide6.QtQuickControls2 import QQuickStyle

from models.PythonModel import PythonModel
from models.Calculator import PowerCalculator, FaultCurrentCalculator, ChargingCalc
from models.ThreePhase import ThreePhaseSineWaveModel
from models.ElectricPy import ResonantFreq, ConversionCalculator, SeriesRLCChart, PhasorPlot
from models.calculators.CalculatorFactory import ConcreteCalculatorFactory
from models.VoltageDropMV import VoltageDropMVCalculator
from models.ResultsManager import ResultsManager
from services.interfaces import ICalculatorFactory, IModelFactory, IQmlEngine, ILogger
from services.container import Container
from services.implementations import DefaultLogger, QmlEngineWrapper, ModelFactory
CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

import rc_resources as rc_resources

@dataclass
class AppConfig:
    """Application configuration settings.
    
    Attributes:
        style (str): Qt Quick style to use
        app_name (str): Name of the application
        org_name (str): Organization name
        icon_path (str): Path to application icon
    """
    style: str = "Universal"
    app_name: str = "Electrical"
    org_name: str = "QtProject"
    icon_path: str = "icons/gallery/24x24/Wave_dark.ico"

class Application:
    """Main application class implementing dependency injection and component management.
    
    This class serves as the primary application controller, managing:
    - Dependency injection
    - Model initialization
    - QML registration
    - Application lifecycle
    """
    
    def __init__(self, container: Optional[Container] = None):
        """Initialize application with dependency container and configuration.
        
        Args:
            container: Dependency injection container
            config: Optional application configuration
        """
        self.config = AppConfig()
        self.container = container or Container()
        
        # Create QApplication first
        self.app = QApplication(sys.argv)
        
        # Resolve dependencies
        self.logger = self.container.resolve(ILogger)
        self.calculator_factory = self.container.resolve(ICalculatorFactory)
        self.qml_engine = self.container.resolve(IQmlEngine)
        self.model_factory = self.container.resolve(IModelFactory)
        
        # Initialize QML engine with QApplication
        self.qml_engine.initialize(self.app)
        
        # Add import paths in correct order
        self.qml_engine.engine.addImportPath(os.path.dirname(CURRENT_DIR))  # Root path
        self.qml_engine.engine.addImportPath(CURRENT_DIR)  # Project path
        
        # Add explicit paths for components
        components_path = os.path.join(CURRENT_DIR, "qml", "components")
        self.qml_engine.engine.addImportPath(os.path.dirname(components_path))
        
        # Clear QML cache (optional, but can help with registration issues)
        self.qml_engine.engine.clearComponentCache()
        
        # Register the SineWaveModel type explicitly
        qmlRegisterType(ThreePhaseSineWaveModel, "Sine", 1, 0, "SineWaveModel")
        
        # Create and register ResultsManager
        self.results_manager = ResultsManager()
        
        self.setup()
        
    def setup(self):
        """Configure application components and initialize subsystems."""
        self.logger.setup(level=logging.INFO)
        self.setup_app()
        self.load_models()
        self.register_qml_types()
        self.load_qml()

    def setup_app(self):
        QQuickStyle.setStyle(self.config.style)
        QApplication.setApplicationName(self.config.app_name)
        QApplication.setOrganizationName(self.config.org_name)
        QApplication.setWindowIcon(QIcon(self.config.icon_path))
        QIcon.setThemeName("gallery")

    def load_models(self):
        """Initialize and configure application models using factories."""
        self.voltage_model = self.model_factory.create_model("voltage", csv_path="data/cable_data.csv")
        self.power_calculator = self.calculator_factory.create_calculator("power")
        self.fault_current_calculator = self.calculator_factory.create_calculator("fault")
        self.sine_wave = self.model_factory.create_model("three_phase")
        self.resonant_freq = self.model_factory.create_model("resonant_freq")
        self.conversion_calc = self.model_factory.create_model("conversion_calc")
        self.series_LC_chart = self.model_factory.create_model("series_rlc_chart")
        self.phasorPlotter = self.model_factory.create_model("phasor_plot")
        self.voltage_drop = self.model_factory.create_model("voltage_drop")

    def register_qml_types(self):
        for type_info in self.get_qml_types():
            self.qml_engine.register_type(*type_info)
    
    def get_qml_types(self):
        """Get list of QML types to register.
        
        Returns:
            list: Tuples of (class, uri, major, minor, name) for QML registration
        """
        return [
            (PythonModel, "Python", 1, 0, "PythonModel"),
            (ChargingCalc, "Charging", 1, 0, "ChargingCalc"),
            (PowerCalculator, "Calculator", 1, 0, "PowerCalculator"),
            (FaultCurrentCalculator, "Fault", 1, 0, "FaultCalculator"),
            (ResonantFreq, "RFreq", 1, 0, "ResonantFreq"),
            (ConversionCalculator, "ConvCalc", 1, 0, "ConversionCalc"),
            (SeriesRLCChart, "RLC", 1, 0, "SeriesRLCChart"),
            (PhasorPlot, "PPlot", 1, 0, "PhasorPlot"),
            (VoltageDropMVCalculator,"VDropMV", 1, 0, "VoltageDropMV"),
            (ResultsManager, "Results", 1, 0, "ResultsManager")
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

if __name__ == "__main__":
    container = setup_container()
    app = Application(container)
    app.run()

