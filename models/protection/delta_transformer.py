from PySide6.QtCore import QObject, Property, Signal, Slot
import math
import tempfile
import os
from datetime import datetime
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt

from services.file_saver import FileSaver
from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="delta_transformer")

class DeltaTransformerCalculator(QObject):
    """Calculator for open delta protection transformer configurations"""
    
    primaryVoltageChanged = Signal()
    secondaryVoltageChanged = Signal()
    powerRatingChanged = Signal()
    resistorCalculated = Signal(float)
    wattageCalculated = Signal(float)
    exportComplete = Signal(bool, str)  # Add new signal for export status

    def __init__(self, parent=None):
        super().__init__(parent)
        self._primary_voltage = 0.0
        self._secondary_voltage = 0.0
        self._power_rating = 0.0
        self._required_resistor = 0.0
        self._required_wattage = 0.0
        
        # Initialize file saver
        self._file_saver = FileSaver()
        
        # Connect file saver signals to our exportComplete signal
        self._file_saver.saveStatusChanged.connect(self.exportComplete)

    @Property(float, notify=primaryVoltageChanged)
    def primaryVoltage(self):
        return self._primary_voltage

    @primaryVoltage.setter
    def primaryVoltage(self, value):
        if value >= 0 and self._primary_voltage != value:
            self._primary_voltage = value
            self.primaryVoltageChanged.emit()
            self._calculate()

    @Property(float, notify=secondaryVoltageChanged)
    def secondaryVoltage(self):
        return self._secondary_voltage

    @secondaryVoltage.setter
    def secondaryVoltage(self, value):
        if value >= 0 and self._secondary_voltage != value:
            self._secondary_voltage = value
            self.secondaryVoltageChanged.emit()
            self._calculate()

    @Property(float, notify=powerRatingChanged)
    def powerRating(self):
        return self._power_rating

    @powerRating.setter
    def powerRating(self, value):
        if value >= 0 and self._power_rating != value:
            self._power_rating = value
            self.powerRatingChanged.emit()
            self._calculate()

    def _calculate(self):
        """Calculate required resistor value for open delta protection configuration"""
        try:
            if self._primary_voltage <= 0 or self._secondary_voltage <= 0 or self._power_rating <= 0:
                return

            # Per standard calculation method:
            # R = (3*√3*Us^2)/Pe where:
            # Us = Secondary voltage / 3
            # Pe = Power rating of secondary winding in VA
            
            # Calculate resistor using R = (3*√3*Us^2)/Pe
            self._required_resistor = (3 * math.sqrt(3) * (self._secondary_voltage / 3)**2) / self._power_rating
            # Calculate wattage rating
            self._required_wattage = ((3 * self._secondary_voltage / 3)**2) / self._required_resistor

            self.resistorCalculated.emit(self._required_resistor)
            self.wattageCalculated.emit(self._required_wattage)
            
        except Exception as e:
            print(f"Error in delta transformer calculation: {e}")

    @Slot(float)
    def setPrimaryVoltage(self, voltage):
        self.primaryVoltage = voltage

    @Slot(float)
    def setSecondaryVoltage(self, voltage):
        self.secondaryVoltage = voltage

    @Slot(float)
    def setPowerRating(self, power):
        self.powerRating = power

    @Slot(float, float, float)
    def calculateResistor(self, primary_v, secondary_v, power_kva):
        """Calculate resistor value from given parameters"""
        self.primaryVoltage = primary_v
        self.secondaryVoltage = secondary_v
        self.powerRating = power_kva
        return self._required_resistor

    @Slot(result=str)
    def getPdfPath(self):
        """Return path to reference PDF document"""
        import os
        current_dir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
        return os.path.join(current_dir, "../", "assets", "Protection-Automation-Application-Guide-v1.pdf")

    @Slot(result=float)
    def getRequiredResistor(self):
        """Get the currently calculated resistor value"""
        return self._required_resistor
        
    @Slot(result=float) 
    def getRequiredWattage(self):
        """Get the currently calculated wattage rating"""
        return self._required_wattage
    
    @Property(float, notify=wattageCalculated)
    def wattage(self):
        """Get the currently calculated wattage rating"""
        return self._required_wattage
    
    @Property(float, notify=resistorCalculated)
    def resistor(self):
        """Get the currently calculated wattage rating"""
        return self._required_resistor

    @Slot()
    def exportToPdf(self):
        """Export delta transformer calculations to PDF"""
        try:
            # Create timestamp for filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"delta_transformer_report_{timestamp}")
            if not pdf_file:
                self.exportComplete.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create temporary directory for diagram image
            temp_dir = tempfile.mkdtemp()
            diagram_path = os.path.join(temp_dir, "delta_diagram.png")
            
            # Generate diagram image
            self._generate_diagram(diagram_path)
            
            # Prepare data for PDF generator
            data = {
                'primary_voltage': self._primary_voltage,
                'secondary_voltage': self._secondary_voltage,
                'power_rating': self._power_rating,
                'phase_voltage': self._secondary_voltage / 3,
                'resistor_value': self._required_resistor,
                'resistor_wattage': self._required_wattage,
                'diagram_path': diagram_path if os.path.exists(diagram_path) else None,
                'open_delta_factor': 0.866,  # 86.6% of capacity in open delta
                'safety_factor': 3.0         # 3x safety factor for resistor
            }
            
            # Generate PDF using the DeltaTransformerPdfGenerator
            from utils.pdf.pdf_generator_delta import DeltaTransformerPdfGenerator
            pdf_generator = DeltaTransformerPdfGenerator()
            success = pdf_generator.generate_report(data, pdf_file)
            
            # Clean up temporary files
            try:
                if os.path.exists(diagram_path):
                    os.unlink(diagram_path)
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
            error_msg = f"Error exporting delta transformer report: {str(e)}"
            logger.error(error_msg)
            self.exportComplete.emit(False, error_msg)
            return False
            
    def _generate_diagram(self, filepath):
        """Generate a diagram of the open delta configuration"""
        try:
            # Create figure with appropriate size and padding
            fig, ax = plt.subplots(figsize=(8, 6))
            fig.subplots_adjust(left=0.1, right=0.9, top=0.9, bottom=0.1)
            
            # Set axis limits
            ax.set_xlim(0, 10)
            ax.set_ylim(0, 10)
            
            # Turn off axis ticks
            ax.set_xticks([])
            ax.set_yticks([])
            
            # Draw transformers
            transformer1 = plt.Rectangle((2, 6), 2, 2, fill=False, ec='black', lw=2)
            transformer2 = plt.Rectangle((6, 6), 2, 2, fill=False, ec='black', lw=2)
            ax.add_patch(transformer1)
            ax.add_patch(transformer2)
            
            # Draw resistor
            resistor_x = 8
            resistor_y = 3
            resistor_width = 1
            resistor_height = 0.5
            for i in range(5):
                y_offset = resistor_y + (i * 0.1)
                zigzag = plt.Rectangle((resistor_x, y_offset), resistor_width, resistor_height/5, fill=True, ec='black', fc='lightgray')
                ax.add_patch(zigzag)
            
            # Draw lines connecting elements
            # Primary side
            ax.plot([1, 3], [9, 9], 'k-', lw=2)  # Top horizontal line
            ax.plot([5, 7], [9, 9], 'k-', lw=2)  # Top horizontal line 2
            ax.plot([9, 9], [9, 1], 'k-', lw=2)  # Right vertical line
            ax.plot([1, 1], [9, 1], 'k-', lw=2)  # Left vertical line
            ax.plot([1, 9], [1, 1], 'k-', lw=2)  # Bottom horizontal line
            
            # Connections to transformers
            ax.plot([3, 3], [9, 8], 'k-', lw=2)  # Transformer 1 top
            ax.plot([3, 3], [6, 5], 'k-', lw=2)  # Transformer 1 bottom
            ax.plot([7, 7], [9, 8], 'k-', lw=2)  # Transformer 2 top
            ax.plot([7, 7], [6, 5], 'k-', lw=2)  # Transformer 2 bottom
            
            # Secondary connections
            ax.plot([3, 3], [5, 3], 'k-', lw=2)  # Down from transformer 1
            ax.plot([3, 5], [3, 3], 'k-', lw=2)  # Horizontal to center
            ax.plot([7, 7], [5, 4], 'k-', lw=2)  # Down from transformer 2
            ax.plot([7, 8], [4, 4], 'k-', lw=2)  # To resistor
            ax.plot([8, 8], [4, 3.5], 'k-', lw=2)  # To resistor vertical
            
            # Add labels
            ax.text(1, 9.5, "Primary", fontsize=12)
            ax.text(3, 7, "T1", fontsize=12, ha='center')
            ax.text(7, 7, "T2", fontsize=12, ha='center')
            ax.text(5, 2.5, f"Secondary\n{self._secondary_voltage}V", fontsize=10, ha='center')
            ax.text(8.5, 2.5, f"R={self._required_resistor:.1f}Ω\n{self._required_wattage:.1f}W", fontsize=10, ha='center')
            ax.text(1, 9.2, f"{self._primary_voltage}V", fontsize=10)
            
            # Add title
            ax.set_title(f"Open Delta Transformer Configuration\nPower Rating: {self._power_rating}VA", fontsize=14)
            
            # Save figure
            plt.savefig(filepath, dpi=150, bbox_inches='tight')
            plt.close(fig)
            return True
            
        except Exception as e:
            logger.error(f"Error generating delta diagram: {e}")
            plt.close('all')
            return False
