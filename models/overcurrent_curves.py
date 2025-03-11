from PySide6.QtCore import QObject, Property, Signal, Slot, QPointF
from PySide6.QtCharts import QLineSeries
import math

class OvercurrentCurvesCalculator(QObject):
    """Calculator for time-current curve generation"""
    
    curveChanged = Signal()
    dataChanged = Signal()  # Add new signal for data changes

    def __init__(self, parent=None):
        super().__init__(parent)
        self._series = QLineSeries()
        self._pickup_current = 100.0
        self._time_dial = 0.5
        self._curve_type = "Standard Inverse"
        self._curve_data = []  # Store curve data as list of points
        
        # IEC/ANSI curve constants
        self._curve_constants = {
            "Standard Inverse": {"a": 0.14, "b": 0.02},
            "Very Inverse": {"a": 13.5, "b": 1.0},
            "Extremely Inverse": {"a": 80.0, "b": 2.0},
            "ANSI Moderately Inverse": {"a": 0.0515, "b": 0.02},
            "ANSI Very Inverse": {"a": 19.61, "b": 2.0},
            "ANSI Extremely Inverse": {"a": 28.2, "b": 2.0}
        }
        
        self._calculate_curve()

    def _calculate_curve(self):
        """Calculate time-current curve points"""
        self._series.clear()
        self._curve_data = []  # Clear previous data
        
        if self._pickup_current <= 0:
            self.dataChanged.emit()
            return
            
        constants = self._curve_constants[self._curve_type]
        
        # Generate curve points
        currents = [
            self._pickup_current * multiple 
            for multiple in [1.5, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 15, 20]
        ]
        
        for current in currents:
            multiple = current / self._pickup_current
            time = (constants["a"] * self._time_dial) / ((multiple ** constants["b"]) - 1)
            self._series.append(current, time)
            self._curve_data.append({"current": current, "time": time})
        
        self.curveChanged.emit()
        self.dataChanged.emit()

    # Replace the QLineSeries property with a list of points
    @Property('QVariantList', notify=dataChanged)
    def curveData(self):
        return self._curve_data

    @Property(float, notify=curveChanged)
    def pickupCurrent(self):
        return self._pickup_current
    
    @pickupCurrent.setter
    def pickupCurrent(self, current):
        if current > 0:
            self._pickup_current = current
            self._calculate_curve()
            
    @Property(float, notify=curveChanged)
    def timeDial(self):
        return self._time_dial
    
    @timeDial.setter
    def timeDial(self, dial):
        if dial > 0:
            self._time_dial = dial
            self._calculate_curve()
            
    @Property(str, notify=curveChanged)
    def curveType(self):
        return self._curve_type
    
    @curveType.setter
    def curveType(self, curve_type):
        if curve_type in self._curve_constants:
            self._curve_type = curve_type
            self._calculate_curve()
    
    # Expose the curve data to QML via these methods
    @Slot(result='QVariantList')
    def getCurvePoints(self):
        """Return curve points in a format usable by QML"""
        return self._curve_data
    
    @Slot(result=int)
    def getCurvePointCount(self):
        """Return number of points in the curve"""
        return len(self._curve_data)

    @Slot(float)
    def setPickupCurrent(self, current):
        self.pickupCurrent = current

    @Slot(float)
    def setTimeDial(self, dial):
        self.timeDial = dial

    @Slot(str)
    def setCurveType(self, curve_type):
        self.curveType = curve_type
