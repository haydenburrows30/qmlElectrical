from PySide6.QtCore import QObject, Property, Signal, Slot

class BaseImpedanceCalculator(QObject):
    """Calculator for Base Impedance of a power system using Zb = (kV)^2/MVA"""

    # Define signals
    inputChanged = Signal()
    calculationCompleted = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Initialize parameters
        self._voltage_kv = 11.0     # kV
        self._power_mva = 100.0     # MVA
        self._base_impedance = 1.21  # Ohms
        
    def _calculate(self):
        """Calculate base impedance from kV and MVA"""
        try:
            # Formula: Zb = (kV)^2/MVA
            self._base_impedance = (self._voltage_kv ** 2) / self._power_mva
            return True
        except Exception as e:
            print(f"Error calculating base impedance: {e}")
            return False

    # Properties
    @Property(float, notify=calculationCompleted)
    def voltageKv(self):
        return self._voltage_kv
        
    @voltageKv.setter
    def voltageKv(self, value):
        if value > 0 and self._voltage_kv != value:
            self._voltage_kv = value
            self.inputChanged.emit()
            if self._calculate():
                self.calculationCompleted.emit()
    
    @Property(float, notify=calculationCompleted)
    def powerMva(self):
        return self._power_mva
        
    @powerMva.setter
    def powerMva(self, value):
        if value > 0 and self._power_mva != value:
            self._power_mva = value
            self.inputChanged.emit()
            if self._calculate():
                self.calculationCompleted.emit()
    
    @Property(float, notify=calculationCompleted)
    def baseImpedance(self):
        return self._base_impedance
    
    # Calculation slot
    @Slot(float, float)
    def calculate(self, voltage_kv, power_mva):
        try:
            if voltage_kv > 0 and power_mva > 0:
                self._voltage_kv = voltage_kv
                self._power_mva = power_mva
                if self._calculate():
                    self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating base impedance: {e}")