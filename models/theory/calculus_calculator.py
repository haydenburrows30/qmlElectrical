from PySide6.QtCore import QObject, Property, Signal, Slot, QPointF
import numpy as np
import math

class CalculusCalculator(QObject):
    """Calculator for demonstrating differentiation and integration concepts"""

    functionChanged = Signal()
    functionTypeChanged = Signal()
    parameterAChanged = Signal()
    parameterBChanged = Signal()
    resultsCalculated = Signal()
    
    def __init__(self, parent=None):
        """Initialize the calculator with default values"""
        super().__init__(parent)
        
        # Parameters
        self._function_type = "Sine"  # Default function
        self._parameter_a = 1.0       # Amplitude for most functions
        self._parameter_b = 1.0       # Frequency for periodic functions or other parameters
        
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
    
    # Function implementations
    def _sine_function(self, x):
        return self._parameter_a * np.sin(self._parameter_b * x)
    
    def _polynomial_function(self, x):
        # Represents a*x^b
        return self._parameter_a * np.power(x, self._parameter_b)
    
    def _exponential_function(self, x):
        # Represents a*e^(b*x)
        return self._parameter_a * np.exp(self._parameter_b * x)
        
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
        return self._parameter_a * self._parameter_b * np.power(x, self._parameter_b - 1)
    
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
        if self._parameter_b == -1:
            # For 1/x, integral is ln|x|
            return self._parameter_a * np.log(np.abs(x))
        else:
            return self._parameter_a / (self._parameter_b + 1) * np.power(x, self._parameter_b + 1)
    
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
            
            # Signal that calculation is complete
            self.resultsCalculated.emit()
        except Exception as e:
            print(f"Error in calculus calculation: {e}")
    
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
        """Return the LaTeX formula for the current function"""
        if self._function_type == "Sine":
            return f"{self._parameter_a} \\sin({self._parameter_b}x)"
        elif self._function_type == "Polynomial":
            if self._parameter_b == 0:
                return f"{self._parameter_a}"
            elif self._parameter_b == 1:
                return f"{self._parameter_a}x"
            else:
                return f"{self._parameter_a}x^{{{self._parameter_b}}}"
        elif self._function_type == "Exponential":
            return f"{self._parameter_a}e^{{{self._parameter_b}x}}"
        elif self._function_type == "Power":
            return f"|x|^{{{self._parameter_a}}} \\cdot \\text{{sgn}}(x)"
        elif self._function_type == "Gaussian":
            return f"{self._parameter_a}e^{{-(x-{self._parameter_b})^2}}"
        else:
            return "Unknown function"
    
    @Property(str, notify=resultsCalculated)
    def derivativeFormula(self):
        """Return the LaTeX formula for the derivative"""
        if self._function_type == "Sine":
            return f"{self._parameter_a * self._parameter_b} \\cos({self._parameter_b}x)"
        elif self._function_type == "Polynomial":
            if self._parameter_b == 0:
                return "0"
            elif self._parameter_b == 1:
                return f"{self._parameter_a}"
            else:
                return f"{self._parameter_a * self._parameter_b}x^{{{self._parameter_b - 1}}}"
        elif self._function_type == "Exponential":
            return f"{self._parameter_a * self._parameter_b}e^{{{self._parameter_b}x}}"
        elif self._function_type == "Power":
            if self._parameter_a == 0:
                return "0"
            else:
                return f"{self._parameter_a}|x|^{{{self._parameter_a - 1}}}"
        elif self._function_type == "Gaussian":
            return f"-2{self._parameter_a}(x-{self._parameter_b})e^{{-(x-{self._parameter_b})^2}}"
        else:
            return "Unknown derivative"
    
    @Property(str, notify=resultsCalculated)
    def integralFormula(self):
        """Return the LaTeX formula for the integral"""
        if self._function_type == "Sine":
            return f"-\\frac{{{self._parameter_a}}}{{{self._parameter_b}}} \\cos({self._parameter_b}x) + C"
        elif self._function_type == "Polynomial":
            if self._parameter_b == -1:
                return f"{self._parameter_a} \\ln|x| + C"
            else:
                return f"\\frac{{{self._parameter_a}}}{{{self._parameter_b + 1}}}x^{{{self._parameter_b + 1}}} + C"
        elif self._function_type == "Exponential":
            if self._parameter_b == 0:
                return f"{self._parameter_a}x + C"
            else:
                return f"\\frac{{{self._parameter_a}}}{{{self._parameter_b}}}e^{{{self._parameter_b}x}} + C"
        elif self._function_type == "Power":
            if self._parameter_a == -1:
                return "\\ln|x| + C"
            else:
                return f"\\frac{{\\text{{sgn}}(x)|x|^{{{self._parameter_a + 1}}}}}{{{self._parameter_a + 1}}} + C"
        elif self._function_type == "Gaussian":
            return f"\\text{{erf}}(x-{self._parameter_b}) \\cdot \\frac{{\\sqrt{{\\pi}}}}{2} \\cdot {self._parameter_a} + C"
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
