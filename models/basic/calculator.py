from PySide6.QtCore import QObject, Slot, Signal, Property

import math

class PowerCalculator(QObject):
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
    dataChanged = Signal()
    exportComplete = Signal(bool, str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._kva = 0.0
        self._voltage = 0.0
        self._current = 0.0
        self._phase = "Three Phase"

        from services.file_saver import FileSaver
        self._file_saver = FileSaver()
        self._file_saver.saveStatusChanged.connect(self.exportComplete)

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

    @Slot(str, list)
    def append_series(self, series_name, data_points):
        self.chart_data_qml = data_points
        self.series_name = series_name
        self.series_appended.emit()

    @Slot()
    def reset(self):
        self._voltage = 0.0
        self._current = 0.0
        self._power_factor = 1.0
        self.dataChanged.emit()
    
    @Slot()
    def calculate(self):
        self.calculateCurrent()

    @Slot()
    def exportReport(self):
        """Export power calculator report to PDF"""
        try:
            from datetime import datetime
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            pdf_file = self._file_saver.get_save_filepath("pdf", f"transformer_current_report_{timestamp}")
            if not pdf_file:
                self.exportComplete.emit(False, "PDF export canceled")
                return False
            
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            data = {
                'transformer': True,
                'transformer_phase': self._phase,
                'transformer_kva': self._kva,
                'transformer_voltage': self._voltage,
                'transformer_current': self._current,
                'power': False
            }
            
            from utils.pdf.pdf_generator_power import PowerCurrentPdfGenerator
            pdf_generator = PowerCurrentPdfGenerator()
            success = pdf_generator.generate_report(data, pdf_file)
            
            import gc
            gc.collect()
            
            if success:
                self._file_saver._emit_success_with_path(pdf_file, "PDF saved")
                return True
            else:
                self._file_saver._emit_failure_with_path(pdf_file, "Error saving PDF")
                return False
            
        except Exception as e:
            from services.logger_config import configure_logger
            logger = configure_logger("qmltest", component="power_calculator")
            error_msg = f"Error exporting report: {str(e)}"
            logger.error(error_msg)
            self.exportComplete.emit(False, error_msg)
            return False

class ChargingCalculator(QObject):
    """Calculator for capacitive charging current.
    
    Features:
    - Charging current calculation for cables
    - Frequency dependent calculations
    - Length scaling support
    
    Signals:
        chargingCurrentCalculated: Emitted when calculation completes
    """
    chargingCurrentCalculated = Signal(float)
    dataChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
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

    @Slot()
    def reset(self):
        self._voltage = 0.0
        self._capacitance = 0.0
        self._frequency = 50.0
        self.dataChanged.emit()
    
    @Slot()
    def calculate(self):
        self.calculateChargingCurrent()
    
class ImpedanceCalculator(QObject):
    """Calculator for impedance analysis.
    
    Features:
    - Impedance calculations
    - Fault current estimation
    - Complex number support
    
    Signals:
        impedanceCalculated: Emitted when impedance calculation completes
    """
    impedanceCalculated = Signal(float, float)
    dataChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
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

    @Slot()
    def reset(self):
        self._resistance = 0.0
        self._reactance = 0.0
        self._impedance = 0.0
        self._phase_angle = 0.0
        self.dataChanged.emit()
    
    @Slot()
    def calculate(self):
        self.calculateImpedance()

class ConversionCalculator(QObject):
    """Calculator for various electrical and mechanical unit conversions.
    
    Features:
    - Power conversions (watts, dBm, horsepower)
    - Frequency conversions (Hz, RPM, rad/s)
    
    Signals:
        resultCalculated: Emitted when conversion calculation completes
    """
    resultCalculated = Signal(float)
    dataChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
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
        - Watts to dBmW: $P_{dBm} = 10 \\log_{10}(P_W \\cdot 1000)$
        - dBmW to Watts: $P_W = 10^{P_{dBm}/10} / 1000$
        - HP to Watts: $P_W = P_{HP} \\cdot 746$

        Frequency & Angular:
        - Rad/s to Hz: $f = \\omega/(2\\pi)$
        - RPM to Hz: $f = N/60$
        - Hz to RPM: $N = f \\cdot 60$

        Three-Phase Relationships:
        - Line-Phase Voltage: $V_{ph} = V_L/\\sqrt{3}$
        - Phase-Line Voltage: $V_L = V_{ph} \\cdot \\sqrt{3}$
        - Line-Phase Current: $I_{ph} = I_L/\\sqrt{3}$
        - Phase-Line Current: $I_L = I_{ph} \\cdot \\sqrt{3}$

        Per Unit System:
        - Base Impedance: $Z_{base} = \\frac{kV_{base}^2}{MVA_{base}}$
        - Per Unit Value: $Z_{pu} = Z_{actual}/Z_{base}$
        - Impedance Base Change: $Z_{new} = Z_{old} \\cdot \\frac{MVA_{old}}{MVA_{new}}$

        Sequence Components:
        - Positive Sequence: $\\vec{V_a} = V_1 \\angle 0°$
        - Negative Sequence: $\\vec{V_a} = V_2 \\angle 0°$

        Fault Calculations:
        - Symmetrical to Phase: $I_{ph} = I_{sym} \\cdot \\sqrt{3}$

        Reactance Frequency:
        - 50Hz to 60Hz: $X_{60} = X_{50} \\cdot \\frac{60}{50}$
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
            elif self._conversion_type == "celsius_to_fahrenheit":
                self._result = (self._input_value * 9/5) + 32
            elif self._conversion_type == "fahrenheit_to_celsius":
                self._result = (self._input_value - 32) * 5/9
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
            self.resultCalculated.emit(self._result)

    @Property(float, notify=resultCalculated)
    def result(self):
        return self._result

    @Slot()
    def reset(self):
        self._input_value = 0.0
        self._result = 0.0
        self.dataChanged.emit()
    
    @Slot()
    def calculate(self):
        self.calculateResult()

class KwFromCurrentCalculator(QObject):
    """Calculator for determining power (kW) from current input.
    
    Features:
    - Single and three-phase power calculations
    - Custom voltage values
    - Power factor support
    - kVA calculation
    
    Signals:
        kwCalculated: Emitted when kW calculation completes
        kvaCalculated: Emitted when kVA calculation completes
    """
    kwCalculated = Signal(float)
    kvaCalculated = Signal(float)
    dataChanged = Signal()
    exportComplete = Signal(bool, str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._current = 0.0
        self._phase = "Three Phase"
        self._power_factor = 0.8  # Default power factor
        self._kw = 0.0
        self._voltage = 415.0  # Default voltage
        self._kva = 0.0

        from services.file_saver import FileSaver
        self._file_saver = FileSaver()
        self._file_saver.saveStatusChanged.connect(self.exportComplete)

    @Slot(float)
    def setCurrent(self, current):
        """Set current in amperes.
        
        Args:
            current: Current value in amperes
        """
        self._current = current
        self.calculateKw()

    @Slot(str)
    def setPhase(self, phase):
        self._phase = phase
        self.calculateKw()

    @Slot(float)
    def setPowerFactor(self, pf):
        """Set power factor.
        
        Args:
            pf: Power factor value between 0 and 1
        """
        self._power_factor = pf
        self.calculateKw()  # Always recalculate to ensure values update

    @Slot(float)
    def setVoltage(self, voltage):
        """Set voltage in volts.
        
        Args:
            voltage: Voltage value in volts
        """
        self._voltage = voltage
        self.calculateKw()

    def calculateKw(self):
        if self._current > 0:
            if self._phase == "Single Phase":
                self._kva = self._voltage * self._current / 1000
            elif self._phase == "Three Phase":
                self._kva = math.sqrt(3) * self._voltage * self._current / 1000
                
            self._kw = self._kva * self._power_factor
            
            self.kvaCalculated.emit(self._kva)
            self.kwCalculated.emit(self._kw)

    @Property(float, notify=kwCalculated)
    def kw(self):
        return self._kw

    @Property(float, notify=kvaCalculated)
    def kva(self):
        return self._kva

    @Slot()
    def reset(self):
        self._current = 0.0
        self._power_factor = 0.8
        self._voltage = 415.0
        self._kw = 0.0
        self._kva = 0.0
        self.dataChanged.emit()
    
    @Slot()
    def calculate(self):
        self.calculateKw()

    @Slot()
    def exportReport(self):
        """Export power from current calculator report to PDF"""
        try:
            from datetime import datetime
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            pdf_file = self._file_saver.get_save_filepath("pdf", f"power_current_report_{timestamp}")
            if not pdf_file:
                self.exportComplete.emit(False, "PDF export canceled")
                return False
            
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            data = {
                'transformer': False,
                'power': True,
                'power_phase': self._phase,
                'power_current': self._current,
                'power_voltage': self._voltage,
                'power_pf': self._power_factor,
                'power_kw': self._kw,
                'power_kva': self._kva
            }
            
            from utils.pdf.pdf_generator_power import PowerCurrentPdfGenerator
            pdf_generator = PowerCurrentPdfGenerator()
            success = pdf_generator.generate_report(data, pdf_file)
            
            import gc
            gc.collect()
            
            if success:
                self._file_saver._emit_success_with_path(pdf_file, "PDF saved")
                return True
            else:
                self._file_saver._emit_failure_with_path(pdf_file, "Error saving PDF")
                return False
            
        except Exception as e:
            from services.logger_config import configure_logger
            logger = configure_logger("qmltest", component="power_calculator")
            error_msg = f"Error exporting report: {str(e)}"
            logger.error(error_msg)
            self.exportComplete.emit(False, error_msg)
            return False