from abc import ABC, abstractmethod
from PySide6.QtCore import QObject

# Create a metaclass that combines QObject and ABC
class MetaQObjectABC(type(QObject), type(ABC)):
    """Metaclass that combines QObject and ABC metaclasses.
    
    This metaclass allows creation of abstract base classes that can also
    inherit from QObject, resolving the metaclass conflict between Qt and ABC.
    """
    pass

class BaseCalculator(QObject, ABC, metaclass=MetaQObjectABC):
    """Abstract base class for all calculator implementations.
    
    Provides a common interface for calculator classes, combining Qt's QObject
    functionality with Python's ABC for abstract method definitions.
    
    All calculator implementations must inherit from this class and implement
    the abstract methods.
    """
    
    @abstractmethod
    def reset(self):
        """Reset calculator to its default state.
        
        Implementations should reset all internal values to their defaults
        and emit appropriate signals.
        """
        pass

    @abstractmethod
    def calculate(self):
        """Perform the calculator's main calculation.
        
        Implementations should perform their primary calculation logic
        and update internal state accordingly.
        """
        pass
