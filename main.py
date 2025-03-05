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
from services.interfaces import ICalculatorFactory, IModelFactory, IQmlEngine, ILogger
from services.container import Container
from services.implementations import DefaultLogger, QmlEngineWrapper, ModelFactory
CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

import rc_resources as rc_resources

@dataclass
class AppConfig:
    style: str = "Universal"
    app_name: str = "Electrical"
    org_name: str = "QtProject"
    icon_path: str = "icons/gallery/24x24/Wave_dark.ico"

class Application:
    def __init__(self, container: Container, config: Optional[AppConfig] = None):
        self.config = config or AppConfig()
        self.container = container
        
        # Create QApplication first
        self.app = QApplication(sys.argv)
        
        # Resolve dependencies
        self.logger = container.resolve(ILogger)
        self.calculator_factory = container.resolve(ICalculatorFactory)
        self.qml_engine = container.resolve(IQmlEngine)
        self.model_factory = container.resolve(IModelFactory)
        
        # Initialize QML engine with QApplication
        self.qml_engine.initialize(self.app)
        
        self.setup()
        
    def setup(self):
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
        self.voltage_model = self.model_factory.create_model("voltage", csv_path="cable_data.csv")
        self.power_calculator = self.calculator_factory.create_calculator("power")
        self.fault_current_calculator = self.calculator_factory.create_calculator("fault")
        self.sine_wave = self.model_factory.create_model("three_phase")
        self.resonant_freq = self.model_factory.create_model("resonant_freq")
        self.conversion_calc = self.model_factory.create_model("conversion_calc")
        self.series_LC_chart = self.model_factory.create_model("series_rlc_chart")
        self.phasorPlotter = self.model_factory.create_model("phasor_plot")

    def register_qml_types(self):
        for type_info in self.get_qml_types():
            self.qml_engine.register_type(*type_info)
    
    def get_qml_types(self):
        return [
            (PythonModel, "Python", 1, 0, "PythonModel"),
            (ChargingCalc, "Charging", 1, 0, "ChargingCalc"),
            (PowerCalculator, "Calculator", 1, 0, "PowerCalculator"),
            (FaultCurrentCalculator, "Fault", 1, 0, "FaultCalculator"),
            (ThreePhaseSineWaveModel, "Sine", 1, 0, "SineWaveModel"),
            (ResonantFreq, "RFreq", 1, 0, "ResonantFreq"),
            (ConversionCalculator, "ConvCalc", 1, 0, "ConversionCalc"),
            (SeriesRLCChart, "RLC", 1, 0, "SeriesRLCChart"),
            (PhasorPlot, "PPlot", 1, 0, "PhasorPlot")
        ]

    def load_qml(self):
        self.qml_engine.load_qml(os.path.join(CURRENT_DIR, "qml", "main.qml"))
        
    def run(self):
        sys.exit(self.app.exec())

def setup_container() -> Container:
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

