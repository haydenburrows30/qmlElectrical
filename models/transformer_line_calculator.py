from PySide6.QtCore import QObject, Property, Signal, Slot
import math
import cmath

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
        self._transformer_rating = 1000.0  # kVA
        self._transformer_impedance = 6.0  # %
        self._transformer_x_r_ratio = 8.0  # X/R ratio
        
        # Line parameters (5km cable)
        self._line_length = 5.0  # km
        self._line_r = 0.25  # Ohm/km
        self._line_x = 0.20  # Ohm/km
        self._line_c = 0.3  # μF/km
        
        # Load parameters
        self._load_mva = 0.8  # MVA
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
        
        # Perform initial calculations
        self._calculate()
    
    def _calculate(self):
        """Calculate transformer-line-load parameters"""
        try:
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
            
            # 4. Calculate voltage drop
            load_current = (self._load_mva * 1e6) / (math.sqrt(3) * self._transformer_hv_voltage)
            load_angle = math.acos(self._load_pf)
            load_current_complex = load_current * complex(math.cos(load_angle), -math.sin(load_angle))
            
            voltage_drop_complex = load_current_complex * (complex(self._transformer_r, self._transformer_x) + self._line_total_z)
            self._voltage_drop = (abs(voltage_drop_complex) / self._transformer_hv_voltage) * 100.0
            
            # 5. Calculate fault currents
            # LV fault current
            system_z_lv = 1.1 * 1e-6  # Assumed source impedance at LV (400V)
            fault_z_lv = system_z_lv + (complex(self._transformer_r, self._transformer_x) * 
                                     (self._transformer_lv_voltage/self._transformer_hv_voltage)**2)
            self._fault_current_lv = (self._transformer_lv_voltage / math.sqrt(3)) / abs(fault_z_lv) / 1000  # kA
            
            # HV fault current
            fault_z_hv = complex(self._transformer_r, self._transformer_x) + self._line_total_z
            self._fault_current_hv = (self._transformer_hv_voltage / math.sqrt(3)) / abs(fault_z_hv) / 1000  # kA
            
            # 6. Calculate relay settings
            # Set pickup current at 120% of full load current
            transformer_full_load_current = (self._transformer_rating * 1000) / (math.sqrt(3) * self._transformer_hv_voltage)
            self._relay_pickup_current = 1.2 * transformer_full_load_current
            
            # CT ratio selection (select standard ratio higher than pickup)
            # Changed to use 1A secondary instead of 5A
            ct_primary = math.ceil(self._relay_pickup_current / 100) * 100
            self._relay_ct_ratio = f"{ct_primary}/1"  # Changed from 5A to 1A secondary
            
            # Time dial setting (using typical Very Inverse curve)
            # Time dial depends on coordination study, using typical value
            self._relay_time_dial = 0.3
            
            # Calculate regulated voltage - modified for 3-phase delta-connected regulators
            if self._voltage_regulator_enabled:
                # Calculate nominal voltage with drop
                nominal_voltage = self._transformer_hv_voltage / 1000  # Convert to kV
                voltage_with_drop = nominal_voltage * (1 - self._voltage_drop / 100.0)
                
                # Calculate required tap position to achieve target voltage
                target_voltage = self._voltage_regulator_target
                voltage_difference_percent = ((target_voltage - voltage_with_drop) / nominal_voltage) * 100.0
                
                # Limit to regulator range
                voltage_difference_percent = max(min(voltage_difference_percent, self._voltage_regulator_range), 
                                              -self._voltage_regulator_range)
                
                # Step resolution for a 32-step regulator with ±10% range
                step_size = self._voltage_regulator_range / (self._voltage_regulator_steps / 2)  # Size of each tap step
                
                # Calculate tap position (positive for boost, negative for buck)
                max_tap = self._voltage_regulator_steps // 2
                self._regulator_tap_position = round(voltage_difference_percent / step_size)
                
                # Calculate regulated voltage - for single-phase regulators in delta configuration
                # Each regulator handles line-to-line voltage
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
            
            # Emit completion signal - emit both signals for compatibility
            self.calculationCompleted.emit()
            self.calculationsComplete.emit()  # Backwards compatibility
            
        except Exception as e:
            print(f"Error in transformer-line calculations: {e}")
            
    @Property(float, notify=transformerChanged)
    def transformerRating(self):
        return self._transformer_rating
    
    @transformerRating.setter
    def transformerRating(self, value):
        if self._transformer_rating != value and value > 0:
            self._transformer_rating = value
            self.transformerChanged.emit()
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
    def loadPowerFactor(self):
        return self._load_pf
    
    @loadPowerFactor.setter
    def loadPowerFactor(self, value):
        if self._load_pf != value and 0 < value <= 1:
            self._load_pf = value
            self.loadChanged.emit()
            self._calculate()
    
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
    
    # Read-only results
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def transformerZOhms(self):
        return self._transformer_z
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def transformerROhms(self):
        return self._transformer_r
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def transformerXOhms(self):
        return self._transformer_x
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def lineTotalZ(self):
        return abs(self._line_total_z)
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def voltageDrop(self):
        return self._voltage_drop
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def faultCurrentLV(self):
        return self._fault_current_lv
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def faultCurrentHV(self):
        return self._fault_current_hv
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def relayPickupCurrent(self):
        return self._relay_pickup_current
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def relayTimeDial(self):
        return self._relay_time_dial
    
    @Property(str, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def relayCtRatio(self):
        return self._relay_ct_ratio
    
    @Property(str, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def relayCurveType(self):
        return self._relay_curve_type
    
    @Property(float, notify=calculationCompleted)
    def regulatedVoltage(self):
        return self._regulated_voltage
    
    @Property(int, notify=calculationCompleted)
    def regulatorTapPosition(self):
        return self._regulator_tap_position
    
    # QML slots for setters
    @Slot(float)
    def setTransformerRating(self, value):
        self.transformerRating = value
        
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
        self.loadMVA = value
        
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
        return True
