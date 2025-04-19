from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class MachineCalculator(QObject):
    """Calculator for electric machine characteristics"""

    # Define signals
    machineTypeChanged = Signal()
    machineTypesChanged = Signal()  # Add new signal
    ratedVoltageChanged = Signal()
    ratedCurrentChanged = Signal()
    ratedPowerChanged = Signal()
    powerFactorChanged = Signal()
    efficiencyChanged = Signal()
    lossesChanged = Signal()
    rotationalSpeedChanged = Signal()
    torqueChanged = Signal()
    slipChanged = Signal()
    resultsCalculated = Signal()
    temperatureRiseChanged = Signal()
    temperatureClassChanged = Signal()
    coolingMethodChanged = Signal()
    coolingMethodsChanged = Signal()  # Add new signal
    temperatureClassesChanged = Signal()  # Add new signal

    def __init__(self, parent=None):
        super().__init__(parent)
        # Initialize properties
        self._machine_type = "Induction Motor"  # Default machine type
        self._rated_voltage = 400.0  # V
        self._rated_current = 10.0   # A
        self._power_factor = 0.85
        self._efficiency = 0.9       # 90%
        self._rated_power = 5.0      # kW
        self._rotational_speed = 1450.0  # RPM
        self._poles = 4
        self._frequency = 50.0       # Hz
        self._slip = 0.033           # For induction motors
        self._machine_types = ["Induction Motor", "Synchronous Motor", "DC Motor", "Synchronous Generator", "DC Generator"]
        
        # Derived values
        self._torque = 0.0
        self._losses = 0.0
        
        # Add new properties
        self._temperature_rise = 0.0
        self._temperature_class = "F"  # B, F, H classes
        self._cooling_method = "TEFC"  # TEFC, ODP, TENV
        self._ambient_temp = 40.0
        self._temperature_classes = {
            "B": 130,
            "F": 155,
            "H": 180
        }
        self._cooling_methods = ["TEFC", "ODP", "TENV"]
        
        # Input mode
        self._input_mode = "VC"  # Voltage and Current input mode by default
                                 # Alternative: "VP" for Voltage and Power input
        
        # Calculate initial values
        self._calculate()
    
    def _calculate(self):
        """Calculate machine parameters based on inputs"""
        try:
            # First check input mode and calculate the missing parameter
            if self._input_mode == "VP" and self._rated_voltage > 0 and self._rated_power > 0:
                # Calculate current from power and voltage
                if "DC" in self._machine_type:
                    # DC machines: I = P/V
                    self._rated_current = (self._rated_power * 1000) / (self._rated_voltage * self._efficiency)
                else:
                    # 3-phase AC: I = P/(√3 * V * PF * efficiency)
                    self._rated_current = (self._rated_power * 1000) / (math.sqrt(3) * self._rated_voltage * self._power_factor * self._efficiency)
                self.ratedCurrentChanged.emit()

            # Input power calculation - now using the updated values
            if "DC" in self._machine_type:
                input_power = self._rated_voltage * self._rated_current / 1000  # kW for DC
            else:
                # For 3-phase AC machines
                input_power = self._rated_voltage * self._rated_current * math.sqrt(3) * self._power_factor / 1000  # kW for 3-phase
            
            # Efficiency calculations - Fixed to properly update power
            if self._machine_type.endswith("Motor"):
                # Motor: Output = Input * Efficiency
                if self._input_mode == "VC":  # Only update rated power if not directly set
                    self._rated_power = input_power * self._efficiency
                    self.ratedPowerChanged.emit()
                self._losses = input_power * (1 - self._efficiency)  # More accurate loss calculation
            else:
                # Generator: Input is mechanical power, Output is electrical
                mechanical_power = self._rated_power / self._efficiency  # Calculate mechanical input power
                self._losses = mechanical_power - self._rated_power  # Losses = input - output
            
            # Speed calculations
            if self._machine_type == "Induction Motor":
                # Synchronous speed
                sync_speed = 120 * self._frequency / self._poles
                # Actual speed based on slip
                self._rotational_speed = sync_speed * (1 - self._slip)
            elif self._machine_type == "Synchronous Motor" or self._machine_type == "Synchronous Generator":
                # Synchronous machines run at sync speed
                self._rotational_speed = 120 * self._frequency / self._poles
                self._slip = 0
            
            # Torque calculation with protection against division by zero
            if self._rotational_speed > 10:  # Prevent division by near-zero values
                self._torque = 9550 * self._rated_power / self._rotational_speed
            else:
                self._torque = 0  # Set torque to zero for very low speeds
            
            # Improved temperature rise calculation
            cooling_factor = {
                "TEFC": 1.0,
                "ODP": 1.2,
                "TENV": 0.8
            }[self._cooling_method]
            
            # More realistic thermal model that considers machine size
            # Thermal resistance decreases with machine size
            thermal_resistance = 0.05 / (0.1 + self._rated_power ** 0.7)  # °C/W
            self._temperature_rise = self._losses * 1000 * thermal_resistance * cooling_factor
            self.temperatureRiseChanged.emit()
            
            # Check if temperature rise exceeds class limit and adjust efficiency
            max_allowed_rise = self._temperature_classes[self._temperature_class] - self._ambient_temp
            
            # Avoid recalculation loops by checking significant changes
            if self._temperature_rise > max_allowed_rise:
                temp_exceed_ratio = (self._temperature_rise / max_allowed_rise) - 1
                # Cap the derating to avoid excessive reduction
                temp_exceed_ratio = min(temp_exceed_ratio, 0.5)
                new_efficiency = self._efficiency * (1 - 0.05 * temp_exceed_ratio)
                
                # Only update if efficiency would significantly change
                if abs(new_efficiency - self._efficiency) > 0.005:
                    self._efficiency = max(new_efficiency, 0.6)  # Don't let efficiency drop below 60%
                    self.efficiencyChanged.emit()
                    
                    # Recalculate once with new efficiency but don't loop
                    if self._machine_type.endswith("Motor"):
                        self._losses = input_power * (1 - self._efficiency)
                        if self._input_mode == "VC":
                            self._rated_power = input_power * self._efficiency
                    else:
                        self._losses = (self._rated_power / self._efficiency) - self._rated_power
                    
                    self.ratedPowerChanged.emit()
                    self.lossesChanged.emit()
            
            # Calculate detailed torque characteristics
            if self._machine_type == "Induction Motor":
                self._starting_torque = self._torque * 1.5
                self._breakdown_torque = self._torque * 2.5
                self._pullup_torque = self._torque * 1.8
            elif self._machine_type == "Synchronous Motor":
                self._starting_torque = self._torque * 1.0
                self._breakdown_torque = self._torque * 2.0
                self._pullup_torque = self._torque * 1.2
            else:  # DC Motors
                self._starting_torque = self._torque * 1.6
                self._breakdown_torque = self._torque * 1.6
                self._pullup_torque = self._torque * 1.6
            
            # Emit signals
            self.lossesChanged.emit()
            self.torqueChanged.emit()
            self.rotationalSpeedChanged.emit()
            self.slipChanged.emit()
            self.resultsCalculated.emit()
            
        except Exception as e:
            print(f"Error in machine calculation: {e}")
    
    # Properties and setters
    @Property(str, notify=machineTypeChanged)
    def machineType(self):
        return self._machine_type
    
    @machineType.setter
    def machineType(self, value):
        if self._machine_type != value and value in self._machine_types:
            self._machine_type = value
            self.machineTypeChanged.emit()
            self._calculate()  # Recalculate when machine type changes
    
    @Property(float, notify=ratedVoltageChanged)
    def ratedVoltage(self):
        return self._rated_voltage
    
    @ratedVoltage.setter
    def ratedVoltage(self, value):
        if self._rated_voltage != value and value > 0:
            self._rated_voltage = value
            self.ratedVoltageChanged.emit()
            self._calculate()
    
    @Property(float, notify=ratedCurrentChanged)
    def ratedCurrent(self):
        return self._rated_current
    
    @ratedCurrent.setter
    def ratedCurrent(self, value):
        if self._rated_current != value and value >= 0:
            self._rated_current = value
            self.ratedCurrentChanged.emit()
            self._calculate()
    
    @Property(float, notify=powerFactorChanged)
    def powerFactor(self):
        return self._power_factor
    
    @powerFactor.setter
    def powerFactor(self, value):
        if self._power_factor != value and 0 < value <= 1:
            self._power_factor = value
            self.powerFactorChanged.emit()
            self._calculate()
    
    @Property(float, notify=efficiencyChanged)
    def efficiency(self):
        return self._efficiency
    
    @efficiency.setter
    def efficiency(self, value):
        if self._efficiency != value and 0 < value <= 1:
            self._efficiency = value
            self.efficiencyChanged.emit()
            self._calculate()
    
    @Property(float, notify=ratedPowerChanged)
    def ratedPower(self):
        return self._rated_power
    
    @ratedPower.setter
    def ratedPower(self, value):
        if self._rated_power != value and value > 0:
            self._rated_power = value
            self.ratedPowerChanged.emit()
            self._calculate()
    
    @Property(float, notify=lossesChanged)
    def losses(self):
        return self._losses
    
    @Property(float, notify=rotationalSpeedChanged)
    def rotationalSpeed(self):
        return self._rotational_speed
    
    @rotationalSpeed.setter
    def rotationalSpeed(self, value):
        if self._rotational_speed != value and value > 0:
            self._rotational_speed = value
            # Calculate slip for induction motors
            if self._machine_type == "Induction Motor":
                sync_speed = 120 * self._frequency / self._poles
                self._slip = (sync_speed - value) / sync_speed
                self.slipChanged.emit()
            self.rotationalSpeedChanged.emit()
            self._calculate()
    
    @Property(float, notify=torqueChanged)
    def torque(self):
        return self._torque
    
    @Property(float, notify=slipChanged)
    def slip(self):
        return self._slip
    
    @slip.setter
    def slip(self, value):
        if self._slip != value and 0 <= value < 1 and self._machine_type == "Induction Motor":
            self._slip = value
            # Calculate speed
            sync_speed = 120 * self._frequency / self._poles
            self._rotational_speed = sync_speed * (1 - self._slip)
            self.slipChanged.emit()
            self.rotationalSpeedChanged.emit()
            self._calculate()
    
    @Property(int)
    def poles(self):
        return self._poles
    
    @poles.setter
    def poles(self, value):
        if self._poles != value and value > 0 and value % 2 == 0:
            self._poles = value
            self._calculate()
    
    @Property(float)
    def frequency(self):
        return self._frequency
    
    @frequency.setter
    def frequency(self, value):
        if self._frequency != value and value > 0:
            self._frequency = value
            self._calculate()
    
    @Property(list, notify=machineTypesChanged)  # Add the notify signal
    def machineTypes(self):
        return self._machine_types
    
    @Property(float, notify=temperatureRiseChanged)
    def temperatureRise(self):
        return self._temperature_rise
    
    @Property(str, notify=temperatureClassChanged)
    def temperatureClass(self):
        return self._temperature_class
    
    @temperatureClass.setter
    def temperatureClass(self, value):
        if value in self._temperature_classes and value != self._temperature_class:
            old_class = self._temperature_class
            self._temperature_class = value
            self.temperatureClassChanged.emit()
            
            # Recalculate efficiency based on temperature class
            old_max_temp = self._temperature_classes[old_class]
            new_max_temp = self._temperature_classes[value]
            
            # If moving to a lower temperature class
            if new_max_temp < old_max_temp and self._temperature_rise > (new_max_temp - self._ambient_temp):
                # Calculate efficiency derating
                allowed_rise = new_max_temp - self._ambient_temp
                temp_exceed_ratio = self._temperature_rise / allowed_rise
                efficiency_derating = 1 - 0.05 * temp_exceed_ratio
                
                # Update efficiency if it would change
                new_efficiency = self._efficiency * efficiency_derating
                if new_efficiency != self._efficiency:
                    self._efficiency = new_efficiency
                    self.efficiencyChanged.emit()
            
            # Recalculate all dependent values
            self._calculate()
    
    @Property(str)
    def coolingMethod(self):
        return self._cooling_method
    
    @coolingMethod.setter
    def coolingMethod(self, value):
        if value in self._cooling_methods:
            self._cooling_method = value
            self.coolingMethodChanged.emit()
            self._calculate()
    
    @Property(list, notify=coolingMethodsChanged)  # Add notify signal
    def coolingMethods(self):
        return self._cooling_methods
    
    @Property(list, notify=temperatureClassesChanged)
    def temperatureClasses(self):
        return list(self._temperature_classes.keys())
    
    @Property(float)
    def startingTorque(self):
        return self._starting_torque
    
    @Property(float)
    def breakdownTorque(self):
        return self._breakdown_torque
    
    @Property(float)
    def pullupTorque(self):
        return self._pullup_torque
    
    # New property for input mode
    @Property(str)
    def inputMode(self):
        return self._input_mode
    
    @inputMode.setter
    def inputMode(self, value):
        if value in ["VC", "VP"] and value != self._input_mode:
            self._input_mode = value
            self._calculate()
    
    # QML slots
    @Slot(str)
    def setMachineType(self, machine_type):
        self.machineType = machine_type
    
    @Slot(float)
    def setRatedVoltage(self, voltage):
        self.ratedVoltage = voltage
    
    @Slot(float)
    def setRatedCurrent(self, current):
        self.ratedCurrent = current
    
    @Slot(float)
    def setPowerFactor(self, pf):
        self.powerFactor = pf
    
    @Slot(float)
    def setEfficiency(self, efficiency):
        self.efficiency = efficiency
    
    @Slot(int)
    def setPoles(self, poles):
        self.poles = poles
    
    @Slot(float)
    def setFrequency(self, frequency):
        self.frequency = frequency
    
    @Slot(float)
    def setSlip(self, slip):
        self.slip = slip
    
    @Slot(float)
    def setRotationalSpeed(self, rpm):
        self.rotationalSpeed = rpm
    
    @Slot(str)
    def setTemperatureClass(self, temp_class):
        self.temperatureClass = temp_class
    
    @Slot(str)
    def setCoolingMethod(self, method):
        self.coolingMethod = method
    
    @Slot(float)
    def setRatedPower(self, power):
        self.ratedPower = power
    
    @Slot(str)
    def setInputMode(self, mode):
        self.inputMode = mode
    
    @Slot()
    def calculate(self):
        self._calculate()
