import os
import sys

from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide6.QtWidgets import QApplication
from PySide6.QtGui import QIcon
from PySide6.QtQuickControls2 import QQuickStyle

from models.PythonModel import PythonModel
from models.Calculator import PowerCalculator, FaultCurrentCalculator, ChargingCalc
from models.ThreePhase import ThreePhaseSineWaveModel
CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

import rc_resources as rc_resources

if __name__ == "__main__":
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    QQuickStyle.setStyle("Universal")
    QApplication.setApplicationName("Electrical")
    QApplication.setOrganizationName("QtProject")

    QIcon.setThemeName("gallery")

    # Load CSV before QML window appears
    csv_path = "cable_data.csv"
    voltage_model = PythonModel(csv_path)
    power_calculator = PowerCalculator()
    fault_current_calculator = FaultCurrentCalculator()
    sine_wave = ThreePhaseSineWaveModel()
    
    qmlRegisterType(PythonModel, "Python", 1, 0, "PythonModel")
    qmlRegisterType(ChargingCalc, "Charging", 1, 0, "ChargingCalc")
    qmlRegisterType(PowerCalculator, "Calculator", 1, 0, "PowerCalculator")
    qmlRegisterType(FaultCurrentCalculator, "Fault", 1, 0, "FaultCalculator")
    qmlRegisterType(ThreePhaseSineWaveModel, "Sine", 1, 0, "SineWaveModel")    

    engine.load(os.path.join(CURRENT_DIR, "qml", "main.qml"))
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())
    
    