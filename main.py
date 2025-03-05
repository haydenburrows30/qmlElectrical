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
CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

import rc_resources as rc_resources

@dataclass
class AppConfig:
    style: str = "Universal"
    app_name: str = "Electrical"
    org_name: str = "QtProject"
    icon_path: str = "icons/gallery/24x24/Wave_dark.ico"

class Application:
    def __init__(self, config: Optional[AppConfig] = None):
        self.config = config or AppConfig()
        self.setup_logging()
        self.app = QApplication(sys.argv)
        self.engine = QQmlApplicationEngine()
        self.setup_app()
        self.load_models()
        self.register_qml_types()
        self.load_qml()

    def setup_logging(self):
        logging.basicConfig(level=logging.INFO)

    def setup_app(self):
        QQuickStyle.setStyle(self.config.style)
        QApplication.setApplicationName(self.config.app_name)
        QApplication.setOrganizationName(self.config.org_name)
        QApplication.setWindowIcon(QIcon(self.config.icon_path))
        QIcon.setThemeName("gallery")

    def load_models(self):
        csv_path = "cable_data.csv"
        self.voltage_model = PythonModel(csv_path)
        self.power_calculator = PowerCalculator()
        self.fault_current_calculator = FaultCurrentCalculator()
        self.sine_wave = ThreePhaseSineWaveModel()
        self.resonant_freq = ResonantFreq()
        self.conversion_calc = ConversionCalculator()
        self.series_LC_chart = SeriesRLCChart()
        self.phasorPlotter = PhasorPlot()

    def register_qml_types(self):
        qmlRegisterType(PythonModel, "Python", 1, 0, "PythonModel")
        qmlRegisterType(ChargingCalc, "Charging", 1, 0, "ChargingCalc")
        qmlRegisterType(PowerCalculator, "Calculator", 1, 0, "PowerCalculator")
        qmlRegisterType(FaultCurrentCalculator, "Fault", 1, 0, "FaultCalculator")
        qmlRegisterType(ThreePhaseSineWaveModel, "Sine", 1, 0, "SineWaveModel")
        qmlRegisterType(ResonantFreq, "RFreq", 1, 0, "ResonantFreq")
        qmlRegisterType(ConversionCalculator, "ConvCalc", 1, 0, "ConversionCalc")
        qmlRegisterType(SeriesRLCChart, "RLC", 1, 0, "SeriesRLCChart")
        qmlRegisterType(PhasorPlot, "PPlot", 1, 0, "PhasorPlot")

    def load_qml(self):
        self.engine.load(os.path.join(CURRENT_DIR, "qml", "main.qml"))
        if not self.engine.rootObjects():
            sys.exit(-1)

    def run(self):
        sys.exit(self.app.exec())

if __name__ == "__main__":
    app = Application()
    app.run()

