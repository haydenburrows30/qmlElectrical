from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class ProtectionRelayCalculator(QObject):
    """Calculator for protection relay coordination"""

    pickupCurrentChanged = Signal()
    timeDialChanged = Signal()
    curveTypeChanged = Signal()
    faultCurrentChanged = Signal()
    calculationsComplete = Signal()
    curveTypesChanged = Signal()  # Add new signal

    def __init__(self, parent=None):
        super().__init__(parent)
        self._pickup_current = 100.0  # Primary amps
        self._time_dial = 0.5
        self._curve_type = "IEC Standard Inverse"
        self._fault_current = 1000.0  # Maximum fault current
        self._operating_time = 0.0
        
        # IEC Curve constants
        self._curve_constants = {
            "IEC Standard Inverse": {"a": 0.14, "b": 0.02},
            "IEC Very Inverse": {"a": 13.5, "b": 1.0},
            "IEC Extremely Inverse": {"a": 80.0, "b": 2.0},
            "IEC Long Time Inverse": {"a": 120, "b": 1.0}
        }
        
        self._curve_points = []
        self._curve_type_names = list(self._curve_constants.keys())
        
        self._calculate()

    def _calculate(self):
        if self._pickup_current <= 0:
            return
            
        # Calculate multiple of pickup
        M = self._fault_current / self._pickup_current
        
        # Get curve constants
        constants = self._curve_constants.get(self._curve_type, 
                                           self._curve_constants["IEC Standard Inverse"])
        
        # Calculate operating time
        if M > 1:
            self._operating_time = (constants["a"] * self._time_dial) / ((M ** constants["b"]) - 1)
        else:
            self._operating_time = float('inf')
            
        # Calculate time-current curve points
        multiples = [1.5, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 15, 20]
        self._curve_points = []
        
        for m in multiples:
            t = (constants["a"] * self._time_dial) / ((m ** constants["b"]) - 1)
            self._curve_points.append({"current": m * self._pickup_current, "time": t})
        
        self.calculationsComplete.emit()

    # Properties and setters...
    @Property(float, notify=pickupCurrentChanged)
    def pickupCurrent(self):
        return self._pickup_current
    
    @pickupCurrent.setter
    def pickupCurrent(self, value):
        if value > 0:
            self._pickup_current = value
            self.pickupCurrentChanged.emit()
            self._calculate()

    @Property(float, notify=timeDialChanged)
    def timeDial(self):
        return self._time_dial
    
    @timeDial.setter
    def timeDial(self, value):
        if value > 0:
            self._time_dial = value
            self.timeDialChanged.emit()
            self._calculate()

    @Property(str, notify=curveTypeChanged)
    def curveType(self):
        return self._curve_type
    
    @curveType.setter
    def curveType(self, curve):
        if curve in self._curve_constants:
            self._curve_type = curve
            self.curveTypeChanged.emit()
            self._calculate()

    @Property(float, notify=faultCurrentChanged)
    def faultCurrent(self):
        return self._fault_current
    
    @faultCurrent.setter
    def faultCurrent(self, current):
        if current > 0:
            self._fault_current = current
            self.faultCurrentChanged.emit()
            self._calculate()

    @Property(float, notify=calculationsComplete)
    def operatingTime(self):
        return self._operating_time

    @Property(list, notify=curveTypesChanged)  # Update property to use notification signal
    def curvePoints(self):
        return self._curve_points

    @Property(list, notify=curveTypesChanged)  # Update property to use notification signal
    def curveTypes(self):
        return self._curve_type_names

    # QML slots
    @Slot(float)
    def setPickupCurrent(self, current):
        self.pickupCurrent = current

    @Slot(float)
    def setTimeDial(self, td):
        self.timeDial = td

    @Slot(str)
    def setCurveType(self, curve):
        self.curveType = curve

    @Slot(float)
    def setFaultCurrent(self, current):
        self.faultCurrent = current
