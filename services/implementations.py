import logging
from typing import Any
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from .interfaces import ILogger, IQmlEngine, IModelFactory
from models.three_phase import ThreePhaseSineWaveModel
from models.rlc import SeriesRLCChart
from models.voltage_drop_orion import VoltageDrop
from models.results_manager import ResultsManager
from models.real_time_chart import RealTimeChart

class DefaultLogger(ILogger):
    """Default logging implementation using Python's logging module."""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        
    def setup(self, level=logging.INFO):
        self.logger.setLevel(level)
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)

    def info(self, message):
        self.logger.info(message)

    def error(self, message):  # Add error method
        self.logger.error(message)

    def debug(self, message):  # Add debug method
        self.logger.debug(message)

    def warning(self, message):  # Add warning method
        self.logger.warning(message)

class QmlEngineWrapper(IQmlEngine):
    """Wrapper for QQmlApplicationEngine providing initialization control."""
    
    def __init__(self, app=None):
        self.app = app
        self.engine = None
        
    def initialize(self, app):
        """Initialize the QML engine with a QApplication instance.
        
        Args:
            app: QApplication instance
        """
        self.app = app
        self.engine = QQmlApplicationEngine()
        
    def load_qml(self, path: str) -> None:
        """Load QML file at specified path.
        
        Args:
            path: Path to QML file
            
        Raises:
            RuntimeError: If engine not initialized
        """
        if not self.engine:
            raise RuntimeError("QML Engine not initialized. Call initialize() first")
        self.engine.load(path)
        
    def register_type(self, type_class: type, uri: str, major: int, minor: int, name: str) -> None:
        qmlRegisterType(type_class, uri, major, minor, name)

class ModelFactory(IModelFactory):
    """Factory for creating model instances.
    
    Manages creation of various model types with support for
    configuration parameters.
    """
    
    def create_model(self, model_type: str, **kwargs) -> Any:
        """Create a model instance of specified type.
        
        Args:
            model_type: Type of model to create
            **kwargs: Configuration parameters for model
            
        Returns:
            Created model instance
            
        Raises:
            ValueError: If model_type is unknown
        """
        model_map = {
            "three_phase": ThreePhaseSineWaveModel,
            "series_rlc_chart": SeriesRLCChart,
            "voltage_drop": VoltageDrop,
            "results_manager": ResultsManager,
            "realtime_chart": RealTimeChart
        }
        
        if model_type not in model_map:
            raise ValueError(f"Unknown model type: {model_type}")
            
        creator = model_map[model_type]
        return creator()
