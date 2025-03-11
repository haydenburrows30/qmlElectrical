from PySide6.QtCore import QObject, Signal, Property, Slot
import numpy as np

class SineCalculator(QObject):
    # Add new signals
    rmsChanged = Signal()
    peakChanged = Signal()
    yValuesChanged = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._frequency = 50.0
        self._amplitude = 230.0
        self._yValues = self._calculate_waveform()
        self._rms = self._amplitude / np.sqrt(2)
        self._peak = self._amplitude
    
    # Update properties to use notify signals
    @Property(float, notify=rmsChanged)
    def rms(self):
        return self._rms
        
    @Property(float, notify=peakChanged)
    def peak(self):
        return self._peak
        
    @Property(list, notify=yValuesChanged)
    def yValues(self):
        return self._yValues
        
    @Slot(float)
    def setFrequency(self, freq):
        self._frequency = freq
        self._yValues = self._calculate_waveform()
        self.yValuesChanged.emit()
        
    @Slot(float)
    def setAmplitude(self, amp):
        self._amplitude = amp
        self._rms = self._amplitude / np.sqrt(2)
        self._peak = self._amplitude
        self._yValues = self._calculate_waveform()
        self.rmsChanged.emit()
        self.peakChanged.emit()
        self.yValuesChanged.emit()
        
    def _calculate_waveform(self):
        t = np.linspace(0, 2*np.pi, 1000)
        return (self._amplitude * np.sin(t)).tolist()
