from PySide6.QtCore import QObject, Property, Signal, Slot

class VoltageDividerCalculator(QObject):
    """Calculator for voltage divider circuits"""

    # Define signals for property changes
    inputChanged = Signal()
    calculationCompleted = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Initialize input parameters
        self._input_voltage = 12.0  # V
        self._r1 = 10000.0         # Ohms 
        self._r2 = 10000.0         # Ohms
        
        # Initialize calculated values
        self._output_voltage = 0.0  # V
        self._current = 0.0         # A
        self._power_r1 = 0.0        # W
        self._power_r2 = 0.0        # W
        
        # Calculate initial values
        self._calculate()

    def _calculate(self):
        """Calculate voltage divider parameters"""
        try:
            # Calculate total resistance
            total_r = self._r1 + self._r2
            
            # Calculate current through the circuit
            self._current = self._input_voltage / total_r
            
            # Calculate output voltage across R2
            self._output_voltage = self._input_voltage * (self._r2 / total_r)
            
            # Calculate power dissipation in each resistor
            self._power_r1 = self._current * self._current * self._r1
            self._power_r2 = self._current * self._current * self._r2
            
            self.calculationCompleted.emit()
            
        except Exception as e:
            print(f"Error in voltage divider calculation: {e}")

    # Properties and setters
    @Property(float, notify=inputChanged)
    def inputVoltage(self):
        return self._input_voltage
    
    @inputVoltage.setter
    def inputVoltage(self, value):
        if value > 0:
            self._input_voltage = value
            self.inputChanged.emit()
            self._calculate()

    @Property(float, notify=inputChanged)
    def r1(self):
        return self._r1
    
    @r1.setter
    def r1(self, value):
        if value > 0:
            self._r1 = value
            self.inputChanged.emit()
            self._calculate()
    
    @Property(float, notify=inputChanged)  
    def r2(self):
        return self._r2
    
    @r2.setter
    def r2(self, value):
        if value > 0:
            self._r2 = value
            self.inputChanged.emit()
            self._calculate()
    
    # Read-only result properties
    @Property(float, notify=calculationCompleted)
    def outputVoltage(self):
        return self._output_voltage
    
    @Property(float, notify=calculationCompleted)
    def current(self):
        return self._current
    
    @Property(float, notify=calculationCompleted)
    def powerR1(self):
        return self._power_r1
    
    @Property(float, notify=calculationCompleted)
    def powerR2(self):
        return self._power_r2
    
    # QML slots
    @Slot(float)
    def setInputVoltage(self, value):
        self.inputVoltage = value
    
    @Slot(float)
    def setR1(self, value):
        self.r1 = value
        
    @Slot(float)
    def setR2(self, value):
        self.r2 = value
        
    @Slot()
    def refreshCalculations(self):
        self._calculate()
        return True
