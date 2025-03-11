from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class TransformerCalculator(QObject):
    """Calculator for transformer voltage/current relationships"""

    primaryVoltageChanged = Signal()
    secondaryVoltageChanged = Signal()
    primaryCurrentChanged = Signal()
    secondaryCurrentChanged = Signal()
    turnsRatioChanged = Signal()
    powerRatingChanged = Signal()
    efficiencyChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._primary_voltage = 0.0
        self._secondary_voltage = 0.0
        self._primary_current = 0.0
        self._secondary_current = 0.0
        self._turns_ratio = 0.0
        self._power_rating = 0.0
        self._efficiency = 95.0  # Typical efficiency

    @Property(float, notify=primaryVoltageChanged)
    def primaryVoltage(self):
        return self._primary_voltage

    @primaryVoltage.setter
    def primaryVoltage(self, value):
        if self._primary_voltage != value and value >= 0:
            self._primary_voltage = value
            self.primaryVoltageChanged.emit()
            self._calculate()

    @Property(float, notify=secondaryVoltageChanged)
    def secondaryVoltage(self):
        return self._secondary_voltage

    @secondaryVoltage.setter
    def secondaryVoltage(self, value):
        if self._secondary_voltage != value and value >= 0:
            self._secondary_voltage = value
            self.secondaryVoltageChanged.emit()
            self._calculate()

    @Property(float, notify=primaryCurrentChanged)
    def primaryCurrent(self):
        return self._primary_current

    @primaryCurrent.setter
    def primaryCurrent(self, value):
        if self._primary_current != value and value >= 0:
            self._primary_current = value
            self.primaryCurrentChanged.emit()
            self._calculate()

    @Property(float, notify=secondaryCurrentChanged)
    def secondaryCurrent(self):
        return self._secondary_current

    @Property(float, notify=turnsRatioChanged)
    def turnsRatio(self):
        return self._turns_ratio

    @Property(float, notify=powerRatingChanged)
    def powerRating(self):
        return self._power_rating

    @Property(float, notify=efficiencyChanged)
    def efficiency(self):
        return self._efficiency

    def _calculate(self):
        """Calculate transformer parameters based on inputs"""
        try:
            # Calculate turns ratio
            if self._primary_voltage > 0 and self._secondary_voltage > 0:
                self._turns_ratio = self._primary_voltage / self._secondary_voltage
                
                # Calculate secondary current based on power conservation
                if self._primary_current > 0:
                    self._secondary_current = self._primary_current * self._turns_ratio
                
                # Calculate power rating
                self._power_rating = self._primary_voltage * self._primary_current

            self.turnsRatioChanged.emit()
            self.secondaryCurrentChanged.emit()
            self.powerRatingChanged.emit()
            
        except Exception as e:
            print(f"Calculation error: {e}")

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
