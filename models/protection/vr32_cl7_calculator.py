from PySide6.QtCore import QObject, Property, Signal, Slot
import math
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import tempfile
import os
from datetime import datetime
from utils.pdf.pdf_generator_vr32cl7 import VR32CL7PdfGenerator

from services.file_saver import FileSaver
from services.logger_config import configure_logger

# Setup component-specific logger
logger = configure_logger("qmltest", component="vr32cl7")

class VR32CL7Calculator(QObject):
    """Calculator for voltage regulator VR32/CL7 settings"""
    
    # Define signals for property changes
    generationCapacityChanged = Signal()
    cableLengthChanged = Signal()
    cableRChanged = Signal()
    cableXChanged = Signal()
    loadDistanceChanged = Signal()
    powerFactorChanged = Signal()
    resultsCalculated = Signal()
    exportComplete = Signal(bool, str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Input parameters - default values
        self._generation_capacity_kw = 500.0
        self._cable_length_km = 8.0
        self._cable_r_per_km = 1.15
        self._cable_x_per_km = 0.126
        self._load_distance_km = 3.0
        self._power_factor = 0.95  # Default power factor
        
        # Calculated values
        self._resistance = 0.0
        self._reactance = 0.0
        self._impedance = 0.0
        self._impedance_angle = 0.0
        
        # Initialize file saver
        self._file_saver = FileSaver()

        # Initialize PDF generator
        self._pdf_generator = VR32CL7PdfGenerator()
        self._file_saver.saveStatusChanged.connect(self.exportComplete)
        
        # Calculate initial values
        self._calculate()
    
    @Property(float, notify=generationCapacityChanged)
    def generation_capacity_kw(self):
        return self._generation_capacity_kw
    
    @generation_capacity_kw.setter
    def generation_capacity_kw(self, value):
        if value != self._generation_capacity_kw and value > 0:
            self._generation_capacity_kw = value
            self.generationCapacityChanged.emit()
            self._calculate()
    
    @Property(float, notify=cableLengthChanged)
    def cable_length_km(self):
        return self._cable_length_km
    
    @cable_length_km.setter
    def cable_length_km(self, value):
        if value != self._cable_length_km and value > 0:
            self._cable_length_km = value
            self.cableLengthChanged.emit()
            self._calculate()
    
    @Property(float, notify=cableRChanged)
    def cable_r_per_km(self):
        return self._cable_r_per_km
    
    @cable_r_per_km.setter
    def cable_r_per_km(self, value):
        if value != self._cable_r_per_km and value > 0:
            self._cable_r_per_km = value
            self.cableRChanged.emit()
            self._calculate()
    
    @Property(float, notify=cableXChanged)
    def cable_x_per_km(self):
        return self._cable_x_per_km
    
    @cable_x_per_km.setter
    def cable_x_per_km(self, value):
        if value != self._cable_x_per_km and value > 0:
            self._cable_x_per_km = value
            self.cableXChanged.emit()
            self._calculate()
    
    @Property(float, notify=loadDistanceChanged)
    def load_distance_km(self):
        return self._load_distance_km
    
    @load_distance_km.setter
    def load_distance_km(self, value):
        if value != self._load_distance_km and value >= 0:
            self._load_distance_km = value
            self.loadDistanceChanged.emit()
            self._calculate()
    
    @Property(float, notify=powerFactorChanged)
    def power_factor(self):
        return self._power_factor
    
    @power_factor.setter
    def power_factor(self, value):
        if value != self._power_factor and 0 < value <= 1:
            self._power_factor = value
            self.powerFactorChanged.emit()
            self._calculate()
    
    # Read-only result properties
    @Property(float, notify=resultsCalculated)
    def resistance(self):
        return self._resistance
    
    @Property(float, notify=resultsCalculated)
    def reactance(self):
        return self._reactance
    
    @Property(float, notify=resultsCalculated)
    def impedance(self):
        return self._impedance
    
    @Property(float, notify=resultsCalculated)
    def impedance_angle(self):
        return self._impedance_angle
    
    def _calculate(self):
        """Calculate the regulator impedance parameters"""
        try:
            # Calculate total length
            total_length = self._cable_length_km + self._load_distance_km
            
            # Calculate resistance, reactance, and impedance
            self._resistance = self._cable_r_per_km * total_length
            self._reactance = self._cable_x_per_km * total_length
            
            # Calculate impedance magnitude
            self._impedance = math.sqrt(self._resistance**2 + self._reactance**2)
            
            # Calculate impedance angle (in degrees)
            self._impedance_angle = math.degrees(math.atan2(self._reactance, self._resistance))
            
            # Emit signal for calculation completed
            self.resultsCalculated.emit()
            
        except Exception as e:
            logger.error(f"Error in calculation: {e}")
    
    @Slot()
    def calculate(self):
        """Slot to trigger calculation manually"""
        self._calculate()
        return True
    
    @Slot()
    def exportPlot(self):
        """Export results to a PDF with visualization"""
        try:
            # Create timestamp for filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"vr32cl7_results_{timestamp}")
            if not pdf_file:
                self.exportComplete.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create temporary directory for chart image
            temp_dir = tempfile.mkdtemp()
            chart_image_path = os.path.join(temp_dir, "impedance_chart.png")
            
            # Generate matplotlib chart
            self._generate_chart(chart_image_path)
            
            # Prepare data for PDF
            data = {
                'generation_capacity': self._generation_capacity_kw,
                'cable_length': self._cable_length_km,
                'cable_r': self._cable_r_per_km,
                'cable_x': self._cable_x_per_km,
                'load_distance': self._load_distance_km,
                'power_factor': self._power_factor,
                'resistance': self._resistance,
                'reactance': self._reactance,
                'impedance': self._impedance,
                'impedance_angle': self._impedance_angle,
                'chart_image_path': chart_image_path if os.path.exists(chart_image_path) else None
            }
            
            # Generate PDF using the specialized PDF generators
            success = self._pdf_generator.generate_report(data, pdf_file)
            
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
            error_msg = f"Error exporting results: {str(e)}"
            logger.error(error_msg)
            self.exportComplete.emit(False, error_msg)
            return False
    
    def _generate_chart(self, filepath):
        """Generate impedance chart using matplotlib
        
        Args:
            filepath (str): Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create figure
            plt.figure(figsize=(10, 6))
            
            # Create data for the impedance triangle
            r_vals = [0, self._resistance, self._resistance, 0]
            x_vals = [0, 0, self._reactance, 0]
            
            # Plot impedance triangle
            plt.plot(r_vals, x_vals, 'b-', linewidth=2)
            
            # Plot R and X components
            plt.plot([0, self._resistance], [0, 0], 'r-', linewidth=2, label='Resistance (R)')
            plt.plot([self._resistance, self._resistance], [0, self._reactance], 'g-', linewidth=2, label='Reactance (X)')
            plt.plot([0, self._resistance], [0, self._reactance], 'b-', linewidth=2, label='Impedance (Z)')
            
            # Add annotations
            plt.annotate(f"R = {self._resistance:.2f} Ω", 
                      xy=(self._resistance/2, -0.1), 
                      ha='center', 
                      bbox=dict(boxstyle='round', fc='white', alpha=0.7))
            
            plt.annotate(f"X = {self._reactance:.2f} Ω", 
                      xy=(self._resistance + 0.1, self._reactance/2), 
                      ha='left', 
                      bbox=dict(boxstyle='round', fc='white', alpha=0.7))
            
            plt.annotate(f"Z = {self._impedance:.2f} Ω\nθ = {self._impedance_angle:.2f}°", 
                      xy=(self._resistance/2, self._reactance/2), 
                      ha='center', 
                      bbox=dict(boxstyle='round', fc='white', alpha=0.7))
            
            # Set labels and title
            plt.title('VR32/CL7 Impedance Triangle')
            plt.xlabel('Resistance (Ω)')
            plt.ylabel('Reactance (Ω)')
            
            # Add grid and legend
            plt.grid(True)
            plt.legend()
            
            # Set axis limits with some padding
            padding = max(self._resistance, self._reactance) * 0.2
            plt.xlim(-padding, self._resistance + padding)
            plt.ylim(-padding, self._reactance + padding)
            
            # Add input parameters as text
            plt.figtext(0.5, 0.01, 
                      f"Generation: {self._generation_capacity_kw} kW | Cable: {self._cable_length_km} km, R={self._cable_r_per_km} Ω/km, X={self._cable_x_per_km} Ω/km | Load Distance: {self._load_distance_km} km", 
                      ha='center', 
                      bbox=dict(boxstyle='round', fc='lightblue', alpha=0.2, pad=5))
            
            # Save the figure
            plt.tight_layout(rect=[0, 0.04, 1, 0.97])
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            import gc
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating chart: {e}")
            plt.close('all')  # Make sure to close figures on error
            return False
