from PySide6.QtCore import QObject, Property, Signal, Slot
import numpy as np
import math

class HarmonicAnalysisCalculator(QObject):
    """Calculator for harmonic analysis and THD calculation"""

    fundamentalChanged = Signal()
    harmonicsChanged = Signal()
    calculationsComplete = Signal()
    thdChanged = Signal()
    crestFactorChanged = Signal()  # Add new signal
    waveformChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._fundamental = 100.0  # Fundamental amplitude
        self._fundamentalMagnitude = 100.0
        self._fundamentalAngle = 0.0
        self._harmonics = [0.0] * 15  # Up to 15th harmonic
        self._harmonics_dict = {}  # Dict to store harmonic orders and their values
        self._thd = 0.0
        self._cf = 0.0
        self._individual_distortion = [0.0] * 15
        self._waveform_points = []
        self._waveform = []
        self._spectrum_points = []
        self._spectrum = []
        
        self._calculate()

    def _calculate(self):
        if self._fundamental <= 0:
            return
            
        # Calculate THD
        sum_squares = sum(h * h for h in self._harmonics)
        self._thd = math.sqrt(sum_squares) / self._fundamental * 100.0
        
        # Calculate individual harmonic distortion
        self._individual_distortion = [
            (h / self._fundamental * 100.0) if self._fundamental > 0 else 0.0
            for h in self._harmonics
        ]
        
        # Generate waveform points
        t = np.linspace(0, 0.04, 1000)  # Two cycles of 50Hz
        waveform = self._fundamental * np.sin(2 * np.pi * 50 * t)
        
        for n, amplitude in enumerate(self._harmonics, 2):
            if amplitude > 0:
                waveform += amplitude * np.sin(2 * np.pi * 50 * n * t)
        
        self._waveform_points = list(zip(t, waveform))
        
        # Calculate waveform, spectrum, THD and CF
        t = np.linspace(0, 2*np.pi, 1000)
        wave = np.zeros_like(t)
        
        # Sum all harmonics
        for order, (mag, angle) in self._harmonics_dict.items():
            wave += mag * np.sin(order * t + np.deg2rad(angle))
            
        self._waveform = wave.tolist()
        
        # Calculate THD
        fundamental = self._harmonics_dict.get(1, (100, 0))[0]
        harmonics = np.array([mag for order, (mag, _) in self._harmonics_dict.items() if order > 1])
        self._thd = np.sqrt(np.sum(harmonics**2)) / fundamental * 100
        
        # Calculate CF with check for zero
        if len(wave) and np.mean(wave**2) > 0:
            self._cf = np.max(np.abs(wave)) / np.sqrt(np.mean(wave**2))
        else:
            self._cf = 0.0
        
        self.crestFactorChanged.emit()  # Emit signal after calculation
        self.waveformChanged.emit()
        self.calculationsComplete.emit()

    # Properties and setters...
    @Property(float, notify=fundamentalChanged)
    def fundamental(self):
        return self._fundamental
    
    @fundamental.setter
    def fundamental(self, value):
        if value >= 0:
            self._fundamental = value
            self.fundamentalChanged.emit()
            self._calculate()

    @Property(list, notify=calculationsComplete)
    def harmonics(self):
        return self._harmonics
    
    @Property(float, notify=calculationsComplete)
    def thd(self):
        return self._thd

    @Property(float, notify=crestFactorChanged)  # Add notify signal
    def crestFactor(self):
        """Get Crest Factor."""
        return self._cf

    @Property(list, notify=calculationsComplete)
    def individualDistortion(self):
        return self._individual_distortion

    @Property(list, notify=calculationsComplete)
    def waveformPoints(self):
        return self._waveform_points

    @Property(list)
    def waveform(self):
        """Get time-domain waveform points."""
        return self._waveform
        
    @Property(list)
    def spectrum(self):
        """Get frequency spectrum points."""
        return self._spectrum

    @Slot(float)
    def setFundamental(self, value):
        self.fundamental = value

    @Slot(int, float)
    def setHarmonic(self, index, amplitude):
        """Set the amplitude of a specific harmonic"""
        if 0 <= index < len(self._harmonics):
            self._harmonics[index] = amplitude
            self.harmonicsChanged.emit()
            self._calculate()

    @Slot(int, float, float)
    def setHarmonic(self, order, magnitude, angle):
        """Set magnitude and angle for a harmonic order."""
        self._harmonics_dict[order] = (magnitude, angle)
        self._calculate()

    @Slot(list)
    def setAllHarmonics(self, harmonics):
        """Set all harmonic amplitudes at once"""
        if len(harmonics) <= len(self._harmonics):
            self._harmonics = harmonics + [0.0] * (len(self._harmonics) - len(harmonics))
            self.harmonicsChanged.emit()
            self._calculate()
