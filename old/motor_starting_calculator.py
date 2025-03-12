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
    startingMultiplierChanged = Signal()  # Add new signal

    def __init__(self, parent=None):
        super().__init__(parent)
        # Initialize properties
        self._motor_power = 0.0  # kW
        self._voltage = 400.0    # V
        self._efficiency = 0.85  # 85%
        self._power_factor = 0.8 # 0.8
        self._starting_method = "DOL"  # Direct On Line
        self._starting_current = 0.0
        self._starting_torque = 0.0
        self._starting_methods = ["DOL", "Star-Delta", "Soft Starter", "VFD"]
        self._current_multiplier = 6.0  # Default multiplier for DOL
        self._starting_multiplier = self._current_multipliers["DOL"]  # Cache the multiplier
        
        # Starting current multipliers for different methods
        self._current_multipliers = {
            "DOL": 6.0,
            "Star-Delta": 2.0,
            "Soft Starter": 3.0,
            "VFD": 1.0
        }
        
        # Starting torque multipliers for different methods
        self._torque_multipliers = {
            "DOL": 1.0,
            "Star-Delta": 0.33,
            "Soft Starter": 0.5,
            "VFD": 1.5
        }

    def _calculate(self):
        """Calculate starting current and torque based on inputs"""
        try:
            # Convert motor power to VA
            motor_va = self._motor_power * 1000 / (self._efficiency * self._power_factor)
            
            # Calculate full load current
            full_load_current = motor_va / (math.sqrt(3) * self._voltage)
            
            # Calculate starting current based on method
            multiplier = self._current_multipliers.get(self._starting_method, 6.0)
            self._starting_current = full_load_current * multiplier
            
            # Calculate nominal torque (Nm)
            nominal_torque = 9.55 * self._motor_power / 1.0  # Assuming 1.0 is base speed
            
            # Calculate starting torque
            torque_multiplier = self._torque_multipliers.get(self._starting_method, 1.0)
            self._starting_torque = nominal_torque * torque_multiplier
            
            # Emit signals for UI update
            self.startingCurrentChanged.emit()
            self.startingTorqueChanged.emit()
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
            self._starting_multiplier = self._current_multipliers.get(value, 6.0)  # Update multiplier
            self.startingMethodChanged.emit()
            self.startingMultiplierChanged.emit()
            self._calculate()

    @Property(float, notify=startingCurrentChanged)
    def startingCurrent(self):
        return self._starting_current
    
    @Property(float, notify=startingTorqueChanged)
    def startingTorque(self):
        return self._starting_torque
    
    @Property(list)
    def startingMethods(self):
        return self._starting_methods

    @Property(float, notify=startingMultiplierChanged)
    def startingMultiplier(self):
        return self._starting_multiplier

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
