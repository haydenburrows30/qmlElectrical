from PySide6.QtCore import QObject, Property, Signal, Slot
import math
import cmath
from datetime import datetime

from utils.pdf.pdf_generator_grid_wind import PDFGenerator
from services.logger_config import configure_logger
from services.file_saver import FileSaver


logger = configure_logger("qmltest", component="transformer_line")

class TransformerLineCalculator(QObject):
    """Calculator for transformer-line system analysis including protection parameters"""

    # Define signals
    transformerChanged = Signal()
    lineChanged = Signal()
    loadChanged = Signal()
    voltageRegulatorChanged = Signal()
    calculationCompleted = Signal()  # Main signal
    calculationsComplete = Signal()  # Additional alias signal for QML compatibility
    pdfExportStatusChanged = Signal(bool, str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Transformer parameters (400V/11kV)
        self._transformer_lv_voltage = 400.0  # V
        self._transformer_hv_voltage = 11000.0  # V
        self._transformer_rating = 300.0  # kVA
        self._transformer_impedance = 4.5  # %
        self._transformer_x_r_ratio = 8.0  # X/R ratio
        self._transformer_flc_hv = 29.2 # HV FLC
        self._transformer_flc_lv = 417.0 # HV FLC

        # Line parameters (5km cable)
        self._line_length = 5.0  # km
        self._line_r = 1.42  # Ohm/km
        self._line_x = 0.13  # Ohm/km
        self._line_c = 0.3  # μF/km
        
        # Load parameters
        self._load_mva = 0.5  # MVA - This is for protection settings
        self._display_load_mva = 0.5  # MVA - This is for display purposes only
        self._load_pf = 0.85  # Power factor
        
        # Voltage regulator parameters
        self._voltage_regulator_enabled = True
        self._voltage_regulator_type = "Eaton Single-Phase"
        self._voltage_regulator_model = "Cooper VR-32"
        self._voltage_regulator_connection = "Delta"
        self._voltage_regulator_capacity = 185.0  # kVA (per phase)
        self._voltage_regulator_bandwidth = 2.0  # Percent
        self._voltage_regulator_range = 10.0  # Percent
        self._voltage_regulator_steps = 32  # Number of steps
        self._voltage_regulator_target = 11.0  # kV
        
        # Additional protection parameters
        self._neutral_grounding_resistance = 5.0  # Ohms
        self._ground_fault_current = 0.0  # A
        self._differential_relay_slope = 25  # %
        self._differential_relay_pickup = 0.2  # Per unit
        self._reverse_power_threshold = -0.1  # % of rating
        self._frequency_relay_settings = {
            "under_freq": 47.5,  # Hz
            "over_freq": 51.5,   # Hz
            "df_dt": 0.5         # /s
        }
        self._voltage_relay_settings = {
            "under_voltage": 0.8,  # per unit
            "over_voltage": 1.2,   # per unit
            "time_delay": 2.0      # seconds
        }
        
        # Harmonic analysis parameters
        self._harmonic_limits = {
            2: 2.0,   # 2nd harmonic: 2%
            3: 5.0,   # 3rd harmonic: 5%
            5: 6.0,   # 5th harmonic: 6%
            7: 5.0,   # 7th harmonic: 5%
            11: 3.5,  # 11th harmonic: 3.5%
            13: 3.0   # 13th harmonic: 3%
        }
        self._thd_limit = 8.0  # Total Harmonic Distortion limit
        
        # Calculated values
        self._transformer_z = 0.0  # Ohm
        self._transformer_r = 0.0  # Ohm
        self._transformer_x = 0.0  # Ohm
        self._line_total_z = 0.0  # Ohm
        self._voltage_drop = 0.0  # %
        self._fault_current_lv = 0.0  # kA
        self._fault_current_hv = 0.0  # kA
        self._fault_current_slg = 0.000  # kA
        self._relay_pickup_current = 0.0  # A
        self._relay_time_dial = 0.0
        self._relay_curve_type = "Very Inverse"
        self._relay_ct_ratio = "300/5"
        self._regulated_voltage = 0.0  # kV
        self._regulator_tap_position = 0  # Current tap position
        self._regulator_three_phase_capacity = 0.0  # kVA
        self._unregulated_voltage = 0.0  # kV
        self._recommended_hv_cable = ""
        self._recommended_lv_cable = ""
        self._differential_settings = {}
        
        # IEC/IEEE standard time-overcurrent curves
        self._iec_curves = {
            "Standard Inverse": {"a": 0.14, "b": 0.02},
            "Very Inverse": {"a": 13.5, "b": 1.0},
            "Extremely Inverse": {"a": 80.0, "b": 2.0},
            "Long-Time Inverse": {"a": 120.0, "b": 1.0}
        }

        # Additional calculated values for expert popup
        self._z0_transformer = 0.0  # Ohm
        self._z0_line = 0.0  # Ohm
        self._z_ng_referred = 0.0  # Ohm
        self._x_r_ratio_at_fault = 0.0
        self._asymmetry_factor = 1.0
        self._short_circuit_mva = 0.0  # MVA
        self._instantaneous_pickup = 0.0  # A
        self._trip_time_max_fault = 0.0  # s
        self._breaker_duty_factor = 1.0
        self._curve_a_constant = 13.5
        self._curve_b_exponent = 1.0
        self._minimum_fault_current = 0.0  # A
        self._remote_backup_trip_time = 0.7  # s
        
        # Initialize the file saver
        self._file_saver = FileSaver()

         # Connect file saver signal to our exportComplete signal
        self._file_saver.saveStatusChanged.connect(self.pdfExportStatusChanged)
        
        # Perform initial calculations
        self._calculate()

    @Slot()
    def exportTransformerReport(self):
        """Export transformer calculations to PDF"""
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

            # If no filepath provided, use FileSaver to get one
            pdf_file = self._file_saver.get_save_filepath("pdf", f"transformer_line_results_{timestamp}")
            if not pdf_file:
                self.pdfExportStatusChanged.emit(False, "PDF export canceled")
                return False

            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")

            export_data = {
                # Transformer parameters
                "transformer_rating": self._transformer_rating,
                "transformer_hv_voltage": self._transformer_hv_voltage,
                "transformer_lv_voltage": self._transformer_lv_voltage,
                "transformer_flc_hv": self._transformer_flc_hv,
                "transformer_flc_lv": self._transformer_flc_lv,
                "transformer_impedance": self._transformer_impedance,
                "transformer_xr_ratio": self._transformer_x_r_ratio,
                "transformer_z": self._transformer_z,
                "transformer_r": self._transformer_r,
                "transformer_x": self._transformer_x,
                
                # Line parameters
                "line_length": self._line_length,
                "line_r": self._line_r,
                "line_x": self._line_x,
                "line_total_z": abs(self._line_total_z),
                "voltage_drop": self._voltage_drop,
                "unregulated_voltage": self._unregulated_voltage,
                "regulated_voltage": self._regulated_voltage,
                "recommended_hv_cable": self._recommended_hv_cable,
                "recommended_lv_cable": self._recommended_lv_cable,
                
                # Regulator parameters
                "regulator_enabled": self._voltage_regulator_enabled,
                "regulator_type": self._voltage_regulator_type,
                "regulator_connection": self._voltage_regulator_connection,
                "tap_position": self._regulator_tap_position,
                "regulator_target": self._voltage_regulator_target,
                "regulator_bandwidth": self._voltage_regulator_bandwidth,
                "regulator_range": self._voltage_regulator_range,
                "regulator_three_phase_capacity": self._regulator_three_phase_capacity,
                
                # Fault analysis
                "fault_current_lv": self._fault_current_lv,
                "fault_current_hv": self._fault_current_hv,
                "fault_current_slg": self._fault_current_slg,
                "ground_fault_current": self._ground_fault_current,
                
                # Protection settings
                "ct_ratio": self._relay_ct_ratio,
                "relay_pickup_current": self._relay_pickup_current,
                "relay_curve_type": self._relay_curve_type,
                "time_dial": self._relay_time_dial,
                "differential_slope": self._differential_relay_slope,
                "reverse_power": self._reverse_power_threshold,
                "frequency_settings": self._frequency_relay_settings,
                "voltage_settings": self._voltage_relay_settings,
                
                # Harmonic analysis
                "harmonic_limits": self._harmonic_limits,
                "thd_limit": self._thd_limit,
                "differential_settings": self._differential_settings
            }

            generator = PDFGenerator()

            result = generator.generate_transformer_report(export_data, pdf_file)

            if result:
                self._file_saver._emit_success_with_path(pdf_file, "PDF saved")
                return True
            else:
                self._file_saver._emit_failure_with_path(pdf_file, "Error saving PDF")
                return False

        except Exception as e:
            error_msg = (f"Error exporting transformer report: {e}")
            logger.error(error_msg)
            self.pdfExportStatusChanged.emit(False, error_msg)
            return False

    @Slot("QVariant")
    def exportProtectionReport(self, data):
        """Export protection requirements to PDF"""
        try:
            # Convert QJSValue to Python dict if needed
            if hasattr(data, 'toVariant'):
                js_data = data.toVariant()
            else:
                js_data = data

            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

            # If no filepath provided, use FileSaver to get one
            pdf_file = self._file_saver.get_save_filepath("pdf", f"wind_protection_results_{timestamp}")
            if not pdf_file:
                self.pdfExportStatusChanged.emit(False, "PDF export canceled")
                return False
            
            # Clean up filepath using FileSaver's helper methods
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")

            generator = PDFGenerator()

            result = generator.generate_protection_report(js_data, pdf_file)

            if result:
                self._file_saver._emit_success_with_path(pdf_file, "PDF saved")
                return True
            else:
                self._file_saver._emit_failure_with_path(pdf_file, "Error saving PDF")
                return False
            
        except Exception as e:
            logger.error(f"Error exporting protection report: {e}")
            import traceback
            logger.error(traceback.format_exc())

            error_msg = f"Error saving PDF: {str(e)}"
            self.pdfExportStatusChanged.emit(False, error_msg)
            return False

    def _calculate_cable_sizes(self):
        """Calculate recommended cable sizes based on currents"""
        # Calculate HV current
        current_hv = (self._load_mva * 1e6) / (math.sqrt(3) * self._transformer_hv_voltage)
        
        # Calculate LV current
        current_lv = (self._load_mva * 1e6) / (math.sqrt(3) * self._transformer_lv_voltage)
        
        # Determine HV cable size
        if current_hv < 30:
            self._recommended_hv_cable = "25 mm²"
        elif current_hv < 50:
            self._recommended_hv_cable = "35 mm²"
        elif current_hv < 70:
            self._recommended_hv_cable = "50 mm²"
        elif current_hv < 90:
            self._recommended_hv_cable = "70 mm²"
        elif current_hv < 120:
            self._recommended_hv_cable = "95 mm²"
        else:
            self._recommended_hv_cable = "120 mm² or larger"
            
        # Determine LV cable size
        if current_lv < 100:
            self._recommended_lv_cable = "25 mm²"
        elif current_lv < 150:
            self._recommended_lv_cable = "50 mm²"
        elif current_lv < 200:
            self._recommended_lv_cable = "70 mm²"
        elif current_lv < 250:
            self._recommended_lv_cable = "95 mm²"
        elif current_lv < 300:
            self._recommended_lv_cable = "120 mm²"
        else:
            self._recommended_lv_cable = "150 mm² or larger"

    def _calculate_trip_time(self, current_multiple):
        """Calculate relay trip time based on curve type"""
        try:
            if current_multiple <= 1.0:
                return float('inf')  # Won't trip below pickup
                
            curve = self._iec_curves.get(self._relay_curve_type)
            if not curve:
                return 0.0
            
            # IEC standard formula implementation
            numerator = curve["a"] * self._relay_time_dial
            denominator = (current_multiple**curve["b"]) - 1
            
            # Add minimum operating time check
            trip_time = numerator / denominator if denominator > 0 else float('inf')
            return max(trip_time, 0.025)  # Minimum 25ms operating time
            
        except Exception as e:
            logger.error(f"Error calculating trip time: {e}")
            return 0.0

    @Slot(float, result=float)
    def calculateTripTime(self, current_multiple):
        """Public method to calculate relay trip time"""
        return self._calculate_trip_time(current_multiple)

    @Slot(str, result=dict)
    def getCurveParams(self, curve_type):
        """Get IEC curve parameters for given curve type"""
        return self._iec_curves.get(curve_type, {"a": 0.14, "b": 0.02})

    @Slot(str, float)
    def setRelayCurveType(self, curve_type):
        """Update relay curve type"""
        if curve_type in self._iec_curves:
            self._relay_curve_type = curve_type
            self.calculationCompleted.emit()

    @Slot(float)
    def setRelayTimeDial(self, value):
        """Update relay time dial setting"""
        if 0.1 <= value <= 1.0:
            self._relay_time_dial = value
            self.calculationCompleted.emit()

    def _calculate_differential_protection(self):
        """Calculate differential protection settings"""
        try:
            # Calculate currents on both sides
            i_hv = (self._transformer_rating * 1000) / (math.sqrt(3) * self._transformer_hv_voltage)
            i_lv = (self._transformer_rating * 1000) / (math.sqrt(3) * self._transformer_lv_voltage)
            
            # Calculate CT ratios for both sides
            ct_primary_hv = next((x for x in [50, 75, 100, 150, 200, 300, 400, 500] if x > i_hv), 500)
            ct_primary_lv = next((x for x in [100, 200, 300, 400, 600, 800, 1000] if x > i_lv), 1000)
            
            # Calculate differential settings
            pickup = 0.2 * i_hv  # 20% of HV full load current
            slope1 = 0.25  # 25% slope for first region
            slope2 = 0.50  # 50% slope for second region
            
            return {
                "hv_ct_ratio": f"{ct_primary_hv}/1",
                "lv_ct_ratio": f"{ct_primary_lv}/1",
                "pickup_current": pickup,
                "slope1": slope1,
                "slope2": slope2,
                "breakpoint": 2.0  # Current where slope changes
            }
        except Exception as e:
            logger.error(f"Error calculating differential protection: {e}")
            return None
    @Slot()
    def debug_calculations(self):
        try:
            logger.info("\nTransformer Impedance:")
            logger.info(f"Total Z: {self._transformer_z:.2f} ohm")
            logger.info(f"R: {self._transformer_r:.2f} ohm")
            logger.info(f"X: {self._transformer_x:.2f} ohm")

            logger.info("\nLine Parameters:")
            logger.info(f"R per km: {self._line_r:.3f} ohm")
            logger.info(f"X per km: {self._line_x:.3f} ohm")
            logger.info(f"Length: {self._line_length:.2f} km")
            logger.info(f"Total Z: {abs(self._line_total_z):.2f} ohm at angle {math.degrees(cmath.phase(self._line_total_z)):.1f} deg")

            logger.info("\nGround Fault Calculation:")
            logger.info(f"Z0 Transformer: {abs(self._z0_transformer):.2f} ohms")
            logger.info(f"Z0 Line: {abs(self._z0_line):.2f} ohms")
            if 'z_ng' in locals(): logger.info(f"NGR (referred to HV): {abs(self._z_ng_referred):.2f} ohms")
            logger.info(f"Ground Fault Current: {self._ground_fault_current:.3f} kA")

            logger.info(f"\nLV Fault Current Calculation:")
            logger.info(f"LV Fault Current: {self._fault_current_lv:.2f} kA")
            
            logger.info("\nFault Current Calculations:")
            logger.info(f"Three-phase fault: {self._fault_current_hv:.2f} kA")
            logger.info(f"SLG fault: {self._fault_current_slg:.2f} kA")
            logger.info(f"Ground fault: {self._ground_fault_current:.2f} kA")

            logger.info("\nVoltage Drop Calculation:")
            logger.info(f"Voltage Drop: {self._voltage_drop:.2f}%")
            logger.info(f"Unregulated Voltage: {self._unregulated_voltage:.2f} kV")

            diff_settings = self._differential_settings

            logger.info("\nDifferential Protection Settings:")
            logger.info(f"HV CT Ratio: {diff_settings['hv_ct_ratio']}")
            logger.info(f"LV CT Ratio: {diff_settings['lv_ct_ratio']}")
            logger.info(f"Pickup Current: {diff_settings['pickup_current']:.2f} A")
            logger.info(f"Slope 1: {diff_settings['slope1']*100:.0f}%")
            logger.info(f"Slope 2: {diff_settings['slope2']*100:.0f}%")

            logger.info("\nVoltage Regulator:")
            logger.info(f"Target Voltage: {self._voltage_regulator_target:.2f} kV")
            logger.info(f"Tap Position: {self._regulator_tap_position}")
            logger.info(f"Regulated Voltage: {self._regulated_voltage:.2f} kV")
            logger.info(f"Single Phase Capacity: {self._voltage_regulator_capacity:.1f} kVA")
            logger.info(f"Three Phase Capacity: {self._regulator_three_phase_capacity:.1f} kVA")

            logger.info(f"\nProtection Settings:")
            logger.info(f"Transformer FLC: {self._transformer_flc_hv:.2f} A")
            logger.info(f"Relay Pickup: {self._relay_pickup_current:.2f} A")
            logger.info(f"Selected CT Ratio: {self._relay_ct_ratio}")

            logger.info("\nHarmonic Current Limits:")

            # Calculate harmonic limits
            harmonic_limits = self._calculate_harmonic_limits(self._transformer_flc_hv)

            for harmonic, limit in harmonic_limits.items():
                logger.info(f"{harmonic}th harmonic: {limit:.2f} A")

        except Exception as e:
            logger.error(f"Error logging values: {str(e)}")

    def _calculate_harmonic_limits(self, current):
        """Calculate harmonic current limits"""
        try:
            limits = {}
            for harmonic, percent in self._harmonic_limits.items():
                limits[harmonic] = (percent / 100.0) * current
            return limits
        except Exception as e:
            logger.error(f"Error calculating harmonic limits: {e}")
            return {}

    def _calculate(self):
        """Calculate transformer-line-load parameters"""
        try:
            # 1. Calculate base values
            base_mva = self._transformer_rating / 1000  # Convert kVA to MVA
            base_v_hv = self._transformer_hv_voltage / 1000  # Convert V to kV
            base_z_hv = (self._transformer_hv_voltage**2) / (self._transformer_rating * 1000)  # Ohms
            
            # 2. Calculate transformer impedance
            z_pu = self._transformer_impedance / 100.0  # Convert % to per unit
            self._transformer_z = z_pu * base_z_hv
            
            # Calculate R and X components using X/R ratio
            angle = math.atan(self._transformer_x_r_ratio)
            self._transformer_r = self._transformer_z * math.cos(angle)
            self._transformer_x = self._transformer_z * math.sin(angle)

            # Calculate line impedance
            self._line_total_z = complex(self._line_r * self._line_length, 
                                         self._line_x * self._line_length)

            # Fault current calculations using sequence components
            # Calculate transformer impedance
            z1_transformer = complex(self._transformer_r, self._transformer_x)  # Positive sequence
            z2_transformer = z1_transformer  # Negative sequence equals positive
            # Zero sequence typically 0.85-1.0 times Z1 for transformers - depends on winding type
            z0_transformer = 0.85 * z1_transformer  
            
            # Calculate line impedance sequences
            z1_line = self._line_total_z  # Positive sequence
            z2_line = z1_line  # Negative sequence equals positive
            # Zero sequence typically 2.0-3.5 times Z1 for overhead lines
            z0_line = 3.0 * z1_line
            
            # Total sequence impedances
            z1_total = z1_transformer + z1_line
            z2_total = z2_transformer + z2_line
            z0_total = z0_transformer + z0_line
            
            # Three-phase fault current (uses only positive sequence)
            # Calculation using line-to-line voltage
            self._fault_current_hv = (self._transformer_hv_voltage / (math.sqrt(3) * abs(z1_total))) / 1000  # kA
            
            # Single-line-to-ground fault current (uses all sequences)
            # For SLG fault, we need line-to-neutral voltage
            v_ln = self._transformer_hv_voltage / math.sqrt(3)  # Line-to-neutral voltage
            self._fault_current_slg = (3 * v_ln / abs(z1_total + z2_total + z0_total)) / 1000  # kA
            
            # Ground fault current calculation
            # First check transformer configuration (assume delta-wye with grounded neutral)
            is_delta_primary = True  # HV side is typically delta in distribution transformers
            
            if is_delta_primary:
                # For delta primary winding, ground fault on delta side is limited by:
                # 1. Zero sequence impedance path through the transformer (winding to winding)
                # 2. System grounding on the wye side reflected to delta side
                
                # Calculate zero sequence impedance
                z0_transformer = 1.0 * z1_transformer  # For delta primary, Z0 typically equals Z1
                
                # For a delta primary, the zero sequence current path is through the delta,
                # so ground fault current on delta side will be very small or zero
                # This is because there's no direct ground path on the delta side
                if self._neutral_grounding_resistance > 0:
                    # Convert NGR on LV side to HV equivalent
                    z_ng = complex(self._neutral_grounding_resistance, 0) * (self._transformer_hv_voltage / self._transformer_lv_voltage) ** 2
                    
                    # Calculate ground fault current through transformer (from LV to HV)
                    # This is typically very small due to delta configuration blocking zero sequence
                    v_ln = self._transformer_hv_voltage / math.sqrt(3)
                    total_z0_path = z0_transformer + 3 * z_ng + z0_line
                    self._ground_fault_current = (v_ln / abs(total_z0_path)) / 1000  # kA
                else:
                    # With no NGR, ground fault on delta side has no return path
                    self._ground_fault_current = 0.001  # Negligible current (1A)
            else:
                # For wye-connected HV side with neutral grounding
                # Calculate ground fault current using standard method
                v_ln = self._transformer_hv_voltage / math.sqrt(3)
                z_ng = complex(self._neutral_grounding_resistance, 0)
                total_z0_path = z0_total + 3 * z_ng
                self._ground_fault_current = (3 * v_ln / abs(total_z0_path)) / 1000  # kA
            
            # Store sequence impedances for reference
            self._z0_transformer = abs(z0_transformer)
            self._z0_line = abs(z0_line)
            self._z_ng_referred = abs(z_ng) if 'z_ng' in locals() else 0.0
            
            # Calculate LV fault current using transformer impedance referred to LV side
            z_base_lv = (self._transformer_lv_voltage**2) / (self._transformer_rating * 1000)
            z_t_lv = z_pu * z_base_lv
            
            # LV fault current calculation
            # Use line-to-line voltage
            self._fault_current_lv = (self._transformer_lv_voltage / (math.sqrt(3) * abs(z_t_lv))) / 1000  # Convert to kA

            # Calculate voltage drop using complex power factor
            # Get load current with power factor
            load_current = (self._load_mva * 1e6) / (math.sqrt(3) * self._transformer_hv_voltage)
            load_angle = math.acos(self._load_pf)
            load_current_complex = load_current * complex(math.cos(load_angle), -math.sin(load_angle))
            
            # Calculate sending end voltage (phase)
            sending_voltage = self._transformer_hv_voltage / math.sqrt(3)
            sending_voltage_complex = complex(sending_voltage, 0)
            
            # Calculate total system impedance
            total_impedance = complex(self._transformer_r, self._transformer_x) + self._line_total_z
            
            # Calculate voltage drop using complex arithmetic
            voltage_drop_complex = load_current_complex * total_impedance
            receiving_voltage_complex = sending_voltage_complex - voltage_drop_complex
            
            # Calculate voltage drop percentage more accurately
            self._voltage_drop = (1 - abs(receiving_voltage_complex) / abs(sending_voltage_complex)) * 100.0
            self._unregulated_voltage = (abs(receiving_voltage_complex) * math.sqrt(3)) / 1000.0  # Convert to kV L-L
            
            # Calculate regulator tap position and regulated voltage
            if self._voltage_regulator_enabled:
                target_voltage = self._voltage_regulator_target
                # Corrected calculation with proper number of steps
                step_size = (2 * self._voltage_regulator_range) / self._voltage_regulator_steps
                voltage_difference = target_voltage - self._unregulated_voltage
                
                # Calculate required boost/buck percentage
                required_percent = (voltage_difference / self._unregulated_voltage) * 100.0
                
                # Limit to regulator range
                limited_percent = max(min(required_percent, self._voltage_regulator_range), 
                                   -self._voltage_regulator_range)
                
                # Calculate tap position
                self._regulator_tap_position = round(limited_percent / step_size)
                actual_percent = self._regulator_tap_position * step_size
                
                # Calculate final regulated voltage
                self._regulated_voltage = self._unregulated_voltage * (1 + actual_percent / 100.0)

            else:
                self._regulated_voltage = self._unregulated_voltage
                self._regulator_tap_position = 0
            
            # Calculate protection settings
            self._transformer_flc_hv = (self._transformer_rating * 1000) / (math.sqrt(3) * self._transformer_hv_voltage)
            self._transformer_flc_lv = (self._transformer_rating * 1000) / (math.sqrt(3) * self._transformer_lv_voltage )
            self._relay_pickup_current = self._transformer_flc_hv * 1.25  # 125% of FLC
            self._relay_time_dial = 0.3  # Default time dial setting

            # CT ratio selection
            standard_ct_ratios = [50, 75, 100, 150, 200, 300, 400, 500, 600, 800, 1000, 1200]
            ct_primary = next((x for x in standard_ct_ratios if x > self._transformer_flc_hv * 1.25), 1200)
            self._relay_ct_ratio = f"{ct_primary}/1"

            # Calculate voltage regulator values
            if self._voltage_regulator_enabled:
                # For delta configuration, calculate the effective three-phase power capacity
                self._regulator_three_phase_capacity = self._voltage_regulator_capacity * 3.0

            else:
                self._regulator_three_phase_capacity = 0.0
            
            # Calculate differential protection settings
            diff_settings = self._calculate_differential_protection()
            if diff_settings:
                self._differential_settings = diff_settings

            # Calculate cable sizes based on actual currents
            self._calculate_cable_sizes()

            # Calculate advanced parameters
            self._calculate_additional_parameters()
            
            # Ensure signal emission after all calculations
            self.calculationCompleted.emit()
            self.calculationsComplete.emit()
            
        except Exception as e:
            logger.error(f"Error in transformer-line calculations: {e}")
            logger.exception(e)
    
    def _recalculate_load_values(self):
        """Update load-dependent values when transformer or load parameters change"""
        try:
            # Calculate full load current at HV side
            self._full_load_current = (self._transformer_rating * 1000) / (math.sqrt(3) * self._transformer_hv_voltage)
            
            # Update relay pickup current based on full load current (typically 125%)
            self._relay_pickup_current = self._full_load_current * 1.25
            
            # Update CT ratio selection based on pickup current
            standard_ct_ratios = [50, 75, 100, 150, 200, 300, 400, 500, 600, 800, 1000, 1200, 1500, 2000]
            ct_primary = next((x for x in standard_ct_ratios if x > self._relay_pickup_current), 2000)
            self._relay_ct_ratio = f"{ct_primary}/1"  # Using 1A secondary

        except Exception as e:
            logger.error(f"Error in recalculate_load_values: {str(e)}")
    
    def _calculate_additional_parameters(self):
        """Calculate additional parameters for expert protection popup"""
        try:
            # Zero sequence impedances
            self._z0_transformer = 0.85 * self._transformer_z
            self._z0_line = 3.0 * abs(self._line_total_z)
            
            # Calculate neutral impedance referred to HV
            self._z_ng_referred = self._neutral_grounding_resistance * (self._transformer_hv_voltage / self._transformer_lv_voltage) ** 2
            
            # Calculate X/R ratio at fault point
            r_total = self._transformer_r + (self._line_r * self._line_length)
            x_total = self._transformer_x + (self._line_x * self._line_length)
            self._x_r_ratio_at_fault = x_total / max(r_total, 0.001)  # Prevent division by zero
            
            # Calculate asymmetry factor for fault current
            self._asymmetry_factor = math.sqrt(1 + 2 * math.exp(-2 * math.pi * r_total / max(x_total, 0.001)))
            
            # Calculate short circuit MVA at fault point
            v_kv = self._transformer_hv_voltage / 1000
            self._short_circuit_mva = math.sqrt(3) * v_kv * self._fault_current_hv
            
            # Calculate instantaneous pickup current (typically 8x FLC)
            self._instantaneous_pickup = (self._transformer_rating * 1000) / (math.sqrt(3) * self._transformer_hv_voltage) * 8
            
            # Calculate trip time at maximum fault current
            pickup = self._relay_pickup_current
            fault = self._fault_current_hv * 1000
            multiple = fault / max(pickup, 0.1)  # Prevent division by zero
            
            # Get curve parameters
            curve_params = self._iec_curves.get(self._relay_curve_type, {"a": 13.5, "b": 1.0})
            
            # Calculate trip time based on curve formula
            if multiple > 1.0:
                numerator = curve_params["a"] * self._relay_time_dial
                denominator = (multiple ** curve_params["b"]) - 1
                self._trip_time_max_fault = max(numerator / max(denominator, 0.0001), 0.025)
            else:
                self._trip_time_max_fault = float('inf')  # No trip below pickup
            
            # Calculate breaker duty factor (1.0 for 50Hz systems)
            self._breaker_duty_factor = 1.0
            
            # Calculate curve parameters
            self._curve_a_constant = curve_params["a"]
            self._curve_b_exponent = curve_params["b"]
            
            # Calculate minimum fault current (87% of 3-phase fault current is common approximation)
            self._minimum_fault_current = self._fault_current_hv * 1000 * 0.87
            
            # Calculate remote backup trip time
            self._remote_backup_trip_time = 0.3 + 0.4  # Main trip + coordination margin
            
        except Exception as e:
            logger.error(f"Error in calculating additional parameters: {e}")

    @Property(float, notify=transformerChanged)
    def transformerRating(self):
        return self._transformer_rating
    
    @transformerRating.setter
    def transformerRating(self, value):
        if self._transformer_rating != value and value > 0:
            self._transformer_rating = value
            self.transformerChanged.emit()
            # Recalculate load-dependent values when transformer rating changes
            self._recalculate_load_values()
            self._calculate()

    @Property(float, notify=transformerChanged)
    def lvVoltage(self):
        return self._transformer_lv_voltage
    
    @lvVoltage.setter
    def lvVoltage(self, value):
        if self._transformer_lv_voltage != value and value > 0:
            self._transformer_lv_voltage = value
            self.transformerChanged.emit()
            # Recalculate load-dependent values when transformer rating changes
            self._recalculate_load_values()
            self._calculate()
    
    @Property(float, notify=transformerChanged)
    def hvVoltage(self):
        return self._transformer_hv_voltage
    
    @hvVoltage.setter
    def hvVoltage(self, value):
        if self._transformer_hv_voltage != value and value > 0:
            self._transformer_hv_voltage = value
            self.transformerChanged.emit()
            # Recalculate load-dependent values when transformer rating changes
            self._recalculate_load_values()
            self._calculate()
            
    @Property(float, notify=transformerChanged)
    def transformerImpedance(self):
        return self._transformer_impedance
    
    @transformerImpedance.setter
    def transformerImpedance(self, value):
        if self._transformer_impedance != value and value > 0:
            self._transformer_impedance = value
            self.transformerChanged.emit()
            self._calculate()
    
    @Property(float, notify=transformerChanged)
    def transformerXRRatio(self):
        return self._transformer_x_r_ratio
    
    @transformerXRRatio.setter
    def transformerXRRatio(self, value):
        if self._transformer_x_r_ratio != value and value > 0:
            self._transformer_x_r_ratio = value
            self.transformerChanged.emit()
            self._calculate()
    
    @Property(float, notify=lineChanged)
    def lineLength(self):
        return self._line_length
    
    @lineLength.setter
    def lineLength(self, value):
        if self._line_length != value and value >= 0:
            self._line_length = value
            self.lineChanged.emit()
            self._calculate()
    
    @Property(float, notify=lineChanged)
    def lineR(self):
        return self._line_r
    
    @lineR.setter
    def lineR(self, value):
        if self._line_r != value and value >= 0:
            self._line_r = value
            self.lineChanged.emit()
            self._calculate()
    
    @Property(float, notify=lineChanged)
    def lineX(self):
        return self._line_x
    
    @lineX.setter
    def lineX(self, value):
        if self._line_x != value and value >= 0:
            self._line_x = value
            self.lineChanged.emit()
            self._calculate()
    
    @Property(float, notify=loadChanged)
    def loadMVA(self):
        return self._load_mva
    
    @loadMVA.setter
    def loadMVA(self, value):
        if self._load_mva != value and value >= 0:
            self._load_mva = value
            self.loadChanged.emit()
            self._calculate()
    
    @Property(float, notify=loadChanged)
    def displayLoadMVA(self):
        return self._display_load_mva
    
    @displayLoadMVA.setter
    def displayLoadMVA(self, value):
        if self._display_load_mva != value and value >= 0:
            self._display_load_mva = value
            self.loadChanged.emit()
            self._calculate()
    
    @Property(float, notify=loadChanged)
    def loadPowerFactor(self):
        return self._load_pf
    
    @loadPowerFactor.setter
    def loadPowerFactor(self, value):
        if self._load_pf != value and 0 < value <= 1:
            self._load_pf = value
            self.loadChanged.emit()
            self._calculate()
    
    @Slot(float)
    def setLoadPowerFactorMaintainPower(self, new_pf):
        """Update power factor while maintaining constant real power"""
        try:
            if new_pf <= 0 or new_pf > 1:
                logger.error(f"Invalid power factor value: {new_pf}")
                return
                
            # Calculate current real power
            current_real_power = self._load_mva * self._load_pf
            
            # Calculate new MVA needed to maintain same real power at new PF
            new_mva = current_real_power / new_pf
            
            # Update both values
            self._load_pf = new_pf
            self._load_mva = new_mva
            
            # Recalculate and emit signals
            self._calculate()
            self.loadChanged.emit()
            
        except Exception as e:
            logger.error(f"Error updating power factor: {e}")

    # Add properties for voltage regulator
    @Property(bool, notify=voltageRegulatorChanged)
    def voltageRegulatorEnabled(self):
        return self._voltage_regulator_enabled
    
    @voltageRegulatorEnabled.setter
    def voltageRegulatorEnabled(self, value):
        if self._voltage_regulator_enabled != value:
            self._voltage_regulator_enabled = value
            self.voltageRegulatorChanged.emit()
            self._calculate()
    
    @Property(float, notify=voltageRegulatorChanged)
    def voltageRegulatorBandwidth(self):
        return self._voltage_regulator_bandwidth
    
    @voltageRegulatorBandwidth.setter
    def voltageRegulatorBandwidth(self, value):
        if self._voltage_regulator_bandwidth != value and value > 0:
            self._voltage_regulator_bandwidth = value
            self.voltageRegulatorChanged.emit()
            self._calculate()
    
    @Property(float, notify=voltageRegulatorChanged)
    def voltageRegulatorRange(self):
        return self._voltage_regulator_range
    
    @voltageRegulatorRange.setter
    def voltageRegulatorRange(self, value):
        if self._voltage_regulator_range != value and value > 0:
            self._voltage_regulator_range = value
            self.voltageRegulatorChanged.emit()
            self._calculate()
    
    @Property(int, notify=voltageRegulatorChanged)
    def voltageRegulatorSteps(self):
        return self._voltage_regulator_steps
    
    @voltageRegulatorSteps.setter
    def voltageRegulatorSteps(self, value):
        if self._voltage_regulator_steps != value and value > 0:
            self._voltage_regulator_steps = value
            self.voltageRegulatorChanged.emit()
            self._calculate()
    
    @Property(float, notify=voltageRegulatorChanged)
    def voltageRegulatorTarget(self):
        return self._voltage_regulator_target
    
    @voltageRegulatorTarget.setter
    def voltageRegulatorTarget(self, value):
        if self._voltage_regulator_target != value and value > 0:
            self._voltage_regulator_target = value
            self.voltageRegulatorChanged.emit()
            self._calculate()
    
    @Property(str, notify=voltageRegulatorChanged)
    def voltageRegulatorType(self):
        return self._voltage_regulator_type
    
    @Property(str, notify=voltageRegulatorChanged)
    def voltageRegulatorModel(self):
        return self._voltage_regulator_model
    
    @Property(str, notify=voltageRegulatorChanged)
    def voltageRegulatorConnection(self):
        return self._voltage_regulator_connection
    
    @Property(float, notify=voltageRegulatorChanged)
    def voltageRegulatorCapacity(self):
        return self._voltage_regulator_capacity
    
    @Property(float, notify=calculationCompleted)
    def regulatorThreePhaseCapacity(self):
        return self._regulator_three_phase_capacity
    
    @Property(str, notify=calculationCompleted)
    def recommendedHVCable(self):
        return self._recommended_hv_cable

    @Property(str, notify=calculationCompleted)
    def recommendedLVCable(self):
        return self._recommended_lv_cable

    # Read-only results
    @Property(float, notify=calculationCompleted)
    def transformerZOhms(self):
        return self._transformer_z
    
    @Property(float, notify=calculationCompleted)
    def transformerROhms(self):
        return self._transformer_r
    
    @Property(float, notify=calculationCompleted)
    def transformerXOhms(self):
        return self._transformer_x
    
    @Property(float, notify=calculationCompleted)
    def lineTotalZ(self):
        return abs(self._line_total_z)
    
    @Property(float, notify=calculationCompleted)
    def transformer_flc_hv(self):
        return self._transformer_flc_hv
    
    @Property(float, notify=calculationCompleted)
    def transformer_flc_lv(self):
        return self._transformer_flc_lv

    @Property(float, notify=calculationCompleted)
    def voltageDrop(self):
        return self._voltage_drop
    
    @Property(float, notify=calculationCompleted)
    def faultCurrentLV(self):
        return self._fault_current_lv
    
    @Property(float, notify=calculationCompleted)
    def faultCurrentHV(self):
        return self._fault_current_hv
    
    @Property(float, notify=calculationCompleted)
    def faultCurrentSLG(self):
        return self._fault_current_slg
    
    @Property(float, notify=calculationCompleted)
    def relayPickupCurrent(self):
        """Relay pickup current in primary amps"""
        return self._relay_pickup_current
    
    @Property(float, notify=calculationCompleted)
    def relayTimeDial(self):
        """Time dial setting (0.1 to 1.0)"""
        return self._relay_time_dial
    
    @Property(str, notify=calculationCompleted)
    def relayCtRatio(self):
        """CT ratio (e.g., '300/1')"""
        return self._relay_ct_ratio
    
    @Property(str, notify=calculationCompleted)
    def relayCurveType(self):
        """Relay curve type"""
        return self._relay_curve_type
    
    @Property(float, notify=calculationCompleted)
    def regulatedVoltage(self):
        return self._regulated_voltage
    
    @Property(int, notify=calculationCompleted)
    def regulatorTapPosition(self):
        return self._regulator_tap_position

    @Property(float, notify=calculationCompleted)
    def unregulatedVoltage(self):
        """Get the voltage before regulation in kV"""
        return self._unregulated_voltage

    @Property(float, notify=calculationCompleted)
    def groundFaultCurrent(self):
        """Ground fault current in amps"""
        return self._ground_fault_current
    
    @Property(float, notify=calculationCompleted)
    def differentialRelaySlope(self):
        """Differential relay slope percentage"""
        return self._differential_relay_slope
    
    @Property(dict, notify=calculationCompleted)
    def frequencyRelaySettings(self):
        """Frequency protection settings"""
        return self._frequency_relay_settings
    
    @Property(dict, notify=calculationCompleted)
    def voltageRelaySettings(self):
        """Voltage protection settings"""
        return self._voltage_relay_settings
    
    @Property(float, notify=calculationCompleted)
    def reversePowerThreshold(self):
        """Reverse power protection threshold"""
        return self._reverse_power_threshold
    
    @Property(float, notify=calculationCompleted)
    def z0Transformer(self):
        """Zero sequence impedance of transformer in ohms"""
        return self._z0_transformer

    @Property(float, notify=calculationCompleted)
    def z0Line(self):
        """Zero sequence impedance of line in ohms"""
        return self._z0_line

    @Property(float, notify=calculationCompleted)
    def zNeutralReferred(self):
        """Neutral grounding impedance referred to HV side in ohms"""
        return self._z_ng_referred

    @Property(float, notify=calculationCompleted)
    def xrRatioAtFault(self):
        """X/R ratio at fault point"""
        return self._x_r_ratio_at_fault

    @Property(float, notify=calculationCompleted)
    def asymmetryFactor(self):
        """Asymmetry factor for fault current"""
        return self._asymmetry_factor

    @Property(float, notify=calculationCompleted)
    def shortCircuitMVA(self):
        """Short circuit MVA at fault point"""
        return self._short_circuit_mva

    @Property(float, notify=calculationCompleted)
    def instantaneousPickup(self):
        """Instantaneous pickup current (A)"""
        return self._instantaneous_pickup

    @Property(float, notify=calculationCompleted)
    def tripTimeMaxFault(self):
        """Trip time at maximum fault current (s)"""
        return self._trip_time_max_fault

    @Property(float, notify=calculationCompleted)
    def breakerDutyFactor(self):
        """Breaker duty factor"""
        return self._breaker_duty_factor

    @Property(float, notify=calculationCompleted)
    def curveAConstant(self):
        """A constant for current curve formula"""
        return self._curve_a_constant

    @Property(float, notify=calculationCompleted)
    def curveBExponent(self):
        """B exponent for current curve formula"""
        return self._curve_b_exponent

    @Property(float, notify=calculationCompleted)
    def minimumFaultCurrent(self):
        """Minimum fault current (A)"""
        return self._minimum_fault_current

    @Property(float, notify=calculationCompleted)
    def remoteBackupTripTime(self):
        """Remote backup trip time (s)"""
        return self._remote_backup_trip_time
    @Property(dict, notify=calculationCompleted)
    def differentialSettings(self):
        """Differential protection settings"""
        return self._differential_settings

    # QML slots for setters
    @Slot(float)
    def setTransformerRating(self, value):
        if self._transformer_rating != value and value > 0:
            self._transformer_rating = value
            self.transformerChanged.emit()
            # Recalculate load-dependent values when transformer rating changes
            self._recalculate_load_values()
            self._calculate()

    @Slot(float)
    def setLVTXRating(self, value):
        if self._transformer_lv_voltage != value and value > 0:
            self._transformer_lv_voltage = value
            self.transformerChanged.emit()
            # Recalculate load-dependent values when transformer rating changes
            self._recalculate_load_values()
            self._calculate()

    @Slot(float)
    def setHVTXRating(self, value):
        if self._transformer_hv_voltage != value and value > 0:
            self._transformer_hv_voltage = value
            self.transformerChanged.emit()
            # Recalculate load-dependent values when transformer rating changes
            self._recalculate_load_values()
            self._calculate()
        
    @Slot(float)
    def setTransformerImpedance(self, value):
        self.transformerImpedance = value
        
    @Slot(float)
    def setTransformerXRRatio(self, value):
        self.transformerXRRatio = value
        
    @Slot(float)
    def setLineLength(self, value):
        self.lineLength = value
        
    @Slot(float)
    def setLineR(self, value):
        self.lineR = value
        
    @Slot(float)
    def setLineX(self, value):
        self.lineX = value
        
    @Slot(float)
    def setLoadMVA(self, value):
        self._load_mva = value
        self.loadChanged.emit()
        # Don't immediately calculate to avoid repeated calculations
        
    @Slot(float)
    def setDisplayLoadMVA(self, value):
        if self._display_load_mva != value and value >= 0:
            self._display_load_mva = value
            self.loadChanged.emit()
            self._calculate()
        
    @Slot(float)
    def setLoadPowerFactor(self, value):
        self.loadPowerFactor = value
        
    @Slot(bool)
    def setVoltageRegulatorEnabled(self, value):
        self.voltageRegulatorEnabled = value
    
    @Slot(float)
    def setVoltageRegulatorBandwidth(self, value):
        self.voltageRegulatorBandwidth = value
    
    @Slot(float)
    def setVoltageRegulatorRange(self, value):
        self.voltageRegulatorRange = value
    
    @Slot(int)
    def setVoltageRegulatorSteps(self, value):
        self.voltageRegulatorSteps = value
    
    @Slot(float)
    def setVoltageRegulatorTarget(self, value):
        self.voltageRegulatorTarget = value
    
    @Slot(str)
    def setVoltageRegulatorModel(self, value):
        if self._voltage_regulator_model != value:
            self._voltage_regulator_model = value
            self.voltageRegulatorChanged.emit()
            self._calculate()
    
    @Slot(str)
    def setVoltageRegulatorConnection(self, value):
        if self._voltage_regulator_connection != value:
            self._voltage_regulator_connection = value
            self.voltageRegulatorChanged.emit()
            self._calculate()
    
    @Slot(float)
    def setVoltageRegulatorCapacity(self, value):
        if self._voltage_regulator_capacity != value and value > 0:
            self._voltage_regulator_capacity = value
            self.voltageRegulatorChanged.emit()
            self._calculate()
    
    @Slot()
    def refreshCalculations(self):
        """Force refresh of all calculations"""
        self._calculate()

    @Slot(float, float, str, result=float)
    def calculateTripTimeWithParams(self, current_multiple, time_dial, curve_type):
        """Calculate trip time based on provided parameters"""
        try:
            if current_multiple <= 1.0:
                return float('inf')  # Won't trip below pickup
                
            curve_params = self._iec_curves.get(curve_type, {"a": 13.5, "b": 1.0})
            
            # Formula: t = TD * A / ((I/Ip)^B - 1)
            numerator = curve_params["a"] * time_dial
            denominator = (current_multiple**curve_params["b"]) - 1
            
            trip_time = numerator / denominator if denominator > 0 else float('inf')
            return max(trip_time, 0.025)  # Minimum 25ms operating time
            
        except Exception as e:
            logger.error(f"Error calculating trip time with params: {e}")
            return 0.0

    @Slot(str, result=dict)
    def getCurveDescription(self, curve_type):
        """Get description and formula for relay curve type"""
        descriptions = {
            "Standard Inverse": {
                "description": "Good for general distribution networks.",
                "formula": "t = TDS * 0.14 / ((I/Is)^0.02 - 1)"
            },
            "Very Inverse": {
                "description": "Good for feeder protection and transformer protection.",
                "formula": "t = TDS * 13.5 / ((I/Is) - 1)"
            },
            "Extremely Inverse": {
                "description": "Good for transformer and motor protection.",
                "formula": "t = TDS * 80 / ((I/Is)^2 - 1)"
            },
            "Long-Time Inverse": {
                "description": "Good for high inrush applications.",
                "formula": "t = TDS * 120 / ((I/Is) - 1)"
            },
            "Definite Time": {
                "description": "Good for backup protection schemes.",
                "formula": "t = TDS (regardless of current magnitude)"
            }
        }
        
        return descriptions.get(curve_type, {"description": "Unknown curve type", "formula": ""})