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
    standardCtRatiosChanged = Signal()  # Add new signal
    standardVtRatiosChanged = Signal()  # Add new signal

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
        self._alf = 20.0  # Accuracy Limit Factor
        
        # Standard CT ratios
        self._standard_ct_ratios = [
            "5/5", "10/5", "15/5", "20/5", "25/5", "30/5", "40/5", "50/5",
            "60/5", "75/5", "100/5", "150/5", "200/5", "300/5", "400/5",
            "500/5", "600/5", "800/5", "1000/5", "1200/5", "1500/5", "2000/5"
        ]
        
        # Standard VT ratios
        self._standard_vt_ratios = [
            "11000/110", "22000/110", "33000/110", "66000/110",
            "110000/110", "132000/110", "220000/110", "400000/110"
        ]
        
        self._calculate()

    def _calculate(self):
        # Calculate CT parameters
        self._ct_ratio = self._primary_current / self._secondary_current
        
        # Calculate knee point voltage (typical 2x nominal voltage)
        self._knee_point_voltage = 2.0 * self._secondary_current * math.sqrt(self._burden_va)
        
        # Calculate VT parameters
        self._vt_ratio = self._primary_voltage / self._secondary_voltage
        
        # Calculate maximum fault current (using ALF)
        self._max_fault_current = self._primary_current * self._alf
        
        # Calculate minimum CT accuracy burden
        self._min_accuracy_burden = (self._secondary_current ** 2) * 0.25  # Typical 0.25 ohm
        
        self.calculationsComplete.emit()

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

    # Add other properties and slots as needed...

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
