from PySide6.QtCore import Slot, Signal, Property, QObject

import numpy as np
import pyqtgraph as pg

class PowerCalculator(QObject):
    currentCalculated = Signal(float)

    def __init__(self):
        super().__init__()
        self._kva = 0.0
        self._voltage = 0.0
        self._current = 0.0
        self._phase = "Three Phase"

    @Slot(float)
    def setKva(self, kva):
        self._kva = kva
        self.calculateCurrent()

    @Slot(float)
    def setVoltage(self, voltage):
        self._voltage = voltage
        self.calculateCurrent()

    @Slot(str)
    def setPhase(self, phase):
        self._phase = phase
        self.calculateCurrent()

    def calculateCurrent(self):
        if self._voltage != 0:
            if self._phase == "Single Phase":
                self._current = self._kva * 1000 / self._voltage
            elif self._phase == "Three Phase":
                self._current = self._kva * 1000 / (self._voltage * 1.732)
            self.currentCalculated.emit(self._current)

    @Property(float, notify=currentCalculated)
    def current(self):
        return self._current

class ChargingCalc(QObject):
    chargingCurrentCalculated = Signal(float)

    def __init__(self):
        super().__init__()
        self._voltage = 0.0
        self._capacitance = 0.0
        self._frequency = 50.0  # Default frequency in Hz
        self._chargingCurrent = 0.0
        self._length = 1.0 # in km

    @Slot(float)
    def setVoltage(self, voltage):
        self._voltage = voltage
        self.calculateChargingCurrent()

    @Slot(float)
    def setCapacitance(self, capacitance):
        self._capacitance = capacitance
        self.calculateChargingCurrent()

    @Slot(float)
    def setFrequency(self, frequency):
        self._frequency = frequency
        self.calculateChargingCurrent()

    @Slot(float)
    def setLength(self, length):
        self._length = length
        self.calculateChargingCurrent()

    def calculateChargingCurrent(self):
        if self._voltage != 0 and self._capacitance != 0:
            self._chargingCurrent = (2 * 3.14159 * self._frequency * (self._capacitance / 1E6 ) * self._voltage) * self._length
            self.chargingCurrentCalculated.emit(self._chargingCurrent)

    @Property(float, notify=chargingCurrentCalculated)
    def chargingCurrent(self):
        return self._chargingCurrent
    
class FaultCurrentCalculator(QObject):
    faultCurrentCalculated = Signal(float)

    def __init__(self):
        super().__init__()
        self._voltage = 0.0
        self._impedance = 0.0
        self._faultCurrent = 0.0

    @Slot(float)
    def setVoltage(self, voltage):
        self._voltage = voltage
        self.calculateFaultCurrent()

    @Slot(float)
    def setImpedance(self, impedance):
        self._impedance = impedance
        self.calculateFaultCurrent()

    def calculateFaultCurrent(self):
        if self._voltage != 0 and self._impedance != 0:
            self._faultCurrent = self._voltage / self._impedance
            self.faultCurrentCalculated.emit(self._faultCurrent)

    @Property(float, notify=faultCurrentCalculated)
    def faultCurrent(self):
        return self._faultCurrent
    
class SineWaveModel(QObject):
    dataChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self._frequency = 50
        self._amplitude = 330
        self._y_scale = 1.0
        self._x_scale = 1.0
        self._sample_rate = 500
        self._y_values = []
        self._rms = 0.0
        self._peak = 0.0
        self.update_wave()
    
    def update_wave(self):
        t = np.linspace(0, 2 * np.pi * self._x_scale, self._sample_rate)
        y = self._y_scale * self._amplitude * np.sin(self._frequency * t)

        # Apply downsampling dynamically if the sample rate is too high
        max_points = 1000  # Limit the number of points plotted
        if len(y) > max_points:
            indices = np.linspace(0, len(y) - 1, max_points, dtype=int)
            self._y_values = y[indices].tolist()
        else:
            self._y_values = y.tolist()

        self._rms = np.sqrt(np.mean(np.square(self._y_values)))
        self._peak = max(abs(min(self._y_values)), max(self._y_values))
        self.dataChanged.emit()
    
    @Property(list, notify=dataChanged)
    def yValues(self):
        return self._y_values
    
    @Property(float, notify=dataChanged)
    def rms(self):
        return self._rms
    
    @Property(float, notify=dataChanged)
    def peak(self):
        return self._peak

    @Slot(float)
    def setFrequency(self, freq):
        if abs(self._frequency - freq) > 1:  # Ignore tiny changes
            self._frequency = freq
            self.update_wave()
    
    @Slot(float)
    def setAmplitude(self, amp):
        if self._amplitude != amp:
            self._amplitude = amp
            self.update_wave()
    
    # @Slot(float)
    # def setYScale(self, scale):
    #     if self._y_scale != scale:
    #         self._y_scale = scale
    #         self.update_wave()
    
    # @Slot(float)
    # def setXScale(self, scale):
    #     if self._x_scale != scale:
    #         self._x_scale = scale
    #         self.update_wave()