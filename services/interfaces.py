from abc import ABC, abstractmethod
from typing import Any

class ICalculatorFactory(ABC):
    @abstractmethod
    def create_calculator(self, calculator_type: str) -> Any:
        pass

class IModelFactory(ABC):
    @abstractmethod
    def create_model(self, model_type: str, **kwargs) -> Any:
        pass

class IQmlEngine(ABC):
    @abstractmethod
    def load_qml(self, path: str) -> None:
        pass
    
    @abstractmethod
    def register_type(self, type_class: type, uri: str, major: int, minor: int, name: str) -> None:
        pass

class ILogger(ABC):
    @abstractmethod
    def setup(self, level: str) -> None:
        pass
