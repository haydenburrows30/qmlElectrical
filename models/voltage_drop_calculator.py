from PySide6.QtCore import QObject, Property, Signal, Slot

class VoltageDropCalc(QObject):
    """Calculator for voltage drop in cables"""

    lengthChanged = Signal()
    currentChanged = Signal()
    cableSizeChanged = Signal()
    conductorMaterialChanged = Signal()
    voltageDropChanged = Signal()
    dropPercentageChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._length = 0.0  # meters
        self._current = 0.0  # amperes
        self._cable_size = 2.5  # mm²
        self._conductor_material = "Copper"
        self._voltage_drop = 0.0  # volts
        self._drop_percentage = 0.0  # percentage
        self._system_voltage = 230.0  # default to single phase 230V

    def _calculate(self):
        """Calculate voltage drop based on inputs"""
        if self._length <= 0 or self._current <= 0 or self._cable_size <= 0:
            return

        # Resistivity values in Ω·mm²/m
        resistivity = 0.0168 if self._conductor_material == "Copper" else 0.0278  # Aluminum
        
        # Cable resistance per meter
        r_per_meter = resistivity / self._cable_size
        
        # Total resistance
        total_resistance = r_per_meter * self._length
        
        # Voltage drop calculation: V = I × R
        self._voltage_drop = self._current * total_resistance
        
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
        if self._system_voltage != voltage and voltage > 0:
            self._system_voltage = voltage
            self._calculate()
