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

class ChargingCalculator(BaseCalculator):
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
    impedanceCalculated = Signal(float, float)

    def __init__(self):
        super().__init__()
        self._resistance = 0.0
        self._reactance = 0.0
        self._impedance = 0.0
        self._phase_angle = 0.0

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
            self._phase_angle = math.degrees(math.atan2(self._reactance, self._resistance))
            self.impedanceCalculated.emit(self._impedance, self._phase_angle)

    @Property(float, notify=impedanceCalculated)
    def impedance(self):
        return self._impedance
    
    @Property(float, notify=impedanceCalculated)
    def phaseAngle(self):
        return self._phase_angle

    # def reset(self):
    #     self._voltage = 0.0
    #     self._impedance = 0.0
    #     self.dataChanged.emit()
        
    # def calculate(self):
    #     self.calculateFault()

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
        """Calculate various electrical engineering conversions.

        Power & Energy Conversions:
        - Watts to dBmW: $P_{dBm} = 10 \log_{10}(P_W \cdot 1000)$
        - dBmW to Watts: $P_W = 10^{P_{dBm}/10} / 1000$
        - HP to Watts: $P_W = P_{HP} \cdot 746$
        - kW to MVA: $S_{MVA} = P_{kW}/1000$
        - Joules to kWh: $E_{kWh} = E_J/3600000$

        Frequency & Angular:
        - Rad/s to Hz: $f = \omega/(2\pi)$
        - RPM to Hz: $f = N/60$
        - Hz to RPM: $N = f \cdot 60$

        Three-Phase Relationships:
        - Line-Phase Voltage: $V_{ph} = V_L/\sqrt{3}$
        - Phase-Line Voltage: $V_L = V_{ph} \cdot \sqrt{3}$
        - Line-Phase Current: $I_{ph} = I_L/\sqrt{3}$
        - Phase-Line Current: $I_L = I_{ph} \cdot \sqrt{3}$

        Power Factor:
        - VA to W: $P = S \cdot \cos\phi$
        - W to VA: $S = P/\cos\phi$
        - kVA to kW: $P_{kW} = S_{kVA} \cdot \cos\phi$
        - kW to kVA: $S_{kVA} = P_{kW}/\cos\phi$

        Per Unit System:
        - Base Impedance: $Z_{base} = \\frac{kV_{base}^2}{MVA_{base}}$
        - Per Unit Value: $Z_{pu} = Z_{actual}/Z_{base}$
        - Impedance Base Change: $Z_{new} = Z_{old} \cdot \\frac{MVA_{old}}{MVA_{new}}$

        Sequence Components:
        - Positive Sequence: $\\vec{V_a} = V_1 \\angle 0°$
        - Negative Sequence: $\\vec{V_a} = V_2 \\angle 0°$

        Fault Calculations:
        - Symmetrical to Phase: $I_{ph} = I_{sym} \cdot \sqrt{3}$

        Reactance Frequency:
        - 50Hz to 60Hz: $X_{60} = X_{50} \cdot \\frac{60}{50}$
        """
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
            # New conversions
            elif self._conversion_type == "kw_to_mva":
                self._result = self._input_value / 1000
            elif self._conversion_type == "mva_to_kw":
                self._result = self._input_value * 1000
            elif self._conversion_type == "joules_to_kwh":
                self._result = self._input_value / 3600000
            elif self._conversion_type == "kwh_to_joules":
                self._result = self._input_value * 3600000
            elif self._conversion_type == "celsius_to_fahrenheit":
                self._result = (self._input_value * 9/5) + 32
            elif self._conversion_type == "fahrenheit_to_celsius":
                self._result = (self._input_value - 32) * 5/9
            elif self._conversion_type == "kv_to_v":
                self._result = self._input_value * 1000
            elif self._conversion_type == "v_to_kv":
                self._result = self._input_value / 1000
            elif self._conversion_type == "mh_to_h":
                self._result = self._input_value / 1000
            elif self._conversion_type == "h_to_mh":
                self._result = self._input_value * 1000
            elif self._conversion_type == "uf_to_f":
                self._result = self._input_value / 1000000
            elif self._conversion_type == "f_to_uf":
                self._result = self._input_value * 1000000
            # Additional conversions
            elif self._conversion_type == "kvar_to_var":
                self._result = self._input_value * 1000
            elif self._conversion_type == "var_to_kvar":
                self._result = self._input_value / 1000
            elif self._conversion_type == "mvar_to_var":
                self._result = self._input_value * 1000000
            elif self._conversion_type == "var_to_mvar":
                self._result = self._input_value / 1000000
            elif self._conversion_type == "ma_to_a":
                self._result = self._input_value / 1000
            elif self._conversion_type == "a_to_ma":
                self._result = self._input_value * 1000
            elif self._conversion_type == "ka_to_a":
                self._result = self._input_value * 1000
            elif self._conversion_type == "a_to_ka":
                self._result = self._input_value / 1000
            elif self._conversion_type == "ohm_to_kohm":
                self._result = self._input_value / 1000
            elif self._conversion_type == "kohm_to_ohm":
                self._result = self._input_value * 1000
            elif self._conversion_type == "mohm_to_ohm":
                self._result = self._input_value * 1000000
            elif self._conversion_type == "ohm_to_mohm":
                self._result = self._input_value / 1000000
            # Complex conversions
            elif self._conversion_type == "kva_to_kw_pf":
                # Convert kVA to kW given 0.8 power factor
                self._result = self._input_value * 0.8
            elif self._conversion_type == "kw_to_kva_pf":
                # Convert kW to kVA given 0.8 power factor
                self._result = self._input_value / 0.8
            elif self._conversion_type == "line_to_phase_voltage":
                # Convert line voltage to phase voltage (3-phase)
                self._result = self._input_value / math.sqrt(3)
            elif self._conversion_type == "phase_to_line_voltage":
                # Convert phase voltage to line voltage (3-phase)
                self._result = self._input_value * math.sqrt(3)
            elif self._conversion_type == "line_to_phase_current":
                # Convert line current to phase current (3-phase delta)
                self._result = self._input_value / math.sqrt(3)
            elif self._conversion_type == "phase_to_line_current":
                # Convert phase current to line current (3-phase delta)
                self._result = self._input_value * math.sqrt(3)
            elif self._conversion_type == "kwh_to_mwh":
                self._result = self._input_value / 1000
            elif self._conversion_type == "mwh_to_kwh":
                self._result = self._input_value * 1000
            elif self._conversion_type == "va_to_w_pf":
                # VA to W with 0.8 power factor
                self._result = self._input_value * 0.8
            elif self._conversion_type == "w_to_va_pf":
                # W to VA with 0.8 power factor
                self._result = self._input_value / 0.8
            # Advanced power system conversions
            elif self._conversion_type == "impedance_base_change":
                # Convert impedance to new base MVA (assuming old base is 100 MVA)
                new_base_mva = self._input_value
                old_base_mva = 100
                self._result = old_base_mva / new_base_mva  # Base impedance ratio
            elif self._conversion_type == "sequence_pos_to_abc":
                # Convert positive sequence to phase values (magnitude only)
                # A = 1∠0°, B = 1∠-120°, C = 1∠120°
                magnitude = self._input_value
                self._result = magnitude  # A phase magnitude
            elif self._conversion_type == "sequence_neg_to_abc":
                # Convert negative sequence to phase values (magnitude only)
                # A = 1∠0°, B = 1∠120°, C = 1∠-120°
                magnitude = self._input_value
                self._result = magnitude  # A phase magnitude
            elif self._conversion_type == "per_unit_voltage":
                # Convert voltage to per unit (base voltage 11kV)
                base_voltage = 11000
                self._result = self._input_value / base_voltage
            elif self._conversion_type == "actual_to_per_unit_z":
                # Convert actual impedance to per unit (base 100MVA, 11kV)
                base_mva = 100
                base_kv = 11
                base_z = (base_kv * base_kv * 1000) / base_mva  # in ohms
                self._result = self._input_value / base_z
            elif self._conversion_type == "sym_to_phase_fault":
                # Convert symmetrical fault current to phase values
                sym_current = self._input_value
                self._result = sym_current * math.sqrt(3)  # Line current
            elif self._conversion_type == "power_three_to_single":
                # Convert 3-phase power to per-phase
                total_power = self._input_value
                self._result = total_power / 3
            elif self._conversion_type == "reactance_freq_change":
                # Convert reactance at 50Hz to 60Hzs
                x_at_50hz = self._input_value
                self._result = x_at_50hz * (60/50)
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

class SineCalculator(QObject):
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