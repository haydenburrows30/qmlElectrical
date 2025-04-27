import numpy as np
from PySide6.QtCore import QObject, Signal, Slot, Property, QThreadPool, Qt
from .z_transform_worker import ZTransformCalculatorWorker
from .transform_utils import PYWT_AVAILABLE

class ZTransformCalculator(QObject):
    """Calculator for Z-transform, Wavelet, and Hilbert transforms with multithreading support"""
    
    transformTypeChanged = Signal()
    functionTypeChanged = Signal()
    amplitudeChanged = Signal()
    decayFactorChanged = Signal()
    frequencyChanged = Signal()
    samplingRateChanged = Signal()
    sequenceLengthChanged = Signal()
    waveletTypeChanged = Signal()
    displayOptionChanged = Signal()
    show3DChanged = Signal()
    resultsCalculated = Signal()
    calculatingChanged = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        # Initialize properties
        self._transform_type = "Z-Transform"  # "Z-Transform", "Wavelet", or "Hilbert"
        self._function_type = "Unit Step"     # Function type to transform
        self._amplitude = 1.0                 # Amplitude of the sequence
        self._decay_factor = 0.8              # Decay factor for exponential sequences
        self._frequency = 10.0                # Frequency for sinusoidal sequences (Hz)
        self._sampling_rate = 100             # Sampling rate (Hz)
        self._sequence_length = 100           # Length of the sequence
        self._wavelet_type = "db1" if PYWT_AVAILABLE else "Basic"  # Changed from "Haar" to "db1"
        self._display_option = "Magnitude"    # Display option: Magnitude, Phase, Poles/Zeros
        self._show_3d = False                 # Whether to show 3D visualization for wavelets
        self._calculating = False             # Flag for calculations in progress
        
        # Result storage
        self._time_domain = []                # Time domain signal
        self._transform_result = []           # Transform result (magnitude)
        self._phase_result = []               # Phase information
        self._frequencies = []                # Frequency domain range
        self._pole_locations = []             # Poles of the Z-transform
        self._zero_locations = []             # Zeros of the Z-transform
        self._equation_original = ""          # Text representation of input sequence
        self._equation_transform = ""         # Text representation of transformed equation
        
        # Additional properties for Z-transform
        self._roc_text = ""                   # Region of convergence text
        
        # Additional properties for wavelets
        self._wavelet_levels = 5              # Number of wavelet decomposition levels
        self._edge_handling = "symmetric"     # How edges are handled in wavelet transform
        
        # Additional properties for Hilbert
        self._min_frequency = 0.0             # Minimum instantaneous frequency
        self._max_frequency = 0.0             # Maximum instantaneous frequency
        
        # Function types
        self._function_types = [
            "Unit Step", "Unit Impulse", "Exponential Sequence", 
            "Sinusoidal", "Exponentially Damped Sine", "Rectangular Pulse",
            "First-Difference", "Moving Average", "Chirp Sequence", "Random Sequence"
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
        if self._transform_type != value and value in ["Z-Transform", "Wavelet", "Hilbert"]:
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
    
    @Property(float, notify=amplitudeChanged)
    def amplitude(self):
        return self._amplitude
    
    @amplitude.setter
    def amplitude(self, value):
        if self._amplitude != value:
            self._amplitude = value
            self.amplitudeChanged.emit()
            self._calculate()
    
    @Property(float, notify=decayFactorChanged)
    def decayFactor(self):
        return self._decay_factor
    
    @decayFactor.setter
    def decayFactor(self, value):
        if self._decay_factor != value and value > 0:
            self._decay_factor = value
            self.decayFactorChanged.emit()
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
    
    @Property(int, notify=samplingRateChanged)
    def samplingRate(self):
        return self._sampling_rate
    
    @samplingRate.setter
    def samplingRate(self, value):
        if self._sampling_rate != value and value > 0:
            self._sampling_rate = value
            self.samplingRateChanged.emit()
            self._calculate()
    
    @Property(int, notify=resultsCalculated)
    def sequenceLength(self):
        return self._sequence_length
    
    @sequenceLength.setter
    def sequenceLength(self, value):
        if self._sequence_length != value and 10 <= value <= 500:
            self._sequence_length = value
            self._calculate()
    
    @Property(str, notify=waveletTypeChanged)
    def waveletType(self):
        return self._wavelet_type
    
    @waveletType.setter
    def waveletType(self, value):
        if self._wavelet_type != value:
            if not PYWT_AVAILABLE and value != "Basic":
                # If PyWavelets is not available, only allow "Basic" type
                self._wavelet_type = "Basic"
                print("PyWavelets not available. Using basic implementation.")
            else:
                self._wavelet_type = value
                
            self.waveletTypeChanged.emit()
            if self._transform_type == "Wavelet":
                self._calculate()
    
    @Property(str, notify=displayOptionChanged)
    def displayOption(self):
        return self._display_option
    
    @displayOption.setter
    def displayOption(self, value):
        if self._display_option != value:
            self._display_option = value
            self.displayOptionChanged.emit()
            # No need to recalculate, just change display
    
    @Property(bool, notify=show3DChanged)
    def show3D(self):
        return self._show_3d
    
    @show3D.setter
    def show3D(self, value):
        if self._show_3d != value:
            self._show_3d = value
            self.show3DChanged.emit()
            # No need to recalculate, just change display
    
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
    
    @Property('QVariantList', notify=resultsCalculated)
    def poleLocations(self):
        return self._pole_locations
    
    @Property('QVariantList', notify=resultsCalculated)
    def zeroLocations(self):
        return self._zero_locations
    
    @Property(str, notify=resultsCalculated)
    def equationOriginal(self):
        return self._equation_original
    
    @Property(str, notify=resultsCalculated)
    def equationTransform(self):
        return self._equation_transform
    
    @Property(str, notify=resultsCalculated)
    def rocText(self):
        return self._roc_text
    
    @Property(int, notify=resultsCalculated)
    def waveletLevels(self):
        return self._wavelet_levels
    
    @Property(str, notify=resultsCalculated)
    def edgeHandling(self):
        return self._edge_handling
    
    @Property(float, notify=resultsCalculated)
    def minFrequency(self):
        return self._min_frequency
    
    @Property(float, notify=resultsCalculated)
    def maxFrequency(self):
        return self._max_frequency
    
    @Property(bool, constant=True)
    def pywaveletAvailable(self):
        return PYWT_AVAILABLE
    
    def _calculate(self):
        """Start calculation in a separate thread"""
        try:
            # Set calculating flag
            self.calculating = True
            
            # Create worker
            worker = ZTransformCalculatorWorker(self)
            
            # Start the worker in a separate thread
            self._thread_pool.start(worker)
            
        except Exception as e:
            print(f"Error starting calculation: {str(e)}")
            self.calculating = False
    
    @Slot("QVariantList", "QVariantList", "QVariantList", "QVariantList", "QVariantList", "QVariantList")
    def updateZTransformResults(self, time_domain, frequencies, magnitude, phase, poles, zeros):
        """Update results for Z-transform (called via invokeMethod)"""
        try:
            # Update the result properties
            self._time_domain = time_domain if time_domain else []
            self._frequencies = frequencies if frequencies else []
            self._transform_result = magnitude if magnitude else []
            self._phase_result = phase if phase else []
            self._pole_locations = poles if poles else []
            self._zero_locations = zeros if zeros else []
            
        except Exception as e:
            print(f"Error updating Z-transform results: {str(e)}")
            self._resetResults()
        finally:
            # Always set calculating to false regardless of success or failure
            self.calculating = False
            self.resultsCalculated.emit()
    
    @Slot("QVariantList", "QVariantList", "QVariantList", "QVariantList", "QVariantList")
    def updateWaveletResults(self, time_domain, scales, coeffs, magnitude, phase):
        """Update results for Wavelet transform (called via invokeMethod)"""
        try:
            # Update the result properties
            self._time_domain = time_domain if time_domain else []
            self._frequencies = scales if scales else []
            self._transform_result = magnitude if magnitude else []
            self._phase_result = phase if phase else []
            
        except Exception as e:
            print(f"Error updating Wavelet results: {str(e)}")
            self._resetResults()
        finally:
            # Always set calculating to false regardless of success or failure
            self.calculating = False
            self.resultsCalculated.emit()
    
    @Slot("QVariantList", "QVariantList", "QVariantList", "QVariantList", "QVariantList")
    def updateHilbertResults(self, time_domain, freq, magnitude, phase, analytic):
        """Update results for Hilbert transform (called via invokeMethod)"""
        try:
            # Update the result properties
            self._time_domain = time_domain if time_domain else []
            self._frequencies = freq if freq else []
            self._transform_result = magnitude if magnitude else []
            self._phase_result = phase if phase else []
            
        except Exception as e:
            print(f"Error updating Hilbert results: {str(e)}")
            self._resetResults()
        finally:
            # Always set calculating to false regardless of success or failure
            self.calculating = False
            self.resultsCalculated.emit()
    
    @Slot()
    def resetCalculation(self):
        """Reset the calculation state on error"""
        self._resetResults()
        self.calculating = False
        self.resultsCalculated.emit()
    
    def _resetResults(self):
        """Reset all result properties to empty values"""
        self._time_domain = []
        self._frequencies = []
        self._transform_result = []
        self._phase_result = []
        self._pole_locations = []
        self._zero_locations = []
        self._equation_transform = "Error in calculation"
    
    # QML slots
    @Slot(str)
    def setTransformType(self, transform_type):
        self.transformType = transform_type
    
    @Slot(str)
    def setFunctionType(self, function_type):
        self.functionType = function_type
    
    @Slot(float)
    def setAmplitude(self, value):
        self.amplitude = value
    
    @Slot(float)
    def setDecayFactor(self, value):
        self.decayFactor = value
    
    @Slot(float)
    def setFrequency(self, value):
        self.frequency = value
    
    @Slot(int)
    def setSamplingRate(self, value):
        self.samplingRate = value
    
    @Slot(int)
    def setSequenceLength(self, value):
        self.sequenceLength = value
    
    @Slot(str)
    def setWaveletType(self, value):
        self.waveletType = value
    
    @Slot(str)
    def setDisplayOption(self, value):
        self.displayOption = value
    
    @Slot(bool)
    def setShow3D(self, value):
        self.show3D = value
    
    @Slot()
    def calculate(self):
        self._calculate()
