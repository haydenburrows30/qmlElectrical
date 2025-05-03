from PySide6.QtCore import QObject, Property, Signal, Slot
import numpy as np

from utils.series_helper import SeriesHelper

class CalculusCalculator(QObject):
    """Calculator for demonstrating differentiation and integration concepts"""

    functionChanged = Signal()
    functionTypeChanged = Signal()
    parameterAChanged = Signal()
    parameterBChanged = Signal()
    resultsCalculated = Signal()
    exportComplete = Signal(bool, str)
    
    def __init__(self, parent=None):
        """Initialize the calculator with default values"""
        super().__init__(parent)
        
        # Parameters
        self._function_type = "Sine"  # Default function
        self._parameter_a = 2.0       # Amplitude for most functions
        self._parameter_b = 2.0       # Frequency for periodic functions or other parameters
        
        # Function mapping
        self._function_map = {
            "Sine": self._sine_function,
            "Polynomial": self._polynomial_function,
            "Exponential": self._exponential_function,
            "Power": self._power_function,
            "Gaussian": self._gaussian_function
        }
        
        # Derivative mapping
        self._derivative_map = {
            "Sine": self._sine_derivative,
            "Polynomial": self._polynomial_derivative,
            "Exponential": self._exponential_derivative,
            "Power": self._power_derivative,
            "Gaussian": self._gaussian_derivative
        }
        
        # Integral mapping
        self._integral_map = {
            "Sine": self._sine_integral,
            "Polynomial": self._polynomial_integral,
            "Exponential": self._exponential_integral,
            "Power": self._power_integral,
            "Gaussian": self._gaussian_integral
        }
        
        # Store calculated values
        self._x_values = np.linspace(-5, 5, 200)
        self._function_values = np.zeros_like(self._x_values)
        self._derivative_values = np.zeros_like(self._x_values)
        self._integral_values = np.zeros_like(self._x_values)
        
        # Calculate with initial values
        self._calculate()
        
        # Initialize file saver
        from services.file_saver import FileSaver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our exportComplete signal
        self._file_saver.saveStatusChanged.connect(self.exportComplete)
    
    # Function implementations
    def _sine_function(self, x):
        return self._parameter_a * np.sin(self._parameter_b * x)
    
    def _polynomial_function(self, x):
        # Represents a*x^b, handling negative values properly
        # Use np.sign to preserve sign for odd powers, handle non-integer powers
        if self._parameter_b % 1 == 0:  # Integer exponent
            return self._parameter_a * np.power(x, self._parameter_b)
        else:  # Non-integer exponent: can't raise negative numbers
            # Apply power to absolute value, then restore sign for odd integer powers
            return self._parameter_a * np.power(np.abs(x), self._parameter_b)
    
    def _exponential_function(self, x):
        # Limit the maximum exponent to avoid overflow
        safe_exp = np.clip(self._parameter_b * x, -100, 100)
        return self._parameter_a * np.exp(safe_exp)
        
    def _power_function(self, x):
        # Represents x^a
        return np.power(np.abs(x), self._parameter_a) * np.sign(x)
        
    def _gaussian_function(self, x):
        # Represents a*e^(-(x-b)²)
        return self._parameter_a * np.exp(-np.power(x - self._parameter_b, 2))
    
    # Derivative implementations
    def _sine_derivative(self, x):
        return self._parameter_a * self._parameter_b * np.cos(self._parameter_b * x)
    
    def _polynomial_derivative(self, x):
        if self._parameter_b == 0:
            return np.zeros_like(x)
            
        # Handle non-integer powers properly
        if self._parameter_b % 1 == 0:  # Integer exponent
            if self._parameter_b == 1:
                return np.full_like(x, self._parameter_a)
            else:
                # Handle zeros in the domain for negative powers
                safe_x = np.copy(x)
                safe_x[x == 0] = 1e-10  # Small value to avoid division by zero
                return self._parameter_a * self._parameter_b * np.power(safe_x, self._parameter_b - 1)
        else:  # Non-integer exponent
            # Avoid negative bases with non-integer exponents
            safe_x = np.abs(x)
            # Avoid zero for negative powers
            safe_x[safe_x < 1e-10] = 1e-10
            return self._parameter_a * self._parameter_b * np.power(safe_x, self._parameter_b - 1)
    
    def _exponential_derivative(self, x):
        return self._parameter_a * self._parameter_b * np.exp(self._parameter_b * x)
        
    def _power_derivative(self, x):
        if self._parameter_a == 0:
            return np.zeros_like(x)
        # Handle the derivative of |x|^a * sign(x)
        return self._parameter_a * np.power(np.abs(x), self._parameter_a - 1)
        
    def _gaussian_derivative(self, x):
        return -2 * self._parameter_a * (x - self._parameter_b) * np.exp(-np.power(x - self._parameter_b, 2))
    
    # Integral implementations
    def _sine_integral(self, x):
        return -self._parameter_a / self._parameter_b * np.cos(self._parameter_b * x)
    
    def _polynomial_integral(self, x):
        if abs(self._parameter_b + 1) < 1e-10:  # Check for b = -1
            # For 1/x, integral is ln|x|
            # Avoid log(0)
            safe_x = np.copy(x)
            safe_x[np.abs(safe_x) < 1e-10] = 1e-10
            return self._parameter_a * np.log(np.abs(safe_x))
        else:
            # Handle non-integer powers properly
            if self._parameter_b % 1 == 0:  # Integer exponent
                return self._parameter_a / (self._parameter_b + 1) * np.power(x, self._parameter_b + 1)
            else:  # Non-integer exponent
                # Use absolute value and adjust sign if needed
                return self._parameter_a / (self._parameter_b + 1) * np.power(np.abs(x), self._parameter_b + 1) * np.sign(x)
    
    def _exponential_integral(self, x):
        if self._parameter_b == 0:
            return self._parameter_a * x
        return self._parameter_a / self._parameter_b * np.exp(self._parameter_b * x)
        
    def _power_integral(self, x):
        # Since we're doing indefinite integration, ignore integration constant
        if self._parameter_a == -1:
            return np.log(np.abs(x))
        else:
            return np.sign(x) * np.power(np.abs(x), self._parameter_a + 1) / (self._parameter_a + 1)
        
    def _gaussian_integral(self, x):
        # This one is tricky - we'll use error function approximation
        # For simplicity, we'll use numerical integration for this one
        result = np.zeros_like(x)
        for i in range(len(x)):
            # Simple trapezoidal rule for each point
            if i > 0:
                x_range = np.linspace(-5, x[i], 1000)
                y_values = self._gaussian_function(x_range)
                result[i] = np.trapz(y_values, x_range)
        return result
    
    # Add error handling in the _calculate method
    def _calculate(self):
        """Calculate function, derivative and integral values"""
        try:
            # Get the current function
            function = self._function_map.get(self._function_type, self._sine_function)
            derivative = self._derivative_map.get(self._function_type, self._sine_derivative)
            integral = self._integral_map.get(self._function_type, self._sine_integral)
            
            # Calculate values
            self._function_values = function(self._x_values)
            self._derivative_values = derivative(self._x_values)
            self._integral_values = integral(self._x_values)
            
            # Handle any NaN or Inf values
            self._function_values = np.nan_to_num(self._function_values, nan=0.0, posinf=10000, neginf=-10000)
            self._derivative_values = np.nan_to_num(self._derivative_values, nan=0.0, posinf=10000, neginf=-10000)
            self._integral_values = np.nan_to_num(self._integral_values, nan=0.0, posinf=10000, neginf=-10000)
            
            # Signal that calculation is complete
            self.resultsCalculated.emit()
        except Exception as e:
            print(f"Error in calculus calculation: {e}")
            # Set default values on error
            self._function_values = np.zeros_like(self._x_values)
            self._derivative_values = np.zeros_like(self._x_values)
            self._integral_values = np.zeros_like(self._x_values)
            self.resultsCalculated.emit()
    
    # Property getters/setters
    @Property(str, notify=functionTypeChanged)
    def functionType(self):
        return self._function_type
    
    @functionType.setter
    def functionType(self, value):
        if self._function_type != value and value in self._function_map:
            self._function_type = value
            self.functionTypeChanged.emit()
            self._calculate()
    
    @Property(float, notify=parameterAChanged)
    def parameterA(self):
        return self._parameter_a
    
    @parameterA.setter
    def parameterA(self, value):
        if self._parameter_a != value:
            self._parameter_a = value
            self.parameterAChanged.emit()
            self._calculate()
    
    @Property(float, notify=parameterBChanged)
    def parameterB(self):
        return self._parameter_b
    
    @parameterB.setter
    def parameterB(self, value):
        if self._parameter_b != value:
            self._parameter_b = value
            self.parameterBChanged.emit()
            self._calculate()
    
    # Methods to get calculated values for QML
    @Property('QVariantList', notify=resultsCalculated)
    def xValues(self):
        return self._x_values.tolist()
    
    @Property('QVariantList', notify=resultsCalculated)
    def functionValues(self):
        return self._function_values.tolist()
    
    @Property('QVariantList', notify=resultsCalculated)
    def derivativeValues(self):
        return self._derivative_values.tolist()
    
    @Property('QVariantList', notify=resultsCalculated)
    def integralValues(self):
        return self._integral_values.tolist()
    
    @Property(str, notify=resultsCalculated)
    def functionFormula(self):
        """Return the formula for the current function using HTML formatting"""
        if self._function_type == "Sine":
            return f"{self._parameter_a} &middot; sin({self._parameter_b}x)"
        elif self._function_type == "Polynomial":
            if self._parameter_b == 0:
                return f"{self._parameter_a}"
            elif self._parameter_b == 1:
                return f"{self._parameter_a}x"
            else:
                return f"{self._parameter_a}x<sup>{self._parameter_b}</sup>"
        elif self._function_type == "Exponential":
            return f"{self._parameter_a}e<sup>{self._parameter_b}x</sup>"
        elif self._function_type == "Power":
            return f"|x|<sup>{self._parameter_a}</sup> &middot; sign(x)"
        elif self._function_type == "Gaussian":
            return f"{self._parameter_a}e<sup>-(x-{self._parameter_b})<sup>2</sup></sup>"
        else:
            return "Unknown function"
    
    @Property(str, notify=resultsCalculated)
    def derivativeFormula(self):
        """Return the formula for the derivative using HTML formatting"""
        if self._function_type == "Sine":
            a_times_b = self._parameter_a * self._parameter_b
            return f"{a_times_b:.2f} &middot; cos({self._parameter_b:.2f}x)"
        elif self._function_type == "Polynomial":
            if self._parameter_b == 0:
                return "0"
            elif self._parameter_b == 1:
                return f"{self._parameter_a:.2f}"
            else:
                a_times_b = self._parameter_a * self._parameter_b
                b_minus_1 = self._parameter_b - 1
                return f"{a_times_b:.2f}x<sup>{b_minus_1:.2f}</sup>"
        elif self._function_type == "Exponential":
            a_times_b = self._parameter_a * self._parameter_b
            return f"{a_times_b:.2f}e<sup>{self._parameter_b:.2f}x</sup>"
        elif self._function_type == "Power":
            if self._parameter_a == 0:
                return "0"
            else:
                a_minus_1 = self._parameter_a - 1
                return f"{self._parameter_a:.2f}|x|<sup>{a_minus_1:.2f}</sup>"
        elif self._function_type == "Gaussian":
            return f"-2{self._parameter_a:.2f}(x-{self._parameter_b:.2f})e<sup>-(x-{self._parameter_b:.2f})<sup>2</sup></sup>"
        else:
            return "Unknown derivative"
    
    @Property(str, notify=resultsCalculated)
    def integralFormula(self):
        """Return the formula for the integral using HTML formatting"""
        if self._function_type == "Sine":
            return f"-({self._parameter_a}/{self._parameter_b}) &middot; cos({self._parameter_b}x) + C"
        elif self._function_type == "Polynomial":
            if self._parameter_b == -1:
                return f"{self._parameter_a} &middot; ln|x| + C"
            else:
                b_plus_1 = self._parameter_b + 1
                return f"({self._parameter_a}/{b_plus_1})x<sup>{b_plus_1}</sup> + C"
        elif self._function_type == "Exponential":
            if self._parameter_b == 0:
                return f"{self._parameter_a}x + C"
            else:
                return f"({self._parameter_a}/{self._parameter_b})e<sup>{self._parameter_b}x</sup> + C"
        elif self._function_type == "Power":
            if self._parameter_a == -1:
                return "ln|x| + C"
            else:
                a_plus_1 = self._parameter_a + 1
                return f"(sign(x)|x|<sup>{a_plus_1}</sup>)/({a_plus_1}) + C"
        elif self._function_type == "Gaussian":
            return f"erf(x-{self._parameter_b}) &middot; (&radic;&pi;/2) &middot; {self._parameter_a} + C"
        else:
            return "Unknown integral"
    
    @Property(str, notify=functionTypeChanged)
    def parameterAName(self):
        """Return the name of parameter A based on function type"""
        if self._function_type == "Sine":
            return "Amplitude"
        elif self._function_type == "Polynomial":
            return "Coefficient"
        elif self._function_type == "Exponential":
            return "Amplitude"
        elif self._function_type == "Power":
            return "Exponent"
        elif self._function_type == "Gaussian":
            return "Amplitude"
        else:
            return "Parameter A"
    
    @Property(str, notify=functionTypeChanged)
    def parameterBName(self):
        """Return the name of parameter B based on function type"""
        if self._function_type == "Sine":
            return "Frequency"
        elif self._function_type == "Polynomial":
            return "Exponent"
        elif self._function_type == "Exponential":
            return "Rate"
        elif self._function_type == "Power":
            return "N/A"
        elif self._function_type == "Gaussian":
            return "Center"
        else:
            return "Parameter B"
    
    @Property(bool, notify=functionTypeChanged)
    def showParameterB(self):
        """Should parameter B be shown for the current function?"""
        return self._function_type != "Power"
    
    @Property(str, notify=functionTypeChanged)
    def applicationExample(self):
        """Return real-world application example for the current function"""
        if self._function_type == "Sine":
            return "AC voltage in power systems (V = V₀sin(ωt)).\n\nDerivative: The rate of change of AC voltage, used in determining current through capacitors (I = C·dV/dt).\n\nIntegral: The area under a voltage curve, representing energy in joules (E = ∫V(t)·I·dt)."
        elif self._function_type == "Polynomial":
            return "Distance vs. time relationship in motion with constant acceleration (s = s₀ + v₀t + ½at²).\n\nDerivative: The velocity and acceleration of moving objects (v = ds/dt, a = dv/dt).\n\nIntegral: Work done by a variable force over distance (W = ∫F(x)·dx)."
        elif self._function_type == "Exponential":
            return "Voltage decay across a discharging capacitor (V = V₀e⁻ᵗ/ᴿᶜ).\n\nDerivative: The rate of radioactive decay or RC circuit discharge current (I = C·dV/dt).\n\nIntegral: Total charge transferred during a capacitor charging cycle (Q = ∫I(t)·dt)."
        elif self._function_type == "Power":
            return "Power law relationships in electronics (V ∝ Iᵅ).\n\nDerivative: Sensitivity of nonlinear components like diodes to voltage changes.\n\nIntegral: Energy consumed by nonlinear loads over time (E = ∫P(t)·dt)."
        elif self._function_type == "Gaussian":
            return "Signal pulse shapes in communications or normal distribution of noise in circuits.\n\nDerivative: Rate of change of pulse intensity, used in edge detection.\n\nIntegral: Total energy contained in a pulse (E = ∫P(t)·dt) or probability calculations in error analysis."
        else:
            return "Unknown function"
    
    # Define available function types for QML UI
    @Property(list)
    def availableFunctions(self):
        return list(self._function_map.keys())
    
    # Slots for QML to call
    @Slot(str)
    def setFunctionType(self, function_type):
        self.functionType = function_type
    
    @Slot(float)
    def setParameterA(self, value):
        self.parameterA = value
    
    @Slot(float)
    def setParameterB(self, value):
        self.parameterB = value
        
    @Slot()
    def calculate(self):
        self._calculate()

    @Slot(list, result="QVariantMap")
    def getMinMax(self, array):
        """Calculate min and max values from an array with safety checks and padding.
        
        Returns a dictionary with min and max values that can be used to set axis ranges.
        """
        if not array or len(array) < 1:
            return {"min": 0, "max": 1}
            
        # Only sample a reasonable number of points for min/max calculation
        max_sample_points = 1000
        step = len(array) > max_sample_points and int(len(array) / max_sample_points) or 1
            
        # Use NumPy for faster calculation if possible
        if isinstance(array, np.ndarray):
            # Use efficient numpy operations
            if step > 1:
                sampled = array[::step]
                min_val = np.min(sampled)
                max_val = np.max(sampled)
            else:
                min_val = np.min(array)
                max_val = np.max(array)
        else:
            # Fallback to list operations
            min_val = array[0]
            max_val = array[0]
            
            for i in range(0, len(array), step):
                if array[i] < min_val:
                    min_val = array[i]
                if array[i] > max_val:
                    max_val = array[i]
        
        # Avoid zero ranges that cause render issues
        if abs(max_val - min_val) < 0.00001:
            max_val = min_val + 1
        
        # Add padding (5%)
        padding = (max_val - min_val) * 0.05
        
        return {"min": round(min_val), "max": round(max_val)}

    @Slot(QObject, str)
    def setAxisRange(self, axis, type):
        """Set axis range based on data type.
        
        Args:
            axis: The QValueAxis object
            data_type: String indicating the type of data ('fft', 'phase', 'wave', etc.)
        """

        if type == "Polynomial" or type == "Exponential" or type == "Power":

            data = self._function_values.tolist()
            range_data = self.getMinMax(data)
            axis.setMax(range_data["max"])

        elif type == "Sine" or type == "Gaussian":
            data = self._function_values.tolist()
            range_data = self.getMinMax(data)
            # Add extra padding for waves
            padding = (range_data["max"] - range_data["min"]) * 0.15
            axis.setMin(range_data["min"] - padding)
            axis.setMax(range_data["max"] + padding)

        else:
            # Default to 0-1 range for other types
            axis.setMin(1)
            axis.setMax(10)
    
    @Slot(QObject, str)
    def configureLogAxis(self, axis, type):
        """Configure logarithmic axis based on function type.
        
        Args:
            axis: The LogValueAxis object
            type: The function type string
        """
        # For exponential functions, use a wider range
        if type == "Exponential":
            axis.setMin(0.1)
            axis.setMax(10000)
            axis.setMinorTickCount(10)
            axis.setLabelFormat("%.0e")  # Scientific notation
        # For polynomial functions with positive exponents
        elif type == "Polynomial" and self._parameter_b > 0:
            axis.setMin(0.1)
            axis.setMax(1000)
            axis.setMinorTickCount(8)
            axis.setLabelFormat("%.1f")
        # For power functions
        elif type == "Power" and self._parameter_a > 0:
            axis.setMin(0.1)
            axis.setMax(100)
            axis.setMinorTickCount(5)
            axis.setLabelFormat("%.1f")
        # Default configuration
        else:
            axis.setMin(0.1)
            axis.setMax(10)
            axis.setMinorTickCount(5)
            axis.setLabelFormat("%.1f")

    @Slot('QVariantList', result='QVariantList')
    def getPositiveValues(self, values):
        """Convert data to strictly positive values for log scale display.
        
        Args:
            values: List of values to process
            
        Returns:
            List with positive values only (negatives and zeros replaced)
        """
        if not values:
            return [0.1] * 10  # Default dataset if empty
        
        try:
            # Convert to numpy for faster processing if needed
            use_numpy = True
            if use_numpy:
                arr = np.array(values, dtype=float)
                # Find min positive value for replacing zeros/negatives
                pos_values = arr[arr > 0]
                min_positive = 0.1
                if len(pos_values) > 0:
                    min_positive = np.min(pos_values) / 2
                    if min_positive <= 0:
                        min_positive = 0.1
                
                # Replace non-positive values
                result = np.copy(arr)
                result[result <= 0] = min_positive
                return result.tolist()
            else:
                # Pure Python implementation (slower)
                result = []
                # Find minimum positive value
                min_positive = 0.1
                for val in values:
                    if val > 0 and (val < min_positive or min_positive == 0.1):
                        min_positive = val / 2
                
                if min_positive <= 0:
                    min_positive = 0.1
                    
                # Replace non-positive values
                for val in values:
                    if val <= 0:
                        result.append(min_positive)
                    else:
                        result.append(val)
                return result
        except Exception as e:
            print(f"Error in getPositiveValues: {e}")
            return [0.1] * len(values)  # Return safe values on error

    @Slot()
    def autoAdjustYAxis(self):
        """Auto-adjust Y axis based on current function and parameters"""
        if self._function_type == "Exponential":
            # Adjust parameter ranges for better visualization
            if self._parameter_b > 2:
                self._parameter_b = 1
            elif self._parameter_b < 0 and self._parameter_b > -2:
                self._parameter_b = -0.5
        elif self._function_type == "Polynomial" and self._parameter_b > 6:
            # Scale down high exponents
            self._parameter_b = 4
        
        # Recalculate with new parameters
        self._calculate()

    @Slot()
    def exportReport(self):
        """Export calculus analysis to PDF"""
        try:
            # Create timestamp for filename
            from datetime import datetime
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"calculus_report_{timestamp}")
            if not pdf_file:
                self.exportComplete.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Prepare data for PDF
            data = {
                'function_type': self._function_type,
                'parameter_a': self._parameter_a,
                'parameter_b': self._parameter_b,
                'parameter_a_name': self.parameterAName,
                'parameter_b_name': self.parameterBName,
                'show_parameter_b': self.showParameterB,
                'function_formula': self.functionFormula,
                'derivative_formula': self.derivativeFormula,
                'integral_formula': self.integralFormula,
                'application_example': self.applicationExample,
                'x_values': self._x_values.tolist(),
                'function_values': self._function_values.tolist(),
                'derivative_values': self._derivative_values.tolist(),
                'integral_values': self._integral_values.tolist()
            }
            
            # Generate PDF
            from utils.pdf.pdf_generator_calculus import CalculusPdfGenerator
            pdf_generator = CalculusPdfGenerator()
            success = pdf_generator.generate_report(data, pdf_file)
            
            # Force garbage collection
            import gc
            gc.collect()
            
            # Signal success or failure
            if success:
                self._file_saver._emit_success_with_path(pdf_file, "PDF saved")
                return True
            else:
                self._file_saver._emit_failure_with_path(pdf_file, "Error saving PDF")
                return False
            
        except Exception as e:
            from services.logger_config import configure_logger
            logger = configure_logger("qmltest", component="calculus_calculator")
            error_msg = f"Error exporting report: {str(e)}"
            logger.error(error_msg)
            self.exportComplete.emit(False, error_msg)
            return False
