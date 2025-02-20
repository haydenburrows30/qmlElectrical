import os
import sys
from pathlib import Path

from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide6.QtWidgets import QApplication
from PySide6.QtGui import QIcon
from PySide6.QtQuickControls2 import QQuickStyle

from PySide6.QtGui import QGuiApplication

from models.PythonModel import PythonModel

import rc_resources as rc_resources

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    app_dir = Path(__file__).parent

    engine.addImportPath(os.fspath(app_dir))

    import_paths = [".","..","..."]  # for all the paths you have files.

    for path in import_paths:
        engine.addImportPath(os.fspath(app_dir / path))

    print(engine.importPathList())

    QQuickStyle.setStyle("Universal")
    QApplication.setApplicationName("Electrical")
    QApplication.setOrganizationName("QtProject")

    QIcon.setThemeName("gallery")

    # Load CSV before QML window appears
    csv_path = "cable_data.csv"
    voltage_model = PythonModel(csv_path)

    qmlRegisterType(PythonModel, "Python", 1, 0, "PythonModel")

    url = "qml/main.qml"

    engine.load(os.fspath(app_dir/url))
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())


    
   
    
    
    
    