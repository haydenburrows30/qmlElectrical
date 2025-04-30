from PySide6.QtCore import QObject, Property, Signal, Slot
import tempfile
import os
from datetime import datetime
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

from services.file_saver import FileSaver
from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="battery_calculator")

class BatteryCalculator(QObject):
    """Calculator for battery sizing and runtime calculations"""

    loadChanged = Signal()
    systemVoltageChanged = Signal()
    backupTimeChanged = Signal()
    depthOfDischargeChanged = Signal()
    batteryTypeChanged = Signal()
    calculationsComplete = Signal()
    exportComplete = Signal(bool, str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._load = 0.0  # Watts
        self._system_voltage = 12.0  # Volts
        self._backup_time = 4.0  # Hours
        self._depth_of_discharge = 50.0  # Percent
        self._battery_type = "Lead Acid"
        
        # Calculated values
        self._current_draw = 0.0  # Amps
        self._required_capacity = 0.0  # Amp-hours
        self._recommended_capacity = 0.0  # Amp-hours with safety factor
        self._energy_storage = 0.0  # kWh
        
        # Safety factors by battery type
        self._safety_factors = {
            "Lead Acid": 1.25,
            "Lithium Ion": 1.1,
            "AGM": 1.15
        }
        
        # Initialize file saver
        self._file_saver = FileSaver()
        self._file_saver.saveStatusChanged.connect(self.exportComplete)

        self._calculate()

    def _calculate(self):
        """Calculate battery parameters based on inputs"""
        try:
            if self._system_voltage <= 0 or self._load < 0:
                return
                
            # Calculate current draw
            self._current_draw = self._load / self._system_voltage if self._system_voltage > 0 else 0
            
            # Calculate required capacity considering depth of discharge
            if self._depth_of_discharge > 0:
                # Correct formula: multiply by (100/DoD) since we can only use DoD% of the battery
                self._required_capacity = (self._current_draw * self._backup_time) * (100 / self._depth_of_discharge)
            else:
                self._required_capacity = 0
                
            # Apply safety factor based on battery type
            safety_factor = self._safety_factors.get(self._battery_type, 1.2)
            self._recommended_capacity = self._required_capacity * safety_factor
            
            # Calculate energy storage in kWh
            self._energy_storage = (self._recommended_capacity * self._system_voltage) / 1000
            
            self.calculationsComplete.emit()
            
        except Exception as e:
            print(f"Battery calculation error: {e}")

    @Property(float, notify=loadChanged)
    def load(self):
        return self._load
        
    @load.setter
    def load(self, value):
        if self._load != value and value >= 0:
            self._load = value
            self.loadChanged.emit()
            self._calculate()
            
    @Property(float, notify=systemVoltageChanged)
    def systemVoltage(self):
        return self._system_voltage
        
    @systemVoltage.setter
    def systemVoltage(self, value):
        if self._system_voltage != value and value > 0:
            self._system_voltage = value
            self.systemVoltageChanged.emit()
            self._calculate()
            
    @Property(float, notify=backupTimeChanged)
    def backupTime(self):
        return self._backup_time
        
    @backupTime.setter
    def backupTime(self, value):
        if self._backup_time != value and value >= 0:
            self._backup_time = value
            self.backupTimeChanged.emit()
            self._calculate()
            
    @Property(float, notify=depthOfDischargeChanged)
    def depthOfDischarge(self):
        return self._depth_of_discharge
        
    @depthOfDischarge.setter
    def depthOfDischarge(self, value):
        if self._depth_of_discharge != value and 0 < value < 100:
            self._depth_of_discharge = value
            self.depthOfDischargeChanged.emit()
            self._calculate()
            
    @Property(str, notify=batteryTypeChanged)
    def batteryType(self):
        return self._battery_type
        
    @batteryType.setter
    def batteryType(self, value):
        if self._battery_type != value:
            self._battery_type = value
            self.batteryTypeChanged.emit()
            self._calculate()
            
    @Property(float, notify=calculationsComplete)
    def currentDraw(self):
        return self._current_draw
        
    @Property(float, notify=calculationsComplete)
    def requiredCapacity(self):
        return self._required_capacity
        
    @Property(float, notify=calculationsComplete)
    def recommendedCapacity(self):
        return self._recommended_capacity
        
    @Property(float, notify=calculationsComplete)
    def energyStorage(self):
        return self._energy_storage
        
    # Slots for QML access
    @Slot(float)
    def setLoad(self, value):
        self.load = value
        
    @Slot(float)
    def setSystemVoltage(self, value):
        self.systemVoltage = value
        
    @Slot(float)
    def setBackupTime(self, value):
        self.backupTime = value
        
    @Slot(float)
    def setDepthOfDischarge(self, value):
        self.depthOfDischarge = value
        
    @Slot(str)
    def setBatteryType(self, value):
        self.batteryType = value

    @Slot()
    def exportToPdf(self):
        """Export battery calculations to PDF"""
        try:
            # Create timestamp for filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"battery_report_{timestamp}")
            if not pdf_file:
                self.exportComplete.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create temporary directory for chart image
            temp_dir = tempfile.mkdtemp()
            chart_image_path = os.path.join(temp_dir, "battery_chart.png")
            
            # Create PDF generator
            from utils.pdf.pdf_generator_battery import BatteryPdfGenerator
            pdf_generator = BatteryPdfGenerator()
            
            # Create battery visualization image
            data = {
                'recommended_capacity': self._recommended_capacity,
                'depth_of_discharge': self._depth_of_discharge,
                'battery_type': self._battery_type
            }
            pdf_generator.generate_battery_chart(data, chart_image_path)
            
            # Prepare full data for PDF
            safety_factor = self._safety_factors.get(self._battery_type, 1.2)
            data = {
                'load': self._load,
                'system_voltage': self._system_voltage,
                'backup_time': self._backup_time,
                'depth_of_discharge': self._depth_of_discharge,
                'battery_type': self._battery_type,
                'current_draw': self._current_draw,
                'required_capacity': self._required_capacity,
                'recommended_capacity': self._recommended_capacity,
                'energy_storage': self._energy_storage,
                'safety_factor': safety_factor,
                'battery_image_path': chart_image_path if os.path.exists(chart_image_path) else None
            }
            
            # Generate PDF
            success = pdf_generator.generate_report(data, pdf_file)
            
            # Clean up temporary files
            try:
                if os.path.exists(chart_image_path):
                    os.unlink(chart_image_path)
                os.rmdir(temp_dir)
            except Exception as e:
                logger.error(f"Error cleaning up temp files: {e}")
            
            # Force garbage collection to ensure resources are freed
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
            error_msg = f"Error exporting battery report: {str(e)}"
            logger.error(error_msg)
            self.exportComplete.emit(False, error_msg)
            return False
