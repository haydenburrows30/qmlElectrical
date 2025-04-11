from PySide6.QtCore import QObject, Property, Signal, Slot
import math
import cmath
import logging
from utils.pdf_generator import PDFGenerator

class TransformerLineCalculator(QObject):
    """Calculator for transformer-line system analysis including protection parameters"""

    # Define signals
    transformerChanged = Signal()
    lineChanged = Signal()
    loadChanged = Signal()
    voltageRegulatorChanged = Signal()  # New signal for voltage regulator
    calculationCompleted = Signal()  # Main signal
    calculationsComplete = Signal()  # Additional alias signal for QML compatibility
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Transformer parameters (400V/11kV)
        self._transformer_lv_voltage = 400.0  # V
        self._transformer_hv_voltage = 11000.0  # V
        self._transformer_rating = 300.0  # kVA
        self._transformer_impedance = 6.0  # %
        self._transformer_x_r_ratio = 8.0  # X/R ratio
        
        # Line parameters (5km cable)
        self._line_length = 5.0  # km
        self._line_r = 0.25  # Ohm/km
        self._line_x = 0.20  # Ohm/km
        self._line_c = 0.3  # μF/km
        
        # Load parameters
        self._load_mva = 0.8  # MVA - This is for protection settings
        self._display_load_mva = 0.8  # MVA - This is for display purposes only
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
        
        # Calculated values
        self._transformer_z = 0.0  # Ohm
        self._transformer_r = 0.0  # Ohm
        self._transformer_x = 0.0  # Ohm
        self._line_total_z = 0.0  # Ohm
        self._voltage_drop = 0.0  # %
        self._fault_current_lv = 0.0  # kA
        self._fault_current_hv = 0.0  # kA
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
        
        # Perform initial calculations
        self._calculate()
    
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

    def _calculate(self):
        """Calculate transformer-line-load parameters"""
        try:
            logger = logging.getLogger("qmltest")
            logger.info("\n=== Starting Transformer-Line Calculations ===")
            
            # IMPORTANT: Protection settings must be based on transformer rating, not load
            # Calculate transformer full load current (FLC)
            transformer_flc = (self._transformer_rating * 1000) / (math.sqrt(3) * self._transformer_hv_voltage)
            
            # Set relay pickup current at 125% of transformer FLC - independent of actual load
            self._relay_pickup_current = 1.25 * transformer_flc
            
            # CT ratio selection (select next standard ratio above pickup current)
            standard_ct_ratios = [50, 75, 100, 150, 200, 300, 400, 500, 600, 800, 1000, 1200, 1500, 2000]
            ct_primary = next((x for x in standard_ct_ratios if x > self._relay_pickup_current), 2000)
            self._relay_ct_ratio = f"{ct_primary}/1"  # Using 1A secondary
            
            # Calculate time dial setting - using Very Inverse curve (IEC 60255)
            self._relay_time_dial = 0.3
            self._relay_curve_type = "Very Inverse (IEC)"
            
            logger.info(f"Transformer rating: {self._transformer_rating:.2f} kVA")
            logger.info(f"Transformer full load current: {transformer_flc:.2f} A")
            logger.info(f"Relay pickup current: {self._relay_pickup_current:.2f} A")
            logger.info(f"CT ratio selected: {self._relay_ct_ratio}")
            
            # Now proceed with the rest of the calculations using actual load values
            logger.info(f"Load MVA: {self._load_mva:.4f} MVA")
            logger.info(f"Load power factor: {self._load_pf:.2f}")
            
            # Calculate transformer impedance
            transformer_z_pu = self._transformer_impedance / 100.0
            transformer_z_base = (self._transformer_hv_voltage**2) / (self._transformer_rating * 1000)
            self._transformer_z = transformer_z_pu * transformer_z_base
            
            # Remove print statements and keep only logging
            logger.info("\nTransformer Impedance Calculations:")
            logger.info(f"• Z base: {transformer_z_base:.2f} ohm")
            logger.info(f"• Z (pu): {transformer_z_pu:.3f}")
            logger.info(f"• Total Z: {self._transformer_z:.2f} ohm")
            
            # R and X components
            angle = math.atan(self._transformer_x_r_ratio)
            self._transformer_r = self._transformer_z * math.cos(angle)
            self._transformer_x = self._transformer_z * math.sin(angle)
            logger.info(f"• R: {self._transformer_r:.2f} ohm")
            logger.info(f"• X: {self._transformer_x:.2f} ohm")
            
            # Line calculations
            self._line_total_z = complex(self._line_r * self._line_length, 
                                       self._line_x * self._line_length)
            logger.info("\nLine Parameters:")
            logger.info(f"• Total Z: {abs(self._line_total_z):.2f} at {math.degrees(cmath.phase(self._line_total_z)):.1f} degrees ohm")
            
            # Voltage drop calculations - improve for very low loads
            # Make sure we have a minimum load to avoid division by zero and ensure realistic results
            load_current = max((self._load_mva * 1e6) / (math.sqrt(3) * self._transformer_hv_voltage), 0.1)
            load_angle = math.acos(self._load_pf)
            load_current_complex = load_current * complex(math.cos(load_angle), -math.sin(load_angle))
            
            logger.info("\nLoad Current:")
            logger.info(f"• Magnitude: {load_current:.2f} A")
            logger.info(f"• Angle: {math.degrees(load_angle):.1f}°")
            logger.info(f"• Complex: {load_current_complex:.2f} A")
            
            # 1. Calculate transformer impedance in Ohms (referred to HV side)
            transformer_z_pu = self._transformer_impedance / 100.0
            transformer_z_base = (self._transformer_hv_voltage**2) / (self._transformer_rating * 1000)
            self._transformer_z = transformer_z_pu * transformer_z_base
            
            # Calculate R and X components using X/R ratio
            angle = math.atan(self._transformer_x_r_ratio)
            self._transformer_r = self._transformer_z * math.cos(angle)
            self._transformer_x = self._transformer_z * math.sin(angle)
            
            # 2. Calculate line impedance
            self._line_total_z = complex(self._line_r * self._line_length, 
                                       self._line_x * self._line_length)
            
            # 3. Calculate charging current
            line_charging_current = 2 * math.pi * 50 * self._line_c * 1e-6 * self._transformer_hv_voltage * self._line_length
            
            # 4. Calculate voltage drop (before regulation)
            # Ensure a minimum load current for calculation stability
            load_current = max((self._load_mva * 1e6) / (math.sqrt(3) * self._transformer_hv_voltage), 0.1)
            load_angle = math.acos(self._load_pf)
            load_current_complex = load_current * complex(math.cos(load_angle), -math.sin(load_angle))
            
            # Calculate voltage drop using complex arithmetic for more accurate results
            source_voltage = self._transformer_hv_voltage / math.sqrt(3)  # Phase voltage
            source_voltage_complex = complex(source_voltage, 0)
            total_impedance = complex(self._transformer_r, self._transformer_x) + self._line_total_z
            voltage_drop_complex = load_current_complex * total_impedance
            receiving_end_voltage = source_voltage_complex - voltage_drop_complex
            
            # Improved voltage drop calculation that properly accounts for phase angles
            # Calculate percentage drop using the actual voltage difference
            voltage_drop_percent = (abs(source_voltage_complex) - abs(receiving_end_voltage)) / abs(source_voltage_complex) * 100.0
            
            # For very small loads, calculate a scaled voltage drop based on impedance
            # This provides more realistic results for nominal system conditions
            if self._load_mva < 0.01:  # For very small loads
                # Calculate an approximation based on rated impedance and scaled by actual load
                rated_current = (self._transformer_rating * 1000) / (math.sqrt(3) * self._transformer_hv_voltage)
                rated_drop = (abs(total_impedance) * rated_current) / source_voltage * 100.0
                # Scale by the actual load as a fraction of rated load
                scaled_drop = rated_drop * (self._load_mva * 1000 / self._transformer_rating)
                # Use the scaled drop for very small loads
                self._voltage_drop = max(scaled_drop, 0.01)
            else:
                # Regular calculation for normal loads
                self._voltage_drop = max(voltage_drop_percent, 0.01)  # At least 0.01%
            
            # Calculate unregulated voltage (scaled to line-to-line)
            self._unregulated_voltage = (abs(receiving_end_voltage) * math.sqrt(3)) / 1000.0  # Line-to-line kV
            
            logger.info(f"Source voltage: {source_voltage:.2f} V")
            logger.info(f"Voltage drop complex: {voltage_drop_complex}")
            logger.info(f"Receiving end voltage: {receiving_end_voltage}")
            logger.info(f"Natural voltage drop: {self._voltage_drop:.2f}%")
            logger.info(f"Unregulated voltage: {self._unregulated_voltage:.2f} kV")
            
            # Calculate fault currents - before the regulator calculations
            # LV fault current - using actual transformer impedance
            lv_base_current = self._transformer_rating * 1000 / (math.sqrt(3) * self._transformer_lv_voltage)
            z_base_lv = self._transformer_lv_voltage * self._transformer_lv_voltage / (self._transformer_rating * 1000)
            z_t_pu = self._transformer_impedance / 100.0
            
            # Convert transformer impedance to LV side
            z_t_lv = z_t_pu * z_base_lv
            self._fault_current_lv = (self._transformer_lv_voltage / math.sqrt(3)) / abs(z_t_lv) / 1000  # kA
            
            # HV fault current - using total system impedance
            total_fault_z = complex(self._transformer_r, self._transformer_x) + self._line_total_z
            self._fault_current_hv = (self._transformer_hv_voltage / math.sqrt(3)) / abs(total_fault_z) / 1000  # kA
            
            logger.info(f"Fault current LV: {self._fault_current_lv:.2f} kA")
            logger.info(f"Fault current HV: {self._fault_current_hv:.2f} kA")
            
            # Rest of voltage regulator calculations...
            if self._voltage_regulator_enabled:
                # Use unregulated voltage as input to regulator
                voltage_with_drop = self._unregulated_voltage
                # Calculate required tap position to achieve target voltage
                target_voltage = self._voltage_regulator_target
                voltage_difference_percent = ((target_voltage - voltage_with_drop) / (self._transformer_hv_voltage / 1000)) * 100.0
                
                # Limit to regulator range
                voltage_difference_percent = max(min(voltage_difference_percent, self._voltage_regulator_range), 
                                              -self._voltage_regulator_range)
                
                # Step resolution for a 32-step regulator with ±10% range
                step_size = self._voltage_regulator_range / (self._voltage_regulator_steps / 2)  # Size of each tap step
                
                # Calculate tap position (positive for boost, negative for buck)
                max_tap = self._voltage_regulator_steps // 2
                self._regulator_tap_position = round(voltage_difference_percent / step_size)
                
                # Calculate regulated voltage - for single-phase regulators in delta configuration
                regulation_percent = self._regulator_tap_position * step_size
                self._regulated_voltage = voltage_with_drop * (1 + regulation_percent / 100.0)
                
                # For delta configuration, calculate the effective three-phase power capacity
                # In delta, each regulator handles line-to-line voltage and phase-to-phase current
                self._regulator_three_phase_capacity = self._voltage_regulator_capacity * 3  # Total capacity
            else:
                # No regulation
                self._regulated_voltage = (self._transformer_hv_voltage / 1000) * (1 - self._voltage_drop / 100.0)
                self._regulator_tap_position = 0
                self._regulator_three_phase_capacity = 0
            
            # Calculate relay settings
            # Ensure we use transformer rating for proper full load current calculation
            # This is independent of actual load connected to the transformer
            transformer_full_load_current = (self._transformer_rating * 1000) / (math.sqrt(3) * self._transformer_hv_voltage)
            
            # Set pickup current at 125% of full load current - based on transformer rating, not actual load
            self._relay_pickup_current = 1.25 * transformer_full_load_current
            
            # CT ratio selection (select next standard ratio above pickup current)
            standard_ct_ratios = [50, 75, 100, 150, 200, 300, 400, 500, 600, 800, 1000, 1200, 1500, 2000]
            ct_primary = next((x for x in standard_ct_ratios if x > self._relay_pickup_current), 2000)
            self._relay_ct_ratio = f"{ct_primary}/1"  # Using 1A secondary
            
            # Calculate time dial setting
            # Using Very Inverse curve (IEC 60255)
            # TDS typically 0.1 to 1.0, using 0.3 as default
            self._relay_time_dial = 0.3
            self._relay_curve_type = "Very Inverse (IEC)"
            
            logger.info(f"Transformer full load current: {transformer_full_load_current:.2f} A")
            logger.info(f"Relay pickup current: {self._relay_pickup_current:.2f} A")
            logger.info(f"CT ratio selected: {self._relay_ct_ratio}")
            
            # Calculate cable sizes
            self._calculate_cable_sizes()
            
            # Calculate ground fault current using full zero-sequence network
            # Convert all impedances to HV side and per unit
            base_z_hv = (self._transformer_hv_voltage**2) / (self._transformer_rating * 1000)
            
            # Transformer zero sequence impedance (typically 0.85 * Z1)
            z0_transformer_pu = 0.85 * (self._transformer_impedance / 100.0)
            z0_transformer = complex(z0_transformer_pu * base_z_hv, 0)  # Convert to complex

            # Line zero sequence impedance (typically 3 * Z1)
            z0_line = complex(3 * self._line_r * self._line_length,
                            3 * self._line_x * self._line_length)
            
            # Neutral grounding impedance referred to HV side
            z_ng_referred = complex(self._neutral_grounding_resistance * (self._transformer_hv_voltage / self._transformer_lv_voltage)**2, 0)
            
            # Total zero sequence impedance
            z0_total = z0_transformer + z0_line + z_ng_referred
            
            # Single line to ground fault current (Vln / (Z1 + Z2 + Z0))
            z1 = total_impedance  # Already calculated positive sequence
            z2 = z1  # Negative sequence equals positive for passive network
            
            vln = self._transformer_hv_voltage / math.sqrt(3)
            
            # Calculate ground fault current with minimum value to prevent zero
            self._ground_fault_current = max(vln / abs(z1 + z2 + z0_total), 10.0)  # Minimum 10A
            
            logger.info("\nGround fault calculation:")
            logger.info(f"Z0 transformer: {z0_transformer:.2f} ohm")
            logger.info(f"Z0 line: {z0_line:.2f} ohm")
            logger.info(f"Zn referred: {z_ng_referred:.2f} ohm")
            logger.info(f"Total Z0: {z0_total:.2f} ohm")
            logger.info(f"Total impedance for SLG fault: {(z1 + z2 + z0_total):.2f} ohm")
            logger.info(f"Ground fault current: {self._ground_fault_current:.2f} A")
            
            logger.info("\nProtection Settings:")
            logger.info(f"• Relay Pickup Current: {self._relay_pickup_current:.2f} A")
            logger.info(f"• CT Ratio: {self._relay_ct_ratio}")
            logger.info(f"• Time Dial: {self._relay_time_dial:.2f}")
            logger.info(f"• Curve Type: {self._relay_curve_type}")
            
            # Voltage regulator
            if self._voltage_regulator_enabled:
                logger.info("\nVoltage Regulator:")
                logger.info(f"• Unregulated Voltage: {self._unregulated_voltage:.2f} kV")
                logger.info(f"• Target Voltage: {self._voltage_regulator_target:.2f} kV")
                logger.info(f"• Tap Position: {self._regulator_tap_position}")
                logger.info(f"• Regulated Voltage: {self._regulated_voltage:.2f} kV")
            
            print("Calculations complete.")
            logger.info("\n=== Calculations Complete ===\n")
            
            # Emit completion signal - emit both signals for compatibility
            self.calculationCompleted.emit()
            self.calculationsComplete.emit()  # Backwards compatibility
            
        except Exception as e:
            print(f"Error in calculations: {str(e)}")
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
            
            logger = logging.getLogger("qmltest")
            logger.info(f"Recalculated load values: FLC={self._full_load_current:.2f}A, Pickup={self._relay_pickup_current:.2f}A")
            
        except Exception as e:
            print(f"Error in recalculate_load_values: {str(e)}")
            logging.getLogger("qmltest").error(f"Error in recalculate_load_values: {str(e)}")
    
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
                print(f"Invalid power factor value: {new_pf}")
                return
                
            # Calculate current real power
            current_real_power = self._load_mva * self._load_pf
            
            # Calculate new MVA needed to maintain same real power at new PF
            new_mva = current_real_power / new_pf
            
            # Log the change
            logger = logging.getLogger("qmltest")
            logger.info(f"Updating power factor from {self._load_pf:.2f} to {new_pf:.2f}")
            logger.info(f"Maintaining real power at {current_real_power:.4f} MW")
            logger.info(f"New apparent power: {new_mva:.4f} MVA")
            
            # Update both values
            self._load_pf = new_pf
            self._load_mva = new_mva
            
            # Recalculate and emit signals
            self._calculate()
            self.loadChanged.emit()
            
        except Exception as e:
            print(f"Error updating power factor: {e}")

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
    def voltageDrop(self):
        return self._voltage_drop
    
    @Property(float, notify=calculationCompleted)
    def faultCurrentLV(self):
        return self._fault_current_lv
    
    @Property(float, notify=calculationCompleted)
    def faultCurrentHV(self):
        return self._fault_current_hv
    
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
        logger = logging.getLogger("qmltest")
        logger.info(f"setLoadMVA called with value: {value} from caller: {__import__('traceback').format_stack()[-2]}")
        self._load_mva = value
        self.loadChanged.emit()
        # Don't immediately calculate to avoid repeated calculations
        # self._calculate()
        
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
    
    @Slot("QVariant", str)
    def exportTransformerReport(self, data, filename):
        """Export transformer calculations to PDF"""
        try:
            # Clean up the filename path
            clean_path = filename.strip()
            
            # Ensure path ends with .pdf
            if not clean_path.lower().endswith('.pdf'):
                clean_path += '.pdf'
            
            # Add calculated values to the data dict
            export_data = {
                # Transformer parameters
                "transformer_rating": self._transformer_rating,
                "transformer_impedance": self._transformer_impedance,
                "transformer_xr_ratio": self._transformer_x_r_ratio,
                "transformer_z": self._transformer_z,
                "transformer_r": self._transformer_r,
                "transformer_x": self._transformer_x,
                
                # Line parameters
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
            }
            
            generator = PDFGenerator()
            generator.generate_transformer_report(export_data, clean_path)
            print(f"Transformer report exported to: {clean_path}")
            
        except Exception as e:
            print(f"Error exporting transformer report: {e}")
            print(f"Attempted filename: {filename}")

    @Slot("QVariant", str)
    def exportProtectionReport(self, data, filename):
        """Export protection requirements to PDF"""
        try:
            # Clean up filename
            clean_path = filename.strip()
            if not clean_path.lower().endswith('.pdf'):
                clean_path += '.pdf'

            # Convert QJSValue to Python dict
            js_data = data.toVariant()

            # Extract and validate the data
            export_data = {
                "wind_power": float(js_data["wind_power"]),
                "generator_current": float(js_data["generator_current"]),
                "generator_capacity": float(js_data["generator_capacity"]),
                "transformer_rating": float(js_data["transformer_rating"]),
                "relay_settings": {
                    "pickup_current": float(self._relay_pickup_current),
                    "ct_ratio": self._relay_ct_ratio,
                    "curve_type": self._relay_curve_type
                },
                "voltage_protection": js_data["voltage_protection"],
                "frequency_protection": js_data["frequency_protection"],
            }
            
            generator = PDFGenerator()
            generator.generate_protection_report(export_data, clean_path)
            print(f"Protection report exported to: {clean_path}")
            
        except Exception as e:
            print(f"Error exporting protection report: {e}")
            print(f"Attempted filename: {filename}")
            print(f"Data received: {data}")

    @Slot(float)
    def updateLoadForVoltageOnly(self, value):
        """
        Update load MVA only for voltage drop and regulator calculations without recalculating protection settings.
        This prevents wind turbine output from affecting protection settings which should be based on transformer rating.
        """
        logger = logging.getLogger("qmltest")
        logger.info(f"updateLoadForVoltageOnly called with value: {value}")
        
        if value > 0:
            self._load_for_voltage_calc = value
            
            # Only update voltage drop and regulator calculations
            try:
                # Calculate voltage drop using complex arithmetic for more accurate results
                load_current = max((value * 1e6) / (math.sqrt(3) * self._transformer_hv_voltage), 0.1)
                load_angle = math.acos(self._load_pf)
                load_current_complex = load_current * complex(math.cos(load_angle), -math.sin(load_angle))
                
                # Calculate voltage drop
                source_voltage = self._transformer_hv_voltage / math.sqrt(3)  # Phase voltage
                source_voltage_complex = complex(source_voltage, 0)
                total_impedance = complex(self._transformer_r, self._transformer_x) + self._line_total_z
                voltage_drop_complex = load_current_complex * total_impedance
                receiving_end_voltage = source_voltage_complex - voltage_drop_complex
                
                # Calculate percentage drop using the actual voltage difference
                voltage_drop_percent = (abs(source_voltage_complex) - abs(receiving_end_voltage)) / abs(source_voltage_complex) * 100.0
                
                # For very small loads, calculate a scaled voltage drop based on impedance
                if value < 0.01:  # For very small loads
                    # Calculate an approximation based on rated impedance and scaled by actual load
                    rated_current = (self._transformer_rating * 1000) / (math.sqrt(3) * self._transformer_hv_voltage)
                    rated_drop = (abs(total_impedance) * rated_current) / source_voltage * 100.0
                    # Scale by the actual load as a fraction of rated load
                    scaled_drop = rated_drop * (value * 1000 / self._transformer_rating)
                    # Use the scaled drop for very small loads
                    self._voltage_drop = max(scaled_drop, 0.01)
                else:
                    # Regular calculation for normal loads
                    self._voltage_drop = max(voltage_drop_percent, 0.01)  # At least 0.01%
                
                # Calculate unregulated voltage (scaled to line-to-line)
                self._unregulated_voltage = (abs(receiving_end_voltage) * math.sqrt(3)) / 1000.0  # Line-to-line kV
                
                # Update regulator values if enabled
                if self._voltage_regulator_enabled:
                    # Use unregulated voltage as input to regulator
                    voltage_with_drop = self._unregulated_voltage
                    # Calculate required tap position to achieve target voltage
                    target_voltage = self._voltage_regulator_target
                    voltage_difference_percent = ((target_voltage - voltage_with_drop) / (self._transformer_hv_voltage / 1000)) * 100.0
                    
                    # Limit to regulator range
                    voltage_difference_percent = max(min(voltage_difference_percent, self._voltage_regulator_range), 
                                                  -self._voltage_regulator_range)
                    
                    # Step resolution for a 32-step regulator with ±10% range
                    step_size = self._voltage_regulator_range / (self._voltage_regulator_steps / 2)  # Size of each tap step
                    
                    # Calculate tap position (positive for boost, negative for buck)
                    self._regulator_tap_position = round(voltage_difference_percent / step_size)
                    
                    # Calculate regulated voltage - for single-phase regulators in delta configuration
                    regulation_percent = self._regulator_tap_position * step_size
                    self._regulated_voltage = voltage_with_drop * (1 + regulation_percent / 100.0)
                else:
                    # No regulation
                    self._regulated_voltage = (self._transformer_hv_voltage / 1000) * (1 - self._voltage_drop / 100.0)
                    self._regulator_tap_position = 0
                
                # Notice we DO NOT recalculate protection settings here
                # This preserves the transformer-rated protection values
                
                # Emit signal since values have changed
                self.calculationCompleted.emit()
                self.calculationsComplete.emit()  # Backwards compatibility
                
            except Exception as e:
                logger.error(f"Error in updateLoadForVoltageOnly: {e}")
                logger.exception(e)
        else:
            logger.warning(f"Invalid load value for voltage calculation: {value}")
            
        # Don't store as the official load MVA property to avoid affecting protection settings
        # DO NOT SET self._load_mva = value