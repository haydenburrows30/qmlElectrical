import sys
import os.path

from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide6.QtWidgets import QApplication
from PySide6.QtGui import QIcon
from PySide6.QtQuickControls2 import QQuickStyle

from models.PythonModel import PythonModel
from models.models import VoltageDropModel

import rc_resources as rc_resources

if __name__ == "__main__":
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()

    QQuickStyle.setStyle("Universal")
    QApplication.setApplicationName("Electrical")
    QApplication.setOrganizationName("QtProject")

    QIcon.setThemeName("gallery")

    # Load CSV before QML window appears
    csv_path = "cable_data.csv"  # Change this path if needed
    voltage_model = VoltageDropModel(csv_path)

    qmlRegisterType(VoltageDropModel, "VoltageDrop", 1, 0, "VoltageDropModel")
    qmlRegisterType(PythonModel, "Python", 1, 0, "PythonModel")

    engine.load("qml/main.qml")

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())