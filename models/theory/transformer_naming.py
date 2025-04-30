from PySide6.QtCore import QObject, Property, Signal, Slot
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
import tempfile
import os
import numpy as np
from datetime import datetime

from services.file_saver import FileSaver
from services.logger_config import configure_logger

logger = configure_logger("qmltest", component="transformer_naming")

class TransformerNamingGuide(QObject):
    """Model for transformer naming conventions"""
    
    outputNameChanged = Signal()
    descriptionChanged = Signal()
    errorMessageChanged = Signal()
    transformerTypeChanged = Signal()
    accuracyClassChanged = Signal()
    ratedCurrentChanged = Signal()
    ratedVoltageChanged = Signal()
    secondaryRatingChanged = Signal()
    burdenChanged = Signal()
    frequencyChanged = Signal()
    insulationLevelChanged = Signal()
    applicationChanged = Signal()
    installationChanged = Signal()
    thermalRatingChanged = Signal()
    pdfExportStatusChanged = Signal(bool, str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Default values
        self._transformer_type = "CT"  # CT or VT
        self._accuracy_class = "0.5"
        self._rated_current = "100"    # For CT
        self._rated_voltage = "11000"  # For VT (primary voltage)
        self._secondary_rating = "5"   # 5A or 1A for CT, 110V for VT
        self._burden = "15"            # VA
        self._frequency = "50"         # Hz
        self._insulation_level = "12"  # kV
        self._application = "metering" # metering, protection, or combined
        self._installation = "indoor"  # indoor or outdoor
        self._thermal_rating = "1.2"   # x rated
        self._output_name = ""
        self._description = ""
        self._error_message = ""
        
        # Reference data
        self._ct_accuracy_classes = ["0.1", "0.2", "0.5", "1.0", "3.0", "5P10", "5P20", "10P10", "10P20"]
        self._vt_accuracy_classes = ["0.1", "0.2", "0.5", "1.0", "3.0", "3P", "6P"]
        self._ct_rated_currents = ["5", "10", "15", "20", "30", "40", "50", "60", "75", "100", "150", 
                                   "200", "300", "400", "500", "600", "750", "800", "1000", "1200", 
                                   "1500", "2000", "3000", "4000", "5000"]
        self._ct_secondary_ratings = ["1", "5"]  # 1A or 5A
        self._vt_secondary_ratings = ["100", "110", "115", "120"]  # Common secondary voltages
        self._vt_rated_voltages = ["400", "690", "3300", "6600", "11000", "22000", "33000", 
                                   "66000", "110000", "132000", "220000", "400000"]
        self._insulation_levels = ["0.72", "3.6", "7.2", "12", "17.5", "24", "36", "40.5", 
                                   "72.5", "123", "145", "245", "420"]
        self._applications = ["metering", "protection", "combined"]
        self._installations = ["indoor", "outdoor"]
        self._frequencies = ["50", "60"]
        self._thermal_ratings = ["1.0", "1.2", "1.3", "1.5", "2.0"]
        
        # Standard naming formats by manufacturer
        self._naming_formats = {
            "IEC": {
                "CT": "{type} {ratio} {accuracy_class} {burden}VA {insulation}kV",
                "VT": "{type} {ratio} {accuracy_class} {burden}VA {insulation}kV"
            },
            "ANSI": {
                "CT": "{type}-{ratio}:{accuracy_class}:{thermal}",
                "VT": "{type}-{ratio}:{accuracy_class}:{burden}"
            },
            "ABB": {
                "CT": "CT-{ratio}-{accuracy_class}-{burden}VA-{insulation}kV-{installation}",
                "VT": "VT-{ratio}-{accuracy_class}-{burden}VA-{insulation}kV-{installation}"
            },
            "Siemens": {
                "CT": "{type} {ratio} {accuracy_class}/{application} {burden}VA {thermal}x",
                "VT": "{type} {ratio} {accuracy_class} {burden}VA {thermal}x"
            }
        }
        
        # Generate initial name
        self._generate_name()
        
        # Initialize FileSaver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our pdfExportStatusChanged signal
        self._file_saver.saveStatusChanged.connect(self.pdfExportStatusChanged)

    def _generate_name(self):
        """Generate transformer name based on selected parameters"""
        try:
            # Clear any previous errors
            self._error_message = ""
            
            # Basic validation
            if self._transformer_type not in ["CT", "VT"]:
                self._error_message = "Invalid transformer type"
                return
                
            # Format ratio string
            if self._transformer_type == "CT":
                ratio = f"{self._rated_current}/{self._secondary_rating}"
            else:  # VT
                ratio = f"{self._rated_voltage}/{self._secondary_rating}"
            
            # Build name variants for different standards
            names = {}
            descriptions = []
            
            # IEC format
            iec_params = {
                "type": self._transformer_type,
                "ratio": ratio,
                "accuracy_class": self._accuracy_class,
                "burden": self._burden,
                "insulation": self._insulation_level,
                "application": self._application.capitalize(),
                "thermal": self._thermal_rating,
                "installation": self._installation.capitalize(),
                "frequency": self._frequency
            }
            
            names["IEC"] = self._naming_formats["IEC"][self._transformer_type].format(**iec_params)
            
            # ANSI format 
            ansi_params = iec_params.copy()
            names["ANSI"] = self._naming_formats["ANSI"][self._transformer_type].format(**ansi_params)
            
            # Manufacturer specific formats
            names["ABB"] = self._naming_formats["ABB"][self._transformer_type].format(**iec_params)
            names["Siemens"] = self._naming_formats["Siemens"][self._transformer_type].format(**iec_params)
            
            # Generate description of the naming parts
            if self._transformer_type == "CT":
                descriptions.append(f"<b>CT</b>: Current Transformer")
                descriptions.append(f"<b>{self._rated_current}/{self._secondary_rating}</b>: Primary current rating of {self._rated_current}A with secondary current of {self._secondary_rating}A")
                descriptions.append(f"<b>{self._accuracy_class}</b>: Accuracy class (measurement error limit)")
                if "P" in self._accuracy_class:
                    # Protection class
                    p_class, alf = self._accuracy_class.split("P")
                    descriptions.append(f"   - {p_class}P: Protection class with {p_class}% accuracy")
                    descriptions.append(f"   - {alf}: Accuracy Limit Factor (max. current multiple)")
                descriptions.append(f"<b>{self._burden}VA</b>: Rated burden in volt-amperes")
                descriptions.append(f"<b>{self._insulation_level}kV</b>: Insulation level (max system voltage)")
                if self._thermal_rating != "1.0":
                    descriptions.append(f"<b>{self._thermal_rating}x</b>: Thermal rating factor (continuous overload capability)")
            else:  # VT
                descriptions.append(f"<b>VT</b>: Voltage Transformer")
                descriptions.append(f"<b>{self._rated_voltage}/{self._secondary_rating}</b>: Primary voltage rating of {self._rated_voltage}V with secondary voltage of {self._secondary_rating}V")
                descriptions.append(f"<b>{self._accuracy_class}</b>: Accuracy class (measurement error limit)")
                if "P" in self._accuracy_class:
                    # Protection class
                    descriptions.append(f"   - Protection class for use in protection systems")
                descriptions.append(f"<b>{self._burden}VA</b>: Rated burden in volt-amperes")
                descriptions.append(f"<b>{self._insulation_level}kV</b>: Insulation level (max system voltage)")
            
            descriptions.append(f"<b>{self._frequency}Hz</b>: Rated frequency")
            descriptions.append(f"<b>{self._installation.capitalize()}</b>: Installation environment")
            
            # Additional application-specific information
            if self._application == "metering":
                descriptions.append("<b>Metering</b>: For revenue metering and measurements")
            elif self._application == "protection":
                descriptions.append("<b>Protection</b>: For protection systems requiring higher ALF")
            else:
                descriptions.append("<b>Combined</b>: For both metering and protection applications")
            
            # Set output name with all formats
            self._output_name = "\n".join([f"{std}: {name}" for std, name in names.items()])
            self._description = "<br>".join(descriptions)
            
            # Emit signals
            self.outputNameChanged.emit()
            self.descriptionChanged.emit()
            
        except Exception as e:
            self._error_message = f"Error generating name: {str(e)}"
            self.errorMessageChanged.emit()
    
    @Slot()
    def exportToPdf(self):
        """Export the transformer naming guide to a PDF file
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create timestamp for filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"transformer_naming_guide_{timestamp}")
            if not pdf_file:
                self.pdfExportStatusChanged.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create temporary directory for diagram images
            temp_dir = tempfile.mkdtemp()
            diagram_path = os.path.join(temp_dir, "transformer_diagram.png")
            
            # Generate diagram image using matplotlib
            self._generate_diagram(diagram_path)
            
            # Prepare data for PDF
            names = {}
            for std in ["IEC", "ANSI", "ABB", "Siemens"]:
                if self._transformer_type == "CT":
                    iec_params = {
                        "type": self._transformer_type,
                        "ratio": f"{self._rated_current}/{self._secondary_rating}",
                        "accuracy_class": self._accuracy_class,
                        "burden": self._burden,
                        "insulation": self._insulation_level,
                        "application": self._application.capitalize(),
                        "thermal": self._thermal_rating,
                        "installation": self._installation.capitalize(),
                        "frequency": self._frequency
                    }
                else:  # VT
                    iec_params = {
                        "type": self._transformer_type,
                        "ratio": f"{self._rated_voltage}/{self._secondary_rating}",
                        "accuracy_class": self._accuracy_class,
                        "burden": self._burden,
                        "insulation": self._insulation_level,
                        "application": self._application.capitalize(),
                        "thermal": self._thermal_rating,
                        "installation": self._installation.capitalize(),
                        "frequency": self._frequency
                    }
                names[std] = self._naming_formats[std][self._transformer_type].format(**iec_params)
            
            data = {
                'transformer_type': self._transformer_type,
                'primary_rating': self._rated_current if self._transformer_type == "CT" else self._rated_voltage,
                'secondary_rating': self._secondary_rating,
                'accuracy_class': self._accuracy_class,
                'burden': self._burden,
                'insulation_level': self._insulation_level,
                'application': self._application,
                'installation': self._installation,
                'frequency': self._frequency,
                'thermal_rating': self._thermal_rating,
                'diagram_path': diagram_path if os.path.exists(diagram_path) else None,
                'naming_standards': names,
                'description': self._description.replace('<br>', '\n').replace('<b>', '').replace('</b>', '')
            }
            
            # Generate PDF
            from utils.pdf.pdf_generator_transformer_naming import TransformerNamingPdfGenerator
            pdf_generator = TransformerNamingPdfGenerator()
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
            error_msg = f"Error exporting to PDF: {str(e)}"
            logger.error(error_msg)
            self.pdfExportStatusChanged.emit(False, error_msg)
            return False
    
    def _generate_diagram(self, filepath):
        """Generate a diagram of the transformer using matplotlib
        
        Args:
            filepath: Path to save the diagram image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create figure
            plt.figure(figsize=(10, 8))
            
            # Set up the plot area
            ax = plt.subplot(1, 1, 1)
            
            # Draw different diagrams based on transformer type
            if self._transformer_type == "CT":
                self._draw_ct_diagram(ax)
            else:
                self._draw_vt_diagram(ax)
            
            # Set title
            plt.title(f"{self._transformer_type} - {self._rated_current if self._transformer_type == 'CT' else self._rated_voltage}/{self._secondary_rating} - {self._accuracy_class} - {self._burden}VA", fontsize=14)
            
            # Remove axis ticks
            plt.axis('off')
            
            # Add key parameters as text
            info_text = [
                f"{'Current' if self._transformer_type == 'CT' else 'Voltage'} Transformer ({self._transformer_type})",
                f"Ratio: {self._rated_current if self._transformer_type == 'CT' else self._rated_voltage}/{self._secondary_rating}",
                f"Accuracy Class: {self._accuracy_class}",
                f"Burden: {self._burden} VA",
                f"Insulation Level: {self._insulation_level} kV",
                f"Application: {self._application.capitalize()}",
                f"Installation: {self._installation.capitalize()}",
                f"Frequency: {self._frequency} Hz",
                f"Thermal Rating: {self._thermal_rating}x"
            ]
            
            plt.figtext(0.5, 0.05, '\n'.join(info_text), ha='center', fontsize=12, 
                       bbox={'facecolor': 'lightblue', 'alpha': 0.3, 'pad': 10})
            
            # Save the figure
            plt.tight_layout(rect=[0, 0.15, 1, 0.95])
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
    
    def _draw_ct_diagram(self, ax):
        """Draw a Current Transformer diagram
        
        Args:
            ax: Matplotlib axis to draw on
        """
        # Primary conductor
        ax.plot([-3, 3], [2, 2], 'k-', linewidth=4)
        ax.text(-3.5, 2, "Primary", fontsize=12)
        ax.text(3.2, 2, f"{self._rated_current}A", fontsize=12)
        
        # Core
        circle = plt.Circle((0, 0), 1.5, fill=False, linewidth=2, color='blue')
        ax.add_patch(circle)
        
        # Secondary winding
        for i in range(0, 360, 40):
            angle = i * 3.14159 / 180
            x = 1.5 * 0.8 * np.cos(angle)
            y = 1.5 * 0.8 * np.sin(angle)
            rect = plt.Rectangle((x-0.2, y-0.2), 0.4, 0.4, angle=i, fc='orange', ec='k')
            ax.add_patch(rect)
        
        # Secondary terminals
        ax.plot([-2, -1.5], [-2, -1.5], 'k-', linewidth=2)
        ax.plot([2, 1.5], [-2, -1.5], 'k-', linewidth=2)
        
        # Load
        ax.plot([-2, 2], [-2, -2], 'k-', linewidth=2)
        rectangle = plt.Rectangle((-1, -2.5), 2, 1, fc='green', alpha=0.3, ec='k')
        ax.add_patch(rectangle)
        ax.text(0, -2.3, f"Burden\n{self._burden}VA", ha='center', fontsize=10)
        
        # Secondary current
        ax.text(0, -3.2, f"Secondary: {self._secondary_rating}A", ha='center', fontsize=12)
        
        # Set view limits
        ax.set_xlim(-4, 4)
        ax.set_ylim(-4, 3)
    
    def _draw_vt_diagram(self, ax):
        """Draw a Voltage Transformer diagram
        
        Args:
            ax: Matplotlib axis to draw on
        """
        # Primary side
        ax.plot([-3, -1], [2, 2], 'k-', linewidth=2)
        ax.plot([-3, -1], [-2, -2], 'k-', linewidth=2)
        ax.text(-3.5, 2, "Primary", fontsize=12)
        ax.text(-3.5, -2, f"{self._rated_voltage}V", fontsize=12)
        
        # Transformer core
        rect = plt.Rectangle((-0.75, -1.5), 1.5, 3, fc='gray', alpha=0.3, ec='k')
        ax.add_patch(rect)
        
        # Primary winding
        for i in range(-1, 2, 1):
            circ = plt.Circle((-0.75, i), 0.4, fc='red', alpha=0.3, ec='k')
            ax.add_patch(circ)
            ax.text(-0.75, i, "P", ha='center', va='center', fontsize=10)
        
        # Secondary winding
        for i in range(-1, 2, 1):
            circ = plt.Circle((0.75, i), 0.4, fc='blue', alpha=0.3, ec='k')
            ax.add_patch(circ)
            ax.text(0.75, i, "S", ha='center', va='center', fontsize=10)
        
        # Secondary side
        ax.plot([1, 3], [2, 2], 'k-', linewidth=2)
        ax.plot([1, 3], [-2, -2], 'k-', linewidth=2)
        ax.text(3.2, 2, "Secondary", fontsize=12)
        ax.text(3.2, -2, f"{self._secondary_rating}V", fontsize=12)
        
        # Load
        rect = plt.Rectangle((2, -1.5), 1, 3, fc='green', alpha=0.3, ec='k')
        ax.add_patch(rect)
        ax.text(2.5, 0, f"Burden\n{self._burden}VA", ha='center', fontsize=10)
        
        # Set view limits
        ax.set_xlim(-4, 4)
        ax.set_ylim(-3, 3)
    
    @Property(str, notify=outputNameChanged)
    def outputName(self):
        return self._output_name
    
    @Property(str, notify=descriptionChanged)
    def description(self):
        return self._description
    
    @Property(str, notify=errorMessageChanged)
    def errorMessage(self):
        return self._error_message
    
    # Property getters and setters with notify signals
    @Property(str, notify=transformerTypeChanged)
    def transformerType(self):
        return self._transformer_type
    
    @transformerType.setter
    def transformerType(self, value):
        if value in ["CT", "VT"] and self._transformer_type != value:
            self._transformer_type = value
            self.transformerTypeChanged.emit()
            self._generate_name()
    
    @Property(str, notify=accuracyClassChanged)
    def accuracyClass(self):
        return self._accuracy_class
    
    @accuracyClass.setter
    def accuracyClass(self, value):
        if (value in self._ct_accuracy_classes or value in self._vt_accuracy_classes) and self._accuracy_class != value:
            self._accuracy_class = value
            self.accuracyClassChanged.emit()
            self._generate_name()
    
    @Property(str, notify=ratedCurrentChanged)
    def ratedCurrent(self):
        return self._rated_current
    
    @ratedCurrent.setter
    def ratedCurrent(self, value):
        if value in self._ct_rated_currents and self._rated_current != value:
            self._rated_current = value
            self.ratedCurrentChanged.emit()
            self._generate_name()
    
    @Property(str, notify=ratedVoltageChanged)
    def ratedVoltage(self):
        return self._rated_voltage
    
    @ratedVoltage.setter
    def ratedVoltage(self, value):
        if value in self._vt_rated_voltages and self._rated_voltage != value:
            self._rated_voltage = value
            self.ratedVoltageChanged.emit()
            self._generate_name()
    
    @Property(str, notify=secondaryRatingChanged)
    def secondaryRating(self):
        return self._secondary_rating
    
    @secondaryRating.setter
    def secondaryRating(self, value):
        if self._transformer_type == "CT":
            valid_ratings = self._ct_secondary_ratings
        else:
            valid_ratings = self._vt_secondary_ratings
            
        if value in valid_ratings and self._secondary_rating != value:
            self._secondary_rating = value
            self.secondaryRatingChanged.emit()
            self._generate_name()
    
    @Property(str, notify=burdenChanged)
    def burden(self):
        return self._burden
    
    @burden.setter
    def burden(self, value):
        try:
            burden_value = float(value)
            if 1.0 <= burden_value <= 100.0 and self._burden != value:
                self._burden = value
                self.burdenChanged.emit()
                self._generate_name()
        except ValueError:
            pass
    
    @Property(str, notify=frequencyChanged)
    def frequency(self):
        return self._frequency
    
    @frequency.setter
    def frequency(self, value):
        if value in self._frequencies and self._frequency != value:
            self._frequency = value
            self.frequencyChanged.emit()
            self._generate_name()
    
    @Property(str, notify=insulationLevelChanged)
    def insulationLevel(self):
        return self._insulation_level
    
    @insulationLevel.setter
    def insulationLevel(self, value):
        if value in self._insulation_levels and self._insulation_level != value:
            self._insulation_level = value
            self.insulationLevelChanged.emit()
            self._generate_name()
    
    @Property(str, notify=applicationChanged)
    def application(self):
        return self._application
    
    @application.setter
    def application(self, value):
        if value in self._applications and self._application != value:
            self._application = value
            self.applicationChanged.emit()
            self._generate_name()
    
    @Property(str, notify=installationChanged)
    def installation(self):
        return self._installation
    
    @installation.setter
    def installation(self, value):
        if value in self._installations and self._installation != value:
            self._installation = value
            self.installationChanged.emit()
            self._generate_name()
    
    @Property(str, notify=thermalRatingChanged)
    def thermalRating(self):
        return self._thermal_rating
    
    @thermalRating.setter
    def thermalRating(self, value):
        if value in self._thermal_ratings and self._thermal_rating != value:
            self._thermal_rating = value
            self.thermalRatingChanged.emit()
            self._generate_name()
    
    # Methods to get available options for dropdowns
    @Slot(result="QVariantList")
    def getAccuracyClasses(self):
        if self._transformer_type == "CT":
            return self._ct_accuracy_classes
        else:
            return self._vt_accuracy_classes
    
    @Slot(result="QVariantList")
    def getRatedCurrents(self):
        return self._ct_rated_currents
    
    @Slot(result="QVariantList")
    def getRatedVoltages(self):
        return self._vt_rated_voltages
    
    @Slot(result="QVariantList")
    def getSecondaryRatings(self):
        if self._transformer_type == "CT":
            return self._ct_secondary_ratings
        else:
            return self._vt_secondary_ratings
    
    @Slot(result="QVariantList")
    def getInsulationLevels(self):
        return self._insulation_levels
    
    @Slot(result="QVariantList")
    def getApplications(self):
        return self._applications
    
    @Slot(result="QVariantList")
    def getInstallations(self):
        return self._installations
    
    @Slot(result="QVariantList")
    def getFrequencies(self):
        return self._frequencies
    
    @Slot(result="QVariantList")
    def getThermalRatings(self):
        return self._thermal_ratings
