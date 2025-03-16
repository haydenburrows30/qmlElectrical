from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class FerroresonanceCalculator(QObject):
    """Calculator for analyzing ferroresonance conditions in transformers"""
    
    inductanceChanged = Signal()
    capacitanceChanged = Signal()
    voltageChanged = Signal()
    resonanceCalculated = Signal(float)
    riskLevelCalculated = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._inductance = 0.0  # Transformer inductance in Henries
        self._capacitance = 0.0  # System capacitance in Farads
        self._voltage = 0.0  # System voltage in V
        self._resonant_frequency = 0.0
        self._risk_level = ""

    @Property(float, notify=inductanceChanged)
    def inductance(self):
        return self._inductance

    @inductance.setter
    def inductance(self, value):
        if value >= 0 and self._inductance != value:
            self._inductance = value
            self.inductanceChanged.emit()
            self._calculate()

    @Property(float, notify=capacitanceChanged)
    def capacitance(self):
        return self._capacitance

    @capacitance.setter
    def capacitance(self, value):
        if value >= 0 and self._capacitance != value:
            self._capacitance = value
            self.capacitanceChanged.emit()
            self._calculate()

    @Property(float, notify=voltageChanged)
    def voltage(self):
        return self._voltage

    @voltage.setter
    def voltage(self, value):
        if value >= 0 and self._voltage != value:
            self._voltage = value
            self.voltageChanged.emit()
            self._calculate()

    def _calculate(self):
        """Calculate ferroresonance characteristics"""
        try:
            if self._inductance <= 0 or self._capacitance <= 0:
                return

            # Calculate resonant frequency
            self._resonant_frequency = 1 / (2 * math.pi * math.sqrt(self._inductance * self._capacitance))
            
            # Assess risk level based on system parameters
            if self._resonant_frequency < 50:  # Below power frequency
                risk = "High Risk: Subharmonic ferroresonance possible"
            elif 45 <= self._resonant_frequency <= 55:  # Near power frequency
                risk = "Severe Risk: Fundamental ferroresonance likely"
            else:
                risk = "Moderate Risk: Harmonic ferroresonance possible"
                
            self._risk_level = risk
            
            self.resonanceCalculated.emit(self._resonant_frequency)
            self.riskLevelCalculated.emit(self._risk_level)
            
        except Exception as e:
            print(f"Error in ferroresonance calculation: {e}")

    @Slot(float, float, float)
    def calculate(self, inductance, capacitance, voltage):
        """Calculate ferroresonance from given parameters"""
        self.inductance = inductance
        self.capacitance = capacitance
        self.voltage = voltage
        return self._resonant_frequency
