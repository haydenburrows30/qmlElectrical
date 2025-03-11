from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class InstrumentTransformerCalculator(QObject):
    """Calculator for CT and VT parameters"""

    primaryCurrentChanged = Signal()
    secondaryCurrentChanged = Signal()
    primaryVoltageChanged = Signal()
    secondaryVoltageChanged = Signal()
    burdenChanged = Signal()
    accuracyChanged = Signal()
    calculationsComplete = Signal()
    standardCtRatiosChanged = Signal()
    standardVtRatiosChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._primary_current = 100.0
        self._secondary_current = 5.0
        self._primary_voltage = 11000.0
        self._secondary_voltage = 110.0
        self._burden_va = 15.0
        self._accuracy_class = "0.5"
        self._ct_ratio = 20.0
        self._vt_ratio = 100.0
        self._knee_point_voltage = 0.0
        self._alf = 20.0
        
        self._standard_ct_ratios = [
            "5/5", "10/5", "15/5", "20/5", "25/5", "30/5", "40/5", "50/5",
            "60/5", "75/5", "100/5", "150/5", "200/5", "300/5", "400/5",
            "500/5", "600/5", "800/5", "1000/5", "1200/5", "1500/5", "2000/5"
        ]
        
        self._standard_vt_ratios = [
            "11000/110", "22000/110", "33000/110", "66000/110",
            "110000/110", "132000/110", "220000/110", "400000/110"
        ]
        
        self._accuracy_factors = {
            "0.1": 1.5,  # Higher factor for better accuracy
            "0.2": 1.3,
            "0.5": 1.2,
            "1.0": 1.1
        }
        
        self._calculate()

    @Property(float, notify=primaryVoltageChanged)
    def primaryVoltage(self):
        return self._primary_voltage

    @primaryVoltage.setter
    def primaryVoltage(self, value):
        if value > 0:
            self._primary_voltage = value
            self.primaryVoltageChanged.emit()
            self._calculate()

    @Property(str, notify=accuracyChanged)
    def accuracyClass(self):
        return self._accuracy_class

    @accuracyClass.setter
    def accuracyClass(self, value):
        if self._accuracy_class != value:
            self._accuracy_class = value
            self.accuracyChanged.emit()
            self._calculate()

    def _calculate(self):
        """Calculate transformer parameters based on inputs"""
        try:
            if self._primary_current > 0 and self._secondary_current > 0:
                # Get accuracy factor
                accuracy_factor = self._accuracy_factors.get(self._accuracy_class, 1.2)
                
                # CT calculations with accuracy consideration
                self._ct_ratio = self._primary_current / self._secondary_current
                self._knee_point_voltage = 2.0 * self._secondary_current * math.sqrt(self._burden_va) * accuracy_factor
                self._max_fault_current = self._primary_current * self._alf
                self._min_accuracy_burden = (self._burden_va / (self._secondary_current ** 2)) * accuracy_factor
                
                # VT affects calculations
                if self._primary_voltage > 0 and self._secondary_voltage > 0:
                    vt_ratio = self._primary_voltage / self._secondary_voltage
                    self._knee_point_voltage *= (1 + (vt_ratio / 1000))
                    self._min_accuracy_burden *= (1 + (vt_ratio / 10000))
            
            self.calculationsComplete.emit()
            
        except Exception as e:
            print(f"Calculation error: {e}")
            self._knee_point_voltage = 0.0
            self._max_fault_current = 0.0
            self._min_accuracy_burden = 0.0

    @Property(list, notify=standardCtRatiosChanged)
    def standardCtRatios(self):
        return self._standard_ct_ratios

    @Property(list, notify=standardVtRatiosChanged)
    def standardVtRatios(self):
        return self._standard_vt_ratios

    @Property(float, notify=primaryCurrentChanged)
    def primaryCurrent(self):
        return self._primary_current
    
    @primaryCurrent.setter
    def primaryCurrent(self, current):
        if current > 0:
            self._primary_current = current
            self.primaryCurrentChanged.emit()
            self._calculate()

    @Property(float, notify=burdenChanged)
    def burden(self):
        return self._burden_va
    
    @burden.setter
    def burden(self, va):
        if va > 0:
            self._burden_va = va
            self.burdenChanged.emit()
            self._calculate()

    @Property(float, notify=calculationsComplete)
    def kneePointVoltage(self):
        return self._knee_point_voltage

    @Property(float, notify=calculationsComplete)
    def maxFaultCurrent(self):
        return self._max_fault_current

    @Property(float, notify=calculationsComplete)
    def minAccuracyBurden(self):
        return self._min_accuracy_burden

    @Slot(str)
    def setCtRatio(self, ratio):
        """Set CT ratio from standard format (e.g., '100/5')"""
        try:
            primary, secondary = map(float, ratio.split('/'))
            self.primaryCurrent = primary
            self._secondary_current = secondary
            self._calculate()
        except:
            pass

    @Slot(str)
    def setVtRatio(self, ratio):
        """Set VT ratio from standard format (e.g., '11000/110')"""
        try:
            primary, secondary = map(float, ratio.split('/'))
            self._primary_voltage = primary
            self._secondary_voltage = secondary
            self._calculate()
        except:
            pass

    @Slot(float)
    def setBurden(self, va):
        self.burden = va
