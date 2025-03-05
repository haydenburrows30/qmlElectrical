from abc import ABC, abstractmethod
from PySide6.QtCore import QObject

# Create a metaclass that combines QObject and ABC
class MetaQObjectABC(type(QObject), type(ABC)):
    pass

class BaseCalculator(QObject, ABC, metaclass=MetaQObjectABC):
    """Base calculator class that combines QObject and ABC functionality"""
    
    @abstractmethod
    def reset(self):
        """Reset calculator to default state"""
        pass

    @abstractmethod
    def calculate(self):
        """Perform main calculation"""
        pass
