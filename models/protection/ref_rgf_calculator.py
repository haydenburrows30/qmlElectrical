from PySide6.QtCore import QObject, Signal, Property, Slot
import math
import tempfile
import os
from datetime import datetime
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

from services.file_saver import FileSaver
from services.logger_config import configure_logger

logger = configure_logger("qmltest", component="ref_rgf")

class RefRgfCalculator(QObject):
    """Calculator for REF (Relay Earth Fault) and RGF (Restricted Ground Fault) values"""

    calculationsComplete = Signal()
    
    # New signals for transformer and CT settings
    ctRatioChanged = Signal()
    transformerRatioChanged = Signal()
    transformerMvaChanged = Signal()
    connectionTypeChanged = Signal()
    ctSecondaryTypeChanged = Signal()
    impedanceChanged = Signal()
    faultPointChanged = Signal()
    faultPointFiveChanged = Signal()
    
    # New calculation result signals
    loadCurrentChanged = Signal()
    faultCurrentChanged = Signal()
    faultPointChanged = Signal()
    gDiffPickupChanged = Signal()

    # Add export signals
    exportComplete = Signal(bool, str)

    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Transformer and CT parameters
        self._ph_ct_ratio = 200  # Phase CT ratio
        self._n_ct_ratio = 200  # Neutral CT Ratio
        self._hv_transformer_voltage = 50  # hv transformer voltage in kv
        self._lv_transformer_voltage = 11  # lv transformer voltage in kv
        self._transformer_mva = 2.5  # Default transformer MVA
        self._connection_type = "Wye"  # Default transformer connection type
        self._ct_secondary_type = "5A"  # Default CT secondary type (5A or 1A)
        self._impedance = 6.33 # Impedance
        self._fault_point = 5.0 # Fault point

        # Calculated results
        self._g_diff_pickup = 0.5  # Ground diff pickup current
        self._load_current = 100
        self._fault_current = 0.0
        self._fault_point_five = 5.0 # Fault point
        
        # Initialize file saver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our exportComplete signal
        self._file_saver.saveStatusChanged.connect(self.exportComplete)
        
        # Initial calculation
        self._calculate()
    
    def _calculate(self):
        """Calculate all fault values"""
        try:
            # Calculate base current
            self._load_current = (self._transformer_mva * 1000000) / (math.sqrt(3) * self._lv_transformer_voltage * 1000)
            
            # Calculate fault currents
            self._fault_current = (self._transformer_mva * 1000000) / (math.sqrt(3) * self._lv_transformer_voltage * 1000 * (self._impedance / 100))
            self._fault_point_five = self._fault_current * (self._fault_point / 100)
            
            # Calculate REF and RGF values
            self._g_diff_pickup = self._fault_point_five / self._ph_ct_ratio

            self.calculationsComplete.emit()
            self.loadCurrentChanged.emit()
            self.faultPointChanged.emit()
            self.gDiffPickupChanged.emit()

        except Exception as e:
            print(f"Calculation error: {e}")
    
    @Property(float, notify=ctRatioChanged)
    def phCtRatio(self):
        return self._ph_ct_ratio
    
    @phCtRatio.setter
    def phCtRatio(self, value):
        if self._ph_ct_ratio != value:
            self._ph_ct_ratio = value
            self.ctRatioChanged.emit()
            self._calculate()

    @Property(float, notify=ctRatioChanged)
    def nCtRatio(self):
        return self._n_ct_ratio
    
    @nCtRatio.setter
    def nCtRatio(self, value):
        if self._n_ct_ratio != value:
            self._n_ct_ratio = value
            self.ctRatioChanged.emit()
            self._calculate()

    @Property(float, notify=impedanceChanged)
    def impedance(self):
        return self._impedance
    
    @impedance.setter
    def impedance(self, value):
        if self._impedance != value:
            self._impedance = value
            self.impedanceChanged.emit()
            self._calculate()

    @Property(float, notify=faultPointChanged)
    def faultPoint(self):
        return self._fault_point
    
    @faultPoint.setter
    def faultPoint(self, value):
        if self._fault_point != value:
            self._fault_point = value
            self.faultPointChanged.emit()
            self._calculate()
    
    @Property(float, notify=transformerRatioChanged)
    def hvTransformerVoltage(self):
        return self._hv_transformer_voltage
    
    @hvTransformerVoltage.setter
    def hvTransformerVoltage(self, value):
        if self._hv_transformer_voltage != value:
            self._hv_transformer_voltage = value
            self.transformerRatioChanged.emit()
            self._calculate()

    @Property(float, notify=transformerRatioChanged)
    def lvTransformerVoltage(self):
        return self._lv_transformer_voltage
    
    @lvTransformerVoltage.setter
    def lvTransformerVoltage(self, value):
        if self._lv_transformer_voltage != value:
            self._lv_transformer_voltage = value
            self.transformerRatioChanged.emit()
            self._calculate()
    
    @Property(float, notify=transformerMvaChanged)
    def transformerMva(self):
        return self._transformer_mva
    
    @transformerMva.setter
    def transformerMva(self, value):
        if value > 0 and self._transformer_mva != value:
            self._transformer_mva = value
            self.transformerMvaChanged.emit()
            self._calculate()
    
    @Property(str, notify=connectionTypeChanged)
    def connectionType(self):
        return self._connection_type
    
    @connectionType.setter
    def connectionType(self, value):
        if self._connection_type != value:
            self._connection_type = value
            self.connectionTypeChanged.emit()
            self._calculate()
    
    @Property(str, notify=ctSecondaryTypeChanged)
    def ctSecondaryType(self):
        return self._ct_secondary_type
    
    @ctSecondaryType.setter
    def ctSecondaryType(self, value):
        if self._ct_secondary_type != value:
            self._ct_secondary_type = value
            self.ctSecondaryTypeChanged.emit()
            self._calculate()
    
    # Result properties
    
    @Property(float, notify=loadCurrentChanged)
    def loadCurrent(self):
        return self._load_current
    
    @Property(float, notify=faultCurrentChanged)
    def faultCurrent(self):
        return self._fault_current
    
    @Property(float, notify=faultPointFiveChanged)
    def faultPointFive(self):
        return self._fault_point_five
    
    @Property(float, notify=gDiffPickupChanged)
    def gDiffPickup(self):
        return self._g_diff_pickup
    
    # Slots for direct QML access
    
    @Slot(float)
    def setPhCtRatio(self, value):
        self.phCtRatio = value
    
    @Slot(float)
    def setNCtRatio(self, value):
        self.nCtRatio = value
    
    @Slot(float)
    def setTransformerMva(self, value):
        self.transformerMva = value
    
    @Slot(str)
    def setConnectionType(self, value):
        self.connectionType = value
    
    @Slot(str)
    def setCtSecondaryType(self, value):
        self.ctSecondaryType = value
    
    @Slot(float)
    def setHvTransformerVoltage(self, value):
        self.hvTransformerVoltage = value

    @Slot(float)
    def setLvTransformerVoltage(self, value):
        self.lvTransformerVoltage = value

    @Slot(float)
    def setImpedance(self, value):
        self.impedance = value

    @Slot(float)
    def setFaultPoint(self, value):
        self.faultPoint = value
    
    @Slot()
    def calculate(self):
        self._calculate()

    @Slot()
    def exportResults(self):
        """Export results to a PDF report"""
        try:
            # Create timestamp for filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"ref_rgf_results_{timestamp}")
            if not pdf_file:
                self.exportComplete.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create temporary directory for chart image
            temp_dir = tempfile.mkdtemp()
            chart_image_path = os.path.join(temp_dir, "ref_rgf_diagram.png")
            
            # Generate matplotlib chart
            self._generate_ref_rgf_diagram(chart_image_path)
            
            # Prepare data for PDF
            data = {
                'ph_ct_ratio': self._ph_ct_ratio,
                'n_ct_ratio': self._n_ct_ratio,
                'transformer_mva': self._transformer_mva,
                'hv_transformer_voltage': self._hv_transformer_voltage,
                'lv_transformer_voltage': self._lv_transformer_voltage,
                'connection_type': self._connection_type,
                'ct_secondary_type': self._ct_secondary_type,
                'impedance': self._impedance,
                'fault_point': self._fault_point,
                'load_current': self._load_current,
                'fault_current': self._fault_current,
                'fault_point_five': self._fault_point_five,
                'g_diff_pickup': self._g_diff_pickup,
                'chart_image_path': chart_image_path if os.path.exists(chart_image_path) else None
            }
            
            # Generate PDF
            from utils.pdf.pdf_generator_ref_rgf import RefRgfPdfGenerator
            pdf_generator = RefRgfPdfGenerator()
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
            error_msg = f"Error exporting results: {str(e)}"
            logger.error(error_msg)
            self.exportComplete.emit(False, error_msg)
            return False
    
    def _generate_ref_rgf_diagram(self, filepath):
        """Generate a diagram illustrating REF/RGF protection for the transformer
        
        Args:
            filepath: Path to save the diagram image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create figure
            plt.figure(figsize=(10, 7))
            
            # Create the transformer diagram
            ax = plt.gca()
            
            # Draw transformer
            transformer_center_x = 5
            transformer_center_y = 4
            transformer_width = 3
            transformer_height = 4
            
            # Draw transformer box
            transformer_rect = plt.Rectangle(
                (transformer_center_x - transformer_width/2, transformer_center_y - transformer_height/2),
                transformer_width, transformer_height, 
                fill=False, linewidth=2
            )
            ax.add_patch(transformer_rect)
            
            # Label transformer
            plt.text(
                transformer_center_x, transformer_center_y - transformer_height/2 - 0.5,
                f"{self._transformer_mva} MVA\n{self._hv_transformer_voltage}/{self._lv_transformer_voltage} kV\n{self._connection_type}\nZ = {self._impedance}%",
                horizontalalignment='center', fontsize=12
            )
            
            # Draw HV side
            hv_x = transformer_center_x - transformer_width/2 - 1
            hv_y = transformer_center_y + transformer_height/4
            plt.plot([hv_x, transformer_center_x - transformer_width/2], [hv_y, hv_y], 'k-', linewidth=2)
            plt.text(hv_x - 0.2, hv_y + 0.3, "HV", fontsize=12)
            
            # Draw LV side
            lv_x = transformer_center_x + transformer_width/2 + 1
            lv_y = transformer_center_y + transformer_height/4
            plt.plot([transformer_center_x + transformer_width/2, lv_x], [lv_y, lv_y], 'k-', linewidth=2)
            plt.text(lv_x + 0.2, lv_y + 0.3, "LV", fontsize=12)
            
            # Draw ground
            ground_x = transformer_center_x
            ground_y = transformer_center_y - transformer_height/2 - 1
            plt.plot([ground_x, ground_x], 
                  [transformer_center_y - transformer_height/2, ground_y], 
                  'k-', linewidth=2)
            
            # Draw ground symbol
            ground_width = 0.5
            plt.plot([ground_x - ground_width, ground_x + ground_width], 
                  [ground_y, ground_y], 'k-', linewidth=2)
            plt.plot([ground_x - ground_width*0.7, ground_x + ground_width*0.7], 
                  [ground_y - 0.2, ground_y - 0.2], 'k-', linewidth=2)
            plt.plot([ground_x - ground_width*0.4, ground_x + ground_width*0.4], 
                  [ground_y - 0.4, ground_y - 0.4], 'k-', linewidth=2)
            
            # Draw CTs (represented as circles)
            ct_radius = 0.3
            
            # HV Phase CT
            hv_ct_x = hv_x + 0.5
            hv_ct_y = hv_y
            hv_ct = plt.Circle((hv_ct_x, hv_ct_y), ct_radius, fill=False, linewidth=2)
            ax.add_patch(hv_ct)
            plt.text(hv_ct_x, hv_ct_y - ct_radius - 0.3, f"CT {self._ph_ct_ratio}:{self._ct_secondary_type}", 
                   fontsize=10, horizontalalignment='center')
            
            # LV Phase CT
            lv_ct_x = lv_x - 0.5
            lv_ct_y = lv_y
            lv_ct = plt.Circle((lv_ct_x, lv_ct_y), ct_radius, fill=False, linewidth=2)
            ax.add_patch(lv_ct)
            plt.text(lv_ct_x, lv_ct_y - ct_radius - 0.3, f"CT {self._ph_ct_ratio}:{self._ct_secondary_type}", 
                   fontsize=10, horizontalalignment='center')
            
            # Neutral CT
            n_ct_x = ground_x
            n_ct_y = transformer_center_y - transformer_height/2 - 0.5
            n_ct = plt.Circle((n_ct_x, n_ct_y), ct_radius, fill=False, linewidth=2)
            ax.add_patch(n_ct)
            plt.text(n_ct_x + ct_radius + 0.5, n_ct_y, f"CT {self._n_ct_ratio}:{self._ct_secondary_type}", 
                   fontsize=10, horizontalalignment='left')
            
            # Add REF/RGF relay
            relay_x = transformer_center_x + 2
            relay_y = transformer_center_y - transformer_height/2 - 1
            relay_width = 1.5
            relay_height = 1
            relay_rect = plt.Rectangle(
                (relay_x - relay_width/2, relay_y - relay_height/2),
                relay_width, relay_height, 
                fill=False, linewidth=2, edgecolor='r'
            )
            ax.add_patch(relay_rect)
            plt.text(relay_x, relay_y, "REF/RGF\nRelay", color='r', 
                   fontsize=10, horizontalalignment='center')
            
            # Add fault information
            fault_info_x = 9
            fault_info_y = 6
            plt.text(fault_info_x, fault_info_y, 
                   f"Load Current: {self._load_current:.1f} A\n"
                   f"Fault Current: {self._fault_current:.1f} A\n"
                   f"Fault Point: {self._fault_point:.1f}%\n"
                   f"G-Diff Pickup: {self._g_diff_pickup:.2f} A",
                   fontsize=12,
                   bbox=dict(facecolor='wheat', alpha=0.5))
            
            # Set axis limits with some padding
            ax.set_xlim(0, 10)
            ax.set_ylim(0, 8)
            
            # Remove ticks and axis labels
            ax.set_xticks([])
            ax.set_yticks([])
            
            # Set title
            plt.title('REF/RGF Protection Diagram', fontsize=16)
            
            # Set equal aspect ratio
            ax.set_aspect('equal')
            
            # Save the figure
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            import gc
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating diagram: {e}")
            plt.close('all')  # Make sure to close figures on error
            return False
