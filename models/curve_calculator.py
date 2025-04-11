from dataclasses import dataclass
import numpy as np

@dataclass
class CurveCharacteristics:
    """IEC/ANSI curve characteristics"""
    alpha: float
    beta: float
    L: float

class TimeCurveCalculator:
    """Calculate time-current curve points"""
    
    def __init__(self):
        self.curve_characteristics = {
            "IEC": {
                "Standard Inverse": CurveCharacteristics(0.14, 0.02, 0),
                "Very Inverse": CurveCharacteristics(13.5, 1, 0),
                "Extremely Inverse": CurveCharacteristics(80, 2, 0),
                "Long Time Inverse": CurveCharacteristics(120, 1, 0)
            },
            "ANSI": {
                "Moderate Inverse": CurveCharacteristics(0.0515, 0.02, 0.114),
                "Inverse": CurveCharacteristics(5.95, 2, 0.18),
                "Very Inverse": CurveCharacteristics(3.88, 2, 0.0963),
                "Extremely Inverse": CurveCharacteristics(5.67, 2, 0.0352)
            }
        }
    
    def calculate_trip_time(self, multiple, curve_type, standard, time_dial):
        """Calculate trip time for given current multiple"""
        if standard not in self.curve_characteristics:
            return None
        if curve_type not in self.curve_characteristics[standard]:
            return None
            
        char = self.curve_characteristics[standard][curve_type]
        if multiple <= 1:
            return float('inf')
            
        if standard == "IEC":
            return (char.alpha * time_dial) / (multiple**char.beta - 1)
        else:  # ANSI
            return (char.alpha * time_dial / (multiple**char.beta - 1)) + char.L

    def generate_curve_points(self, pickup_current, curve_type, standard, time_dial, 
                            min_current=None, max_current=None):
        """Generate points for plotting time-current curve"""
        if min_current is None:
            min_current = pickup_current * 0.1
        if max_current is None:
            max_current = pickup_current * 20
            
        points = np.logspace(np.log10(min_current), np.log10(max_current), 100)
        times = []
        
        for current in points:
            multiple = current / pickup_current
            trip_time = self.calculate_trip_time(multiple, curve_type, standard, time_dial)
            if trip_time and trip_time < 100:  # Limit to reasonable times
                times.append(trip_time)
            else:
                times.append(None)
                
        return list(zip(points, times))
