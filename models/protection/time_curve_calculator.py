from PySide6.QtCore import QObject

class TimeCurveCalculator(QObject):
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

    def calculate_operating_time(self, curve_type, standard, current_multiple, time_dial):
        """Calculate relay operating time for given multiple of pickup"""
        try:
            if not curve_type or not standard:
                return None
                
            if standard not in self._curve_coefficients:
                return None
                
            if curve_type not in self._curve_coefficients[standard]:
                return None
                
            if current_multiple <= 1.0 or time_dial <= 0:
                return None
                
            coeff = self._curve_coefficients[standard][curve_type]
            
            if standard == "IEC":
                time = time_dial * (coeff["a"] / ((current_multiple**coeff["b"]) - 1))
            else:  # ANSI
                time = time_dial * (coeff["a"] / ((current_multiple**coeff["b"]) - 1) + 1)
            
            return max(0.01, time)  # Minimum time of 10ms
            
        except (TypeError, ValueError, ZeroDivisionError):
            return None

    def generate_curve_points(self, pickup_current, time_dial, curve_type, standard, 
                            min_current=None, max_current=None):
        """Generate points for plotting time-current curve"""
        try:
            if pickup_current <= 0 or time_dial <= 0:
                return [], []
                
            if min_current is None or min_current <= 0:
                min_current = pickup_current * 1.1
            if max_current is None or max_current <= min_current:
                max_current = pickup_current * 20
            
            current_points = []
            time_points = []
            
            # Generate 100 points on logarithmic scale
            ratio = (max_current/min_current)**(1/99)  # 100 points
            current = min_current
            
            for _ in range(100):
                multiple = current / pickup_current
                time = self.calculate_operating_time(curve_type, standard, multiple, time_dial)
                
                if time is not None:
                    current_points.append(float(current))
                    time_points.append(float(time))
                    
                current *= ratio
            
            return current_points, time_points
            
        except (TypeError, ValueError, ZeroDivisionError):
            return [], []
