from PySide6.QtCore import QObject, Property, Signal, Slot

class TransformerCalculator(QObject):
    """Calculator for transformer voltage/current relationships"""

    primaryVoltageChanged = Signal()
    secondaryVoltageChanged = Signal()
    primaryCurrentChanged = Signal()
    secondaryCurrentChanged = Signal()
    turnsRatioChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._primary_voltage = 0.0
        self._secondary_voltage = 0.0
        self._primary_current = 0.0
        self._secondary_current = 0.0
        self._turns_ratio = 0.0

    def _calculate(self):
        """Calculate transformer parameters based on inputs"""
        # Prevent division by zero
        if self._primary_voltage <= 0 or self._secondary_voltage <= 0:
            return

        # Calculate turns ratio
        self._turns_ratio = self._primary_voltage / self._secondary_voltage
        
        # Calculate secondary current using conservation of power
        # P = V * I therefore: I2 = I1 * V1 / V2
        self._secondary_current = self._primary_current * self._turns_ratio
        
        # Emit signals to notify QML of changes
        self.secondaryCurrentChanged.emit()
        self.turnsRatioChanged.emit()

    @Property(float, notify=primaryVoltageChanged)
    def primaryVoltage(self):
        return self._primary_voltage
    
    @primaryVoltage.setter
    def primaryVoltage(self, voltage):
        if self._primary_voltage != voltage and voltage >= 0:
            self._primary_voltage = voltage
            self.primaryVoltageChanged.emit()
            self._calculate()

    @Property(float, notify=secondaryVoltageChanged)
    def secondaryVoltage(self):
        return self._secondary_voltage
    
    @secondaryVoltage.setter
    def secondaryVoltage(self, voltage):
        if self._secondary_voltage != voltage and voltage >= 0:
            self._secondary_voltage = voltage
            self.secondaryVoltageChanged.emit()
            self._calculate()

    @Property(float, notify=primaryCurrentChanged)
    def primaryCurrent(self):
        return self._primary_current
    
    @primaryCurrent.setter
    def primaryCurrent(self, current):
        if self._primary_current != current and current >= 0:
            self._primary_current = current
            self.primaryCurrentChanged.emit()
            self._calculate()

    @Property(float, notify=secondaryCurrentChanged)
    def secondaryCurrent(self):
        return self._secondary_current

    @Property(float, notify=turnsRatioChanged)
    def turnsRatio(self):
        return self._turns_ratio

    # Slots for QML access
    @Slot(float)
    def setPrimaryVoltage(self, voltage):
        self.primaryVoltage = voltage

    @Slot(float)
    def setSecondaryVoltage(self, voltage):
        self.secondaryVoltage = voltage

    @Slot(float)
    def setPrimaryCurrent(self, current):
        self.primaryCurrent = current
