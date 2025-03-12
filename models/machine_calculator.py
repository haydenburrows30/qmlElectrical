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
        
        # Calculate initial values
        self._calculate()
    
    def _calculate(self):
        """Calculate machine parameters based on inputs"""
        try:
            # Input power calculation
            input_power = self._rated_voltage * self._rated_current * math.sqrt(3) * self._power_factor / 1000  # kW for 3-phase
            
            if "DC" in self._machine_type:
                input_power = self._rated_voltage * self._rated_current / 1000  # kW for DC
            
            # Efficiency calculations
            if self._machine_type.endswith("Motor"):
                # Motor: Output = Input * Efficiency
                self._rated_power = input_power * self._efficiency
                self._losses = input_power - self._rated_power
            else:
                # Generator: Output = Input * Efficiency (Input is mechanical power)
                self._rated_power = input_power
                self._losses = input_power * (1 - self._efficiency)
            
            # Speed and torque
            if self._machine_type == "Induction Motor":
                # Synchronous speed
                sync_speed = 120 * self._frequency / self._poles
                # Actual speed based on slip
                self._rotational_speed = sync_speed * (1 - self._slip)
            elif self._machine_type == "Synchronous Motor" or self._machine_type == "Synchronous Generator":
                # Synchronous machines run at sync speed
                self._rotational_speed = 120 * self._frequency / self._poles
                self._slip = 0
            
            # Torque calculation (N·m)
            self._torque = 9550 * self._rated_power / self._rotational_speed
            
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
            self._calculate()
    
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
    
    @Slot()
    def calculate(self):
        self._calculate()
