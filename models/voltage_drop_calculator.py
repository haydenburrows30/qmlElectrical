from PySide6.QtCore import QObject, Property, Signal, Slot

class VoltageDropCalc(QObject):
    """Calculator for voltage drop in cables"""

    lengthChanged = Signal()
    currentChanged = Signal()
    cableSizeChanged = Signal()
    conductorMaterialChanged = Signal()
    voltageDropChanged = Signal()
    dropPercentageChanged = Signal()
    systemVoltageChanged = Signal()
    systemTypeChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._length = 0.0  # meters
        self._current = 0.0  # amperes
        self._cable_size = 2.5  # mm²
        self._conductor_material = "Copper"
        self._voltage_drop = 0.0  # volts
        self._drop_percentage = 0.0  # percentage
        self._system_voltage = 230.0  # default to single phase 230V
        self._system_type = "Single-phase"  # "Single-phase" or "Three-phase"

    def _calculate(self):
        """Calculate voltage drop based on inputs"""
        if self._length <= 0 or self._current <= 0 or self._cable_size <= 0:
            return

        # Resistivity values in Ω·mm²/m
        if self._conductor_material == "Copper":
            resistance = 0.0168  # Copper resistivity
            reactance = 0.0001  # Approximate reactance for copper
        else:  # Aluminum
            resistance = 0.0278  # Aluminum resistivity  
            reactance = 0.0001  # Approximate reactance for aluminum
        
        # Total impedance calculation (for AC)
        r_per_meter = resistance / self._cable_size
        x_per_meter = reactance  # Reactance is mostly independent of cross-section
        
        # Total resistance
        total_resistance = r_per_meter * self._length
        total_reactance = x_per_meter * self._length
        
        # Voltage drop calculation differs by system type
        if self._system_type == "Single-phase":
            # For single phase: VD = 2 * I * (R*cosφ + X*sinφ) * L
            # Using power factor cosφ = 0.9 (common assumption)
            power_factor = 0.9
            sin_phi = (1 - power_factor**2)**0.5
            
            self._voltage_drop = 2 * self._current * (
                total_resistance * power_factor + 
                total_reactance * sin_phi
            )
        else:  # Three-phase
            # For three phase: VD = √3 * I * (R*cosφ + X*sinφ) * L
            power_factor = 0.9
            sin_phi = (1 - power_factor**2)**0.5
            
            self._voltage_drop = 1.732 * self._current * (
                total_resistance * power_factor + 
                total_reactance * sin_phi
            )
        
        # Calculate drop percentage
        self._drop_percentage = (self._voltage_drop / self._system_voltage) * 100.0
        
        # Notify QML of changes
        self.voltageDropChanged.emit()
        self.dropPercentageChanged.emit()

    @Property(float, notify=lengthChanged)
    def length(self):
        return self._length
    
    @length.setter
    def length(self, value):
        if self._length != value and value >= 0:
            self._length = value
            self.lengthChanged.emit()
            self._calculate()

    @Property(float, notify=currentChanged)
    def current(self):
        return self._current
    
    @current.setter
    def current(self, value):
        if self._current != value and value >= 0:
            self._current = value
            self.currentChanged.emit()
            self._calculate()

    @Property(float, notify=cableSizeChanged)
    def cableSize(self):
        return self._cable_size
    
    @cableSize.setter
    def cableSize(self, value):
        if self._cable_size != value and value > 0:
            self._cable_size = value
            self.cableSizeChanged.emit()
            self._calculate()

    @Property(str, notify=conductorMaterialChanged)
    def conductorMaterial(self):
        return self._conductor_material
    
    @conductorMaterial.setter
    def conductorMaterial(self, material):
        if self._conductor_material != material:
            self._conductor_material = material
            self.conductorMaterialChanged.emit()
            self._calculate()

    @Property(float, notify=voltageDropChanged)
    def voltageDrop(self):
        return self._voltage_drop if self._voltage_drop is not None else 0.0

    @Property(float, notify=dropPercentageChanged)
    def dropPercentage(self):
        return self._drop_percentage if self._drop_percentage is not None else 0.0
    
    @Property(float, notify=systemVoltageChanged)
    def systemVoltage(self):
        return self._system_voltage
    
    @systemVoltage.setter
    def systemVoltage(self, value):
        if self._system_voltage != value and value > 0:
            self._system_voltage = value
            self.systemVoltageChanged.emit()
            self._calculate()
    
    @Property(str, notify=systemTypeChanged)
    def systemType(self):
        return self._system_type
    
    @systemType.setter
    def systemType(self, value):
        if self._system_type != value and value in ["Single-phase", "Three-phase"]:
            self._system_type = value
            self.systemTypeChanged.emit()
            self._calculate()

    # QML slots - Fixed implementations
    @Slot(float)
    def setLength(self, length):
        try:
            length_val = float(length) if length is not None else 0.0
            if length_val >= 0:
                self._length = length_val
                self.lengthChanged.emit()
                self._calculate()
        except (ValueError, TypeError):
            pass

    @Slot(float)
    def setCurrent(self, current):
        try:
            current_val = float(current) if current is not None else 0.0
            if current_val >= 0:
                self._current = current_val
                self.currentChanged.emit()
                self._calculate()
        except (ValueError, TypeError):
            pass

    @Slot(float)
    def setCableSize(self, size):
        try:
            size_val = float(size) if size is not None else 0.0
            if size_val > 0:
                self._cable_size = size_val
                self.cableSizeChanged.emit()
                self._calculate()
        except (ValueError, TypeError):
            pass

    @Slot(str)
    def setConductorMaterial(self, material):
        try:
            if material in ["Copper", "Aluminum"]:
                self._conductor_material = material
                self.conductorMaterialChanged.emit()
                self._calculate()
        except Exception:
            pass

    @Slot(float)
    def setSystemVoltage(self, voltage):
        try:
            voltage_val = float(voltage) if voltage is not None else 230.0
            if voltage_val > 0:
                self._system_voltage = voltage_val
                self.systemVoltageChanged.emit()
                self._calculate()
        except (ValueError, TypeError):
            pass
            
    @Slot(str)
    def setSystemType(self, system_type):
        try:
            if system_type in ["Single-phase", "Three-phase"]:
                self._system_type = system_type
                self.systemTypeChanged.emit()
                self._calculate()
        except Exception:
            pass
