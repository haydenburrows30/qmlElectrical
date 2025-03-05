from abc import ABC, abstractmethod
from typing import Any

class ICalculatorFactory(ABC):
    """Interface for calculator factory implementations."""
    
    @abstractmethod
    def create_calculator(self, calculator_type: str) -> Any:
        """Create calculator instance.
        
        Args:
            calculator_type: Type of calculator to create
            
        Returns:
            Created calculator instance
        """
        pass

class IModelFactory(ABC):
    """Interface for model factory implementations."""
    
    @abstractmethod
    def create_model(self, model_type: str, **kwargs) -> Any:
        """Create model instance.
        
        Args:
            model_type: Type of model to create
            **kwargs: Model configuration parameters
            
        Returns:
            Created model instance
        """
        pass

class IQmlEngine(ABC):
    """Interface for QML engine implementations."""
    
    @abstractmethod
    def load_qml(self, path: str) -> None:
        """Load QML file.
        
        Args:
            path: Path to QML file
        """
        pass
    
    @abstractmethod
    def register_type(self, type_class: type, uri: str, major: int, minor: int, name: str) -> None:
        """Register QML type.
        
        Args:
            type_class: Class of the type to register
            uri: URI of the type
            major: Major version
            minor: Minor version
            name: Name of the type
        """
        pass

class ILogger(ABC):
    """Interface for logger implementations."""
    
    @abstractmethod
    def setup(self, level: str) -> None:
        """Setup logger.
        
        Args:
            level: Logging level
        """
        pass
