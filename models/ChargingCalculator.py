from PySide6.QtCore import QObject, Signal, Property

class ChargingCalculator(QObject):
    voltageChanged = Signal()
    capacitanceChanged = Signal()
    frequencyChanged = Signal()
    lengthChanged = Signal()
    chargingCurrentChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._voltage = 0.0
        self._capacitance = 0.0
        self._frequency = 50.0
        self._length = 0.0

    @Property(float, notify=voltageChanged)
    def voltage(self):
        return self._voltage

    @voltage.setter
    def voltage(self, value):
        if self._voltage != value:
            self._voltage = value
            self.voltageChanged.emit()
            self.chargingCurrentChanged.emit()

    @Property(float, notify=capacitanceChanged)
    def capacitance(self):
        return self._capacitance

    @capacitance.setter
    def capacitance(self, value):
        if self._capacitance != value:
            self._capacitance = value
            self.capacitanceChanged.emit()
            self.chargingCurrentChanged.emit()

    @Property(float, notify=frequencyChanged)
    def frequency(self):
        return self._frequency

    @frequency.setter
    def frequency(self, value):
        if self._frequency != value:
            self._frequency = value
            self.frequencyChanged.emit()
            self.chargingCurrentChanged.emit()

    @Property(float, notify=lengthChanged)
    def length(self):
        return self._length

    @length.setter
    def length(self, value):
        if self._length != value:
            self._length = value
            self.lengthChanged.emit()
            self.chargingCurrentChanged.emit()

    @Property(float, notify=chargingCurrentChanged)
    def chargingCurrent(self):
        try:
            return 2 * 3.14159 * self._frequency * self._capacitance * self._voltage * self._length * 0.001
        except:
            return 0.0
