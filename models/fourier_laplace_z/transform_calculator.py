import io
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from PySide6.QtCore import QObject, Signal, Slot, Property, QThreadPool
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
        """Export the transform results to a PDF file using in-memory image generation
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            from utils.pdf.pdf_generator_transform import TransformPdfGenerator

            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Create filename based on transform type to make it clear which type is being exported
            transform_type = self._transform_type.lower()
            filepath = self._file_saver.get_save_filepath("pdf", f"{transform_type}_report_{timestamp}")
            if not filepath:
                self.pdfExportStatusChanged.emit(False, "PDF export canceled")
                return False
            
            # Clean up filepath using FileSaver's clean_filepath method
            filepath = self._file_saver.clean_filepath(filepath)
            filepath = self._file_saver.ensure_file_extension(filepath, "pdf")
            
            # Generate charts in memory
            time_domain_bytes = self._generate_time_domain_chart_bytes()
            transform_bytes = self._generate_transform_chart_bytes()
            
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
                'time_domain_image_bytes': time_domain_bytes,
                'transform_image_bytes': transform_bytes
            }
            
            # Generate PDF using the new dedicated PDF generator
            pdf_generator = TransformPdfGenerator()
            success = pdf_generator.generate_report(data, filepath)
            
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

    def _generate_time_domain_chart_bytes(self):
        """Generate time domain chart in memory
        
        Returns:
            BytesIO: Image data as BytesIO object or None if generation failed
        """
        try:
            # Create figure with better aspect ratio for time domain
            plt.figure(figsize=(10, 4))
            
            # Time domain chart
            if self._time_domain:
                t_vals = [point['x'] for point in self._time_domain]
                y_vals = [point['y'] for point in self._time_domain]
                
                plt.plot(t_vals, y_vals, 'b-', linewidth=2)
                plt.title(f"Time Domain: {self._function_type} Function")
                plt.xlabel("Time (s)")
                plt.ylabel("Amplitude")
                plt.grid(True, linestyle='--', alpha=0.7)
                
                # Adjust y-axis limits for better visualization
                if y_vals:
                    y_min = min(y_vals)
                    y_max = max(y_vals)
                    y_range = y_max - y_min
                    
                    # Add some padding to y-axis
                    padding = y_range * 0.1 if y_range > 0 else 0.1
                    plt.ylim([y_min - padding, y_max + padding])
            
            # Save the figure to BytesIO object
            buf = io.BytesIO()
            plt.tight_layout()
            plt.savefig(buf, format='png', dpi=150)
            plt.close()
            buf.seek(0)
            
            return buf
            
        except Exception as e:
            logger.error(f"Error generating time domain chart: {e}")
            plt.close('all')  # Ensure figures are closed
            return None

    def _generate_transform_chart_bytes(self):
        """Generate transform domain chart in memory
        
        Returns:
            BytesIO: Image data as BytesIO object or None if generation failed
        """
        try:
            # Create figure
            plt.figure(figsize=(10, 6))
            
            # Plot magnitude
            if self._frequencies and self._transform_result:
                plt.plot(self._frequencies, self._transform_result, 'r-', linewidth=2)
                
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
                plt.grid(True, linestyle='--', alpha=0.7)
            
            # Save the figure to BytesIO object
            buf = io.BytesIO()
            plt.tight_layout()
            plt.savefig(buf, format='png', dpi=150)
            plt.close()
            buf.seek(0)
            
            return buf
            
        except Exception as e:
            logger.error(f"Error generating transform chart: {e}")
            plt.close('all')  # Ensure figures are closed
            return None
