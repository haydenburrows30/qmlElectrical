from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class OhmsLawCalculator(QObject):
    """Calculator for Ohm's Law relationships"""

    # Define signals
    inputChanged = Signal()
    calculationCompleted = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Initialize parameters
        self._voltage = 12.0     # V
        self._current = 0.12     # A
        self._resistance = 100.0  # Ohms
        self._power = 1.44       # W
        
    def _calculate_from_vi(self, voltage, current):
        """Calculate R and P from V and I"""
        self._voltage = voltage
        self._current = current
        self._resistance = voltage / current
        self._power = voltage * current
        
    def _calculate_from_vr(self, voltage, resistance):
        """Calculate I and P from V and R"""
        self._voltage = voltage
        self._resistance = resistance
        self._current = voltage / resistance
        self._power = voltage * self._current
        
    def _calculate_from_vp(self, voltage, power):
        """Calculate I and R from V and P"""
        self._voltage = voltage
        self._power = power
        self._current = power / voltage
        self._resistance = voltage / self._current
        
    def _calculate_from_ir(self, current, resistance):
        """Calculate V and P from I and R"""
        self._current = current
        self._resistance = resistance
        self._voltage = current * resistance
        self._power = self._voltage * current
        
    def _calculate_from_ip(self, current, power):
        """Calculate V and R from I and P"""
        self._current = current
        self._power = power
        self._voltage = power / current
        self._resistance = self._voltage / current
        
    def _calculate_from_rp(self, resistance, power):
        """Calculate V and I from R and P"""
        self._resistance = resistance
        self._power = power
        self._current = math.sqrt(power / resistance)
        self._voltage = self._current * resistance

    # Properties
    @Property(float, notify=calculationCompleted)
    def voltage(self):
        return self._voltage
    
    @Property(float, notify=calculationCompleted)
    def current(self):
        return self._current
    
    @Property(float, notify=calculationCompleted)
    def resistance(self):
        return self._resistance
    
    @Property(float, notify=calculationCompleted)
    def power(self):
        return self._power
    
    # Calculation slots for different parameter combinations
    @Slot(float, float)
    def calculateFromVI(self, voltage, current):
        try:
            if voltage > 0 and current > 0:
                self._calculate_from_vi(voltage, current)
                self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating from V,I: {e}")
    
    @Slot(float, float)
    def calculateFromVR(self, voltage, resistance):
        try:
            if voltage > 0 and resistance > 0:
                self._calculate_from_vr(voltage, resistance)
                self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating from V,R: {e}")
    
    @Slot(float, float)
    def calculateFromVP(self, voltage, power):
        try:
            if voltage > 0 and power > 0:
                self._calculate_from_vp(voltage, power)
                self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating from V,P: {e}")
    
    @Slot(float, float)
    def calculateFromIR(self, current, resistance):
        try:
            if current > 0 and resistance > 0:
                self._calculate_from_ir(current, resistance)
                self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating from I,R: {e}")
    
    @Slot(float, float)
    def calculateFromIP(self, current, power):
        try:
            if current > 0 and power > 0:
                self._calculate_from_ip(current, power)
                self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating from I,P: {e}")
    
    @Slot(float, float)
    def calculateFromRP(self, resistance, power):
        try:
            if resistance > 0 and power > 0:
                self._calculate_from_rp(resistance, power)
                self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating from R,P: {e}")
