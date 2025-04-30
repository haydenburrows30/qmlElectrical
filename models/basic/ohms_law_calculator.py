from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class OhmsLawCalculator(QObject):
    """Calculator for Ohm's Law relationships"""

    # Define signals
    inputChanged = Signal()
    calculationCompleted = Signal()
    exportComplete = Signal(bool, str)

    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Initialize parameters
        self._voltage = 12.0     # V
        self._current = 0.12     # A
        self._resistance = 100.0  # Ohms
        self._power = 1.44       # W
        
        # Initialize file saver
        from services.file_saver import FileSaver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our exportComplete signal
        self._file_saver.saveStatusChanged.connect(self.exportComplete)
        
    def _calculate_from_vi(self, voltage, current):
        """Calculate R and P from V and I"""
        self._voltage = voltage
        self._current = current
        self._resistance = voltage / current
        self._power = voltage * current
        
    def _calculate_from_vr(self, voltage, resistance):
        """Calculate I and P from V and R"""
        self._voltage = voltage
        self._resistance = resistance
        self._current = voltage / resistance
        self._power = voltage * self._current
        
    def _calculate_from_vp(self, voltage, power):
        """Calculate I and R from V and P"""
        self._voltage = voltage
        self._power = power
        self._current = power / voltage
        self._resistance = voltage / self._current
        
    def _calculate_from_ir(self, current, resistance):
        """Calculate V and P from I and R"""
        self._current = current
        self._resistance = resistance
        self._voltage = current * resistance
        self._power = self._voltage * current
        
    def _calculate_from_ip(self, current, power):
        """Calculate V and R from I and P"""
        self._current = current
        self._power = power
        self._voltage = power / current
        self._resistance = self._voltage / current
        
    def _calculate_from_rp(self, resistance, power):
        """Calculate V and I from R and P"""
        self._resistance = resistance
        self._power = power
        self._current = math.sqrt(power / resistance)
        self._voltage = self._current * resistance

    # Properties
    @Property(float, notify=calculationCompleted)
    def voltage(self):
        return self._voltage
    
    @Property(float, notify=calculationCompleted)
    def current(self):
        return self._current
    
    @Property(float, notify=calculationCompleted)
    def resistance(self):
        return self._resistance
    
    @Property(float, notify=calculationCompleted)
    def power(self):
        return self._power
    
    # Calculation slots for different parameter combinations
    @Slot(float, float)
    def calculateFromVI(self, voltage, current):
        try:
            if voltage > 0 and current > 0:
                self._calculate_from_vi(voltage, current)
                self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating from V,I: {e}")
    
    @Slot(float, float)
    def calculateFromVR(self, voltage, resistance):
        try:
            if voltage > 0 and resistance > 0:
                self._calculate_from_vr(voltage, resistance)
                self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating from V,R: {e}")
    
    @Slot(float, float)
    def calculateFromVP(self, voltage, power):
        try:
            if voltage > 0 and power > 0:
                self._calculate_from_vp(voltage, power)
                self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating from V,P: {e}")
    
    @Slot(float, float)
    def calculateFromIR(self, current, resistance):
        try:
            if current > 0 and resistance > 0:
                self._calculate_from_ir(current, resistance)
                self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating from I,R: {e}")
    
    @Slot(float, float)
    def calculateFromIP(self, current, power):
        try:
            if current > 0 and power > 0:
                self._calculate_from_ip(current, power)
                self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating from I,P: {e}")
    
    @Slot(float, float)
    def calculateFromRP(self, resistance, power):
        try:
            if resistance > 0 and power > 0:
                self._calculate_from_rp(resistance, power)
                self.calculationCompleted.emit()
        except Exception as e:
            print(f"Error calculating from R,P: {e}")
    
    @Slot(dict)
    def exportReport(self, inputData):
        """Export Ohm's Law calculation to PDF
        
        Args:
            inputData: Dictionary containing input parameters
        """
        try:
            # Create timestamp for filename
            from datetime import datetime
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"ohms_law_report_{timestamp}")
            if not pdf_file:
                self.exportComplete.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Format values with appropriate units
            voltage_formatted = self._format_value(self._voltage, "voltage") 
            current_formatted = self._format_value(self._current, "current")
            resistance_formatted = self._format_value(self._resistance, "resistance")
            power_formatted = self._format_value(self._power, "power")
            
            # Prepare data for PDF
            data = {
                'param1_name': inputData.get('param1_name', ""),
                'param1_value': inputData.get('param1_value', 0),
                'param1_unit': inputData.get('param1_unit', ""),
                'param2_name': inputData.get('param2_name', ""),
                'param2_value': inputData.get('param2_value', 0),
                'param2_unit': inputData.get('param2_unit', ""),
                'voltage': self._voltage,
                'current': self._current,
                'resistance': self._resistance,
                'power': self._power,
                'voltage_formatted': voltage_formatted,
                'current_formatted': current_formatted,
                'resistance_formatted': resistance_formatted,
                'power_formatted': power_formatted
            }
            
            # Generate PDF
            from utils.pdf.pdf_generator_ohms import OhmsLawPdfGenerator
            pdf_generator = OhmsLawPdfGenerator()
            success = pdf_generator.generate_report(data, pdf_file)
            
            # Force garbage collection
            import gc
            gc.collect()
            
            # Signal success or failure
            if success:
                self._file_saver._emit_success_with_path(pdf_file, "PDF saved")
                return True
            else:
                self._file_saver._emit_failure_with_path(pdf_file, "Error saving PDF")
                return False
            
        except Exception as e:
            from services.logger_config import configure_logger
            logger = configure_logger("qmltest", component="ohms_law_calculator")
            error_msg = f"Error exporting report: {str(e)}"
            logger.error(error_msg)
            self.exportComplete.emit(False, error_msg)
            return False
    
    def _format_value(self, value, unit_type):
        """Format a value with appropriate units
        
        Args:
            value: The numeric value to format
            unit_type: The type of unit ('voltage', 'current', 'resistance', 'power')
            
        Returns:
            str: Formatted value with unit
        """
        if value is None or math.isnan(value):
            return "N/A"
            
        if unit_type == "voltage":
            if value < 1:
                return f"{value * 1000:.2f} mV"
            elif value >= 1000:
                return f"{value / 1000:.2f} kV"
            else:
                return f"{value:.2f} V"
                
        elif unit_type == "current":
            if value < 0.001:
                return f"{value * 1000000:.2f} μA"
            elif value < 1:
                return f"{value * 1000:.2f} mA"
            else:
                return f"{value:.2f} A"
                
        elif unit_type == "resistance":
            if value >= 1000000:
                return f"{value / 1000000:.2f} MΩ"
            elif value >= 1000:
                return f"{value / 1000:.2f} kΩ"
            else:
                return f"{value:.2f} Ω"
                
        elif unit_type == "power":
            if value < 1:
                return f"{value * 1000:.2f} mW"
            elif value >= 1000:
                return f"{value / 1000:.2f} kW"
            else:
                return f"{value:.2f} W"
                
        return f"{value:.2f}"
