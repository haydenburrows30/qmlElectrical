from abc import ABC, abstractmethod
from typing import Type, Dict
from ..calculator import ConversionCalculator, PowerCalculator, FaultCurrentCalculator, ChargingCalculator, KwFromCurrentCalculator
from .BaseCalculator import BaseCalculator
from ..transformer_calculator import TransformerCalculator
from ..motor_calculator import MotorCalculator
from ..power_factor_correction import PowerFactorCorrectionCalculator
from ..cable_ampacity import CableAmpacityCalculator
from ..protection_relay import ProtectionRelayCalculator
from ..harmonic_analysis import HarmonicAnalysisCalculator
from ..instrument_transformer import InstrumentTransformerCalculator
from ..discrimination_analyzer import DiscriminationAnalyzer
from ..voltage_drop_calculator import VoltageDropCalc
from ..machine_calculator import MachineCalculator
from ..earthing_calculator import EarthingCalculator
from ..transmission_calculator import TransmissionLineCalculator
from ..delta_transformer import DeltaTransformerCalculator
from ..ref_rgf_calculator import RefRgfCalculator

class CalculatorFactory(ABC):
    """Abstract factory interface for calculator creation.
    
    Defines the interface for creating calculator instances, allowing
    different factory implementations to provide different calculator types.
    """
    
    @abstractmethod
    def create_calculator(self, calculator_type: str) -> BaseCalculator:
        """Create a calculator instance of the specified type.
        
        Args:
            calculator_type: String identifier for the calculator type
            
        Returns:
            BaseCalculator: Instance of the requested calculator
            
        Raises:
            ValueError: If calculator_type is not recognized
        """
        pass

class ConcreteCalculatorFactory(CalculatorFactory):
    """Concrete implementation of calculator factory.
    
    Manages registration and creation of calculator instances with support
    for built-in calculator types and dynamic registration of new types.
    """
    
    def __init__(self):
        """Initialize factory with default calculator registrations."""
        self._calculators: Dict[str, Type[BaseCalculator]] = {}
        self._register_defaults()
    
    def _register_defaults(self):
        """Register the standard set of calculator types."""
        self._calculators.update({
            "power": PowerCalculator,
            "fault": FaultCurrentCalculator,
            "charging": ChargingCalculator,
            "transformer": TransformerCalculator,
            "motor_starting": MotorCalculator,
            "pf_correction": PowerFactorCorrectionCalculator,
            "cable_ampacity": CableAmpacityCalculator,
            "protection_relay": ProtectionRelayCalculator,
            "harmonic_analysis": HarmonicAnalysisCalculator,
            "instrument_transformer": InstrumentTransformerCalculator,
            "discrimination_analyzer": DiscriminationAnalyzer,
            "voltage_drop": VoltageDropCalc,
            "conversion": ConversionCalculator,
            "machine": MachineCalculator,
            "earthing": EarthingCalculator,
            "transmission_line": TransmissionLineCalculator,
            "delta_transformer": DeltaTransformerCalculator,
            "ref_rgf": RefRgfCalculator,
            "kw_from_current": KwFromCurrentCalculator

        })
    
    def register_calculator(self, name: str, calculator_class: Type[BaseCalculator]):
        """Register a new calculator type.
        
        Args:
            name: String identifier for the calculator type
            calculator_class: Class reference for the calculator implementation
        """
        self._calculators[name] = calculator_class
    
    def create_calculator(self, calculator_type: str) -> BaseCalculator:
        """Create and return a new calculator instance.
        
        Args:
            calculator_type: String identifier for the calculator type
            
        Returns:
            BaseCalculator: New instance of the requested calculator
            
        Raises:
            ValueError: If calculator_type is not registered
        """
        calculator_class = self._calculators.get(calculator_type)
        if calculator_class is None:
            raise ValueError(f"Unknown calculator type: {calculator_type}")
        return calculator_class()
