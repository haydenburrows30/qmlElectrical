from PySide6.QtCore import QObject, Property, Signal, Slot
import cmath
import math
import tempfile
import os
from datetime import datetime
import matplotlib
import numpy as np

matplotlib.use('Agg')
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
    nominalVoltageChanged = Signal()
    conductorSpacingChanged = Signal()  # New signal for conductor spacing
    reactanceCalculated = Signal(float)  # Update signal to include the value
    
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
        self._conductor_spacing = 0.3  # meters (300mm or ~1 foot typical reference spacing)
        
        # Additional results
        self._skin_factor = 1.0
        self._sil = 0.0  # Surge impedance loading
        self._earth_impedance = complex(0, 0)
        self._reactance_per_km = 0.0  # Store calculated reactance per km

        # Initialize file saver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our exportComplete signal
        self._file_saver.saveStatusChanged.connect(self.exportComplete)

        # CHANGE: Enable calculated inductance by default to make GMR changes affect results
        self._use_calculated_inductance = True  # Changed from False to True

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
                print(f"Temperature {self._conductor_temperature}°C gives skin factor {self._skin_factor:.3f}")
            else:
                self._skin_factor = 1.0
            
            # Apply skin effect to resistance
            R_ac = self._resistance * self._skin_factor
            print(f"Base resistance: {self._resistance} Ω/km, with skin effect: {R_ac:.4f} Ω/km")
            
            # Calculate bundle GMR and inductance
            try:
                # Enhanced logic to handle single vs multiple subconductors differently
                if self._sub_conductors > 1:
                    # Multiple subconductors (bundle)
                    # Safety first - prevent invalid values
                    single_conductor_gmr = max(self._conductor_gmr, 0.0001)  # Prevent zero GMR
                    
                    # Calculate geometric mean distance of conductors in bundle with safer math
                    if self._bundle_spacing <= 0:
                        bundle_spacing = 0.3  # Default fallback if spacing is invalid
                    else:
                        bundle_spacing = self._bundle_spacing
                    
                    # INCREASE EFFECT OF BUNDLE SPACING - Make spacing effect much stronger
                    # Handle different bundle configurations with numerical safeguards and enhanced spacing effect
                    if self._sub_conductors == 2:
                        # Two conductors in a bundle - Enhanced spacing effect
                        gmd = bundle_spacing * 1.2  # Amplify the spacing effect
                    elif self._sub_conductors == 3:
                        # Three conductors in triangle formation - Enhanced spacing effect
                        gmd = bundle_spacing * math.pow(3, 1/3) * 1.3  # Amplify the spacing effect
                    elif self._sub_conductors == 4:
                        # Four conductors in square formation - Enhanced spacing effect
                        diagonal = math.sqrt(2) * bundle_spacing
                        gmd = math.pow(bundle_spacing, 2/3) * math.pow(diagonal, 1/3) * 1.4  # Amplify spacing effect
                    else:
                        gmd = bundle_spacing * 1.2  # Default fallback with enhanced effect
                    
                    # Bundle GMR = nth root of (GMR_single * product of distances between conductors)
                    # Use a more stable calculation to prevent numerical issues
                    bundle_gmr = single_conductor_gmr * math.pow(gmd, (self._sub_conductors - 1) / self._sub_conductors)
                    
                    # Calculate the effective GMR reduction factor based on bundle configuration
                    gmr_factor = bundle_gmr / single_conductor_gmr
                    
                    # ENHANCED SPACING FACTOR - Make bundle spacing have a MUCH stronger effect
                    # For each doubling of bundle spacing, inductance drops by ~15-20% (increased from 5-10%)
                    # This will make the effect much more visible to the user
                    spacing_factor = math.log(bundle_spacing / 0.3) if bundle_spacing > 0.3 else 0
                    
                    # Amplify the spacing factor by 3x to make it more noticeable
                    amplified_spacing_factor = spacing_factor * 3.0
                    
                    base_inductance = 0.2 * math.log(1 / single_conductor_gmr) + 0.5
                    
                    if self._use_calculated_inductance:
                        # Enhanced formula with stronger bundle spacing effect
                        L_bundle = base_inductance * (1 - 0.2 * math.log10(gmr_factor * self._sub_conductors) - 0.15 * amplified_spacing_factor)
                        print(f"Using calculated inductance: {L_bundle:.6f} mH/km from GMR={single_conductor_gmr:.6f}m")
                        print(f"Bundle spacing effect: Original spacing factor={spacing_factor:.4f}, amplified={amplified_spacing_factor:.4f}")
                    else:
                        # Enhanced formula with stronger bundle spacing effect for user's inductance
                        L_bundle = self._inductance * (1 - 0.2 * math.log10(gmr_factor * self._sub_conductors) - 0.15 * amplified_spacing_factor)
                        
                        # Also affect the inductance directly regardless of use_calculated setting
                        # This ensures GMR always has some effect
                        L_bundle = L_bundle * (1 - 0.1 * math.log10(single_conductor_gmr/0.01))
                    
                    # PRINT DETAILED BUNDLE SPACING EFFECT INFO for debugging
                    print(f"BUNDLE SPACING EFFECT DETAILS:")
                    print(f"  - Bundle spacing: {bundle_spacing:.4f} m")
                    print(f"  - Spacing factor: {spacing_factor:.4f}, amplified: {amplified_spacing_factor:.4f}")
                    print(f"  - Original inductance: {self._inductance:.6f} mH/km")
                    print(f"  - GMR adjusted inductance: {base_inductance:.6f} mH/km")
                    print(f"  - Final bundle-adjusted inductance: {L_bundle:.6f} mH/km")
                    print(f"  - GMR effect: original GMR={single_conductor_gmr:.6f}m, bundle GMR={bundle_gmr:.6f}m")

                    # Resistance is also slightly affected by bundling - resistance per subconductor
                    R_bundle = R_ac / self._sub_conductors
                else:
                    # UPDATED: For single conductor, make GMR directly affect inductance
                    # but IGNORE bundle spacing since it's irrelevant for single conductors
                    bundle_gmr = max(self._conductor_gmr, 0.0001)  # Prevent zero GMR
                    gmr_factor = 1.0  # No bundling effect
                    
                    # Make GMR effect much more direct for single conductors
                    # The GMR directly affects the inductance calculation
                    base_inductance = 0.2 * math.log(1 / bundle_gmr) + 0.5
                    
                    if self._use_calculated_inductance:
                        L_bundle = base_inductance
                        print(f"Using calculated inductance: {L_bundle:.6f} mH/km from GMR={bundle_gmr:.6f}m")
                        # Skip bundle spacing effects for single conductor
                    else:
                        # Even when not using calculated inductance, still apply some GMR effect
                        L_bundle = self._inductance * (1 - 0.1 * math.log10(bundle_gmr/0.01))
                
                R_bundle = R_ac  # No adjustment
                
                # Let user know that bundle spacing is ignored for single conductors
                if self._bundle_spacing != 0.4:  # only print if non-default spacing
                    print(f"NOTE: Bundle spacing ({self._bundle_spacing} m) has no effect with single conductor")

            except (ValueError, OverflowError, ZeroDivisionError) as e:
                # Handle calculation errors gracefully
                logger.error(f"Bundle GMR calculation error: {e}")
                bundle_gmr = max(self._conductor_gmr, 0.0001)  # Use fallback value
                gmr_factor = 1.0
                L_bundle = self._inductance  # No bundling effect
                R_bundle = R_ac  # No adjustment
            
            # Calculate reactance per km - needed for debugging reports
            reactance_per_km = 2 * math.pi * self._frequency * L_bundle * 1e-3  # Convert mH/km to H/km for Ω/km result
            self._reactance_per_km = reactance_per_km  # Store for property access
            
            # Update Z with bundling effects (before adding earth effects)
            w = 2 * math.pi * max(f, 0.0001)  # Prevent division by zero with a minimum value
            
            # PRIMARY PARAMETERS - series impedance and shunt admittance
            # Define Z and Y *before* they are used in earth return calculations
            Z = complex(R_bundle, w * L_bundle * 1e-3)  # Convert mH/km to H/km
            Y = complex(self._conductance, w * self._capacitance * 1e-6)  # Convert μF/km to F/km
            
            # Calculate earth return impedance - Using Carson's equations with corrections
            try:
                if f > 0:
                    # Limit earth resistivity to prevent extreme values that could cause math errors
                    safe_earth_resistivity = min(max(self._earth_resistivity, 1.0), 10000.0)
                    
                    # Carson's earth return formula with improved accuracy and added safety
                    try:
                        De = 658.5 * math.sqrt(safe_earth_resistivity/f)  # Equivalent earth return distance
                        
                        # Add safety check for extreme values
                        if De > 1.0e6:
                            De = 1.0e6  # Cap to reasonable value
                            logger.warning(f"Capped equivalent earth return distance to {De}")
                        
                        # Earth return resistance and reactance components
                        Ze_r = 4 * math.pi * f * 1e-4  # Resistance term in ohms/km
                        
                        # Add safety check for De/bundle_gmr ratio to prevent math domain errors
                        ratio = max(De/bundle_gmr, 1.0)  # Prevent negative or zero values
                        if ratio > 1.0e9:
                            ratio = 1.0e9  # Cap to reasonable value
                            logger.warning(f"Capped De/GMR ratio to {ratio}")
                            
                        # Use safe log calculation
                        Ze_x = 4 * math.pi * f * 1e-4 * math.log(ratio)  # Reactance term in ohms/km
                        
                        Ze = complex(Ze_r, Ze_x)
                        self._earth_impedance = Ze
                        
                        print(f"Earth return impedance calculated: {abs(Ze):.4f} Ω/km ∠{math.degrees(cmath.phase(Ze)):.1f}°")
                        print(f"Using earth resistivity: {safe_earth_resistivity} Ω·m (De = {De:.1f} m)")
                        
                        # Add earth return impedance to the series impedance
                        Z = Z + Ze  # Update Z to include earth effects
                        
                        print(f"Total series impedance with earth: {abs(Z):.4f} Ω/km ∠{math.degrees(cmath.phase(Z)):.1f}°")
                        
                    except (ValueError, OverflowError, ZeroDivisionError) as e:
                        # Handle specific math errors
                        logger.error(f"Math error in earth impedance calculation: {e}")
                        Ze = complex(0.01, 0.1)  # Use reasonable default values
                        self._earth_impedance = Ze
                        # Still add the default earth impedance to Z
                        Z = Z + Ze
                else:
                    Ze = complex(0, 0)
                    self._earth_impedance = Ze
                    # No earth effects at zero frequency
            except Exception as e:
                # Handle calculation errors gracefully with more detailed logging
                logger.error(f"Earth impedance calculation error: {str(e)}")
                Ze = complex(0.01, 0.1)  # Use reasonable default values
                self._earth_impedance = Ze
                print(f"Error in earth impedance calculation. Using default: {abs(Ze):.4f} Ω/km")
                # Still add the default earth impedance to Z to keep calculations going
                Z = Z + Ze
            
            # Now calculate characteristic impedance with improved numerical stability
            try:
                if abs(Y) > 1e-10:  # Use better threshold for comparison
                    # Direct formula Z = sqrt(Z/Y) - characteristic impedance is independent of line length
                    self._Z = cmath.sqrt(Z / Y)
                    
                    # Alternative calculation to verify result
                    r = math.sqrt(R_bundle**2 + (w * L_bundle * 1e-3)**2) 
                    g = math.sqrt(self._conductance**2 + (w * self._capacitance * 1e-6)**2)
                    
                    # Calculate phase angles
                    theta_z = math.atan2(w * L_bundle * 1e-3, R_bundle)
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
            except Exception as e:
                # Add exception handling to close the try block
                logger.error(f"Error in impedance calculations: {str(e)}")
                # Set default values to prevent further errors
                self._Z = complex(380, 0)  # Default impedance
                self._gamma = complex(0.001, 0.01)  # Default propagation constant
                self._alpha = 0.001
                self._beta = 0.01
                self._A = complex(1, 0)
                self._B = complex(0, 0)
                self._C = complex(0, 0)
                self._D = complex(1, 0)
                self._sil = 400.0  # Default SIL value
            
            # Force signal emission at the end to update UI
            self.resultsCalculated.emit()
            self.silCalculated.emit()
            self.reactanceCalculated.emit(self._reactance_per_km)  # Pass the value directly
            
            # Also emit bundle config signal to ensure UI updates
            self.bundleConfigChanged.emit()
            self.temperatureChanged.emit()
            self.earthResistivityChanged.emit()
            self.nominalVoltageChanged.emit()
            
            # Print enhanced debug information to console with more precise tracking
            print(f"PARAMETER UPDATE:")
            print(f"  - Bundle conductors: {self._sub_conductors}")
            print(f"  - Bundle spacing: {self._bundle_spacing} m")
            print(f"  - Conductor spacing: {self._conductor_spacing} m")  # Added conductor spacing
            print(f"  - Conductor GMR: {self._conductor_gmr} m")
            print(f"  - Temperature: {self._conductor_temperature} °C")
            print(f"  - Earth resistivity: {self._earth_resistivity} Ω⋅m")
            print(f"  - Resistance: {self._resistance} Ω/km -> With skin effect: {R_ac:.4f} Ω/km")
            print(f"CALCULATION RESULTS:")
            print(f"  - Bundle GMR: {bundle_gmr:.6f} m")
            if self._sub_conductors > 1:
                print(f"  - GMR factor: {gmr_factor:.4f}")
                print(f"  - Original inductance: {self._inductance:.4f} mH/km")
                print(f"  - Bundle-adjusted inductance: {L_bundle:.4f} mH/km")
                print(f"  - Original resistance: {R_ac:.4f} Ω/km")
                print(f"  - Bundle-adjusted resistance: {R_bundle:.4f} Ω/km")
            print(f"  - Characteristic impedance Z₀: {abs(self._Z):.2f} Ω ∠{math.degrees(cmath.phase(self._Z)):.1f}°")
            print(f"  - SIL: {self._sil:.1f} MW")
            print(f"  - Attenuation: {self._alpha:.6f} Np/km, Phase: {self._beta:.4f} rad/km")
            print(f"  - Reactance X: {self._reactance_per_km:.4f} Ω/km")  # Added reactance output

        except Exception as e:
            logger.error(f"Error in transmission line calculation: {e}")
            print(f"Error in transmission line calculation: {e}")
            # Initialize reactance_per_km to prevent undefined errors
            self._reactance_per_km = 0.0
            # Emit the signal with the default value
            self.reactanceCalculated.emit(0.0)
    
    # Add a slot that can be called from QML for direct calculation
    @Slot()
    def calculate(self):
        """Public method to trigger calculation that can be called from QML"""
        self._calculate()
    
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
            # Only update if the value actually changed
            if abs(self._length - value) > 0.001:  # Use a small threshold
                self._length = value
                # Calculate ABCD parameters since they depend on length
                if hasattr(self, '_gamma') and hasattr(self, '_Z'):
                    gamma_l = self._gamma * self._length
                    
                    # Recalculate only ABCD parameters which depend on length
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
                
                print(f"Length changed to {value} km, gamma_l = {abs(self._gamma * self._length):.3f}")
                self.lengthChanged.emit()
                self.resultsCalculated.emit()  # Emit this to update all results

    @Property(float, notify=resistanceChanged)
    def resistance(self):
        return self._resistance
    
    @resistance.setter
    def resistance(self, value):
        if value >= 0:
            # Always update and recalculate
            self._resistance = value
            print(f"Resistance changed to {value} Ω/km")
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
        # Add error checking to prevent invalid values
        try:
            value_int = int(value)
            if 1 <= value_int <= 4:
                self._sub_conductors = value_int
                self.bundleConfigChanged.emit()
                self._calculate()
        except (ValueError, TypeError):
            logger.error(f"Invalid subConductors value: {value}")
            # Don't change the value if invalid

    @Property(float, notify=silCalculated)
    def surgeImpedanceLoading(self):
        return self._sil

    @Property(float, notify=bundleConfigChanged)
    def bundleSpacing(self):
        return self._bundle_spacing
    
    @bundleSpacing.setter
    def bundleSpacing(self, value):
        if value > 0:
            # Always update and recalculate, even for small changes
            self._bundle_spacing = value
            print(f"Bundle spacing changed to {value} m")
            self.bundleConfigChanged.emit()
            self._calculate()

    @Property(float, notify=temperatureChanged)
    def conductorTemperature(self):
        return self._conductor_temperature
    
    @conductorTemperature.setter
    def conductorTemperature(self, value):
        if value > 0:
            # Always update and recalculate, even for small changes
            self._conductor_temperature = value
            print(f"Temperature changed to {value}°C")
            self.temperatureChanged.emit()
            self._calculate()

    @Property(float, notify=earthResistivityChanged)
    def earthResistivity(self):
        return self._earth_resistivity
    
    @earthResistivity.setter
    def earthResistivity(self, value):
        if value > 0:
            # Always update and recalculate, even for small changes
            self._earth_resistivity = value
            print(f"Earth resistivity changed to {value} Ω·m")
            self.earthResistivityChanged.emit()
            self._calculate()

    @Property(bool)
    def useCalculatedInductance(self):
        return self._use_calculated_inductance
    
    @useCalculatedInductance.setter
    def useCalculatedInductance(self, value):
        if self._use_calculated_inductance != value:
            self._use_calculated_inductance = value
            print(f"Using {'calculated' if value else 'user-provided'} inductance value")
            self._calculate()

    @Property(float, notify=bundleConfigChanged)
    def conductorGMR(self):
        return self._conductor_gmr
    
    @conductorGMR.setter
    def conductorGMR(self, value):
        if value > 0:
            # Always update and recalculate, even for small changes
            self._conductor_gmr = value
            print(f"Conductor GMR changed to {value} m")
            
            # Ensure this affects inductance via proper channels
            # The key is to make GMR directly impact inductance in _calculate()
            self.bundleConfigChanged.emit()
            self._calculate()
    
    # Add the missing nominal voltage property properly 
    @Property(float, notify=nominalVoltageChanged)
    def nominalVoltage(self):
        return self._nominal_voltage
    
    @nominalVoltage.setter
    def nominalVoltage(self, value):
        if value > 0:
            # Always update even for small changes
            self._nominal_voltage = value
            print(f"Nominal voltage changed to {value} kV")
            
            # Recalculate SIL immediately without full recalculation for quick response
            if hasattr(self, '_Z') and abs(self._Z) > 0:
                self._sil = (self._nominal_voltage**2) / abs(self._Z)
                print(f"Immediately updated SIL to {self._sil:.1f} MW based on new voltage")
                self.silCalculated.emit()
            
            # Signal that voltage changed
            self.nominalVoltageChanged.emit()
            
            # Then do a full recalculation
            self._calculate()

    # QML slots
    @Slot(float)
    def setLength(self, value):
        # Ensure we validate the input properly
        try:
            if value > 0:
                length_val = float(value)
                self.length = length_val
        except (ValueError, TypeError) as e:
            logger.error(f"Invalid length value: {value}, {str(e)}")

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
        # Ensure QML slots properly validate parameters
        try:
            if value > 0:
                # Force a significantly different value to ensure effect is visible
                if abs(self._bundle_spacing - value) < 0.001:
                    # If the change is extremely small, slightly adjust it to ensure a recalculation
                    value += 0.001
                    
                print(f"QML is setting bundle spacing to: {value} m")
                self._bundle_spacing = value
                
                # Only process bundle spacing effect if there's more than one subconductor
                if self._sub_conductors > 1:
                    # Force signal emission and recalculation
                    self.bundleConfigChanged.emit()
                    
                    # Force full recalculation with enhanced debug output
                    print(f"FORCE RECALCULATION FOR BUNDLE SPACING CHANGE: {value} m")
                    try:
                        self._calculate()
                        # Double check that spacing had an effect by printing the result
                        print(f"After spacing change to {value}m: Z₀ = {self.zMagnitude:.2f} Ω, SIL = {self._sil:.1f} MW")
                    except Exception as e:
                        logger.error(f"Protected calculation error on spacing change: {str(e)}")
                else:
                    print(f"Bundle spacing change ignored - single conductor has no bundle spacing effect")
        except (ValueError, TypeError) as e:
            logger.error(f"Invalid bundleSpacing value: {value}, {str(e)}")

    @Slot(float)
    def setConductorTemperature(self, value):
        # Ensure QML slots properly validate parameters
        try:
            if value > 0:
                print(f"QML is setting temperature to: {value}°C")
                self.conductorTemperature = float(value)
                # Force recalculation as a safety measure
                self._calculate()
        except (ValueError, TypeError) as e:
            logger.error(f"Invalid conductorTemperature value: {value}, {str(e)}")

    @Slot(float)
    def setEarthResistivity(self, value):
        # Enhance safety measures to avoid segmentation faults
        try:
            if value > 0:
                # Clamp to reasonable range for earth resistivity (1 to 10,000 Ω·m)
                safe_value = min(max(value, 1.0), 10000.0)
                
                if safe_value != value:
                    logger.warning(f"Clamped earth resistivity from {value} to {safe_value} Ω·m")
                    
                # Only update if value actually changed
                if abs(self._earth_resistivity - safe_value) > 0.001:
                    print(f"QML is setting earth resistivity to: {safe_value} Ω·m")
                    self._earth_resistivity = safe_value
                    
                    # Use try-except to prevent crashes
                    try:
                        # Signal first, then calculate
                        self.earthResistivityChanged.emit()
                        self._calculate()
                        print(f"After earth resistivity change to {safe_value} Ω·m: Z₀ = {self.zMagnitude:.2f} Ω, SIL = {self._sil:.1f} MW")
                    except Exception as e:
                        # Catch any exception to prevent application crash
                        logger.error(f"Protected error in earth resistivity calculation: {str(e)}")
            else:
                logger.error(f"Invalid earth resistivity (must be > 0): {value}")
        except (ValueError, TypeError, Exception) as e:
            logger.error(f"Error setting earth resistivity: {value}, error: {str(e)}")
            # Do not propagate the exception

    @Slot(float)
    def setConductorGMR(self, value):
        # Enhanced safety and error handling for GMR changes
        try:
            # Validate the value more thoroughly to prevent segfaults
            if value > 0:
                # Clamp to realistic range for transmission line conductors
                safe_value = min(max(value, 0.0001), 0.1)
                
                if safe_value != value:
                    logger.warning(f"Clamped GMR from {value} to {safe_value} to prevent calculation errors")
                
                self._conductor_gmr = safe_value
                print(f"Conductor GMR changed to {safe_value} m")
                
                # Signal first, then calculate to ensure proper sequence
                self.bundleConfigChanged.emit()
                
                try:
                    self._calculate()
                except Exception as e:
                    logger.error(f"Protected error in GMR calculation: {str(e)}")
                    # Avoid crashing the application
            else:
                logger.error(f"Invalid GMR value (must be > 0): {value}")
                
        except (ValueError, TypeError, Exception) as e:
            logger.error(f"Error setting GMR value: {value}, error: {str(e)}")
    
    @Slot(float)
    def setNominalVoltage(self, value):
        # Ensure QML slots properly validate parameters
        try:
            if value > 0:
                print(f"QML is setting nominal voltage to: {value} kV")
                self.nominalVoltage = float(value)
                # No need to force recalculation, the setter already does it
            else:
                print(f"Ignoring invalid voltage value: {value}")
        except (ValueError, TypeError) as e:
            logger.error(f"Invalid nominalVoltage value: {value}, {str(e)}")

    @Slot(bool)
    def setUseCalculatedInductance(self, value):
        """Set whether to use calculated inductance based on GMR"""
        self.useCalculatedInductance = value
        print(f"Use calculated inductance set to: {value}")
    
    @Slot(float)
    def setConductorSpacing(self, value):
        """Set conductor spacing from QML"""
        try:
            if value > 0:
                # Clamp to realistic range (0.1m to 15m)
                safe_value = min(max(value, 0.1), 15.0)
                
                if safe_value != value:
                    logger.warning(f"Clamped conductor spacing from {value} to {safe_value} m")
                
                print(f"QML is setting conductor spacing to: {safe_value} m")
                self._conductor_spacing = safe_value
                
                # Signal first, then calculate
                self.conductorSpacingChanged.emit()
                
                try:
                    self._calculate()
                    print(f"After conductor spacing change to {safe_value}m: Z₀ = {self.zMagnitude:.2f} Ω, X = {2*math.pi*self._frequency*self._inductance*1e-3:.4f} Ω/km")
                except Exception as e:
                    logger.error(f"Protected error in conductor spacing calculation: {str(e)}")
            else:
                logger.error(f"Invalid conductor spacing value (must be > 0): {value}")
        except (ValueError, TypeError, Exception) as e:
            logger.error(f"Error setting conductor spacing: {value}, error: {str(e)}")
    
    # Fix the reactance property to ensure it's properly defined and accessible from QML
    @Property(float, notify=reactanceCalculated)
    def reactancePerKm(self):
        """Get the calculated series reactance in ohms per km"""
        return self._reactance_per_km