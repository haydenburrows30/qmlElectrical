from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class DeltaTransformerCalculator(QObject):
    """Calculator for open delta protection transformer configurations"""
    
    primaryVoltageChanged = Signal()
    secondaryVoltageChanged = Signal()
    powerRatingChanged = Signal()
    resistorCalculated = Signal(float)
    wattageCalculated = Signal(float)  # Add new signal

    def __init__(self, parent=None):
        super().__init__(parent)
        self._primary_voltage = 0.0
        self._secondary_voltage = 0.0
        self._power_rating = 0.0
        self._required_resistor = 0.0
        self._required_wattage = 0.0  # Add new property

    @Property(float, notify=primaryVoltageChanged)
    def primaryVoltage(self):
        return self._primary_voltage

    @primaryVoltage.setter
    def primaryVoltage(self, value):
        if value >= 0 and self._primary_voltage != value:
            self._primary_voltage = value
            self.primaryVoltageChanged.emit()
            self._calculate()

    @Property(float, notify=secondaryVoltageChanged)
    def secondaryVoltage(self):
        return self._secondary_voltage

    @secondaryVoltage.setter
    def secondaryVoltage(self, value):
        if value >= 0 and self._secondary_voltage != value:
            self._secondary_voltage = value
            self.secondaryVoltageChanged.emit()
            self._calculate()

    @Property(float, notify=powerRatingChanged)
    def powerRating(self):
        return self._power_rating

    @powerRating.setter
    def powerRating(self, value):
        if value >= 0 and self._power_rating != value:
            self._power_rating = value
            self.powerRatingChanged.emit()
            self._calculate()

    def _calculate(self):
        """Calculate required resistor value for open delta protection configuration"""
        try:
            if self._primary_voltage <= 0 or self._secondary_voltage <= 0 or self._power_rating <= 0:
                return

            # Per standard calculation method:
            # R = (3*√3*Us^2)/Pe where:
            # Us = Secondary voltage / 3
            # Pe = Power rating of secondary winding in VA
            
            # Calculate resistor using R = (3*√3*Us^2)/Pe
            self._required_resistor = (3 * math.sqrt(3) * (self._secondary_voltage / 3)**2) / self._power_rating
            # Calculate wattage rating
            self._required_wattage = ((3 * self._secondary_voltage / 3)**2) / self._required_resistor

            self.resistorCalculated.emit(self._required_resistor)
            self.wattageCalculated.emit(self._required_wattage)
            
        except Exception as e:
            print(f"Error in delta transformer calculation: {e}")

    @Slot(float)
    def setPrimaryVoltage(self, voltage):
        self.primaryVoltage = voltage

    @Slot(float)
    def setSecondaryVoltage(self, voltage):
        self.secondaryVoltage = voltage

    @Slot(float)
    def setPowerRating(self, power):
        self.powerRating = power

    @Slot(float, float, float)
    def calculateResistor(self, primary_v, secondary_v, power_kva):
        """Calculate resistor value from given parameters"""
        self.primaryVoltage = primary_v
        self.secondaryVoltage = secondary_v
        self.powerRating = power_kva
        return self._required_resistor

    @Slot(result=str)
    def getPdfPath(self):
        """Return path to reference PDF document"""
        import os
        current_dir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
        return os.path.join(current_dir, "data", "delta_transformer_guide.pdf")

    @Slot(result=float)
    def getRequiredResistor(self):
        """Get the currently calculated resistor value"""
        return self._required_resistor
        
    @Slot(result=float) 
    def getRequiredWattage(self):
        """Get the currently calculated wattage rating"""
        return self._required_wattage
    
    @Property(float, notify=wattageCalculated)
    def wattage(self):
        """Get the currently calculated wattage rating"""
        return self._required_wattage
    
    @Property(float, notify=resistorCalculated)
    def resistor(self):
        """Get the currently calculated wattage rating"""
        return self._required_resistor
