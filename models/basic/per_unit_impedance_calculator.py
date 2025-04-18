from PySide6.QtCore import QObject, Property, Signal, Slot

class PerUnitImpedanceCalculator(QObject):
    """Calculator for converting per-unit impedance from one base to another using:
       Z_p.u.2 = Z_p.u.1 × (MVA_b2/MVA_b1) × (kV_b1/kV_b2)²
    """

    # Define signals
    inputChanged = Signal()
    calculationCompleted = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Initialize parameters
        self._z_pu1 = 0.1            # Per-unit impedance on base 1
        self._mva_b1 = 100.0         # Base 1 MVA
        self._kv_b1 = 11.0           # Base 1 kV
        self._mva_b2 = 500.0         # Base 2 MVA
        self._kv_b2 = 22.0           # Base 2 kV
        self._z_pu2 = 0.0125         # Per-unit impedance on base 2
        
    def _calculate(self):
        """Calculate per-unit impedance conversion using the formula:
           Z_p.u.2 = Z_p.u.1 × (MVA_b2/MVA_b1) × (kV_b1/kV_b2)²
        """
        try:
            mva_ratio = self._mva_b2 / self._mva_b1
            kv_ratio = self._kv_b1 / self._kv_b2
            self._z_pu2 = self._z_pu1 * mva_ratio * (kv_ratio ** 2)
            return True
        except Exception as e:
            print(f"Error calculating per-unit impedance: {e}")
            return False

    # Properties
    @Property(float, notify=calculationCompleted)
    def zPu1(self):
        return self._z_pu1
        
    @zPu1.setter
    def zPu1(self, value):
        if value >= 0 and self._z_pu1 != value:
            self._z_pu1 = value
            self.inputChanged.emit()
            if self._calculate():
                self.calculationCompleted.emit()
    
    @Property(float, notify=calculationCompleted)
    def mvaB1(self):
        return self._mva_b1
        
    @mvaB1.setter
    def mvaB1(self, value):
        if value > 0 and self._mva_b1 != value:
            self._mva_b1 = value
            self.inputChanged.emit()
            if self._calculate():
                self.calculationCompleted.emit()
    
    @Property(float, notify=calculationCompleted)
    def kvB1(self):
        return self._kv_b1
        
    @kvB1.setter
    def kvB1(self, value):
        if value > 0 and self._kv_b1 != value:
            self._kv_b1 = value
            self.inputChanged.emit()
            if self._calculate():
                self.calculationCompleted.emit()
    
    @Property(float, notify=calculationCompleted)
    def mvaB2(self):
        return self._mva_b2
        
    @mvaB2.setter
    def mvaB2(self, value):
        if value > 0 and self._mva_b2 != value:
            self._mva_b2 = value
            self.inputChanged.emit()
            if self._calculate():
                self.calculationCompleted.emit()
    
    @Property(float, notify=calculationCompleted)
    def kvB2(self):
        return self._kv_b2
        
    @kvB2.setter
    def kvB2(self, value):
        if value > 0 and self._kv_b2 != value:
            self._kv_b2 = value
            self.inputChanged.emit()
            if self._calculate():
                self.calculationCompleted.emit()
    
    @Property(float, notify=calculationCompleted)
    def zPu2(self):
        return self._z_pu2
    
    # Calculation slot for all parameters
    @Slot(float, float, float, float, float)
    def calculate(self, z_pu1, mva_b1, kv_b1, mva_b2, kv_b2):
        try:
            if mva_b1 > 0 and mva_b2 > 0 and kv_b1 > 0 and kv_b2 > 0:
                self._z_pu1 = z_pu1
                self._mva_b1 = mva_b1
                self._kv_b1 = kv_b1
                self._mva_b2 = mva_b2
                self._kv_b2 = kv_b2
                if self._calculate():
                    self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating per-unit impedance: {e}")