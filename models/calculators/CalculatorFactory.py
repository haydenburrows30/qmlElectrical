from abc import ABC, abstractmethod
from typing import Type, Dict
from ..Calculator import PowerCalculator, FaultCurrentCalculator, ChargingCalc
from .BaseCalculator import BaseCalculator

class CalculatorFactory(ABC):
    @abstractmethod
    def create_calculator(self, calculator_type: str) -> BaseCalculator:
        pass

class ConcreteCalculatorFactory(CalculatorFactory):
    def __init__(self):
        self._calculators: Dict[str, Type[BaseCalculator]] = {}
        self._register_defaults()
    
    def _register_defaults(self):
        """Register default calculator types"""
        self._calculators.update({
            "power": PowerCalculator,
            "fault": FaultCurrentCalculator,
            "charging": ChargingCalc
        })
    
    def register_calculator(self, name: str, calculator_class: Type[BaseCalculator]):
        """Register a calculator class with the factory"""
        self._calculators[name] = calculator_class
    
    def create_calculator(self, calculator_type: str) -> BaseCalculator:
        """Create a calculator instance"""
        calculator_class = self._calculators.get(calculator_type)
        if calculator_class is None:
            raise ValueError(f"Unknown calculator type: {calculator_type}")
        return calculator_class()
