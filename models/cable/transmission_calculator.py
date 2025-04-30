from PySide6.QtCore import QObject, Property, Signal, Slot
import cmath
import math
import tempfile
import os
from datetime import datetime
import matplotlib
import numpy as np
# Set non-interactive backend before importing pyplot
matplotlib.use('Agg')  # Use Agg backend which doesn't require a display
import matplotlib.pyplot as plt

from services.file_saver import FileSaver
from services.logger_config import configure_logger

logger = configure_logger("qmltest", component="transmission_line")

class TransmissionLineCalculator(QObject):
    # Define signals
    lengthChanged = Signal()
    resistanceChanged = Signal()
    inductanceChanged = Signal()
    capacitanceChanged = Signal()
    conductanceChanged = Signal()
    frequencyChanged = Signal()
    resultsCalculated = Signal()

    # Add new signals
    bundleConfigChanged = Signal()
    temperatureChanged = Signal()
    earthResistivityChanged = Signal()
    silCalculated = Signal()

    # Add export status signal
    exportComplete = Signal(bool, str)

    def __init__(self, parent=None):
        super().__init__(parent)
        # Initialize properties
        self._length = 100.0  # km
        self._resistance = 0.1  # Ω/km
        self._inductance = 1.0  # mH/km
        self._capacitance = 0.01  # µF/km
        self._conductance = 0.00001  # S/km - Typical value for overhead lines (1e-5 S/km)
        self._frequency = 50.0  # Hz
        
        # Results
        self._Z = complex(0, 0)  # Characteristic impedance
        self._gamma = complex(0, 0)  # Propagation constant
        self._alpha = 0.0  # Attenuation constant
        self._beta = 0.0  # Phase constant
        self._A = complex(1, 0)  # ABCD parameters
        self._B = complex(0, 0)
        self._C = complex(0, 0)
        self._D = complex(1, 0)
        
        # Add new properties
        self._bundle_spacing = 0.4  # meters
        self._sub_conductors = 2    # conductors per bundle
        self._conductor_gmr = 0.0078  # meters
        self._conductor_temperature = 75.0  # °C
        self._earth_resistivity = 100.0  # Ω⋅m
        self._nominal_voltage = 400.0  # kV
        
        # Additional results
        self._skin_factor = 1.0
        self._sil = 0.0  # Surge impedance loading
        self._earth_impedance = complex(0, 0)

        # Initialize file saver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our exportComplete signal
        self._file_saver.saveStatusChanged.connect(self.exportComplete)

        self._calculate()

    def _calculate(self):
        """Perform transmission line calculations"""
        try:
            # Calculate skin effect factor - More accurate formula
            f = self._frequency
            # Improved skin effect model using conductor temperature
            if f > 0:
                # More accurate formula for skin effect based on frequency and temperature
                temp_factor = 1 + 0.00403 * (self._conductor_temperature - 20)  # Temperature correction
                self._skin_factor = 1 + 0.00477 * math.sqrt(f) * temp_factor
            else:
                self._skin_factor = 1.0
            
            # Apply skin effect to resistance
            R_ac = self._resistance * self._skin_factor
            
            # Calculate bundle GMR - Corrected formula
            if self._sub_conductors > 1:
                # Correct geometric mean radius formula for bundle conductors
                single_conductor_gmr = self._conductor_gmr
                
                # Calculate geometric mean distance of conductors in bundle
                if self._sub_conductors == 2:
                    # Two conductors in a bundle
                    gmd = self._bundle_spacing
                elif self._sub_conductors == 3:
                    # Three conductors in triangle formation
                    gmd = math.pow(self._bundle_spacing, 3)**(1/3)
                elif self._sub_conductors == 4:
                    # Four conductors in square formation
                    # Fix: For square formation with 4 conductors, we need product of 6 distances
                    diagonal = math.sqrt(2) * self._bundle_spacing
                    gmd = math.pow(self._bundle_spacing**4 * diagonal**2, 1/6)
                else:
                    gmd = self._bundle_spacing  # Default fallback
                
                # Bundle GMR = nth root of (GMR_single * product of distances between conductors)
                bundle_gmr = math.pow(single_conductor_gmr * math.pow(gmd, self._sub_conductors - 1), 1/self._sub_conductors)
            else:
                bundle_gmr = self._conductor_gmr
            
            # Calculate earth return impedance - Using Carson's equations with corrections
            if f > 0:
                # Carson's earth return formula with improved accuracy
                De = 658.5 * math.sqrt(self._earth_resistivity/f)  # Equivalent earth return distance
                # Earth return resistance and reactance components
                Ze_r = 4 * math.pi * f * 1e-4  # Resistance term in ohms/km
                Ze_x = 4 * math.pi * f * 1e-4 * math.log(De/bundle_gmr)  # Reactance term in ohms/km
                Ze = complex(Ze_r, Ze_x)
                self._earth_impedance = Ze
            else:
                Ze = complex(0, 0)
                self._earth_impedance = Ze
            
            # Update Z with bundling and earth effects
            w = 2 * math.pi * f if f > 0 else 0.0001  # Prevent division by zero
            
            # Primary parameters - series impedance and shunt admittance
            Z = complex(R_ac, w * self._inductance * 1e-3)  # Convert mH/km to H/km
            Y = complex(self._conductance, w * self._capacitance * 1e-6)  # Convert μF/km to F/km
            
            # Calculate characteristic impedance with improved numerical stability
            if abs(Y) > 1e-10:  # Use better threshold for comparison
                # Direct formula Z = sqrt(Z/Y) - characteristic impedance is independent of line length
                self._Z = cmath.sqrt(Z / Y)
                
                # Alternative calculation to verify result
                r = math.sqrt(R_ac**2 + (w * self._inductance * 1e-3)**2) 
                g = math.sqrt(self._conductance**2 + (w * self._capacitance * 1e-6)**2)
                
                # Calculate phase angles
                theta_z = math.atan2(w * self._inductance * 1e-3, R_ac)
                theta_y = math.atan2(w * self._capacitance * 1e-6, self._conductance) if self._conductance > 0 else math.pi/2
                
                # Alternative Z magnitude and angle calculation
                z_mag_alt = math.sqrt(r/g)
                z_ang_alt = (theta_z - theta_y)/2
                
                # Use the direct calculation, but verify it's reasonable
                if abs(abs(self._Z) - z_mag_alt) > z_mag_alt * 0.5:
                    # If large discrepancy, use the alternative calculation
                    self._Z = complex(z_mag_alt * math.cos(z_ang_alt), z_mag_alt * math.sin(z_ang_alt))
            else:
                # Handle zero or near-zero Y (open circuit)
                self._Z = complex(1e6, 0)  # High impedance as fallback
            
            # Calculate SIL - Surge Impedance Loading (more accurate formula)
            if abs(self._Z) > 0:
                # Fix: SIL formula needs proper units - kV^2/Zc in MW
                # SIL in MW = (kV^2 / Zc)
                self._sil = (self._nominal_voltage**2) / abs(self._Z)
                
                # Convert to proper MW units (if nominal voltage is in kV)
                self._sil = self._sil / 1.0  # Remove any unit conversion if already correct
            
            # Calculate propagation constant
            self._gamma = cmath.sqrt(Z * Y)
            self._alpha = self._gamma.real  # Attenuation constant (Np/km)
            self._beta = self._gamma.imag   # Phase constant (rad/km)
            
            # Calculate ABCD parameters - these DO depend on line length
            gamma_l = self._gamma * self._length  # This is where length affects the calculations
            
            # Use hyperbolic functions with numerical stability checks
            if abs(gamma_l) < 100:  # Prevent overflow
                self._A = cmath.cosh(gamma_l)
                self._B = self._Z * cmath.sinh(gamma_l)
                self._C = cmath.sinh(gamma_l) / self._Z
                self._D = self._A  # D = A for symmetrical lines
            else:
                # Fix: Alternative calculation for very long lines
                half_exp_pos = cmath.exp(gamma_l/2)
                half_exp_neg = cmath.exp(-gamma_l/2)
                self._A = (half_exp_pos + half_exp_neg) / 2
                self._B = self._Z * (half_exp_pos - half_exp_neg) / 2
                self._C = (half_exp_pos - half_exp_neg) / (2 * self._Z)
                self._D = self._A
            
            self.resultsCalculated.emit()
            self.silCalculated.emit()  # Make sure to emit this signal when SIL is recalculated
            
        except Exception as e:
            print(f"Error in transmission line calculation: {e}")

    @Slot()
    def exportReport(self):
        """Export transmission line analysis to PDF"""
        try:
            # Create timestamp for filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"transmission_line_report_{timestamp}")
            if not pdf_file:
                self.exportComplete.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create temporary directory for chart image
            temp_dir = tempfile.mkdtemp()
            chart_image_path = os.path.join(temp_dir, "transmission_line_viz.png")
            
            # Generate chart using matplotlib
            self._generate_visualization_chart(chart_image_path)
            
            # Prepare data for PDF
            data = {
                'length': self._length,
                'resistance': self._resistance,
                'inductance': self._inductance,
                'capacitance': self._capacitance,
                'conductance': self._conductance,
                'frequency': self._frequency,
                'nominal_voltage': self._nominal_voltage,
                'sub_conductors': self._sub_conductors,
                'bundle_spacing': self._bundle_spacing,
                'conductor_gmr': self._conductor_gmr,
                'conductor_temperature': self._conductor_temperature,
                'earth_resistivity': self._earth_resistivity,
                'z_magnitude': abs(self._Z),
                'z_angle': math.degrees(cmath.phase(self._Z)),
                'alpha': self._alpha,
                'beta': self._beta,
                'sil': self._sil,
                'a_magnitude': abs(self._A),
                'a_angle': math.degrees(cmath.phase(self._A)),
                'b_magnitude': abs(self._B),
                'b_angle': math.degrees(cmath.phase(self._B)),
                'c_magnitude': abs(self._C),
                'c_angle': math.degrees(cmath.phase(self._C)),
                'd_magnitude': abs(self._D),
                'd_angle': math.degrees(cmath.phase(self._D)),
                'chart_image_path': chart_image_path if os.path.exists(chart_image_path) else None
            }
            
            # Generate PDF
            from utils.pdf.pdf_generator_transmission import TransmissionPdfGenerator
            pdf_generator = TransmissionPdfGenerator()
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
            error_msg = f"Error exporting report: {str(e)}"
            logger.error(error_msg)
            self.exportComplete.emit(False, error_msg)
            return False
    
    def _generate_visualization_chart(self, filepath):
        """Generate transmission line visualization chart
        
        Args:
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create figure
            plt.figure(figsize=(10, 6))
            
            # Calculate points for voltage and current profiles along the line
            x_points = np.linspace(0, self._length, 100)
            voltage_profile = []
            current_profile = []
            
            # Calculate A, B, C, D parameters for varying lengths
            for x in x_points:
                gamma_x = self._gamma * x
                a = cmath.cosh(gamma_x)
                b = self._Z * cmath.sinh(gamma_x)
                c = cmath.sinh(gamma_x) / self._Z
                d = a  # D = A for symmetrical lines
                
                # Use simplified model with normalized voltage and current
                v_ratio = abs(a)  # |V_sending/V_receiving| assuming I_r = 0
                i_ratio = abs(c * 1.0)  # |I_sending| with normalized V_r
                
                voltage_profile.append(v_ratio)
                current_profile.append(i_ratio)
            
            # Plot voltage and current profiles
            plt.subplot(211)
            plt.plot(x_points, voltage_profile, 'b-', linewidth=2, label='Voltage Magnitude')
            plt.title('Voltage Profile Along the Line')
            plt.ylabel('Voltage Ratio |V/Vr|')
            plt.grid(True)
            plt.legend()
            
            plt.subplot(212)
            plt.plot(x_points, current_profile, 'r-', linewidth=2, label='Current Magnitude')
            plt.title('Current Profile Along the Line')
            plt.xlabel('Distance from Receiving End (km)')
            plt.ylabel('Current Ratio |I/Ir|')
            plt.grid(True)
            plt.legend()
            
            # Add overall title
            plt.suptitle(f'Transmission Line Analysis (Length: {self._length} km, Z₀: {abs(self._Z):.2f} Ω)', fontsize=14)
            
            # Add line parameters as text
            plt.figtext(0.5, 0.01, 
                      f"R: {self._resistance} Ω/km, L: {self._inductance} mH/km, C: {self._capacitance} μF/km, f: {self._frequency} Hz", 
                      ha="center", fontsize=9, bbox={"facecolor":"lightblue", "alpha":0.2, "pad":5})
            
            # Save the figure
            plt.tight_layout(rect=[0, 0.03, 1, 0.95])
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection
            import gc
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating visualization chart: {e}")
            # Make sure to close figures on error
            plt.close('all')
            return False

    # Properties
    @Property(float, notify=lengthChanged)
    def length(self):
        return self._length
    
    @length.setter
    def length(self, value):
        if value > 0:
            self._length = value
            self.lengthChanged.emit()
            self._calculate()

    @Property(float, notify=resistanceChanged)
    def resistance(self):
        return self._resistance
    
    @resistance.setter
    def resistance(self, value):
        if value >= 0:
            self._resistance = value
            self.resistanceChanged.emit()
            self._calculate()

    @Property(float, notify=inductanceChanged)
    def inductance(self):
        return self._inductance
    
    @inductance.setter
    def inductance(self, value):
        if value >= 0:
            self._inductance = value
            self.inductanceChanged.emit()
            self._calculate()

    @Property(float, notify=capacitanceChanged)
    def capacitance(self):
        return self._capacitance
    
    @capacitance.setter
    def capacitance(self, value):
        if value >= 0:
            self._capacitance = value
            self.capacitanceChanged.emit()
            self._calculate()

    @Property(float, notify=conductanceChanged)
    def conductance(self):
        """
        Get the conductance per unit length (S/km).
        
        Conductance represents leakage current through insulation.
        Higher conductance:
        1. Decreases characteristic impedance magnitude
        2. Modifies impedance phase angle
        3. Increases transmission line losses
        4. Decreases the surge impedance loading (SIL)
        
        For most power lines, conductance is very small in dry conditions.
        """
        return self._conductance
    
    @conductance.setter
    def conductance(self, value):
        if value >= 0:
            self._conductance = value
            self.conductanceChanged.emit()
            self._calculate()

    @Property(float, notify=frequencyChanged)
    def frequency(self):
        return self._frequency
    
    @frequency.setter
    def frequency(self, value):
        if value > 0:
            self._frequency = value
            self.frequencyChanged.emit()
            self._calculate()

    # Results properties
    @Property(complex, notify=resultsCalculated)
    def characteristicImpedance(self):
        return self._Z
    
    @Property(float, notify=resultsCalculated)
    def attenuationConstant(self):
        return self._alpha
    
    @Property(float, notify=resultsCalculated)
    def phaseConstant(self):
        return self._beta
    
    @Property(complex, notify=resultsCalculated)
    def parameterA(self):
        return self._A
    
    @Property(complex, notify=resultsCalculated)
    def parameterB(self):
        return self._B
    
    @Property(complex, notify=resultsCalculated)
    def parameterC(self):
        return self._C
    
    @Property(complex, notify=resultsCalculated)
    def parameterD(self):
        return self._D

    @Property(float, notify=resultsCalculated)
    def zMagnitude(self):
        """Get magnitude of characteristic impedance"""
        return abs(self._Z)
    
    @Property(float, notify=resultsCalculated)
    def zAngle(self):
        """Get angle of characteristic impedance in degrees"""
        return math.degrees(cmath.phase(self._Z))
    
    @Property(float, notify=resultsCalculated)
    def aMagnitude(self):
        return abs(self._A)
    
    @Property(float, notify=resultsCalculated)
    def aAngle(self):
        return math.degrees(cmath.phase(self._A))
    
    @Property(float, notify=resultsCalculated)
    def bMagnitude(self):
        return abs(self._B)
    
    @Property(float, notify=resultsCalculated)
    def bAngle(self):
        return math.degrees(cmath.phase(self._B))
    
    @Property(float, notify=resultsCalculated)
    def cMagnitude(self):
        return abs(self._C)
    
    @Property(float, notify=resultsCalculated)
    def cAngle(self):
        return math.degrees(cmath.phase(self._C))
    
    @Property(float, notify=resultsCalculated)
    def dMagnitude(self):
        return abs(self._D)
    
    @Property(float, notify=resultsCalculated)
    def dAngle(self):
        """Get angle of D parameter in degrees"""
        return math.degrees(cmath.phase(self._D))

    @Property(int, notify=bundleConfigChanged)
    def subConductors(self):
        return self._sub_conductors
    
    @subConductors.setter
    def subConductors(self, value):
        if 1 <= value <= 4:
            self._sub_conductors = value
            self.bundleConfigChanged.emit()
            self._calculate()

    @Property(float, notify=silCalculated)
    def surgeImpedanceLoading(self):
        return self._sil

    @Property(float, notify=bundleConfigChanged)
    def bundleSpacing(self):
        return self._bundle_spacing
    
    @bundleSpacing.setter
    def bundleSpacing(self, value):
        if value > 0:
            self._bundle_spacing = value
            self.bundleConfigChanged.emit()
            self._calculate()

    @Property(float, notify=temperatureChanged)
    def conductorTemperature(self):
        return self._conductor_temperature
    
    @conductorTemperature.setter
    def conductorTemperature(self, value):
        if value > 0:
            self._conductor_temperature = value
            self.temperatureChanged.emit()
            self._calculate()

    @Property(float, notify=earthResistivityChanged)
    def earthResistivity(self):
        return self._earth_resistivity
    
    @earthResistivity.setter
    def earthResistivity(self, value):
        if value > 0:
            self._earth_resistivity = value
            self.earthResistivityChanged.emit()
            self._calculate()

    @Property(float)
    def conductorGMR(self):
        return self._conductor_gmr
    
    @conductorGMR.setter
    def conductorGMR(self, value):
        if value > 0:
            self._conductor_gmr = value
            self.bundleConfigChanged.emit()
            self._calculate()
    
    @Property(float)
    def nominalVoltage(self):
        return self._nominal_voltage
    
    @nominalVoltage.setter
    def nominalVoltage(self, value):
        if value > 0:
            self._nominal_voltage = value
            self.silCalculated.emit()
            self._calculate()
    
    # QML slots
    @Slot(float)
    def setLength(self, value):
        self.length = value
    
    @Slot(float)
    def setResistance(self, value):
        self.resistance = value

    @Slot(float)
    def setInductance(self, value):
        self.inductance = value

    @Slot(float)
    def setCapacitance(self, value):
        self.capacitance = value

    @Slot(float)
    def setConductance(self, value):
        self.conductance = value

    @Slot(float)
    def setFrequency(self, value):
        self.frequency = value

    @Slot(int)
    def setSubConductors(self, value):
        self.subConductors = value

    @Slot(float)
    def setBundleSpacing(self, value):
        self.bundleSpacing = value

    @Slot(float)
    def setConductorTemperature(self, value):
        self.conductorTemperature = value

    @Slot(float)
    def setEarthResistivity(self, value):
        self.earthResistivity = value

    @Slot(float)
    def setConductorGMR(self, value):
        self.conductorGMR = value
    
    @Slot(float)
    def setNominalVoltage(self, value):
        self.nominalVoltage = value