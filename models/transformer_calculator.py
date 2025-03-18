from PySide6.QtCore import QObject, Property, Signal, Slot, QStringListModel
import math

class TransformerCalculator(QObject):
    """Calculator for transformer voltage/current relationships"""

    primaryVoltageChanged = Signal()
    secondaryVoltageChanged = Signal()
    primaryCurrentChanged = Signal()
    secondaryCurrentChanged = Signal()
    turnsRatioChanged = Signal()
    powerRatingChanged = Signal()
    efficiencyChanged = Signal()
    apparentPowerChanged = Signal()
    vectorGroupChanged = Signal()
    vectorGroupDescriptionChanged = Signal()
    correctedRatioChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._primary_voltage = 0.0
        self._secondary_voltage = 0.0
        self._primary_current = 0.0
        self._secondary_current = 0.0
        self._turns_ratio = 0.0
        self._power_rating = 0.0
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
        self._vector_group_factors = {
            "Dyn11": {"voltage": math.sqrt(3), "current": 1/math.sqrt(3)},
            "Yyn0":  {"voltage": 1, "current": 1},
            "Dyn1":  {"voltage": math.sqrt(3), "current": 1/math.sqrt(3)},
            "Yzn1":  {"voltage": 1, "current": 1},
            "Yd1":   {"voltage": 1/math.sqrt(3), "current": math.sqrt(3)},
            "Dd0":   {"voltage": 1, "current": 1},
            "Yy0":   {"voltage": 1, "current": 1}
        }

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
        if self._secondary_voltage != value and value >= 0:
            self._secondary_voltage = value
            self.secondaryVoltageChanged.emit()
            self._calculate()

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

    @Property(float, notify=powerRatingChanged)
    def powerRating(self):
        return self._power_rating

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
                
                # Recalculate the corrected ratio when vector group changes
                self._calculate_corrected_ratio()

    @Property(str, notify=vectorGroupDescriptionChanged)
    def vectorGroupDescription(self):
        return self._vector_group_description

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

    def _calculate_from_apparent_power(self):
        """Calculate currents based on apparent power (KVA)"""
        try:
            # Convert KVA to VA
            apparent_power_va = self._apparent_power * 1000  # Converting kVA to VA
            print(f"Calculating from apparent power: {self._apparent_power} kVA = {apparent_power_va} VA")
            
            # Calculate primary current if primary voltage is provided
            if self._primary_voltage > 0:
                self._primary_current = apparent_power_va / self._primary_voltage
                print(f"Primary current calculated: {self._primary_current} A from {self._apparent_power} kVA / {self._primary_voltage} V")
                self.primaryCurrentChanged.emit()
            else:
                print(f"Primary voltage is {self._primary_voltage}, can't calculate current")
                
            # Calculate secondary current if secondary voltage is provided
            if self._secondary_voltage > 0:
                self._secondary_current = apparent_power_va / self._secondary_voltage
                print(f"Secondary current calculated: {self._secondary_current} A from {self._apparent_power} kVA / {self._secondary_voltage} V")
                self.secondaryCurrentChanged.emit()
            else:
                print(f"Secondary voltage is {self._secondary_voltage}, can't calculate current")
                
            # Update power rating
            self._power_rating = apparent_power_va
            self.powerRatingChanged.emit()
            
            # If we have both voltages, recalculate the turns ratio
            if self._primary_voltage > 0 and self._secondary_voltage > 0:
                self._turns_ratio = self._primary_voltage / self._secondary_voltage
                self.turnsRatioChanged.emit()
                
                # Calculate the corrected ratio
                self._calculate_corrected_ratio()
            
        except Exception as e:
            print(f"Calculation error in kVA: {e}")

    def _calculate(self):
        """Calculate transformer parameters based on inputs"""
        try:
            # Calculate turns ratio if both voltages are available
            if self._primary_voltage > 0 and self._secondary_voltage > 0:
                self._turns_ratio = self._primary_voltage / self._secondary_voltage
                
                # Calculate secondary current based on power conservation
                if self._primary_current > 0:
                    self._secondary_current = (self._primary_current * self._primary_voltage) / self._secondary_voltage
                
                # Calculate power rating
                self._power_rating = self._primary_voltage * self._primary_current

            self.turnsRatioChanged.emit()
            self.secondaryCurrentChanged.emit()
            self.powerRatingChanged.emit()
            
            # Calculate corrected ratio if turns ratio was updated
            self._calculate_corrected_ratio()
            
        except Exception as e:
            print(f"Calculation error: {e}")

    # Slots for QML access
    @Slot(float)
    def setSecondaryVoltage(self, voltage):
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
