import logging
from typing import Any
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from .interfaces import ILogger, IQmlEngine, IModelFactory
from models.PythonModel import PythonModel
from models.ThreePhase import ThreePhaseSineWaveModel
from models.ElectricPy import ResonantFreq, ConversionCalculator, SeriesRLCChart, PhasorPlot

class DefaultLogger(ILogger):
    def setup(self, level: str) -> None:
        logging.basicConfig(level=level)

class QmlEngineWrapper(IQmlEngine):
    def __init__(self, app=None):
        self.app = app
        self.engine = None
        
    def initialize(self, app):
        """Initialize engine with QApplication instance"""
        self.app = app
        self.engine = QQmlApplicationEngine()
        
    def load_qml(self, path: str) -> None:
        if not self.engine:
            raise RuntimeError("QML Engine not initialized. Call initialize() first")
        self.engine.load(path)
        
    def register_type(self, type_class: type, uri: str, major: int, minor: int, name: str) -> None:
        qmlRegisterType(type_class, uri, major, minor, name)

class ModelFactory(IModelFactory):
    def create_model(self, model_type: str, **kwargs) -> Any:
        model_map = {
            "voltage": lambda: PythonModel(kwargs.get('csv_path')),
            "three_phase": ThreePhaseSineWaveModel,
            "resonant_freq": ResonantFreq,
            "conversion_calc": ConversionCalculator,
            "series_rlc_chart": SeriesRLCChart,
            "phasor_plot": PhasorPlot
        }
        
        if model_type not in model_map:
            raise ValueError(f"Unknown model type: {model_type}")
            
        creator = model_map[model_type]
        return creator()
