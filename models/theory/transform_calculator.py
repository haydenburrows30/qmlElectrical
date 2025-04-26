import math
import numpy as np
import concurrent.futures
import multiprocessing
from PySide6.QtCore import QObject, Signal, Slot, Property, QRunnable, QThreadPool, QMetaObject, Qt, Q_ARG

class TransformCalculatorWorker(QRunnable):
    """Worker thread for performing calculations"""
    
    def __init__(self, parent):
        super().__init__()
        self.parent = parent
        self.transform_type = parent._transform_type
        self.function_type = parent._function_type
        self.parameter_a = parent._parameter_a
        self.parameter_b = parent._parameter_b
        self.frequency = parent._frequency
        self.sample_points = parent._sample_points
        
        # Add thread pool for parallelizing calculations
        self.thread_pool = concurrent.futures.ThreadPoolExecutor(
            max_workers=min(8, multiprocessing.cpu_count())
        )
    
    def run(self):
        try:
            # Generate the time domain signal
            time_domain = self._generate_time_domain()
            
            # Calculate the appropriate transform
            if self.transform_type == "Fourier":
                freq, magnitude, phase = self._calculate_fourier_transform(time_domain)
            else:  # Laplace
                freq, magnitude, phase = self._calculate_laplace_transform(time_domain)
            
            # Use Qt's thread-safe mechanism to update the main object
            QMetaObject.invokeMethod(self.parent, "updateResults", 
                                    Qt.ConnectionType.QueuedConnection,
                                    Q_ARG("QVariantList", time_domain),
                                    Q_ARG("QVariantList", freq),
                                    Q_ARG("QVariantList", magnitude),
                                    Q_ARG("QVariantList", phase))
            
        except Exception:
            # Silently handle the error without logging
            pass
        finally:
            # Make sure to shut down the thread pool
            self.thread_pool.shutdown(wait=False)
            
    def _generate_time_domain(self):
        """Generate the time domain signal based on the selected function"""
        if self.transform_type == "Fourier":
            # For Fourier transforms, use a time range covering several periods
            periods = 4
            t_max = periods / self.frequency if self.frequency > 0 else 10
            t = np.linspace(0, t_max, self.sample_points)
        else:
            # For Laplace transforms, use a longer time range for non-periodic functions
            t_max = 10 / self.parameter_b if self.parameter_b > 0 else 10
            t = np.linspace(0, t_max, self.sample_points)
        
        y = np.zeros_like(t)
        
        # Generate the appropriate function
        if self.function_type == "Sine":
            y = self.parameter_a * np.sin(2 * np.pi * self.frequency * t)
            self.parent._equation_original = f"{self.parameter_a} sin(2π·{self.frequency}t)"
        
        elif self.function_type == "Square":
            y = self.parameter_a * np.sign(np.sin(2 * np.pi * self.frequency * t))
            self.parent._equation_original = f"{self.parameter_a} square(2π·{self.frequency}t)"
        
        elif self.function_type == "Sawtooth":
            y = self.parameter_a * (2 * (self.frequency * t - np.floor(self.frequency * t + 0.5)))
            self.parent._equation_original = f"{self.parameter_a} sawtooth(2π·{self.frequency}t)"
        
        elif self.function_type == "Exponential":
            y = self.parameter_a * np.exp(-self.parameter_b * t)
            self.parent._equation_original = f"{self.parameter_a} e^(-{self.parameter_b}t)"
        
        elif self.function_type == "Gaussian":
            sigma = self.parameter_b/5 if self.parameter_b > 0 else 0.2
            y = self.parameter_a * np.exp(-(t - self.parameter_b)**2 / (2 * sigma**2))
            self.parent._equation_original = f"{self.parameter_a} exp(-(t-{self.parameter_b})²/2σ²)"
        
        elif self.function_type == "Step":
            y = self.parameter_a * np.ones_like(t)
            y[t < self.parameter_b] = 0
            self.parent._equation_original = f"{self.parameter_a} u(t-{self.parameter_b})"
        
        elif self.function_type == "Impulse":
            # Approximating impulse with a narrow Gaussian
            sigma = 0.05
            y = self.parameter_a * np.exp(-(t - self.parameter_b)**2 / (2 * sigma**2)) / (sigma * np.sqrt(2 * np.pi))
            self.parent._equation_original = f"{self.parameter_a} δ(t-{self.parameter_b})"
        
        elif self.function_type == "Damped Sine":
            y = self.parameter_a * np.exp(-self.parameter_b * t) * np.sin(2 * np.pi * self.frequency * t)
            self.parent._equation_original = f"{self.parameter_a} e^(-{self.parameter_b}t) sin(2π·{self.frequency}t)"
        
        # Optimize dictionary creation with list comprehension
        return [{"x": float(x), "y": float(y)} for x, y in zip(t, y)]
    
    def _calculate_fourier_transform(self, time_domain):
        """Calculate the Fourier transform - optimized with numpy vectorization"""
        # Extract t and y arrays from time_domain
        t = np.array([point["x"] for point in time_domain])
        y = np.array([point["y"] for point in time_domain])
        
        n = len(t)
        dt = t[1] - t[0]
        
        # Optimize padding calculation
        n_padded = 2**int(np.ceil(np.log2(n)) + 2) 
        
        # Use faster numpy operations where possible
        yf = np.fft.rfft(y, n=n_padded) * dt
        freq = np.fft.rfftfreq(n_padded, dt)
        
        # Vectorized operations for magnitude and phase
        magnitude = np.abs(yf)
        phase = np.angle(yf, deg=True)
        
        # Set the equation in a separate step
        self._set_fourier_equation()
        
        # Efficiently convert to list with proper data types
        return freq.astype(float).tolist(), magnitude.astype(float).tolist(), phase.astype(float).tolist()
    
    def _calculate_laplace_transform(self, time_domain):
        """Calculate the Laplace transform"""
        # Extract t and y arrays from time_domain
        t = np.array([point["x"] for point in time_domain])
        y = np.array([point["y"] for point in time_domain])
        
        # For demonstration, we'll use numerical integration for most functions
        # Use a better range for s values to clearly show resonance
        if self.function_type == "Sine":
            omega = 2 * np.pi * self.frequency
            # Create s_values centered around the resonant frequency for better visualization
            s_values = np.linspace(0, max(300, omega * 3), 200)  # Show up to 3x the resonant frequency
        else:
            s_values = np.linspace(0.1, 5, 50)  # Standard range for other functions
        
        # Initialize arrays for the results
        magnitude = np.zeros_like(s_values)
        phase = np.zeros_like(s_values)
        
        # Generate the transformed equation and compute values
        if self.function_type == "Sine":
            omega = 2 * np.pi * self.frequency
            # More precise equation showing the resonant frequency explicitly
            self.parent._equation_transform = (f"L{{f(t)}} = {self.parameter_a}·ω/(s²+ω²), "
                                              f"where ω={omega:.1f} rad/s ({self.frequency:.1f} Hz)\n"
                                              f"Resonant peak at s=j·{omega:.1f} rad/s")
            
            # This should create a resonant peak at s = jω, not a straight line
            for i, s_imag in enumerate(s_values):
                s = complex(0.1, s_imag)  # Use small real part for numerical stability
                # Calculate magnitude from the transfer function
                complex_result = self.parameter_a * omega / (s**2 + omega**2)
                magnitude[i] = abs(complex_result)
                phase[i] = np.angle(complex_result, deg=True)
            
            # Store the resonant frequency
            self.parent._resonant_frequency = omega
        elif self.function_type == "Exponential":
            self.parent._equation_transform = f"L{{f(t)}} = {self.parameter_a}/(s+{self.parameter_b})"
            for i, s in enumerate(s_values):
                magnitude[i] = self.parameter_a / (s + self.parameter_b)
                phase[i] = 0  # Real-valued for simple exponential
                
            # No specific resonance for exponential
            self.parent._resonant_frequency = -1
        else:
            # Numerical integration for other functions
            self.parent._equation_transform = "L{f(t)} = ∫₀^∞ f(t)·e^(-st)dt"
            for i, s in enumerate(s_values):
                integrand = y * np.exp(-s * t)
                magnitude[i] = np.trapz(integrand, t)
                phase[i] = 0  # Simplified
                
            # No specific resonance for other functions
            self.parent._resonant_frequency = -1
        
        return s_values.tolist(), magnitude.tolist(), phase.tolist()
    
    def _set_fourier_equation(self):
        """Set the equation for the Fourier transform"""
        if self.function_type == "Sine":
            self.parent._equation_transform = f"F(ω) = {self.parameter_a/2}i[δ(ω-{self.frequency}) - δ(ω+{self.frequency})]"
        
        elif self.function_type == "Square":
            self.parent._equation_transform = f"F(ω) = {2*self.parameter_a/np.pi}·sum(sin(nπ/2)/(n)·δ(ω-n·{self.frequency}))"
        
        elif self.function_type == "Exponential":
            self.parent._equation_transform = f"F(ω) = {self.parameter_a}/{self.parameter_b}·1/(1+iω/{self.parameter_b})"
        
        else:
            self.parent._equation_transform = "F(ω) = ∫f(t)·e^(-iωt)dt"

