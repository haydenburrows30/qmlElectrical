from PySide6.QtCore import Slot, Signal, Property, QObject
from models.calculators.BaseCalculator import BaseCalculator

from PySide6.QtCore import *
from PySide6.QtCharts import *

import numpy as np
import math

class PowerCalculator(BaseCalculator):
    currentCalculated = Signal(float)
    series_appended = Signal()

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

    def append_series(self, series_name, data_points):
        self.chart_data_qml = data_points
        self.series_name = series_name
        self.series_appended.emit()

    def reset(self):
        self._voltage = 0.0
        self._current = 0.0
        self._power_factor = 1.0
        self.dataChanged.emit()
        
    def calculate(self):
        self.calculatePower()

class ChargingCalc(BaseCalculator):
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
            self._chargingCurrent = (2 * math.pi * self._frequency * self._capacitance * self._voltage * self._length) / (math.sqrt(3) * 1000)
            self.chargingCurrentCalculated.emit(self._chargingCurrent)

    @Property(float, notify=chargingCurrentCalculated)
    def chargingCurrent(self):
        return self._chargingCurrent

    def reset(self):
        self._voltage = 0.0
        self._capacitance = 0.0
        self._frequency = 50.0
        self.dataChanged.emit()
        
    def calculate(self):
        self.calculateChargingCurrent()
    
class FaultCurrentCalculator(BaseCalculator):
    impedanceCalculated = Signal(float)

    def __init__(self):
        super().__init__()
        self._resistance = 0.0
        self._reactance = 0.0
        self._impedance = 0.0

    @Slot(float)
    def setResistance(self, resistance):
        self._resistance = resistance
        self.calculateImpedance()

    @Slot(float)
    def setReactance(self, reactance):
        self._reactance = reactance
        self.calculateImpedance()

    def calculateImpedance(self):
        if self._resistance != 0 and self._reactance != 0:
            self._impedance =  math.sqrt(math.pow(self._resistance,2) + math.pow(self._reactance,2))
            self.impedanceCalculated.emit(self._impedance)

    @Property(float, notify=impedanceCalculated)
    def impedance(self):
        return self._impedance

    def reset(self):
        self._voltage = 0.0
        self._impedance = 0.0
        self.dataChanged.emit()
        
    def calculate(self):
        self.calculateFault()
    
class SineWaveModel(QObject):
    dataChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self._frequency = 1
        self._amplitude = 330
        self._y_scale = 1.0
        self._x_scale = 1.0
        self._sample_rate = 100
        self._y_values = []
        self._rms = 0.0
        self._peak = 0.0
        self.update_wave()
    
    def update_wave(self):
        t = np.linspace(0, 2 * np.pi * self._x_scale, self._sample_rate)
        y = self._y_scale * self._amplitude * np.sin(self._frequency * t)

        # Apply downsampling dynamically if the sample rate is too high
        max_points = 500  # Limit the number of points plotted
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
        if abs(self._frequency - freq) > 0.1:  # Ignore tiny changes
            self._frequency = freq
            self.update_wave()
    
    @Slot(float)
    def setAmplitude(self, amp):
        if abs(self._amplitude - amp) > 1:  # Ignore tiny changes
            self._amplitude = amp
            self.update_wave()