from PySide6.QtCore import QObject, Signal, Property
import math

class FrequencyCalculator(QObject):
    resonantFrequencyChanged = Signal()
    angularFrequencyChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._inductance = 0.0
        self._capacitance = 0.0
        self._resonant_frequency = 0.0
        self._angular_frequency = 0.0

    @Property(float)
    def inductance(self):
        return self._inductance

    @inductance.setter
    def inductance(self, value):
        if value != self._inductance:
            self._inductance = value
            self._calculate()

    @Property(float)
    def capacitance(self):
        return self._capacitance

    @capacitance.setter
    def capacitance(self, value):
        if value != self._capacitance:
            self._capacitance = value
            self._calculate()

    @Property(float, notify=resonantFrequencyChanged)
    def resonantFrequency(self):
        return self._resonant_frequency

    @Property(float, notify=angularFrequencyChanged)
    def angularFrequency(self):
        return self._angular_frequency

    def _calculate(self):
        try:
            if self._inductance > 0 and self._capacitance > 0:
                # Convert capacitance from μF to F
                c = self._capacitance * 1e-6
                # Calculate angular frequency
                self._angular_frequency = 1 / math.sqrt(self._inductance * c)
                # Calculate resonant frequency
                self._resonant_frequency = self._angular_frequency / (2 * math.pi)
            else:
                self._angular_frequency = 0.0
                self._resonant_frequency = 0.0

            self.resonantFrequencyChanged.emit()
            self.angularFrequencyChanged.emit()
        except:
            self._angular_frequency = 0.0
            self._resonant_frequency = 0.0
