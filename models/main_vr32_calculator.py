#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
from PySide6.QtCore import QObject, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

# Import our calculator class
from vr32_cl7_calculator import VR32CL7Calculator

def main():
    # Create application
    app = QGuiApplication(sys.argv)
    app.setApplicationName("VR32 CL-7 Calculator")
    
    # Create our Python calculator instance
    calculator = VR32CL7Calculator()
    
    # Create QML engine
    engine = QQmlApplicationEngine()
    
    # Expose our Python calculator to QML
    engine.rootContext().setContextProperty("pyCalculator", calculator)
    
    # Load our QML file
    qml_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "VR32CL7Calculator.qml")
    engine.load(QUrl.fromLocalFile(qml_file))
    
    # Check if QML loaded successfully
    if not engine.rootObjects():
        sys.exit(-1)
    
    # Start the application event loop
    sys.exit(app.exec())

if __name__ == "__main__":
    main()