from PySide6.QtCore import QAbstractTableModel, Qt, Slot, Signal, Property, QObject
from PySide6.QtGui import QKeyEvent
from PySide6.QtWidgets import QApplication

class PowerCalculator(QObject):
    currentCalculated = Signal(float)

    def __init__(self):
        super().__init__()
        self._kva = 0.0
        self._voltage = 0.0
        self._current = 0.0
        self._phase = "Three Phase"

    @Slot(float)
    def setKva(self, kva):
        self._kva = kva
        self.calculateCurrent()

    @Slot(float)
    def setVoltage(self, voltage):
        self._voltage = voltage
        self.calculateCurrent()

    @Slot(str)
    def setPhase(self, phase):
        self._phase = phase
        self.calculateCurrent()

    def calculateCurrent(self):
        if self._voltage != 0:
            if self._phase == "Single Phase":
                self._current = self._kva * 1000 / self._voltage
            elif self._phase == "Three Phase":
                self._current = self._kva * 1000 / (self._voltage * 1.732)
            self.currentCalculated.emit(self._current)

    @Property(float, notify=currentCalculated)
    def current(self):
        return self._current

class ChargingCalc(QObject):
    chargingCurrentCalculated = Signal(float)

    def __init__(self):
        super().__init__()
        self._voltage = 0.0
        self._capacitance = 0.0
        self._frequency = 50.0  # Default frequency in Hz
        self._chargingCurrent = 0.0
        self._length = 1.0 # in km

    @Slot(float)
    def setVoltage(self, voltage):
        self._voltage = voltage
        self.calculateChargingCurrent()

    @Slot(float)
    def setCapacitance(self, capacitance):
        self._capacitance = capacitance
        self.calculateChargingCurrent()

    @Slot(float)
    def setFrequency(self, frequency):
        self._frequency = frequency
        self.calculateChargingCurrent()

    @Slot(float)
    def setLength(self, length):
        self._length = length
        self.calculateChargingCurrent()

    def calculateChargingCurrent(self):
        if self._voltage != 0 and self._capacitance != 0:
            self._chargingCurrent = (2 * 3.14159 * self._frequency * (self._capacitance / 1E6 ) * self._voltage) * self._length
            self.chargingCurrentCalculated.emit(self._chargingCurrent)

    @Property(float, notify=chargingCurrentCalculated)
    def chargingCurrent(self):
        return self._chargingCurrent