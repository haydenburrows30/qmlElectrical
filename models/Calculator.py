from PySide6.QtCore import Slot, Signal, Property, QObject
from models.calculators.BaseCalculator import BaseCalculator

from PySide6.QtCore import *
from PySide6.QtCharts import *

import numpy as np
import math

class PowerCalculator(BaseCalculator):
    """Calculator for power-related calculations.
    
    Features:
    - Single and three-phase power calculations
    - Current calculation based on power and voltage
    - Power factor support
    
    Signals:
        currentCalculated: Emitted when current calculation completes
        series_appended: Emitted when new data series is added
    """
    
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
        """Set apparent power in kVA.
        
        Args:
            kva: Apparent power value
        """
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
    """Calculator for capacitive charging current.
    
    Features:
    - Charging current calculation for cables
    - Frequency dependent calculations
    - Length scaling support
    
    Signals:
        chargingCurrentCalculated: Emitted when calculation completes
    """
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
    """Calculator for fault current analysis.
    
    Features:
    - Impedance calculations
    - Fault current estimation
    - Complex number support
    
    Signals:
        impedanceCalculated: Emitted when impedance calculation completes
    """
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

class ResonantFrequencyCalculator(BaseCalculator):
    """Calculator for resonant frequency.
    
    Features:
    - LC resonant frequency calculation
    - Capacitance and inductance based calculations
    
    Signals:
        frequencyCalculated: Emitted when frequency calculation completes
    """
    frequencyCalculated = Signal(float)

    def __init__(self):
        super().__init__()
        self._capacitance = 0.0  # in microfarads
        self._inductance = 0.0   # in millihenries
        self._frequency = 0.0    # in Hz

    @Slot(float)
    def setCapacitance(self, capacitance):
        self._capacitance = capacitance
        self.calculateFrequency()

    @Slot(float)
    def setInductance(self, inductance):
        self._inductance = inductance
        self.calculateFrequency()

    def calculateFrequency(self):
        if self._capacitance > 0 and self._inductance > 0:
            # Convert from μF to F and mH to H
            c_farads = self._capacitance * 1e-6
            l_henries = self._inductance * 1e-3
            self._frequency = 1 / (2 * math.pi * math.sqrt(l_henries * c_farads))
            self.frequencyCalculated.emit(self._frequency)

    @Property(float, notify=frequencyCalculated)
    def frequency(self):
        return self._frequency

    def reset(self):
        self._capacitance = 0.0
        self._inductance = 0.0
        self._frequency = 0.0
        self.dataChanged.emit()
        
    def calculate(self):
        self.calculateFrequency()

class ConversionCalculator(BaseCalculator):
    """Calculator for various electrical and mechanical unit conversions.
    
    Features:
    - Power conversions (watts, dBm, horsepower)
    - Frequency conversions (Hz, RPM, rad/s)
    
    Signals:
        resultCalculated: Emitted when conversion calculation completes
    """
    resultCalculated = Signal(float)

    def __init__(self):
        super().__init__()
        self._input_value = 0.0
        self._conversion_type = "watts_to_dbmw"
        self._result = 0.0

    @Slot(float)
    def setInputValue(self, value):
        self._input_value = value
        self.calculateResult()

    @Slot(str)
    def setConversionType(self, conversion_type):
        self._conversion_type = conversion_type
        self.calculateResult()

    def calculateResult(self):
        if self._input_value != 0:
            if self._conversion_type == "watts_to_dbmw":
                self._result = 10 * math.log10(self._input_value * 1000)
            elif self._conversion_type == "dbmw_to_watts":
                self._result = math.pow(10, self._input_value / 10) / 1000
            elif self._conversion_type == "rad_to_hz":
                self._result = self._input_value / (2 * math.pi)
            elif self._conversion_type == "hp_to_watts":
                self._result = self._input_value * 746
            elif self._conversion_type == "rpm_to_hz":
                self._result = self._input_value / 60
            elif self._conversion_type == "radians_to_hz":
                self._result = self._input_value / (2 * math.pi)
            elif self._conversion_type == "hz_to_rpm":
                self._result = self._input_value * 60
            elif self._conversion_type == "watts_to_hp":
                self._result = self._input_value / 746
            self.resultCalculated.emit(self._result)

    @Property(float, notify=resultCalculated)
    def result(self):
        return self._result

    def reset(self):
        self._input_value = 0.0
        self._result = 0.0
        self.dataChanged.emit()
        
    def calculate(self):
        self.calculateResult()

class PowerTriangleModel(QObject):
    dataChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self._apparent_power = 100.0  # S (kVA)
        self._power_factor = 0.8      # cos(φ)
        self._real_power = 0.0        # P (kW)
        self._reactive_power = 0.0    # Q (kVAr)
        self._phase_angle = 0.0       # φ (degrees)
        self.update_values()
    
    def update_values(self):
        self._phase_angle = math.degrees(math.acos(self._power_factor))
        self._real_power = self._apparent_power * self._power_factor
        self._reactive_power = self._apparent_power * math.sin(math.radians(self._phase_angle))
        self.dataChanged.emit()
        
    @Property(float, notify=dataChanged)
    def apparentPower(self):
        return self._apparent_power
        
    @Property(float, notify=dataChanged)
    def powerFactor(self):
        return self._power_factor
        
    @Property(float, notify=dataChanged)
    def realPower(self):
        return self._real_power
        
    @Property(float, notify=dataChanged)
    def reactivePower(self):
        return self._reactive_power
        
    @Property(float, notify=dataChanged)
    def phaseAngle(self):
        return self._phase_angle
    
    @Slot(float)
    def setApparentPower(self, value):
        if abs(self._apparent_power - value) > 0.1:
            self._apparent_power = value
            self.update_values()
            
    @Slot(float)
    def setPowerFactor(self, value):
        if value > 0 and value <= 1 and abs(self._power_factor - value) > 0.01:
            self._power_factor = value
            self.update_values()
            
    @Slot(float)
    def setRealPower(self, value):
        if abs(self._real_power - value) > 0.1:
            self._real_power = value
            self._power_factor = self._real_power / self._apparent_power if self._apparent_power > 0 else 0
            self.update_values()

class ImpedanceVectorModel(QObject):
    dataChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self._resistance = 3.0    # R (ohms)
        self._reactance = 4.0     # X (ohms)
        self._impedance = 0.0     # Z (ohms)
        self._phase_angle = 0.0   # θ (degrees)
        self.update_values()
    
    def update_values(self):
        self._impedance = math.sqrt(self._resistance**2 + self._reactance**2)
        self._phase_angle = math.degrees(math.atan2(self._reactance, self._resistance))
        self.dataChanged.emit()
        
    @Property(float, notify=dataChanged)
    def resistance(self):
        return self._resistance
        
    @Property(float, notify=dataChanged)
    def reactance(self):
        return self._reactance
        
    @Property(float, notify=dataChanged)
    def impedance(self):
        return self._impedance
        
    @Property(float, notify=dataChanged)
    def phaseAngle(self):
        return self._phase_angle
    
    @Slot(float)
    def setResistance(self, value):
        if abs(self._resistance - value) > 0.01:
            self._resistance = value
            self.update_values()
            
    @Slot(float)
    def setReactance(self, value):
        if abs(self._reactance - value) > 0.01:
            self._reactance = value
            self.update_values()