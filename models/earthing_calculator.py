from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class EarthingCalculator(QObject):
    """Calculator for earthing system design"""

    # Define signals
    soilResistivityChanged = Signal()
    gridDepthChanged = Signal()
    gridLengthChanged = Signal()
    gridWidthChanged = Signal()
    rodLengthChanged = Signal()
    rodCountChanged = Signal()
    faultCurrentChanged = Signal()
    faultDurationChanged = Signal()
    resultsCalculated = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        # Initialize properties
        self._soil_resistivity = 100.0  # Ohm-meters
        self._grid_depth = 0.5  # meters
        self._grid_length = 20.0  # meters
        self._grid_width = 20.0  # meters
        self._rod_length = 3.0  # meters
        self._rod_count = 4  # number of rods
        self._fault_current = 10000.0  # Amperes
        self._fault_duration = 0.5  # seconds
        
        # Derived values
        self._grid_resistance = 0.0
        self._touch_voltage = 0.0
        self._step_voltage = 0.0
        self._conductor_size = 0.0
        self._voltage_rise = 0.0
        
        self._calculate()

    def _calculate(self):
        try:
            # Calculate grid resistance (Schwarz's equation simplified)
            area = self._grid_length * self._grid_width
            perimeter = 2 * (self._grid_length + self._grid_width)
            
            # Grid resistance calculation
            self._grid_resistance = (self._soil_resistivity / (4 * math.sqrt(area))) * (1 + (1 / (1 + self._grid_depth * math.sqrt(20/area))))
            
            # Rod contribution
            if self._rod_count > 0:
                rod_resistance = self._soil_resistivity / (2 * math.pi * self._rod_length * self._rod_count)
                self._grid_resistance = (self._grid_resistance * rod_resistance) / (self._grid_resistance + rod_resistance)
            
            # Ground potential rise
            self._voltage_rise = self._fault_current * self._grid_resistance
            
            # Touch voltage (simplified)
            self._touch_voltage = 0.7 * self._voltage_rise
            
            # Step voltage (simplified)
            self._step_voltage = 0.4 * self._voltage_rise
            
            # Conductor size (based on IEEE 80)
            Akcmil = (self._fault_current * math.sqrt(self._fault_duration * 0.0954)) / 7.06
            self._conductor_size = Akcmil * 0.5067  # Convert to mm²
            
            self.resultsCalculated.emit()
            
        except Exception as e:
            print(f"Error in earthing calculation: {e}")

    # Properties and setters
    @Property(float, notify=soilResistivityChanged)
    def soilResistivity(self):
        return self._soil_resistivity
    
    @soilResistivity.setter
    def soilResistivity(self, value):
        if value > 0:
            self._soil_resistivity = value
            self.soilResistivityChanged.emit()
            self._calculate()

    @Property(float, notify=gridDepthChanged)
    def gridDepth(self):
        return self._grid_depth
    
    @gridDepth.setter
    def gridDepth(self, value):
        if value > 0:
            self._grid_depth = value
            self.gridDepthChanged.emit()
            self._calculate()

    @Property(float, notify=gridLengthChanged)
    def gridLength(self):
        return self._grid_length
    
    @gridLength.setter
    def gridLength(self, value):
        if value > 0:
            self._grid_length = value
            self.gridLengthChanged.emit()
            self._calculate()

    @Property(float, notify=gridWidthChanged)
    def gridWidth(self):
        return self._grid_width
    
    @gridWidth.setter
    def gridWidth(self, value):
        if value > 0:
            self._grid_width = value
            self.gridWidthChanged.emit()
            self._calculate()

    @Property(float, notify=rodLengthChanged)
    def rodLength(self):
        return self._rod_length
    
    @rodLength.setter
    def rodLength(self, value):
        if value > 0:
            self._rod_length = value
            self.rodLengthChanged.emit()
            self._calculate()

    @Property(int, notify=rodCountChanged)
    def rodCount(self):
        return self._rod_count
    
    @rodCount.setter
    def rodCount(self, value):
        if value >= 0:
            self._rod_count = value
            self.rodCountChanged.emit()
            self._calculate()
    
    @Property(float, notify=faultCurrentChanged)
    def faultCurrent(self):
        return self._fault_current
    
    @faultCurrent.setter
    def faultCurrent(self, value):
        if value > 0:
            self._fault_current = value
            self.faultCurrentChanged.emit()
            self._calculate()

    @Property(float, notify=faultDurationChanged)
    def faultDuration(self):
        return self._fault_duration
    
    @faultDuration.setter
    def faultDuration(self, value):
        if value > 0:
            self._fault_duration = value
            self.faultDurationChanged.emit()
            self._calculate()

    @Property(float, notify=resultsCalculated)
    def gridResistance(self):
        return self._grid_resistance
    
    @Property(float, notify=resultsCalculated)
    def touchVoltage(self):
        return self._touch_voltage
    
    @Property(float, notify=resultsCalculated)
    def stepVoltage(self):
        return self._step_voltage
    
    @Property(float, notify=resultsCalculated)
    def conductorSize(self):
        return self._conductor_size
    
    @Property(float, notify=resultsCalculated)
    def voltageRise(self):
        return self._voltage_rise

    # QML slots
    @Slot(float)
    def setSoilResistivity(self, value):
        self.soilResistivity = value

    @Slot(float)
    def setGridDepth(self, value):
        self.gridDepth = value

    @Slot(float)
    def setGridLength(self, value):
        self.gridLength = value

    @Slot(float)
    def setGridWidth(self, value):
        self.gridWidth = value

    @Slot(float)
    def setRodLength(self, value):
        self.rodLength = value

    @Slot(int)
    def setRodCount(self, value):
        self.rodCount = value

    @Slot(float)
    def setFaultCurrent(self, value):
        self.faultCurrent = value

    @Slot(float)
    def setFaultDuration(self, value):
        self.faultDuration = value

    # ... similar slots for other setters ...
