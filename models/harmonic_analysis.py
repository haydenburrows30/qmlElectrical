from PySide6.QtCore import QObject, Property, Signal, Slot
import numpy as np
import math

class HarmonicAnalysisCalculator(QObject):
    """Calculator for harmonic analysis and THD calculation"""

    fundamentalChanged = Signal()
    harmonicsChanged = Signal()
    calculationsComplete = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._fundamental = 100.0  # Fundamental amplitude
        self._harmonics = [0.0] * 15  # Up to 15th harmonic
        self._thd = 0.0
        self._individual_distortion = [0.0] * 15
        self._waveform_points = []
        self._spectrum_points = []
        
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

    @Property(list, notify=calculationsComplete)
    def individualDistortion(self):
        return self._individual_distortion

    @Property(list, notify=calculationsComplete)
    def waveformPoints(self):
        return self._waveform_points

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

    @Slot(list)
    def setAllHarmonics(self, harmonics):
        """Set all harmonic amplitudes at once"""
        if len(harmonics) <= len(self._harmonics):
            self._harmonics = harmonics + [0.0] * (len(self._harmonics) - len(harmonics))
            self.harmonicsChanged.emit()
            self._calculate()
