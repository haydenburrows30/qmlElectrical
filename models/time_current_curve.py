from PySide6.QtCore import QObject, Signal, Property, Slot
import numpy as np
import math

class TimeCurveCalculator(QObject):
    """Calculator for time-current curves and coordination"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._curve_coefficients = {
            "IEC": {
                "Standard Inverse": {"a": 0.14, "b": 0.02},
                "Very Inverse": {"a": 13.5, "b": 1.0},
                "Extremely Inverse": {"a": 80.0, "b": 2.0},
                "Long Time Inverse": {"a": 120.0, "b": 1.0}
            },
            "ANSI": {
                "Moderate Inverse": {"a": 0.0104, "b": 0.02},
                "Inverse": {"a": 5.95, "b": 2.0},
                "Very Inverse": {"a": 3.88, "b": 2.0},
                "Extremely Inverse": {"a": 5.67, "b": 2.0}
            }
        }
        self._grading_time = 0.4  # seconds between curves

    def calculate_operating_time(self, curve_type, standard, current_multiple, time_dial):
        """Calculate relay operating time for given multiple of pickup"""
        if standard not in self._curve_coefficients:
            return None
            
        if curve_type not in self._curve_coefficients[standard]:
            return None
            
        coeff = self._curve_coefficients[standard][curve_type]
        
        if standard == "IEC":
            time = time_dial * (coeff["a"] / (current_multiple**coeff["b"] - 1))
        else:  # ANSI
            time = time_dial * (coeff["a"] / (current_multiple**coeff["b"] - 1) + 1)
            
        return time

    def generate_curve_points(self, pickup_current, time_dial, curve_type, standard, 
                            min_current=None, max_current=None):
        """Generate points for plotting time-current curve"""
        if min_current is None:
            min_current = pickup_current * 1.1
        if max_current is None:
            max_current = pickup_current * 20
            
        current_points = np.logspace(np.log10(min_current), np.log10(max_current), 100)
        time_points = []
        
        for current in current_points:
            multiple = current / pickup_current
            time = self.calculate_operating_time(curve_type, standard, multiple, time_dial)
            if time:
                time_points.append(time)
            else:
                time_points.append(None)
                
        return current_points, time_points

    @Slot(float)
    def setGradingTime(self, time):
        """Set the grading time between curves"""
        self._grading_time = max(0.2, min(time, 1.0))  # Limit between 0.2-1.0s
