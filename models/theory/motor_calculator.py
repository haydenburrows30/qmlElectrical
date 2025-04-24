from PySide6.QtCore import QObject, Property, Signal, Slot
import math
from datetime import datetime
from services.file_saver import FileSaver

from services.logger_config import configure_logger
logger = configure_logger("qmltest", component="motor_calc")

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
    recommendationsChanged = Signal()
    exportDataToFolderCompleted = Signal(bool, str)  # Add new signal for export completion

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

        # Initialize FileSaver
        self._file_saver = FileSaver()

        # Connect file saver signal to our pdfExportStatusChanged signal
        self._file_saver.saveStatusChanged.connect(self.exportDataToFolderCompleted)

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
            
            # Ensure motor speed is valid
            if self._motor_speed > 0:
                # Calculate nominal torque (Nm)
                self._nominal_torque = (9.55 * self._motor_power * 1000) / self._motor_speed
            else:
                self._nominal_torque = 0.0
            
            # Get torque multiplier for the current motor type and starting method
            torque_multiplier = self._torque_multipliers.get(self._motor_type, {}).get(self._starting_method, 1.0)
            # Store the torque multiplier directly (since QML displays it as percentage)
            self._starting_torque = torque_multiplier
            
            # Emit signals for UI update
            self.startingCurrentChanged.emit()
            self.startingTorqueChanged.emit()
            self.nominalTorqueChanged.emit()
            self.resultsCalculated.emit()
            self.recommendationsChanged.emit()
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
            self.motorTypeChanged.emit()
            self.startingMultiplierChanged.emit()
            self.recommendationsChanged.emit()
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
        
    @Property(str, notify=recommendationsChanged)
    def startingRecommendations(self):
        recommendations = []
        if self._starting_method == "DOL":
            recommendations.append("Ensure the motor can handle high inrush current.")
        elif self._starting_method == "Star-Delta":
            recommendations.append("Verify compatibility with motor windings.")
        elif self._starting_method == "Soft Starter":
            recommendations.append("Check for smooth ramp-up settings.")
        elif self._starting_method == "VFD":
            recommendations.append("Optimize ramp settings for energy efficiency.")
        return "• " + "\n• ".join(recommendations)

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
        if method in self._starting_methods:
            if self._starting_method != method:
                self._starting_method = method
                self.startingMethodChanged.emit()
                self.startingMultiplierChanged.emit()
                self.recommendationsChanged.emit()
                self._calculate()
        else:
            print(f"Warning: Attempted to set invalid starting method: {method}")
        
    @Slot(int)
    def setMotorSpeed(self, rpm):
        self.motorSpeed = rpm
    
    @Slot(str)
    def setMotorType(self, motor_type):
        self.motorType = motor_type
    
    @Slot(str, result=bool)
    def isMethodApplicable(self, method):
        applicable = self._applicable_methods.get(self._motor_type, ["DOL"])
        return method in applicable
    
    @Slot(bool)
    def setDebug(self, enable):
        self._debug = enable
        
    @Slot(result=dict)
    def getMotorSpeedOptions(self):
        return self._motor_speeds
        
    @Slot()
    def exportResults(self):
        """Export motor starting results to CSV file."""
        try:
            # Create a timestamp for the filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

            filePath = self._file_saver.get_save_filepath("csv", f"motor_starting_data_{timestamp}")

            if not filePath:
                self.exportDataToFolderCompleted.emit(False, "CSV export canceled")
                return False
            
            # Prepare data in the format expected by save_csv
            csv_data = []
            
            # Add header and data
            csv_data.append(["Motor Starting Calculator Results"])
            csv_data.append(["Date", datetime.now().strftime('%Y-%m-%d %H:%M:%S')])
            csv_data.append([])
            
            csv_data.append(["Motor Type", self._motor_type])
            csv_data.append(["Motor Power (kW)", self._motor_power])
            csv_data.append(["Voltage (V)", self._voltage])
            csv_data.append(["Efficiency", self._efficiency])
            csv_data.append(["Power Factor", self._power_factor])
            csv_data.append(["Starting Method", self._starting_method])
            csv_data.append(["Full Load Current (A)", f"{self._full_load_current:.2f}"])
            csv_data.append(["Starting Current (A)", f"{self._starting_current:.2f}"])
            csv_data.append(["Starting Current Multiplier", f"{self.startingMultiplier:.2f}"])
            csv_data.append(["Nominal Torque (Nm)", f"{self._nominal_torque:.2f}"])
            csv_data.append(["Starting Torque (% FLT)", f"{self._starting_torque*100:.1f}"])
            csv_data.append(["Estimated Temperature Rise (°C)", f"{self.estimateTemperatureRise():.1f}"])
            csv_data.append(["Recommended Cable Size", self.recommendCableSize()])
            csv_data.append(["Estimated Start Duration (s)", f"{self.estimateStartDuration():.1f}"])
            csv_data.append(["Energy Usage (kWh)", f"{self.calculateStartingEnergy():.3f}"])
            csv_data.append([])
            csv_data.append(["Recommendations"])
            
            # Split recommendations into separate lines
            recommendations = self.startingRecommendations.replace('• ', '')
            for rec in recommendations.split('\n'):
                csv_data.append([rec])
            
            # Call save_csv with the prepared data
            result = self._file_saver.save_csv(filePath, csv_data)
            
            if result:
                self._file_saver._emit_success_with_path(filePath, "Data saved:")
                return True
            else:
                self._file_saver._emit_failure_with_path(filePath, f"Error saving:")
                return False

        except Exception as e:
            error_msg = f"Error exporting motor data: {str(e)}"
            logger.error(error_msg)
            self.exportDataToFolderCompleted.emit(False, error_msg)
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
        try:
            if self._starting_current <= 0 or self._full_load_current <= 0:
                return 0.0
            multiplier = self._current_multipliers.get(self._motor_type, {}).get(self._starting_method, 6.0)
            heatGenerated = pow(self._starting_current / self._full_load_current, 2) * self._starting_duration
            thermalFactor = {
                "Induction Motor": 1.0,
                "Synchronous Motor": 0.9,
                "Wound Rotor Motor": 0.8,
                "Permanent Magnet Motor": 0.7,
                "Single Phase Motor": 1.2
            }.get(self._motor_type, 1.0)
            dutyCycleFactor = 1.0
            if "Intermittent" in self._duty_cycle:
                dutyCycleFactor = 0.8
            elif "Short-time" in self._duty_cycle:
                dutyCycleFactor = 0.9
            tempRise = heatGenerated * 0.1 * thermalFactor * dutyCycleFactor
            return min(tempRise, 140)
        except Exception as e:
            print(f"Error calculating temperature rise: {e}")
            return 0.0
    
    @Slot(result=str)
    def getTemperatureRiseLevel(self):
        tempRise = self.estimateTemperatureRise()
        if tempRise < 40:
            return "normal"
        elif tempRise < 80:
            return "warning"
        else:
            return "critical"
    
    @Slot(result=str)
    def recommendCableSize(self):
        try:
            if self._starting_current <= 0:
                return "N/A"
            multiplier = self._current_multipliers.get(self._motor_type, {}).get(self._starting_method, 6.0)
            flc = self._starting_current / multiplier
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
        try:
            base_duration = self._starting_duration
            motor_type_factor = {
                "Induction Motor": 1.0,
                "Synchronous Motor": 1.2,
                "Wound Rotor Motor": 0.8,
                "Permanent Magnet Motor": 0.7,
                "Single Phase Motor": 1.1
            }
            method_factor = {
                "DOL": 0.8,
                "Star-Delta": 1.5,
                "Soft Starter": 1.2,
                "VFD": 1.1
            }
            type_multiplier = motor_type_factor.get(self._motor_type, 1.0)
            method_multiplier = method_factor.get(self._starting_method, 1.0)
            power_factor = 1.0 + (self._motor_power / 100.0)
            return base_duration * type_multiplier * method_multiplier * power_factor
        except Exception as e:
            print(f"Error estimating start duration: {e}")
            return self._starting_duration
    
    @Slot(result=float)
    def calculateStartingEnergy(self):
        try:
            if self._starting_current <= 0:
                return 0.0
            duration = self.estimateStartDuration()
            energy = (math.sqrt(3) * self._voltage * self._starting_current * 
                     self._power_factor * (duration / 3600))
            if self._starting_method == "VFD":
                energy *= 0.6
            elif self._starting_method == "Soft Starter":
                energy *= 0.8
            return energy
        except Exception as e:
            print(f"Error calculating starting energy: {e}")
            return 0.0
    
    @Slot(result=str)
    def getStartingRecommendations(self):
        return self.startingRecommendations
