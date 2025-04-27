import math
import numpy as np
from PySide6.QtCore import QObject, Signal, Slot, Property, QThreadPool, Qt, Q_ARG

# Import the worker class from the new file
from .worker import TransformCalculatorWorker

class TransformCalculator(QObject):
    """Calculator for Fourier and Laplace transforms with multithreading support"""
    
    transformTypeChanged = Signal()
    functionTypeChanged = Signal()
    parameterAChanged = Signal()
    parameterBChanged = Signal()
    frequencyChanged = Signal()
    samplePointsChanged = Signal()
    windowTypeChanged = Signal()
    customFormulaChanged = Signal()
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
        self._window_type = "None"        # Window function type
        self._calculating = False         # Flag for calculations in progress
        self._custom_formula = "sin(2*pi*f*t)"  # Default custom formula
        
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
            "Gaussian", "Step", "Impulse", "Damped Sine", "Custom"
        ]
        
        # Window function types
        self._window_types = [
            "None", "Hann", "Hamming", "Blackman", "Bartlett", 
            "Flattop", "Kaiser", "Gaussian", "Tukey"
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
    
    @Property(str, notify=windowTypeChanged)
    def windowType(self):
        return self._window_type
    
    @windowType.setter
    def windowType(self, value):
        if self._window_type != value and value in self._window_types:
            self._window_type = value
            self.windowTypeChanged.emit()
            # Only recalculate if Fourier is selected
            if self._transform_type == "Fourier":
                self._calculate()
    
    @Property(list, notify=resultsCalculated)
    def windowTypes(self):
        return self._window_types
    
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
    
    @Property(str, notify=customFormulaChanged)
    def customFormula(self):
        return self._custom_formula
    
    @customFormula.setter
    def customFormula(self, value):
        if self._custom_formula != value:
            self._custom_formula = value
            self.customFormulaChanged.emit()
            self._calculate()
    
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
            self._time_domain = time_domain if time_domain else []
            self._frequencies = frequencies if frequencies else []
            self._transform_result = magnitude if magnitude else []
            self._phase_result = phase if phase else []
            
        except Exception as e:
            # Log the error
            print(f"Error updating results: {str(e)}")
            # Ensure properties are at least empty lists, not None
            self._time_domain = []
            self._frequencies = []
            self._transform_result = []
            self._phase_result = []
        finally:
            # Always set calculating to false regardless of success or failure
            self.calculating = False
            self.resultsCalculated.emit()
    
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
    
    @Slot(str)
    def setWindowType(self, window_type):
        self.windowType = window_type
    
    @Slot(str)
    def setCustomFormula(self, formula):
        self.customFormula = formula
    
    @Slot()
    def calculate(self):
        self._calculate()
