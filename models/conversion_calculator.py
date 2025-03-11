from PySide6.QtCore import QObject, Signal, Property, Slot
import math

class ConversionCalculator(QObject):
    resultChanged = Signal()
    valueChanged = Signal()
    fromUnitChanged = Signal()
    toUnitChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._value = 0.0
        self._result = 0.0
        self._from_unit = "watts_to_dbmw"
        self._to_unit = "dbmw_to_watts"
        self._calculate()

    @Property(float, notify=valueChanged)
    def value(self):
        return self._value

    @value.setter
    def value(self, val):
        if self._value != val:
            self._value = val
            self.valueChanged.emit()
            self._calculate()

    @Property(str, notify=fromUnitChanged)
    def fromUnit(self):
        return self._from_unit

    @fromUnit.setter
    def fromUnit(self, unit):
        if self._from_unit != unit:
            self._from_unit = unit
            self.fromUnitChanged.emit()
            self._calculate()

    @Property(str, notify=toUnitChanged)
    def toUnit(self):
        return self._to_unit

    @toUnit.setter
    def toUnit(self, unit):
        if self._to_unit != unit:
            self._to_unit = unit
            self.toUnitChanged.emit()
            self._calculate()

    @Property(float, notify=resultChanged)
    def result(self):
        return self._result

    @Slot(str)
    def setFromUnit(self, unit):
        if self._from_unit != unit:
            self._from_unit = unit
            self.fromUnitChanged.emit()
            self._calculate()

    @Slot(str)
    def setToUnit(self, unit):
        if self._to_unit != unit:
            self._to_unit = unit
            self.toUnitChanged.emit()
            self._calculate()

    def _calculate(self):
        try:
            if self._from_unit == "watts_to_dbmw":
                self._result = 10 * math.log10(self._value * 1000)
            elif self._from_unit == "dbmw_to_watts":
                self._result = pow(10, self._value/10) / 1000
            elif self._from_unit == "rad_to_hz":
                self._result = self._value / (2 * math.pi)
            elif self._from_unit == "hp_to_watts":
                self._result = self._value * 745.7
            elif self._from_unit == "rpm_to_hz":
                self._result = self._value / 60
            elif self._from_unit == "radians_to_hz":
                self._result = self._value / (2 * math.pi)
            elif self._from_unit == "hz_to_rpm":
                self._result = self._value * 60
            elif self._from_unit == "watts_to_hp":
                self._result = self._value / 745.7
            else:
                self._result = self._value
            self.resultChanged.emit()
        except:
            self._result = 0.0
            self.resultChanged.emit()
