from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class MotorCalculator(QObject):
    """Calculator for motor starting characteristics"""

    # Define signals
    motorPowerChanged = Signal()
    voltageChanged = Signal()
    efficiencyChanged = Signal()
    powerFactorChanged = Signal()
    startingMethodChanged = Signal()
    startingCurrentChanged = Signal()
    startingTorqueChanged = Signal()
    resultsCalculated = Signal()
    startingMultiplierChanged = Signal()
    nominalTorqueChanged = Signal()
    motorTypeChanged = Signal()
    motorSpeedChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        # Initialize properties
        self._motor_power = 0.0  # kW
        self._voltage = 400.0    # V
        self._efficiency = 0.85  # 85%
        self._power_factor = 0.8 # 0.8
        self._starting_method = "DOL"
        self._starting_current = 0.0
        self._starting_torque = 0.0
        self._nominal_torque = 0.0
        self._full_load_current = 0.0
        self._starting_methods = ["DOL", "Star-Delta", "Soft Starter", "VFD"]
        self._debug = False
        
        # Motor types
        self._motor_type = "Induction Motor"
        self._motor_types = [
            "Induction Motor", 
            "Synchronous Motor", 
            "Wound Rotor Motor",
            "Permanent Magnet Motor",
            "Single Phase Motor"
        ]
        
        # Starting current multipliers for different methods and motor types
        self._current_multipliers = {
            "Induction Motor": {
                "DOL": 6.0,
                "Star-Delta": 2.0,
                "Soft Starter": 3.0,
                "VFD": 1.0
            },
            "Synchronous Motor": {
                "DOL": 5.0,
                "Star-Delta": 1.8,
                "Soft Starter": 2.5,
                "VFD": 1.0
            },
            "Wound Rotor Motor": {
                "DOL": 4.0,
                "Star-Delta": 1.6,
                "Soft Starter": 2.0,
                "VFD": 1.0
            },
            "Permanent Magnet Motor": {
                "DOL": 8.0,
                "Star-Delta": 3.0,
                "Soft Starter": 4.0,
                "VFD": 1.2
            },
            "Single Phase Motor": {
                "DOL": 7.0,
                "Star-Delta": 0.0,  # Not applicable
                "Soft Starter": 3.5,
                "VFD": 1.2
            }
        }
        
        # Starting torque multipliers for different methods and motor types
        self._torque_multipliers = {
            "Induction Motor": {
                "DOL": 1.0,
                "Star-Delta": 0.33,
                "Soft Starter": 0.5,
                "VFD": 1.5
            },
            "Synchronous Motor": {
                "DOL": 0.8,
                "Star-Delta": 0.3,
                "Soft Starter": 0.4,
                "VFD": 1.2
            },
            "Wound Rotor Motor": {
                "DOL": 1.2,
                "Star-Delta": 0.4,
                "Soft Starter": 0.6,
                "VFD": 1.5
            },
            "Permanent Magnet Motor": {
                "DOL": 1.5,
                "Star-Delta": 0.5,
                "Soft Starter": 0.7,
                "VFD": 1.8
            },
            "Single Phase Motor": {
                "DOL": 0.7,
                "Star-Delta": 0.0,  # Not applicable
                "Soft Starter": 0.4,
                "VFD": 1.0
            }
        }
        
        # Motor characteristics
        self._motor_characteristics = {
            "Induction Motor": {
                "efficiency_range": (0.75, 0.95),
                "power_factor_range": (0.7, 0.9),
                "description": "The most common type of AC motor. Simple, rugged design with a squirrel-cage rotor. "
            },
            "Synchronous Motor": {
                "efficiency_range": (0.85, 0.97),
                "power_factor_range": (0.8, 1.0),
                "description": "Runs at synchronous speed, can be used for power factor correction"
            },
            "Wound Rotor Motor": {
                "efficiency_range": (0.7, 0.92),
                "power_factor_range": (0.65, 0.85),
                "description": "Has rotor windings brought out via slip rings, allowing external resistance"
            },
            "Permanent Magnet Motor": {
                "efficiency_range": (0.9, 0.98),
                "power_factor_range": (0.85, 0.95),
                "description": "High efficiency motor using permanent magnets instead of rotor windings"
            },
            "Single Phase Motor": {
                "efficiency_range": (0.6, 0.85),
                "power_factor_range": (0.6, 0.8),
                "description": "Used for residential and light commercial applications"
            }
        }
        
        # Standard motor speeds based on frequency and poles
        self._motor_speeds = {
            "2 Pole (50 Hz)": 3000,
            "4 Pole (50 Hz)": 1500,
            "6 Pole (50 Hz)": 1000,
            "8 Pole (50 Hz)": 750,
            "2 Pole (60 Hz)": 3600,
            "4 Pole (60 Hz)": 1800,
            "6 Pole (60 Hz)": 1200,
            "8 Pole (60 Hz)": 900
        }
        
        self._motor_speed = 1500  # Default to 4 pole 50Hz
        
        # Applicable starting methods for each motor type
        self._applicable_methods = {
            "Induction Motor": ["DOL", "Star-Delta", "Soft Starter", "VFD"],
            "Synchronous Motor": ["DOL", "Soft Starter", "VFD"],
            "Wound Rotor Motor": ["DOL", "Soft Starter", "VFD"],
            "Permanent Magnet Motor": ["DOL", "Soft Starter", "VFD"],
            "Single Phase Motor": ["DOL", "Soft Starter", "VFD"]
        }

        # Add additional properties to support new features
        self._starting_duration = 5.0  # Default starting duration in seconds
        self._ambient_temperature = 25.0  # Default ambient temperature in °C
        self._duty_cycle = "S1 (Continuous)"  # Default duty cycle

    def _calculate(self):
        """Calculate starting current and torque based on inputs"""
        try:
            # Input validation
            if self._motor_power <= 0 or self._voltage <= 0 or self._efficiency <= 0 or self._power_factor <= 0:
                print("Invalid input parameters detected")
                return
                
            # Convert motor power to VA
            motor_va = self._motor_power * 1000 / (self._efficiency * self._power_factor)
            
            # Calculate full load current
            self._full_load_current = motor_va / (math.sqrt(3) * self._voltage)
            
            # Get multiplier for the current motor type and starting method
            multiplier = self._current_multipliers.get(self._motor_type, {}).get(self._starting_method, 6.0)
            self._starting_current = self._full_load_current * multiplier
            
            # Calculate nominal torque (Nm)
            self._nominal_torque = (9.55 * self._motor_power * 1000) / self._motor_speed
            
            # Get torque multiplier for the current motor type and starting method
            torque_multiplier = self._torque_multipliers.get(self._motor_type, {}).get(self._starting_method, 1.0)
            # Store the torque multiplier directly (since QML displays it as percentage)
            self._starting_torque = torque_multiplier
            
            # Emit signals for UI update
            self.startingCurrentChanged.emit()
            self.startingTorqueChanged.emit()
            self.nominalTorqueChanged.emit()
            self.resultsCalculated.emit()
        except ZeroDivisionError as e:
            print(f"Division by zero error: {e}")
            # Clear results to avoid displaying incorrect values
            self._full_load_current = 0.0
            self._starting_current = 0.0
            self._nominal_torque = 0.0
            self._starting_torque = 0.0
        except Exception as e:
            print(f"Error in calculation: {e}")
            # Initialize values to avoid undefined states
            self._full_load_current = 0.0
            self._starting_current = 0.0
            self._nominal_torque = 0.0
            self._starting_torque = 0.0

    # Property getters and setters
    @Property(float, notify=motorPowerChanged)
    def motorPower(self):
        return self._motor_power
    
    @motorPower.setter
    def motorPower(self, value):
        if self._motor_power != value and value >= 0:
            self._motor_power = value
            self.motorPowerChanged.emit()
            self._calculate()
    
    @Property(float, notify=voltageChanged)
    def voltage(self):
        return self._voltage
    
    @voltage.setter
    def voltage(self, value):
        if self._voltage != value and value > 0:
            self._voltage = value
            self.voltageChanged.emit()
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
    
    @Property(float, notify=powerFactorChanged)
    def powerFactor(self):
        return self._power_factor
    
    @powerFactor.setter
    def powerFactor(self, value):
        if self._power_factor != value and 0 < value <= 1:
            self._power_factor = value
            self.powerFactorChanged.emit()
            self._calculate()
    
    @Property(str, notify=startingMethodChanged)
    def startingMethod(self):
        return self._starting_method

    @Property(float, notify=startingCurrentChanged)
    def startingCurrent(self):
        return self._starting_current
    
    @Property(float, notify=startingTorqueChanged)
    def startingTorque(self):
        return self._starting_torque
    
    @Property(float, notify=nominalTorqueChanged)
    def nominalTorque(self):
        return self._nominal_torque
    
    @Property(float)
    def fullLoadCurrent(self):
        return self._full_load_current
    
    @Property(float, notify=startingMultiplierChanged)
    def startingMultiplier(self):
        return self._current_multipliers.get(self._motor_type, {}).get(self._starting_method, 6.0)
    
    @Property(list)
    def startingMethods(self):
        return self._starting_methods

    @Property(str, notify=motorTypeChanged)
    def motorType(self):
        return self._motor_type
    
    @motorType.setter
    def motorType(self, value):
        if self._motor_type != value and value in self._motor_types:
            self._motor_type = value
            
            # Update applicable starting methods
            self._starting_methods = self._applicable_methods.get(value, ["DOL", "VFD"])
            
            # If current method is not applicable to new motor type, default to DOL
            if self._starting_method not in self._starting_methods:
                self._starting_method = "DOL"
                self.startingMethodChanged.emit()
            
            # Suggest appropriate efficiency and power factor for this motor type
            char = self._motor_characteristics.get(value, {})
            eff_range = char.get("efficiency_range", (0.7, 0.9))
            pf_range = char.get("power_factor_range", (0.7, 0.9))
            
            # Use default values from the range
            self._efficiency = (eff_range[0] + eff_range[1]) / 2
            self._power_factor = (pf_range[0] + pf_range[1]) / 2
            
            self.efficiencyChanged.emit()
            self.powerFactorChanged.emit()
            self.motorTypeChanged.emit()
            self.startingMultiplierChanged.emit()
            self._calculate()
    
    @Property(int, notify=motorSpeedChanged)
    def motorSpeed(self):
        return self._motor_speed
    
    @motorSpeed.setter
    def motorSpeed(self, value):
        if self._motor_speed != value and value > 0:
            self._motor_speed = value
            self.motorSpeedChanged.emit()
            self._calculate()
            
    @Property(list)
    def motorTypes(self):
        return self._motor_types
    
    @Property(str)
    def motorDescription(self):
        return self._motor_characteristics.get(self._motor_type, {}).get("description", "")
    
    @Property(float)
    def startingDuration(self):
        return self._starting_duration
        
    @startingDuration.setter
    def startingDuration(self, value):
        if self._starting_duration != value and value > 0:
            self._starting_duration = value
            # No need for a signal as this doesn't directly affect main calculations
            
    @Property(float)
    def ambientTemperature(self):
        return self._ambient_temperature
        
    @ambientTemperature.setter
    def ambientTemperature(self, value):
        if self._ambient_temperature != value:
            self._ambient_temperature = value
    
    @Property(str)
    def dutyCycle(self):
        return self._duty_cycle
        
    @dutyCycle.setter
    def dutyCycle(self, value):
        if self._duty_cycle != value:
            self._duty_cycle = value
        
    # QML slots
    @Slot(float)
    def setMotorPower(self, power):
        self.motorPower = power
        
    @Slot(float)
    def setVoltage(self, voltage):
        self.voltage = voltage
        
    @Slot(float)
    def setEfficiency(self, efficiency):
        self.efficiency = efficiency
        
    @Slot(float)
    def setPowerFactor(self, pf):
        self.powerFactor = pf
    
    @Slot(str)
    def setStartingMethod(self, method):
        """Set the starting method with proper validation - avoid recursive call"""
        if method in self._starting_methods:
            if self._starting_method != method:
                # Directly set the property instead of calling self.startingMethod = method
                self._starting_method = method
                self.startingMethodChanged.emit()
                # Emit the multiplier changed signal since it depends on the method
                self.startingMultiplierChanged.emit()
                self._calculate()
        else:
            print(f"Warning: Attempted to set invalid starting method: {method}")
        
    @Slot(int)
    def setMotorSpeed(self, rpm):
        if rpm > 0 and self._motor_speed != rpm:
            self._motor_speed = rpm
            self._calculate()
    
    @Slot(str)
    def setMotorType(self, motor_type):
        self.motorType = motor_type
    
    @Slot(str, result=bool)
    def isMethodApplicable(self, method):
        """Check if a starting method is applicable to the current motor type"""
        applicable = self._applicable_methods.get(self._motor_type, ["DOL"])
        return method in applicable
    
    @Slot(bool)
    def setDebug(self, enable):
        self._debug = enable
        
    @Slot(result=dict)
    def getMotorSpeedOptions(self):
        """Return the available motor speed options"""
        return self._motor_speeds
        
    @Slot(str, result=bool)
    def exportResults(self, filePath):
        """Export the calculation results to a CSV file"""
        try:
            # Always print the file path for debugging
            print(f"Attempting to export to: '{filePath}'")
            
            # Handle Qt URL format if it wasn't handled on the QML side
            if filePath.startswith("file://"):
                filePath = filePath.replace("file://", "")
            
            # Ensure the directory exists
            import os
            directory = os.path.dirname(filePath)
            if directory and not os.path.exists(directory):
                try:
                    os.makedirs(directory)
                    print(f"Created directory: {directory}")
                except Exception as e:
                    print(f"Error creating directory: {e}")
            
            # Print the absolute path for easier debugging
            abs_path = os.path.abspath(filePath)
            print(f"Absolute path: {abs_path}")
            
            with open(filePath, 'w') as f:
                f.write("Motor Starting Calculator Results\n")
                f.write(f"Motor Type,{self._motor_type}\n")
                f.write(f"Motor Power (kW),{self._motor_power}\n")
                f.write(f"Voltage (V),{self._voltage}\n")
                f.write(f"Efficiency,{self._efficiency}\n")
                f.write(f"Power Factor,{self._power_factor}\n")
                f.write(f"Starting Method,{self._starting_method}\n")
                f.write(f"Full Load Current (A),{self._full_load_current:.2f}\n")
                f.write(f"Starting Current (A),{self._starting_current:.2f}\n")
                f.write(f"Starting Current Multiplier,{self.startingMultiplier:.2f}\n")
                f.write(f"Nominal Torque (Nm),{self._nominal_torque:.2f}\n")
                f.write(f"Starting Torque (% FLT),{self._starting_torque*100:.1f}\n")
            
            # Print success message with the absolute path
            print(f"Successfully exported to: '{abs_path}'")
            return True
        except Exception as e:
            print(f"Error exporting results: {e}")
            return False

    @Slot(float)
    def setStartingDuration(self, duration):
        self.startingDuration = duration
    
    @Slot(float)
    def setAmbientTemperature(self, temp):
        self.ambientTemperature = temp
    
    @Slot(str)
    def setDutyCycle(self, cycle):
        self.dutyCycle = cycle
    
    @Slot(result=float)
    def estimateTemperatureRise(self):
        """Calculate estimated temperature rise during motor starting"""
        try:
            if self._starting_current <= 0:
                return 0.0
                
            # Get current multiplier for this motor/method combination
            multiplier = self._current_multipliers.get(self._motor_type, {}).get(self._starting_method, 6.0)
            flc = self._starting_current / multiplier
            
            # Calculate heat generated based on I²t principle
            heatGenerated = pow(self._starting_current / flc, 2) * self._starting_duration
            
            # Apply thermal coefficient based on motor type
            thermalFactor = {
                "Induction Motor": 1.0,
                "Synchronous Motor": 0.9,
                "Wound Rotor Motor": 0.8,
                "Permanent Magnet Motor": 0.7,
                "Single Phase Motor": 1.2
            }.get(self._motor_type, 1.0)
            
            # Apply duty cycle factor
            dutyCycleFactor = 1.0
            if "Intermittent" in self._duty_cycle:
                dutyCycleFactor = 0.8
            elif "Short-time" in self._duty_cycle:
                dutyCycleFactor = 0.9
                
            # Calculate temperature rise with factors
            tempRise = heatGenerated * 0.1 * thermalFactor * dutyCycleFactor
            
            # Limit to realistic values based on insulation class
            return min(tempRise, 140)
        except Exception as e:
            print(f"Error calculating temperature rise: {e}")
            return 0.0
    
    @Slot(result=str)
    def getTemperatureRiseLevel(self):
        """Get qualitative assessment of temperature rise"""
        tempRise = self.estimateTemperatureRise()
        if tempRise < 40:
            return "normal"
        elif tempRise < 80:
            return "warning"
        else:
            return "critical"
    
    @Slot(result=str)
    def recommendCableSize(self):
        """Recommend minimum cable size based on motor full load current"""
        try:
            if self._starting_current <= 0:
                return "N/A"
            
            # Get current multiplier for this motor/method combination
            multiplier = self._current_multipliers.get(self._motor_type, {}).get(self._starting_method, 6.0)
            flc = self._starting_current / multiplier
            
            # Standard cable sizing based on current carrying capacity
            if flc <= 10:
                return "1.5 mm²"
            elif flc <= 16:
                return "2.5 mm²"
            elif flc <= 25:
                return "4 mm²"
            elif flc <= 32:
                return "6 mm²"
            elif flc <= 50:
                return "10 mm²"
            elif flc <= 63:
                return "16 mm²"
            elif flc <= 80:
                return "25 mm²"
            elif flc <= 100:
                return "35 mm²"
            elif flc <= 125:
                return "50 mm²"
            elif flc <= 160:
                return "70 mm²"
            elif flc <= 200:
                return "95 mm²"
            elif flc <= 250:
                return "120 mm²"
            else:
                return "150 mm² or larger"
        except Exception as e:
            print(f"Error recommending cable size: {e}")
            return "N/A"

    @Slot(result=float)
    def estimateStartDuration(self):
        """Estimate the motor starting duration based on current parameters"""
        try:
            # Simple estimation based on motor type and starting method
            base_duration = self._starting_duration
            
            # Adjust based on motor type
            motor_type_factor = {
                "Induction Motor": 1.0,
                "Synchronous Motor": 1.2,
                "Wound Rotor Motor": 0.8,
                "Permanent Magnet Motor": 0.7,
                "Single Phase Motor": 1.1
            }
            
            # Adjust based on starting method
            method_factor = {
                "DOL": 0.8,
                "Star-Delta": 1.5,
                "Soft Starter": 1.2,
                "VFD": 1.1
            }
            
            type_multiplier = motor_type_factor.get(self._motor_type, 1.0)
            method_multiplier = method_factor.get(self._starting_method, 1.0)
            
            # Final estimate considering motor power (larger motors take longer)
            power_factor = 1.0 + (self._motor_power / 100.0)  # Slight increase for larger motors
            
            return base_duration * type_multiplier * method_multiplier * power_factor
        except Exception as e:
            print(f"Error estimating start duration: {e}")
            return self._starting_duration  # Return default if calculation fails
    
    @Slot(result=float)
    def calculateStartingEnergy(self):
        """Calculate energy used during motor starting in kWh"""
        try:
            if self._starting_current <= 0:
                return 0.0
                
            # Get duration from estimate or use default
            duration = self.estimateStartDuration()
            
            # Calculate energy based on starting current, voltage, and power factor
            # Convert to kWh (I * V * √3 * PF * hours / 1000)
            energy_kWh = (self._starting_current * self._voltage * math.sqrt(3) * 
                          self._power_factor * (duration / 3600)) / 1000
                          
            # For VFD, energy usage is typically lower due to controlled ramp
            if self._starting_method == "VFD":
                energy_kWh *= 0.6  # 60% of DOL energy usage
            elif self._starting_method == "Soft Starter":
                energy_kWh *= 0.8  # 80% of DOL energy usage
                
            return energy_kWh
        except Exception as e:
            print(f"Error calculating starting energy: {e}")
            return 0.0
    
    @Slot(result=str)
    def getStartingRecommendations(self):
        """Generate recommendations based on current motor parameters"""
        try:
            recommendations = []
            
            # Base recommendations by motor type
            motor_type_recommendations = {
                "Induction Motor": "Standard induction motors are robust and suitable for most applications.",
                "Synchronous Motor": "Synchronous motors require field excitation control during starting.",
                "Wound Rotor Motor": "Wound rotor motors allow for customizable starting characteristics.",
                "Permanent Magnet Motor": "PM motors must use VFD control - never use DOL starting!",
                "Single Phase Motor": "Single phase motors are suitable for small residential applications."
            }
            
            if self._motor_type in motor_type_recommendations:
                recommendations.append(motor_type_recommendations[self._motor_type])
            
            # Starting method recommendations
            method_recommendations = {
                "DOL": "DOL starting creates high inrush current. Consider using soft starter if supply is limited.",
                "Star-Delta": "Star-Delta reduces starting current to about 33% of DOL values.",
                "Soft Starter": "Set ramp time according to load characteristics (typically 2-10 seconds).",
                "VFD": "VFDs offer the best control but consider harmonics filtering."
            }
            
            if self._starting_method in method_recommendations:
                recommendations.append(method_recommendations[self._starting_method])
            
            # Power-specific recommendations
            if self._motor_power > 30 and self._starting_method == "DOL":
                recommendations.append("For motors > 30kW, star-delta or soft starting is often preferred due to utility restrictions.")
            
            # Protection recommendations
            if self._starting_current > 200:
                recommendations.append("High starting current may cause significant voltage drop. Check supply capacity.")
            
            # Cable sizing recommendation
            flc = self._starting_current / self._current_multipliers.get(self._motor_type, {}).get(self._starting_method, 6.0)
            cable_size = "Standard"
            
            if flc <= 10:
                cable_size = "1.5 mm²"
            elif flc <= 16:
                cable_size = "2.5 mm²"
            elif flc <= 25:
                cable_size = "4 mm²"
            elif flc <= 32:
                cable_size = "6 mm²"
            elif flc <= 50:
                cable_size = "10 mm²"
            elif flc <= 63:
                cable_size = "16 mm²"
            elif flc > 63:
                cable_size = "Consult electrical standards for cables above 16 mm²"
            
            recommendations.append(f"Use minimum {cable_size} cables for power connections.")
            
            return "\n• ".join(recommendations)
        except Exception as e:
            print(f"Error generating recommendations: {e}")
            return "Could not generate recommendations due to an error."
