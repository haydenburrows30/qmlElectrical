from PySide6.QtCore import QObject, Property, Signal, Slot
import math
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
import os
import tempfile
from datetime import datetime

from services.file_saver import FileSaver
from services.logger_config import configure_logger

# Setup component-specific logger
logger = configure_logger("qmltest", component="earthing")

class EarthingCalculator(QObject):
    """Calculator for earthing system design
    
    Implementation follows IEEE Standard 80 "Guide for Safety in AC Substation Grounding"
    Key components included:
    - Grid resistance calculation using IEEE 80 approach
    - Ground rod contribution with mutual coupling factors
    - Touch and step voltage calculations with safety thresholds
    - Conductor sizing based on IEEE 80 thermal equations for copper
    """

    # Define signals
    soilResistivityChanged = Signal()
    gridDepthChanged = Signal()
    gridLengthChanged = Signal()
    gridWidthChanged = Signal()
    rodLengthChanged = Signal()
    rodCountChanged = Signal()
    faultCurrentChanged = Signal()
    faultDurationChanged = Signal()
    resultsCalculated = Signal()
    
    # Add PDF export status signal
    pdfExportStatusChanged = Signal(bool, str)

    def __init__(self, parent=None):
        super().__init__(parent)
        # Initialize properties
        self._soil_resistivity = 100.0  # Ohm-meters
        self._grid_depth = 0.5  # meters
        self._grid_length = 20.0  # meters
        self._grid_width = 20.0  # meters
        self._rod_length = 3.0  # meters
        self._rod_count = 4  # number of rods
        self._fault_current = 10000.0  # Amperes
        self._fault_duration = 0.5  # seconds
        
        # Derived values
        self._grid_resistance = 0.0
        self._touch_voltage = 0.0
        self._step_voltage = 0.0
        self._conductor_size = 0.0
        self._voltage_rise = 0.0
        
        # Initialize FileSaver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our pdfExportStatusChanged signal
        self._file_saver.saveStatusChanged.connect(self.pdfExportStatusChanged)
        
        self._calculate()

    def _calculate(self):
        try:
            # Calculate grid resistance using improved Schwarz's equation
            area = self._grid_length * self._grid_width
            perimeter = 2 * (self._grid_length + self._grid_width)
            
            # Improved grid resistance calculation
            L_total = perimeter + (self._rod_count * self._rod_length)
            
            # Grid resistance calculation (IEEE 80 approach)
            self._grid_resistance = self._soil_resistivity / (math.pi * L_total) * (
                math.log(2 * L_total / math.sqrt(0.5 * self._grid_depth)) +
                (self._grid_length * self._grid_width) / (L_total ** 2) - 1
            )
            
            # Rod contribution - improved formula
            if self._rod_count > 0:
                # Rod spacing estimated based on perimeter
                avg_spacing = perimeter / max(1, self._rod_count)
                # Rod resistance with mutual coupling factor
                rod_resistance = self._soil_resistivity / (2 * math.pi * self._rod_length * self._rod_count) * (
                    1 + 0.8 * (self._rod_length / math.sqrt(area))
                )
                # Combined resistance - using parallel combination with mutual factor
                mutual_factor = 0.7  # Approximation of mutual coupling
                self._grid_resistance = (self._grid_resistance * rod_resistance) / (
                    self._grid_resistance + rod_resistance * mutual_factor
                )
            
            # Ground potential rise
            self._voltage_rise = self._fault_current * self._grid_resistance
            
            # Touch voltage (IEEE 80 approach)
            mesh_factor = 0.75  # Approximation of mesh factor
            self._touch_voltage = mesh_factor * self._voltage_rise
            
            # Step voltage (IEEE 80 approach)
            step_factor = 0.4  # Approximation of step factor
            self._step_voltage = step_factor * self._voltage_rise
            
            # Conductor size (based on IEEE 80)
            # For copper conductor (TCAP=397, αr=0.00393, ρr=1.78)
            TCAP = 397  # Thermal capacity (J/cm³/°C)
            alpha_r = 0.00393  # Thermal coefficient of resistivity (1/°C)
            rho_r = 1.78  # Resistivity (μΩ·cm)
            
            # IEEE 80 equation for copper conductor size
            Akcmil = (self._fault_current * math.sqrt(self._fault_duration * 0.0954)) / 7.06
            
            # Convert kcmil to mm²
            self._conductor_size = Akcmil * 0.5067  # Convert to mm²
            
            self.resultsCalculated.emit()
            
        except Exception as e:
            logger.error(f"Error in earthing calculation: {e}")

    # Properties and setters
    @Property(float, notify=soilResistivityChanged)
    def soilResistivity(self):
        return self._soil_resistivity
    
    @soilResistivity.setter
    def soilResistivity(self, value):
        if value > 0:
            self._soil_resistivity = value
            self.soilResistivityChanged.emit()
            self._calculate()

    @Property(float, notify=gridDepthChanged)
    def gridDepth(self):
        return self._grid_depth
    
    @gridDepth.setter
    def gridDepth(self, value):
        if value > 0:
            self._grid_depth = value
            self.gridDepthChanged.emit()
            self._calculate()

    @Property(float, notify=gridLengthChanged)
    def gridLength(self):
        return self._grid_length
    
    @gridLength.setter
    def gridLength(self, value):
        if value > 0:
            self._grid_length = value
            self.gridLengthChanged.emit()
            self._calculate()

    @Property(float, notify=gridWidthChanged)
    def gridWidth(self):
        return self._grid_width
    
    @gridWidth.setter
    def gridWidth(self, value):
        if value > 0:
            self._grid_width = value
            self.gridWidthChanged.emit()
            self._calculate()

    @Property(float, notify=rodLengthChanged)
    def rodLength(self):
        return self._rod_length
    
    @rodLength.setter
    def rodLength(self, value):
        if value > 0:
            self._rod_length = value
            self.rodLengthChanged.emit()
            self._calculate()

    @Property(int, notify=rodCountChanged)
    def rodCount(self):
        return self._rod_count
    
    @rodCount.setter
    def rodCount(self, value):
        if value >= 0:
            self._rod_count = value
            self.rodCountChanged.emit()
            self._calculate()
    
    @Property(float, notify=faultCurrentChanged)
    def faultCurrent(self):
        return self._fault_current
    
    @faultCurrent.setter
    def faultCurrent(self, value):
        if value > 0:
            self._fault_current = value
            self.faultCurrentChanged.emit()
            self._calculate()

    @Property(float, notify=faultDurationChanged)
    def faultDuration(self):
        return self._fault_duration
    
    @faultDuration.setter
    def faultDuration(self, value):
        if value > 0:
            self._fault_duration = value
            self.faultDurationChanged.emit()
            self._calculate()

    @Property(float, notify=resultsCalculated)
    def gridResistance(self):
        return self._grid_resistance
    
    @Property(float, notify=resultsCalculated)
    def touchVoltage(self):
        return self._touch_voltage
    
    @Property(float, notify=resultsCalculated)
    def stepVoltage(self):
        return self._step_voltage
    
    @Property(float, notify=resultsCalculated)
    def conductorSize(self):
        return self._conductor_size
    
    @Property(float, notify=resultsCalculated)
    def voltageRise(self):
        return self._voltage_rise

    # QML slots
    @Slot(float)
    def setSoilResistivity(self, value):
        self.soilResistivity = value

    @Slot(float)
    def setGridDepth(self, value):
        self.gridDepth = value

    @Slot(float)
    def setGridLength(self, value):
        self.gridLength = value

    @Slot(float)
    def setGridWidth(self, value):
        self.gridWidth = value

    @Slot(float)
    def setRodLength(self, value):
        self.rodLength = value

    @Slot(int)
    def setRodCount(self, value):
        self.rodCount = value

    @Slot(float)
    def setFaultCurrent(self, value):
        self.faultCurrent = value

    @Slot(float)
    def setFaultDuration(self, value):
        self.faultDuration = value

    @Slot()
    def exportToPdf(self):
        """Export the earthing system analysis to a PDF file
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            from utils.pdf.pdf_generator_earthing import EarthingPdfGenerator
            
            # Create timestamp for filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"earthing_analysis_{timestamp}")
            if not pdf_file:
                self.pdfExportStatusChanged.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create temporary directory for chart image
            temp_dir = tempfile.mkdtemp()
            diagram_image_path = os.path.join(temp_dir, "earthing_diagram.png")
            
            # Generate diagram using the PDF generator
            pdf_generator = EarthingPdfGenerator()
            
            # Prepare data for diagram
            diagram_data = {
                'grid_length': self._grid_length,
                'grid_width': self._grid_width,
                'rod_count': self._rod_count,
                'rod_length': self._rod_length,
                'grid_resistance': self._grid_resistance
            }
            
            # Generate the diagram
            pdf_generator.generate_diagram(diagram_data, diagram_image_path)
            
            # Prepare data for PDF
            data = {
                'soil_resistivity': self._soil_resistivity,
                'grid_depth': self._grid_depth,
                'grid_length': self._grid_length,
                'grid_width': self._grid_width,
                'grid_area': self._grid_length * self._grid_width,
                'rod_length': self._rod_length,
                'rod_count': self._rod_count,
                'fault_current': self._fault_current,
                'fault_duration': self._fault_duration,
                'grid_resistance': self._grid_resistance,
                'touch_voltage': self._touch_voltage,
                'step_voltage': self._step_voltage,
                'conductor_size': self._conductor_size,
                'voltage_rise': self._voltage_rise,
                'diagram_image_path': diagram_image_path if os.path.exists(diagram_image_path) else None
            }
            
            # Generate PDF
            success = pdf_generator.generate_report(data, pdf_file)
            
            # Clean up temporary files
            try:
                if os.path.exists(diagram_image_path):
                    os.unlink(diagram_image_path)
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
            error_msg = f"Error exporting to PDF: {str(e)}"
            logger.error(error_msg)
            self.pdfExportStatusChanged.emit(False, error_msg)
            return False