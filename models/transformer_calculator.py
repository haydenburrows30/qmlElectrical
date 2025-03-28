from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class TransformerCalculator(QObject):
    """Calculator for transformer voltage/current relationships"""

    primaryVoltageChanged = Signal()
    secondaryVoltageChanged = Signal()
    primaryCurrentChanged = Signal()
    secondaryCurrentChanged = Signal()
    turnsRatioChanged = Signal()
    efficiencyChanged = Signal()
    apparentPowerChanged = Signal()
    vectorGroupChanged = Signal()
    vectorGroupDescriptionChanged = Signal()
    correctedRatioChanged = Signal()
    
    # Add new signals for impedance properties
    impedancePercentChanged = Signal()
    resistancePercentChanged = Signal()
    reactancePercentChanged = Signal()
    shortCircuitPowerChanged = Signal()
    voltageDropChanged = Signal()
    
    # Add new signals
    copperLossesChanged = Signal()
    ironLossesChanged = Signal()
    temperatureRiseChanged = Signal()
    warningsChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._primary_voltage = 0.0
        self._secondary_voltage = 0.0
        self._primary_current = 0.0
        self._secondary_current = 0.0
        self._turns_ratio = 0.0
        self._efficiency = 95.0  # Typical efficiency
        self._apparent_power = 0.0  # KVA value
        self._vector_group = "Dyn11"
        self._vector_group_description = "Delta primary, wye secondary with 30° phase shift"
        self._corrected_ratio = 0.0
        
        # Define vector group information
        self._vector_group_descriptions = {
            "Dyn11": "Delta primary, wye secondary with 30° phase shift",
            "Yyn0": "Wye primary, wye secondary with 0° phase shift",
            "Dyn1": "Delta primary, wye secondary with -30° phase shift",
            "Yzn1": "Wye primary, zigzag secondary with -30° phase shift",
            "Yd1": "Wye primary, delta secondary with -30° phase shift",
            "Dd0": "Delta primary, delta secondary with 0° phase shift",
            "Yy0": "Wye primary, wye secondary with 0° phase shift"
        }
        
        # Voltage correction factors for different vector groups
        # For delta-wye and wye-delta connections, the voltage ratio is affected by √3
        # For Dyn11, secondary current calculation needs to be adjusted
        self._vector_group_factors = {
            "Dyn11": {"voltage": math.sqrt(3), "current": 1},  # For Dyn11, corrected current factor
            "Yyn0":  {"voltage": 1, "current": 1},
            "Dyn1":  {"voltage": math.sqrt(3), "current": 1},  # Corrected
            "Yzn1":  {"voltage": 1, "current": 1},
            "Yd1":   {"voltage": 1/math.sqrt(3), "current": math.sqrt(3)},
            "Dd0":   {"voltage": 1, "current": 1},
            "Yy0":   {"voltage": 1, "current": 1}
        }
        
        # Add impedance properties
        self._impedance_percent = 6.0  # Typical impedance for distribution transformers
        self._resistance_percent = 1.0  # Typical R% for distribution transformers
        self._reactance_percent = 5.83  # Calculated from Z% and R% (Z² = R² + X²)
        self._short_circuit_power = 0.0  # MVA
        self._voltage_drop = 0.0  # Percentage
        
        # Add copper losses property (watts)
        self._copper_losses = 0.0  # Watts

        # Add new properties
        self._iron_losses = 0.0  # No-load losses in watts
        self._temperature_rise = 0.0  # Temperature rise in Celsius
        self._warnings = []  # List of warning messages

    @Property(float, notify=primaryVoltageChanged)
    def primaryVoltage(self):
        return self._primary_voltage

    @primaryVoltage.setter
    def primaryVoltage(self, value):
        if self._primary_voltage != value and value >= 0:
            self._primary_voltage = value
            self.primaryVoltageChanged.emit()
            self._calculate()

    @Property(float, notify=secondaryVoltageChanged)
    def secondaryVoltage(self):
        return self._secondary_voltage

    @secondaryVoltage.setter
    def secondaryVoltage(self, value):
        print(f"Setting secondary voltage: {value} (current: {self._secondary_voltage})")
        # Safe comparison with tolerance for floating point
        if abs(self._secondary_voltage - value) > 0.0001 and value >= 0:
            self._secondary_voltage = value
            self.secondaryVoltageChanged.emit()
            self._calculate()
        elif value < 0:
            print("Warning: Attempted to set negative secondary voltage")

    @Property(float, notify=primaryCurrentChanged)
    def primaryCurrent(self):
        return self._primary_current

    @primaryCurrent.setter
    def primaryCurrent(self, value):
        if self._primary_current != value and value >= 0:
            self._primary_current = value
            self.primaryCurrentChanged.emit()
            self._calculate()

    @Property(float, notify=secondaryCurrentChanged)
    def secondaryCurrent(self):
        return self._secondary_current

    @Property(float, notify=turnsRatioChanged)
    def turnsRatio(self):
        return self._turns_ratio

    @Property(float, notify=efficiencyChanged)
    def efficiency(self):
        return self._efficiency

    @Property(float, notify=apparentPowerChanged)
    def apparentPower(self):
        return self._apparent_power

    @apparentPower.setter
    def apparentPower(self, value):
        if self._apparent_power != value and value >= 0:
            self._apparent_power = value
            self.apparentPowerChanged.emit()
            self._calculate_from_apparent_power()

    @Property(float, notify=correctedRatioChanged)
    def correctedRatio(self):
        return self._corrected_ratio

    @Property(str, notify=vectorGroupChanged)
    def vectorGroup(self):
        return self._vector_group

    @vectorGroup.setter
    def vectorGroup(self, value):
        if value in self._vector_group_descriptions:
            if self._vector_group != value:
                self._vector_group = value
                self._vector_group_description = self._vector_group_descriptions.get(value, "")
                self.vectorGroupChanged.emit()
                self.vectorGroupDescriptionChanged.emit()
                
                # Recalculate the corrected ratio AND secondary current when vector group changes
                self._calculate_corrected_ratio()
                
                # If we have the right conditions, also recalculate the secondary current
                self._apply_vector_group_current_correction()

    @Property(str, notify=vectorGroupDescriptionChanged)
    def vectorGroupDescription(self):
        return self._vector_group_description

    @Property(float, notify=impedancePercentChanged)
    def impedancePercent(self):
        return self._impedance_percent

    @impedancePercent.setter
    def impedancePercent(self, value):
        if self._impedance_percent != value and value >= 0:
            self._impedance_percent = value
            self.impedancePercentChanged.emit()
            
            # Update reactance based on Z² = R² + X²
            if self._impedance_percent >= self._resistance_percent:
                self._reactance_percent = math.sqrt(self._impedance_percent**2 - self._resistance_percent**2)
                self.reactancePercentChanged.emit()
            
            self._calculate_impedance_parameters()

    @Property(float, notify=resistancePercentChanged)
    def resistancePercent(self):
        return self._resistance_percent

    @resistancePercent.setter
    def resistancePercent(self, value):
        if self._resistance_percent != value and value >= 0:
            self._resistance_percent = value
            self.resistancePercentChanged.emit()
            
            # Update reactance based on Z² = R² + X²
            if self._impedance_percent >= self._resistance_percent:
                self._reactance_percent = math.sqrt(self._impedance_percent**2 - self._resistance_percent**2)
                self.reactancePercentChanged.emit()
            
            self._calculate_impedance_parameters()

    @Property(float, notify=reactancePercentChanged)
    def reactancePercent(self):
        return self._reactance_percent

    @Property(float, notify=shortCircuitPowerChanged)
    def shortCircuitPower(self):
        return self._short_circuit_power

    @Property(float, notify=voltageDropChanged)
    def voltageDrop(self):
        return self._voltage_drop

    @Property(float, notify=copperLossesChanged)
    def copperLosses(self):
        return self._copper_losses

    @copperLosses.setter
    def copperLosses(self, value):
        if self._copper_losses != value and value >= 0:
            self._copper_losses = value
            self.copperLossesChanged.emit()
            
            # Calculate resistance percentage from copper losses if we have rated power
            if self._apparent_power > 0:
                # R% = (Copper Losses × 100) / (Rated kVA × 1000)
                self._resistance_percent = (self._copper_losses * 100) / (self._apparent_power * 1000)
                self.resistancePercentChanged.emit()
                
                # Update reactance based on Z² = R² + X²
                if self._impedance_percent >= self._resistance_percent:
                    self._reactance_percent = math.sqrt(self._impedance_percent**2 - self._resistance_percent**2)
                    self.reactancePercentChanged.emit()
                
                self._calculate_impedance_parameters()

    @Property(float, notify=ironLossesChanged)
    def ironLosses(self):
        return self._iron_losses
        
    @ironLosses.setter
    def ironLosses(self, value):
        if self._iron_losses != value and value >= 0:
            self._iron_losses = value
            self.ironLossesChanged.emit()
            self._calculate_efficiency()

    @Property(float, notify=temperatureRiseChanged)
    def temperatureRise(self):
        return self._temperature_rise
        
    @Property('QVariantList', notify=warningsChanged)
    def warnings(self):
        return self._warnings

    def _calculate_corrected_ratio(self):
        """Calculate turns ratio corrected for vector group"""
        try:
            if self._turns_ratio > 0:
                factor = self._vector_group_factors.get(self._vector_group, {"voltage": 1})["voltage"]
                old_ratio = self._corrected_ratio
                self._corrected_ratio = self._turns_ratio * factor
                print(f"Corrected ratio: {self._corrected_ratio} = {self._turns_ratio} × {factor} (for {self._vector_group})")
                
                # Only emit if the value actually changed (with a small tolerance for floating point errors)
                if abs(old_ratio - self._corrected_ratio) > 0.0001:
                    self.correctedRatioChanged.emit()
            else:
                # Reset corrected ratio if turns ratio is invalid
                if self._corrected_ratio != 0:
                    self._corrected_ratio = 0
                    self.correctedRatioChanged.emit()
        except Exception as e:
            print(f"Error calculating corrected ratio: {e}")

    def _apply_vector_group_current_correction(self):
        """Apply vector group current correction factor to secondary current"""
        if self._primary_current > 0 and self._primary_voltage > 0 and self._secondary_voltage > 0:
            # For a Dyn11 configuration (and similar D-Y configs), handle secondary current differently
            if self._vector_group in ["Dyn11", "Dyn1"] or (self._vector_group[0] == "D" and self._vector_group[1].lower() == "y"):
                # For delta-wye configurations, secondary current calculation is direct
                # using S = √3 × V_line × I_line for both sides
                self._secondary_current = self._apparent_power * 1000 / (math.sqrt(3) * self._secondary_voltage)
            else:
                # Get the current correction factor for this vector group
                factor = self._vector_group_factors.get(self._vector_group, {"current": 1})["current"]
                
                # Calculate the base secondary current using conservation of power
                base_secondary_current = (self._primary_current * self._primary_voltage) / self._secondary_voltage
                
                # Apply vector group correction factor to secondary current
                self._secondary_current = base_secondary_current * factor
            
            print(f"Secondary current with vector group correction ({self._vector_group}): {self._secondary_current} A")
            self.secondaryCurrentChanged.emit()

    def _calculate_from_apparent_power(self):
        """
        Calculate currents based on apparent power (KVA).
        
        Note: Using 3-phase line-to-line (phase-phase) voltages for calculations.
        """
        try:
            # Convert KVA to VA (this is 3-phase total apparent power)
            apparent_power_va = self._apparent_power * 1000  # Converting kVA to VA
            print(f"Calculating from 3-phase apparent power: {self._apparent_power} kVA = {apparent_power_va} VA")
            
            # Calculate primary current if primary voltage is provided
            # For 3-phase balanced system: I = S / (√3 × V_line)
            if self._primary_voltage > 0:
                self._primary_current = apparent_power_va / (math.sqrt(3) * self._primary_voltage)
                print(f"Primary current calculated: {self._primary_current} A from {self._apparent_power} kVA / (√3 × {self._primary_voltage} V)")
                self.primaryCurrentChanged.emit()
            else:
                print(f"Primary voltage is {self._primary_voltage}, can't calculate current")
                
            # Calculate secondary current if secondary voltage is provided
            # For Dyn11 and similar vector groups, the LV side needs direct calculation:
            if self._secondary_voltage > 0:
                if self._vector_group in ["Dyn11", "Dyn1"] or (self._vector_group[0] == "D" and self._vector_group[1].lower() == "y"):
                    # For delta-wye, secondary is wye connected, so S/(√3 × V_line) gives the correct current
                    self._secondary_current = apparent_power_va / (math.sqrt(3) * self._secondary_voltage)
                elif self._vector_group[0].upper() == "Y" and self._vector_group[1].lower() == "d":
                    # For wye-delta secondary currents
                    self._secondary_current = apparent_power_va / (math.sqrt(3) * self._secondary_voltage) * math.sqrt(3)
                else:
                    # Default calculation
                    self._secondary_current = apparent_power_va / (math.sqrt(3) * self._secondary_voltage)
                    
                print(f"Secondary current calculated: {self._secondary_current} A from {self._apparent_power} kVA / (√3 × {self._secondary_voltage} V)")
                self.secondaryCurrentChanged.emit()
            else:
                print(f"Secondary voltage is {self._secondary_voltage}, can't calculate current")
                
            # If we have both voltages, recalculate the turns ratio
            if self._primary_voltage > 0 and self._secondary_voltage > 0:
                self._turns_ratio = self._primary_voltage / self._secondary_voltage
                self.turnsRatioChanged.emit()
                
                # Calculate the corrected ratio
                self._calculate_corrected_ratio()
                
                # Apply vector group correction to secondary current
                self._apply_vector_group_current_correction()
            
        except Exception as e:
            print(f"Calculation error in kVA: {e}")

    def _calculate(self):
        """
        Calculate transformer parameters based on inputs.
        
        Note: All voltage values are assumed to be 3-phase line-to-line (phase-phase) values
        for both primary and secondary sides.
        """
        try:
            # Calculate turns ratio if both voltages are available (using line-to-line voltages)
            if self._primary_voltage > 0 and self._secondary_voltage > 0:
                self._turns_ratio = self._primary_voltage / self._secondary_voltage
                
                # Calculate secondary current based on power conservation including vector group correction
                if self._primary_current > 0:
                    # The base relation between currents is modified by the vector group
                    factor = self._vector_group_factors.get(self._vector_group, {"current": 1})["current"]
                    base_secondary_current = (self._primary_current * self._primary_voltage) / self._secondary_voltage
                    self._secondary_current = base_secondary_current * factor

            self.turnsRatioChanged.emit()
            self.secondaryCurrentChanged.emit()
            
            # Calculate corrected ratio if turns ratio was updated
            self._calculate_corrected_ratio()
            
            # Also calculate impedance parameters
            self._calculate_impedance_parameters()
            
        except Exception as e:
            print(f"Calculation error: {e}")

    def _calculate_impedance_parameters(self):
        """Calculate transformer parameters related to impedance"""
        try:
            # Calculate short-circuit power MVA based on Z%
            if self._impedance_percent > 0 and self._apparent_power > 0:
                self._short_circuit_power = (100.0 / self._impedance_percent) * self._apparent_power / 1000.0  # MVA
                self.shortCircuitPowerChanged.emit()
            
            # Calculate voltage drop at rated current
            # VD% = IR×cosΦ + IX×sinΦ (assume power factor = 0.8)
            if self._impedance_percent > 0:
                power_factor = 0.8
                sin_phi = math.sqrt(1 - power_factor**2)
                self._voltage_drop = self._resistance_percent * power_factor + self._reactance_percent * sin_phi
                self.voltageDropChanged.emit()
        
        except Exception as e:
            print(f"Error calculating impedance parameters: {e}")

    def _calculate_efficiency(self):
        """Calculate transformer efficiency under load"""
        if self._apparent_power > 0:
            total_losses = self._iron_losses + self._copper_losses
            input_power = self._apparent_power * 1000 * 0.8  # Assuming 0.8 power factor
            if input_power > total_losses:
                self._efficiency = ((input_power - total_losses) / input_power) * 100
                self.efficiencyChanged.emit()

    def _calculate_temperature_rise(self):
        """Estimate temperature rise based on losses"""
        if self._apparent_power > 0:
            # Simplified estimation based on typical values
            self._temperature_rise = (self._copper_losses / (self._apparent_power * 10)) + 35
            self.temperatureRiseChanged.emit()

    def _validate_parameters(self):
        """Validate parameters and generate warnings"""
        self._warnings = []
        
        if self._impedance_percent < 3:
            self._warnings.append("Low impedance may result in high fault currents")
        if self._impedance_percent > 8:
            self._warnings.append("High impedance may cause excessive voltage drop")
            
        if self._efficiency < 90:
            self._warnings.append("Unusually low efficiency detected")
            
        if self._temperature_rise > 65:
            self._warnings.append("High temperature rise may reduce transformer life")
            
        self.warningsChanged.emit()

    # Helper methods for three-phase calculations
    def _line_to_phase_voltage(self, line_voltage):
        """Convert line-to-line voltage to phase voltage in a 3-phase system"""
        return line_voltage / math.sqrt(3)
        
    def _phase_to_line_voltage(self, phase_voltage):
        """Convert phase voltage to line-to-line voltage in a 3-phase system"""
        return phase_voltage * math.sqrt(3)

    # Slots for QML access
    @Slot(float)
    def setSecondaryVoltage(self, voltage):
        print(f"setSecondaryVoltage slot called with: {voltage}")
        self.secondaryVoltage = voltage

    @Slot(float)
    def setPrimaryCurrent(self, current):
        self.primaryCurrent = current

    @Slot(float)
    def setApparentPower(self, power):
        print(f"Setting kVA to: {power}, PV: {self._primary_voltage}, SV: {self._secondary_voltage}")
        if power >= 0:
            self._apparent_power = power
            self.apparentPowerChanged.emit()
            self._calculate_from_apparent_power()
        else:
            self._apparent_power = 0
            self.apparentPowerChanged.emit()

    @Slot(str)
    def setVectorGroup(self, vector_group):
        print(f"Setting vector group to: {vector_group}")
        old_group = self._vector_group
        self.vectorGroup = vector_group
        
        # Force recalculation if vector group changed but signal wasn't emitted
        # This can happen if vectorGroup setter doesn't detect a change
        if old_group == self._vector_group and self._turns_ratio > 0:
            self._calculate_corrected_ratio()

    # Add new slots for QML access
    @Slot(float)
    def setImpedancePercent(self, value):
        self.impedancePercent = value

    @Slot(float)
    def setResistancePercent(self, value):
        self.resistancePercent = value

    # Add new slot
    @Slot(float)
    def setCopperLosses(self, value):
        self.copperLosses = value

    @Slot(float)
    def setIronLosses(self, value):
        self.ironLosses = value
