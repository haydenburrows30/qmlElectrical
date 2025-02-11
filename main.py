from PySide6.QtWidgets import QApplication
import sys

from PySide6.QtCore import QAbstractTableModel, Qt
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType

from PythonModel import PythonModel

app = QApplication(sys.argv)
engine = QQmlApplicationEngine()

qmlRegisterType(PythonModel, "Python", 1, 0, "PythonModel")

engine.load("main.qml")

if not engine.rootObjects():
    sys.exit(-1)

sys.exit(app.exec())