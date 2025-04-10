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

    def _calculate(self):
        """Calculate starting current and torque based on inputs"""
        try:
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
            self._starting_torque = self._nominal_torque * torque_multiplier / self._nominal_torque if self._nominal_torque > 0 else 0
            
            # Emit signals for UI update
            self.startingCurrentChanged.emit()
            self.startingTorqueChanged.emit()
            self.nominalTorqueChanged.emit()
            self.resultsCalculated.emit()
        except Exception as e:
            print(f"Error in calculation: {e}")

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
    
    @startingMethod.setter
    def startingMethod(self, value):
        if self._starting_method != value and value in self._starting_methods:
            self._starting_method = value
            self.startingMethodChanged.emit()
            # Emit the multiplier changed signal since it depends on the method
            self.startingMultiplierChanged.emit()
            self._calculate()

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
    
    @Property(list)
    def motorTypes(self):
        return self._motor_types
    
    @Property(str)
    def motorDescription(self):
        return self._motor_characteristics.get(self._motor_type, {}).get("description", "")
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
        self.startingMethod = method
        
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
