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
        try:
            # Update harmonics array from dictionary input
            harmonics = [0.0] * 15  # Reset array
            harmonics[0] = self._fundamental  # Set fundamental
            
            # Map harmonic orders to correct indices
            for order, (magnitude, _) in self._harmonics_dict.items():
                if 1 <= order < len(harmonics):
                    harmonics[order-1] = magnitude
            
            self._harmonics = harmonics
            
            # Calculate THD using only actual harmonics (excluding fundamental)
            if self._fundamental > 0:
                harmonics_sum = sum(h * h for h in harmonics[1:])
                self._thd = math.sqrt(harmonics_sum) / self._fundamental * 100.0
            
            # Calculate individual distortion for display harmonics [1,3,5,7,11,13]
            display_orders = [1, 3, 5, 7, 11, 13]
            self._individual_distortion = [
                (harmonics[order-1] / self._fundamental * 100.0)
                for order in display_orders
            ]
            
            # Generate waveform
            t = np.linspace(0, 4*np.pi, 500)
            wave = self._fundamental * np.sin(t)
            
            for n, amplitude in enumerate(harmonics[1:], 2):
                if amplitude > 0:
                    wave += amplitude * np.sin(n * t)
            
            self._waveform = wave.tolist()
            
            # Calculate crest factor
            if wave.size:
                rms = np.sqrt(np.mean(wave**2))
                if rms > 0:
                    self._cf = np.max(np.abs(wave)) / rms
            
            self.batchUpdate()
            
        except Exception as e:
            print(f"Calculation error: {e}")

    def batchUpdate(self):
        """Emit all signals at once to reduce update frequency"""
        self.harmonicsChanged.emit()
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
    def setHarmonic(self, order, magnitude, angle=0):
        """Set magnitude and angle for a harmonic order."""
        if order > 0 and order <= len(self._harmonics):
            self._harmonics_dict[order] = (magnitude, angle)
            print(f"Setting harmonic {order} to magnitude {magnitude}")  # Debug print
            self._calculate()

    @Slot(list)
    def setAllHarmonics(self, harmonics):
        """Set all harmonic amplitudes at once"""
        if len(harmonics) <= len(self._harmonics):
            self._harmonics = harmonics + [0.0] * (len(self._harmonics) - len(harmonics))
            self.harmonicsChanged.emit()
            self._calculate()
