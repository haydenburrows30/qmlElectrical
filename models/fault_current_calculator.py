from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class FaultCurrentCalculator(QObject):
    """Calculator for fault current analysis including system, transformer and cable impedances"""
    
    # Define signals for QML
    calculationComplete = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # System parameters
        self._system_voltage = 11.0  # kV
        self._system_mva = 500.0  # MVA
        self._system_xr_ratio = 15.0  # System X/R ratio
        
        # Transformer parameters
        self._transformer_mva = 5.0  # MVA
        self._transformer_z = 6.0  # %
        self._transformer_xr_ratio = 10.0  # Transformer X/R ratio
        
        # Cable parameters
        self._cable_length = 0.5  # km
        self._cable_r = 0.2  # Ω/km (resistance)
        self._cable_x = 0.15  # Ω/km (reactance)
        
        # Motor contribution (if applicable)
        self._include_motors = False
        self._motor_mva = 1.0  # MVA
        self._motor_contribution_factor = 4.0  # Typical value for induction motors
        
        # Fault parameters
        self._fault_type = "3-Phase"
        self._fault_resistance = 0.0  # Ω (arc or ground resistance)
        
        # Calculated results
        self._initial_sym_current = 0.0  # kA
        self._peak_fault_current = 0.0  # kA
        self._breaking_current = 0.0  # kA
        self._thermal_current = 0.0  # kA
        self._total_impedance = 0.0  # Ω
        self._total_r = 0.0  # Ω (resistance)
        self._total_x = 0.0  # Ω (reactance)
        self._system_pu_z = 0.0  # System impedance in per-unit
        self._transformer_pu_z = 0.0  # Transformer impedance in per-unit
        self._cable_pu_z = 0.0  # Cable impedance in per-unit
        self._effective_xr_ratio = 0.0  # Effective X/R ratio of the circuit
        
        # Initial calculation
        self._calculate()

    def _calculate(self):
        """Perform fault current calculations"""
        try:
            # Base values for per-unit calculations
            base_kv = self._system_voltage
            base_mva = self._transformer_mva
            z_base = (base_kv * 1000) ** 2 / (base_mva * 1e6)
            
            # Calculate system impedance in per-unit
            z_system_pu = base_mva / self._system_mva
            self._system_pu_z = z_system_pu
            
            # Split system impedance into R and X components using system X/R ratio
            system_x = z_system_pu * self._system_xr_ratio / math.sqrt(1 + self._system_xr_ratio**2)
            system_r = system_x / self._system_xr_ratio
            
            # Calculate transformer impedance in per-unit
            z_transformer_pu = self._transformer_z / 100.0
            self._transformer_pu_z = z_transformer_pu
            
            # Split transformer impedance into R and X components using transformer X/R ratio
            tx_x = z_transformer_pu * self._transformer_xr_ratio / math.sqrt(1 + self._transformer_xr_ratio**2)
            tx_r = tx_x / self._transformer_xr_ratio
            
            # Calculate cable impedance in ohms
            cable_r_ohm = self._cable_r * self._cable_length
            cable_x_ohm = self._cable_x * self._cable_length
            
            # Convert cable impedance to per-unit
            cable_r_pu = cable_r_ohm / z_base
            cable_x_pu = cable_x_ohm / z_base
            self._cable_pu_z = math.sqrt(cable_r_pu**2 + cable_x_pu**2)
            
            # Calculate motor contribution in per-unit (if included)
            motor_x_pu = 0
            motor_r_pu = 0
            if self._include_motors:
                motor_z_pu = 1.0 / (self._motor_mva / base_mva * self._motor_contribution_factor)
                motor_xr_ratio = 20.0  # Typical X/R ratio for motors
                motor_x_pu = motor_z_pu * motor_xr_ratio / math.sqrt(1 + motor_xr_ratio**2)
                motor_r_pu = motor_x_pu / motor_xr_ratio
            
            # Calculate fault resistance in per-unit
            fault_r_pu = self._fault_resistance / z_base
            
            # Calculate total R, X in per-unit
            total_r_pu = system_r + tx_r + cable_r_pu + fault_r_pu
            total_x_pu = system_x + tx_x + cable_x_pu
            
            # If motors included, add their contribution (in parallel)
            if self._include_motors and (motor_r_pu > 0 or motor_x_pu > 0):
                # Convert R-jX to complex form for parallel combination
                z_circuit = complex(total_r_pu, total_x_pu)
                z_motor = complex(motor_r_pu, motor_x_pu)
                # Parallel combination: Z = Z1*Z2/(Z1+Z2)
                z_total = (z_circuit * z_motor) / (z_circuit + z_motor)
                total_r_pu = z_total.real
                total_x_pu = z_total.imag
            
            # Calculate total impedance in per-unit and ohms
            total_z_pu = math.sqrt(total_r_pu**2 + total_x_pu**2)
            self._total_r = total_r_pu * z_base
            self._total_x = total_x_pu * z_base
            self._total_impedance = total_z_pu * z_base
            
            # Calculate effective X/R ratio
            if total_r_pu > 0:
                self._effective_xr_ratio = total_x_pu / total_r_pu
            else:
                self._effective_xr_ratio = 20.0  # Default high value if R is zero
            
            # Calculate fault currents based on type
            if total_z_pu > 0:
                base_current_pu = 1.0 / total_z_pu
                base_current_ka = base_current_pu * base_mva * 1e6 / (math.sqrt(3) * base_kv * 1000) / 1000
                
                fault_factors = {
                    "3-Phase": 1.0,
                    "Line-Line": 0.866,  # √3/2
                    "Line-Ground": 0.577,  # 1/√3
                    "Line-Line-Ground": 1.15  # Typical factor for LLG faults
                }
                
                factor = fault_factors.get(self._fault_type, 1.0)
                self._initial_sym_current = base_current_ka * factor
                
                # Calculate peak fault current (includes DC component)
                # Using IEEE 399 formula: peak = √2 × Ik × κ, where κ = 1.02 + 0.98e^(-3/X/R)
                peak_factor = math.sqrt(2) * (1.02 + 0.98 * math.exp(-3.0/self._effective_xr_ratio))
                self._peak_fault_current = self._initial_sym_current * peak_factor
                
                # Breaking current (after DC decay) - improved formula
                # For circuit breakers with typical breaking time of 50-80ms
                t_breaking = 0.08  # seconds, typical breaking time
                breaking_factor = 1.0 + (math.exp(-2 * math.pi * 50 * t_breaking / self._effective_xr_ratio))
                self._breaking_current = self._initial_sym_current * breaking_factor
                
                # Thermal equivalent current (1 second) - improved formula based on IEC standards
                duration = 1.0  # seconds
                thermal_factor = math.sqrt((1 + self._effective_xr_ratio) / 
                                         (1 + self._effective_xr_ratio * math.exp(-2 * duration / self._effective_xr_ratio)))
                self._thermal_current = self._initial_sym_current * thermal_factor
            else:
                # Avoid division by zero
                self._initial_sym_current = 0
                self._peak_fault_current = 0
                self._breaking_current = 0
                self._thermal_current = 0
            
            # Notify QML that calculation is complete
            self.calculationComplete.emit()
            
        except Exception as e:
            print(f"Fault current calculation error: {e}")
    
    # Property getters for QML - Results section
    @Property(float, notify=calculationComplete)
    def initialSymCurrent(self):
        return self._initial_sym_current
    
    @Property(float, notify=calculationComplete)
    def peakFaultCurrent(self):
        return self._peak_fault_current
    
    @Property(float, notify=calculationComplete)  
    def breakingCurrent(self):
        return self._breaking_current
    
    @Property(float, notify=calculationComplete)
    def thermalCurrent(self):
        return self._thermal_current
    
    @Property(float, notify=calculationComplete)
    def totalImpedance(self):
        return self._total_impedance
    
    @Property(float, notify=calculationComplete)
    def totalR(self):
        return self._total_r
    
    @Property(float, notify=calculationComplete)
    def totalX(self):
        return self._total_x
    
    @Property(float, notify=calculationComplete)
    def effectiveXrRatio(self):
        return self._effective_xr_ratio
    
    @Property(float, notify=calculationComplete)
    def systemPuZ(self):
        return self._system_pu_z
    
    @Property(float, notify=calculationComplete)
    def transformerPuZ(self):
        return self._transformer_pu_z
    
    @Property(float, notify=calculationComplete)
    def cablePuZ(self):
        return self._cable_pu_z
    
    # System properties
    @Property(float, notify=calculationComplete)
    def systemVoltage(self):
        return self._system_voltage
        
    @systemVoltage.setter
    def systemVoltage(self, voltage):
        if self._system_voltage != voltage and voltage > 0:
            self._system_voltage = voltage
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def systemMva(self):
        return self._system_mva
        
    @systemMva.setter
    def systemMva(self, mva):
        if self._system_mva != mva and mva > 0:
            self._system_mva = mva
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def systemXrRatio(self):
        return self._system_xr_ratio
        
    @systemXrRatio.setter
    def systemXrRatio(self, ratio):
        if self._system_xr_ratio != ratio and ratio > 0:
            self._system_xr_ratio = ratio
            self._calculate()
    
    # Transformer properties
    @Property(float, notify=calculationComplete)
    def transformerMva(self):
        return self._transformer_mva
        
    @transformerMva.setter
    def transformerMva(self, mva):
        if self._transformer_mva != mva and mva > 0:
            self._transformer_mva = mva
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def transformerZ(self):
        return self._transformer_z
        
    @transformerZ.setter
    def transformerZ(self, z):
        if self._transformer_z != z and z >= 0:
            self._transformer_z = z
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def transformerXrRatio(self):
        return self._transformer_xr_ratio
        
    @transformerXrRatio.setter
    def transformerXrRatio(self, ratio):
        if self._transformer_xr_ratio != ratio and ratio > 0:
            self._transformer_xr_ratio = ratio
            self._calculate()
    
    # Cable properties
    @Property(float, notify=calculationComplete)
    def cableLength(self):
        return self._cable_length
        
    @cableLength.setter
    def cableLength(self, length):
        if self._cable_length != length and length >= 0:
            self._cable_length = length
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def cableR(self):
        return self._cable_r
        
    @cableR.setter
    def cableR(self, r):
        if self._cable_r != r and r >= 0:
            self._cable_r = r
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def cableX(self):
        return self._cable_x
        
    @cableX.setter
    def cableX(self, x):
        if self._cable_x != x and x >= 0:
            self._cable_x = x
            self._calculate()
    
    # Fault properties
    @Property(str, notify=calculationComplete)
    def faultType(self):
        return self._fault_type
        
    @faultType.setter
    def faultType(self, fault_type):
        if self._fault_type != fault_type:
            self._fault_type = fault_type
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def faultResistance(self):
        return self._fault_resistance
        
    @faultResistance.setter
    def faultResistance(self, resistance):
        if self._fault_resistance != resistance and resistance >= 0:
            self._fault_resistance = resistance
            self._calculate()
    
    # Motor contribution properties
    @Property(bool, notify=calculationComplete)
    def includeMotors(self):
        return self._include_motors
        
    @includeMotors.setter
    def includeMotors(self, include):
        if self._include_motors != include:
            self._include_motors = include
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def motorMva(self):
        return self._motor_mva
        
    @motorMva.setter
    def motorMva(self, mva):
        if self._motor_mva != mva and mva > 0:
            self._motor_mva = mva
            self._calculate()
    
    @Property(float, notify=calculationComplete)
    def motorContributionFactor(self):
        return self._motor_contribution_factor
        
    @motorContributionFactor.setter
    def motorContributionFactor(self, factor):
        if self._motor_contribution_factor != factor and factor > 0:
            self._motor_contribution_factor = factor
            self._calculate()
    
    # Slots for receiving values from QML (keep these for backward compatibility)
    @Slot(float)
    def setSystemVoltage(self, voltage):
        self.systemVoltage = voltage
    
    @Slot(float)
    def setSystemMva(self, mva):
        self.systemMva = mva
    
    @Slot(float)
    def setSystemXrRatio(self, ratio):
        self.systemXrRatio = ratio
    
    @Slot(float)
    def setTransformerMva(self, mva):
        self.transformerMva = mva
    
    @Slot(float)
    def setTransformerZ(self, z):
        self.transformerZ = z
    
    @Slot(float)
    def setTransformerXrRatio(self, ratio):
        self.transformerXrRatio = ratio
    
    @Slot(float)
    def setCableLength(self, length):
        self.cableLength = length
    
    @Slot(float)
    def setCableR(self, r):
        self.cableR = r
    
    @Slot(float)
    def setCableX(self, x):
        self.cableX = x
    
    @Slot(str)
    def setFaultType(self, fault_type):
        self.faultType = fault_type
    
    @Slot(float)
    def setFaultResistance(self, resistance):
        self.faultResistance = resistance
    
    @Slot(bool)
    def setIncludeMotors(self, include):
        self.includeMotors = include
    
    @Slot(float)
    def setMotorMva(self, mva):
        self.motorMva = mva
    
    @Slot(float)
    def setMotorContributionFactor(self, factor):
        self.motorContributionFactor = factor
    
    # Legacy property and slot for backwards compatibility
    @Property(float, notify=calculationComplete)
    def xrRatio(self):
        return self._system_xr_ratio
    
    @xrRatio.setter
    def xrRatio(self, ratio):
        self.systemXrRatio = ratio
    
    @Slot(float)
    def setXrRatio(self, ratio):
        self.systemXrRatio = ratio