class TransformCalculator(QObject):
    """Calculator for Fourier and Laplace transforms with multithreading support"""
    
    transformTypeChanged = Signal()
    functionTypeChanged = Signal()
    parameterAChanged = Signal()
    parameterBChanged = Signal()
    frequencyChanged = Signal()
    samplePointsChanged = Signal()
    resultsCalculated = Signal()
    calculatingChanged = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        # Initialize properties
        self._transform_type = "Fourier"  # "Fourier" or "Laplace"
        self._function_type = "Sine"      # Function type to transform
        self._parameter_a = 1.0           # First parameter for function
        self._parameter_b = 2.0           # Second parameter for function
        self._frequency = 1.0             # Frequency for periodic functions
        self._sample_points = 500         # Number of points for visualization
        self._calculating = False         # Flag for calculations in progress
        
        # Result storage
        self._time_domain = []            # Time domain signal
        self._transform_result = []       # Transform result
        self._phase_result = []           # Phase information
        self._frequencies = []            # Frequency domain range
        self._equation_original = ""      # Text representation of input equation
        self._equation_transform = ""     # Text representation of transformed equation
        self._resonant_frequency = -1     # Resonant frequency for Laplace transforms
        
        # Function types
        self._function_types = [
            "Sine", "Square", "Sawtooth", "Exponential", 
            "Gaussian", "Step", "Impulse", "Damped Sine"
        ]
        
        # Thread pool for calculations
        self._thread_pool = QThreadPool.globalInstance()
        
        # Initialize calculations
        self._calculate()
    
    @Property(str, notify=transformTypeChanged)
    def transformType(self):
        return self._transform_type
    
    @transformType.setter
    def transformType(self, value):
        if self._transform_type != value and value in ["Fourier", "Laplace"]:
            self._transform_type = value
            self.transformTypeChanged.emit()
            self._calculate()
    
    @Property(str, notify=functionTypeChanged)
    def functionType(self):
        return self._function_type
    
    @functionType.setter
    def functionType(self, value):
        if self._function_type != value and value in self._function_types:
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
    
    @Property(float, notify=frequencyChanged)
    def frequency(self):
        return self._frequency
    
    @frequency.setter
    def frequency(self, value):
        if self._frequency != value and value > 0:
            self._frequency = value
            self.frequencyChanged.emit()
            self._calculate()
    
    @Property(int, notify=samplePointsChanged)
    def samplePoints(self):
        return self._sample_points
    
    @samplePoints.setter
    def samplePoints(self, value):
        if self._sample_points != value and 10 <= value <= 1000:
            self._sample_points = value
            self.samplePointsChanged.emit()
            self._calculate()
    
    @Property(bool, notify=calculatingChanged)
    def calculating(self):
        return self._calculating
    
    @calculating.setter
    def calculating(self, value):
        if self._calculating != value:
            self._calculating = value
            self.calculatingChanged.emit()
    
    @Property(list, notify=resultsCalculated)
    def functionTypes(self):
        return self._function_types
    
    @Property('QVariantList', notify=resultsCalculated)
    def timeDomain(self):
        return self._time_domain
    
    @Property(list, notify=resultsCalculated)
    def transformResult(self):
        return self._transform_result
    
    @Property(list, notify=resultsCalculated)
    def phaseResult(self):
        return self._phase_result
    
    @Property(list, notify=resultsCalculated)
    def frequencies(self):
        return self._frequencies
    
    @Property(str, notify=resultsCalculated)
    def equationOriginal(self):
        return self._equation_original
    
    @Property(str, notify=resultsCalculated)
    def equationTransform(self):
        return self._equation_transform
    
    @Property(float, notify=resultsCalculated)
    def resonantFrequency(self):
        return self._resonant_frequency
    
    def _calculate(self):
        """Start calculation in a separate thread"""
        try:
            # Set calculating flag
            self.calculating = True
            
            # Create worker
            worker = TransformCalculatorWorker(self)
            
            # Start the worker in a separate thread
            self._thread_pool.start(worker)
            
        except Exception:
            # Silently handle the error without logging
            self.calculating = False
    
    @Slot("QVariantList", "QVariantList", "QVariantList", "QVariantList")
    def updateResults(self, time_domain, frequencies, magnitude, phase):
        """Update results from worker thread (called via invokeMethod)"""
        try:
            # Update the result properties
            self._time_domain = time_domain
            self._frequencies = frequencies
            self._transform_result = magnitude
            self._phase_result = phase
            
            # Signal that calculation has finished
            self.calculating = False
            self.resultsCalculated.emit()
            
        except Exception:
            # Silently handle the error without logging
            self.calculating = False
    
    # QML slots
    @Slot(str)
    def setTransformType(self, transform_type):
        self.transformType = transform_type
    
    @Slot(str)
    def setFunctionType(self, function_type):
        self.functionType = function_type
    
    @Slot(float)
    def setParameterA(self, value):
        self.parameterA = value
    
    @Slot(float)
    def setParameterB(self, value):
        self.parameterB = value
    
    @Slot(float)
    def setFrequency(self, value):
        self.frequency = value
    
    @Slot(int)
    def setSamplePoints(self, value):
        self.samplePoints = value
    
    @Slot()
    def calculate(self):
        self._calculate()
