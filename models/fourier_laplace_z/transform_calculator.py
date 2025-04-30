import tempfile
import os
import matplotlib
# Set non-interactive backend before importing pyplot
matplotlib.use('Agg')  # Use Agg backend which doesn't require a display
import matplotlib.pyplot as plt
from PySide6.QtCore import QObject, Signal, Slot, Property, QThreadPool, Qt, Q_ARG

from datetime import datetime
from .transform_worker import TransformCalculatorWorker

from services.file_saver import FileSaver
from services.logger_config import configure_logger

logger = configure_logger("qmltest", component="transform_calculator")

class TransformCalculator(QObject):
    """Calculator for Fourier and Laplace transforms with multithreading support"""
    
    transformTypeChanged = Signal()
    functionTypeChanged = Signal()
    parameterAChanged = Signal()
    parameterBChanged = Signal()
    frequencyChanged = Signal()
    samplePointsChanged = Signal()
    windowTypeChanged = Signal()
    customFormulaChanged = Signal()
    resultsCalculated = Signal()
    calculatingChanged = Signal()
    
    # Add PDF export status signal
    pdfExportStatusChanged = Signal(bool, str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        # Initialize properties
        self._transform_type = "Fourier"  # "Fourier" or "Laplace"
        self._function_type = "Sine"      # Function type to transform
        self._parameter_a = 1.0           # First parameter for function
        self._parameter_b = 2.0           # Second parameter for function
        self._frequency = 1.0             # Frequency for periodic functions
        self._sample_points = 500         # Number of points for visualization
        self._window_type = "None"        # Window function type
        self._calculating = False         # Flag for calculations in progress
        self._custom_formula = "sin(2*pi*f*t)"  # Default custom formula
        
        # Result storage
        self._time_domain = []            # Time domain signal
        self._transform_result = []       # Transform result
        self._phase_result = []           # Phase information
        self._frequencies = []            # Frequency domain range
        self._equation_original = ""      # Text representation of input equation
        self._equation_transform = ""     # Text representation of transformed equation
        self._resonant_frequency = -1     # Resonant frequency for Laplace transforms
        
        # Function types
        self._function_types = [
            "Sine", "Square", "Sawtooth", "Exponential", 
            "Gaussian", "Step", "Impulse", "Damped Sine", "Custom"
        ]
        
        # Window function types
        self._window_types = [
            "None", "Hann", "Hamming", "Blackman", "Bartlett", 
            "Flattop", "Kaiser", "Gaussian", "Tukey"
        ]
        
        # Thread pool for calculations
        self._thread_pool = QThreadPool.globalInstance()
        
        # Initialize FileSaver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our pdfExportStatusChanged signal
        self._file_saver.saveStatusChanged.connect(self.pdfExportStatusChanged)
        
        # Initialize calculations
        self._calculate()
    
    @Property(str, notify=transformTypeChanged)
    def transformType(self):
        return self._transform_type
    
    @transformType.setter
    def transformType(self, value):
        if self._transform_type != value and value in ["Fourier", "Laplace"]:
            self._transform_type = value
            self.transformTypeChanged.emit()
            self._calculate()
    
    @Property(str, notify=functionTypeChanged)
    def functionType(self):
        return self._function_type
    
    @functionType.setter
    def functionType(self, value):
        if self._function_type != value and value in self._function_types:
            self._function_type = value
            self.functionTypeChanged.emit()
            self._calculate()
    
    @Property(float, notify=parameterAChanged)
    def parameterA(self):
        return self._parameter_a
    
    @parameterA.setter
    def parameterA(self, value):
        if self._parameter_a != value:
            self._parameter_a = value
            self.parameterAChanged.emit()
            self._calculate()
    
    @Property(float, notify=parameterBChanged)
    def parameterB(self):
        return self._parameter_b
    
    @parameterB.setter
    def parameterB(self, value):
        if self._parameter_b != value:
            self._parameter_b = value
            self.parameterBChanged.emit()
            self._calculate()
    
    @Property(float, notify=frequencyChanged)
    def frequency(self):
        return self._frequency
    
    @frequency.setter
    def frequency(self, value):
        if self._frequency != value and value > 0:
            self._frequency = value
            self.frequencyChanged.emit()
            self._calculate()
    
    @Property(int, notify=samplePointsChanged)
    def samplePoints(self):
        return self._sample_points
    
    @samplePoints.setter
    def samplePoints(self, value):
        if self._sample_points != value and 10 <= value <= 1000:
            self._sample_points = value
            self.samplePointsChanged.emit()
            self._calculate()
    
    @Property(bool, notify=calculatingChanged)
    def calculating(self):
        return self._calculating
    
    @calculating.setter
    def calculating(self, value):
        if self._calculating != value:
            self._calculating = value
            self.calculatingChanged.emit()
    
    @Property(list, notify=resultsCalculated)
    def functionTypes(self):
        return self._function_types
    
    @Property(str, notify=windowTypeChanged)
    def windowType(self):
        return self._window_type
    
    @windowType.setter
    def windowType(self, value):
        if self._window_type != value and value in self._window_types:
            self._window_type = value
            self.windowTypeChanged.emit()
            # Only recalculate if Fourier is selected
            if self._transform_type == "Fourier":
                self._calculate()
    
    @Property(list, notify=resultsCalculated)
    def windowTypes(self):
        return self._window_types
    
    @Property('QVariantList', notify=resultsCalculated)
    def timeDomain(self):
        return self._time_domain
    
    @Property(list, notify=resultsCalculated)
    def transformResult(self):
        return self._transform_result
    
    @Property(list, notify=resultsCalculated)
    def phaseResult(self):
        return self._phase_result
    
    @Property(list, notify=resultsCalculated)
    def frequencies(self):
        return self._frequencies
    
    @Property(str, notify=resultsCalculated)
    def equationOriginal(self):
        return self._equation_original
    
    @Property(str, notify=resultsCalculated)
    def equationTransform(self):
        return self._equation_transform
    
    @Property(float, notify=resultsCalculated)
    def resonantFrequency(self):
        return self._resonant_frequency
    
    @Property(str, notify=customFormulaChanged)
    def customFormula(self):
        return self._custom_formula
    
    @customFormula.setter
    def customFormula(self, value):
        if self._custom_formula != value:
            self._custom_formula = value
            self.customFormulaChanged.emit()
            self._calculate()
    
    def _calculate(self):
        """Start calculation in a separate thread"""
        try:
            # Set calculating flag
            self.calculating = True
            
            # Create worker
            worker = TransformCalculatorWorker(self)
            
            # Start the worker in a separate thread
            self._thread_pool.start(worker)
            
        except Exception:
            # Silently handle the error without logging
            self.calculating = False
    
    @Slot("QVariantList", "QVariantList", "QVariantList", "QVariantList")
    def updateResults(self, time_domain, frequencies, magnitude, phase):
        """Update results from worker thread (called via invokeMethod)"""
        try:
            # Update the result properties
            self._time_domain = time_domain if time_domain else []
            self._frequencies = frequencies if frequencies else []
            self._transform_result = magnitude if magnitude else []
            self._phase_result = phase if phase else []
            
        except Exception as e:
            # Log the error
            print(f"Error updating results: {str(e)}")
            # Ensure properties are at least empty lists, not None
            self._time_domain = []
            self._frequencies = []
            self._transform_result = []
            self._phase_result = []
        finally:
            # Always set calculating to false regardless of success or failure
            self.calculating = False
            self.resultsCalculated.emit()
    
    # QML slots
    @Slot(str)
    def setTransformType(self, transform_type):
        self.transformType = transform_type
    
    @Slot(str)
    def setFunctionType(self, function_type):
        self.functionType = function_type
    
    @Slot(float)
    def setParameterA(self, value):
        self.parameterA = value
    
    @Slot(float)
    def setParameterB(self, value):
        self.parameterB = value
    
    @Slot(float)
    def setFrequency(self, value):
        self.frequency = value
    
    @Slot(int)
    def setSamplePoints(self, value):
        self.samplePoints = value
    
    @Slot(str)
    def setWindowType(self, window_type):
        self.windowType = window_type
    
    @Slot(str)
    def setCustomFormula(self, formula):
        self.customFormula = formula
    
    @Slot()
    def calculate(self):
        self._calculate()
    
    @Slot(result=bool)
    def export_to_pdf(self):
        """Export the transform results to a PDF file
        
        Args:
            filepath: Path to save the PDF report
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            from utils.pdf.pdf_generator import PDFGenerator

            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

            filepath = self._file_saver.get_save_filepath("pdf", f"fourier_report{timestamp}")
            if not filepath:
                self.pdfExportStatusChanged.emit(False, "PDF export canceled")
                return ""
            
            # Clean up filepath using FileSaver's clean_filepath method
            filepath = self._file_saver.clean_filepath(filepath)
            filepath = self._file_saver.ensure_file_extension(filepath, "pdf")
            
            # Create temporary directory for chart images
            temp_dir = tempfile.mkdtemp()
            time_domain_path = os.path.join(temp_dir, "time_domain.png")
            transform_path = os.path.join(temp_dir, "transform.png")
            
            # Generate charts
            self._generate_chart_for_pdf(time_domain_path, transform_path)
            
            # Determine which parameters are needed based on function type
            needs_param_b = self._function_type not in ["Sine", "Square", "Sawtooth"]
            needs_frequency = self._function_type in ["Sine", "Square", "Sawtooth", "Damped Sine", "Custom"]
            
            # Prepare data for PDF generation
            data = {
                'transform_type': self._transform_type,
                'function_type': self._function_type,
                'parameter_a': self._parameter_a,
                'parameter_b': self._parameter_b,
                'frequency': self._frequency,
                'sample_points': self._sample_points,
                'window_type': self._window_type,
                'equation_original': self._equation_original,
                'equation_transform': self._equation_transform,
                'resonant_frequency': self._resonant_frequency,
                'needs_parameter_b': needs_param_b,
                'needs_frequency': needs_frequency,
                'time_domain_image_path': time_domain_path if os.path.exists(time_domain_path) else None,
                'transform_image_path': transform_path if os.path.exists(transform_path) else None
            }
            
            # Generate PDF
            pdf_generator = PDFGenerator()
            success = pdf_generator.generate_transform_report(data, filepath)
            
            # Clean up temporary files
            try:
                if os.path.exists(time_domain_path):
                    os.remove(time_domain_path)
                if os.path.exists(transform_path):
                    os.remove(transform_path)
                os.rmdir(temp_dir)
            except:
                pass
            
            # Force garbage collection to ensure resources are freed
            import gc
            gc.collect()
            
            # Signal success or failure
            if success:
                self._file_saver._emit_success_with_path(filepath, "PDF saved")
                return True
            else:
                self._file_saver._emit_failure_with_path(filepath, "Error saving PDF")
                return False
            
        except Exception as e:
            error_msg = f"Error exporting to PDF: {str(e)}"
            logger.error(error_msg)
            # Send error to QML via signal
            self.pdfExportStatusChanged.emit(False, error_msg)
            return False

    def _generate_chart_for_pdf(self, time_domain_path, transform_path):
        """Generate charts for PDF export
        
        Args:
            time_domain_path: Path to save time domain chart
            transform_path: Path to save transform chart
        """
        try:
            # Use matplotlib to generate charts
            plt.figure(figsize=(8, 4))
            
            # Time domain chart
            if self._time_domain:
                t_vals = [point['x'] for point in self._time_domain]
                y_vals = [point['y'] for point in self._time_domain]
                
                plt.plot(t_vals, y_vals, 'b-')
                plt.title(f"Time Domain: {self._function_type} Function")
                plt.xlabel("Time (s)")
                plt.ylabel("Amplitude")
                plt.grid(True)
                plt.tight_layout()
                plt.savefig(time_domain_path, dpi=100)
                plt.close()
            
            # Transform domain chart
            if self._frequencies and self._transform_result:
                plt.figure(figsize=(8, 4))
                
                # Plot magnitude
                plt.plot(self._frequencies, self._transform_result, 'r-')
                
                # Add resonant frequency line for Laplace
                if self._transform_type == "Laplace" and self._resonant_frequency > 0:
                    # Find y-range
                    y_max = max(self._transform_result) * 1.1
                    plt.axvline(x=self._resonant_frequency, color='orange', linestyle='--')
                    plt.annotate(f"Resonant: {self._resonant_frequency:.1f} rad/s", 
                                xy=(self._resonant_frequency, y_max*0.9),
                                xytext=(self._resonant_frequency + 5, y_max*0.9),
                                arrowprops=dict(facecolor='orange', shrink=0.05),
                                )
                
                plt.title(f"{self._transform_type} Transform Magnitude")
                x_label = "Frequency (Hz)" if self._transform_type == "Fourier" else "jω (rad/s)"
                plt.xlabel(x_label)
                plt.ylabel("Magnitude")
                plt.grid(True)
                plt.tight_layout()
                plt.savefig(transform_path, dpi=100)
                plt.close('all')  # Close all figures to prevent resource leaks
                
                # Force garbage collection
                import gc
                gc.collect()
                
        except Exception as e:
            print(f"Error generating charts for PDF: {str(e)}")
            # Make sure to close any open figures even on error
            plt.close('all')

    @Slot()
    def generate_plot_for_file_saver(self):
        """Generate and save a plot image
        
        Args:
            default_filename: Default name to suggest
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            filepath = self._file_saver.get_save_filepath("png", f"fourier_plot{timestamp}")
            if not filepath:
                self.pdfExportStatusChanged.emit(False, "Plot save canceled")
                return False
                
            # Generate the plot directly
            result_path = self.generate_plot(filepath)
            
            if result_path:
                # Use standardized success message
                self._file_saver._emit_success_with_path(result_path, "Plot saved")
                return True
            else:
                error_msg = "Failed to generate plot"
                logger.error(error_msg)
                self._file_saver._emit_failure_with_path(result_path, "Plot save failed")
                return False
                
        except Exception as e:
            error_msg = f"Error saving plot: {str(e)}"
            logger.error(error_msg)
            self.pdfExportStatusChanged.emit(False, error_msg)
            return False

    def generate_plot(self, filepath):
        """Generate a plot image for the file saver
        
        Args:
            filepath: Path to save the generated image
            
        Returns:
            str: Path to the saved image or empty string on failure
        """
        try:
            # Create a combined plot with both time and frequency domains
            fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))
            
            # Time domain plot
            if self._time_domain:
                t_vals = [point['x'] for point in self._time_domain]
                y_vals = [point['y'] for point in self._time_domain]
                
                ax1.plot(t_vals, y_vals, 'b-')
                ax1.set_title(f"Time Domain: {self._function_type} Function")
                ax1.set_xlabel("Time (s)")
                ax1.set_ylabel("Amplitude")
                ax1.grid(True)
            
            # Transform domain plot
            if self._frequencies and self._transform_result:
                ax2.plot(self._frequencies, self._transform_result, 'r-')
                
                # Add resonant frequency line for Laplace
                if self._transform_type == "Laplace" and self._resonant_frequency > 0:
                    # Find y-range
                    y_max = max(self._transform_result) * 1.1
                    ax2.axvline(x=self._resonant_frequency, color='orange', linestyle='--')
                    ax2.annotate(f"Resonant: {self._resonant_frequency:.1f} rad/s", 
                                xy=(self._resonant_frequency, y_max*0.9),
                                xytext=(self._resonant_frequency + 5, y_max*0.9),
                                arrowprops=dict(facecolor='orange', shrink=0.05),
                                )
                
                ax2.set_title(f"{self._transform_type} Transform Magnitude")
                x_label = "Frequency (Hz)" if self._transform_type == "Fourier" else "jω (rad/s)"
                ax2.set_xlabel(x_label)
                ax2.set_ylabel("Magnitude")
                ax2.grid(True)
            
            # Add summary information
            plt.figtext(0.5, 0.01, 
                      f"Transform: {self._transform_type} | Function: {self._function_type} | Equation: {self._equation_original}", 
                      ha="center", fontsize=9, bbox={"facecolor":"orange", "alpha":0.2, "pad":5})
            
            plt.tight_layout(rect=[0, 0.03, 1, 0.97])
            plt.savefig(filepath, dpi=100)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            import gc
            gc.collect()
            
            return filepath
            
        except Exception as e:
            print(f"Error generating plot: {str(e)}")
            # Make sure to close any open figures even on error
            plt.close('all')
            return ""
