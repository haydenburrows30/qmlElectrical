from PySide6.QtCore import QObject, Signal, Property, Slot

class BatteryCalculator(QObject):
    loadChanged = Signal()
    systemVoltageChanged = Signal()
    backupTimeChanged = Signal()
    depthOfDischargeChanged = Signal()
    batteryTypeChanged = Signal()
    currentDrawChanged = Signal()
    requiredCapacityChanged = Signal()
    recommendedCapacityChanged = Signal()
    energyStorageChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._load = 0.0
        self._system_voltage = 12
        self._backup_time = 4.0
        self._depth_of_discharge = 50.0
        self._battery_type = "Lead Acid"
        self._efficiency_factors = {
            "Lead Acid": 0.8,
            "Lithium Ion": 0.95,
            "AGM": 0.85
        }
        self._aging_factors = {
            "Lead Acid": 1.25,
            "Lithium Ion": 1.1,
            "AGM": 1.2
        }
        self._calculate()

    @Property(float, notify=loadChanged)
    def load(self):
        return self._load

    @load.setter
    def load(self, value):
        if self._load != value:
            self._load = value
            self.loadChanged.emit()
            self._calculate()

    @Property(int, notify=systemVoltageChanged)
    def systemVoltage(self):
        return self._system_voltage

    @systemVoltage.setter
    def systemVoltage(self, value):
        if self._system_voltage != value:
            self._system_voltage = value
            self.systemVoltageChanged.emit()
            self._calculate()

    @Property(float, notify=backupTimeChanged)
    def backupTime(self):
        return self._backup_time

    @backupTime.setter
    def backupTime(self, value):
        if self._backup_time != value:
            self._backup_time = value
            self.backupTimeChanged.emit()
            self._calculate()

    @Property(float, notify=depthOfDischargeChanged)
    def depthOfDischarge(self):
        return self._depth_of_discharge

    @depthOfDischarge.setter
    def depthOfDischarge(self, value):
        if self._depth_of_discharge != value:
            self._depth_of_discharge = value
            self.depthOfDischargeChanged.emit()
            self._calculate()

    @Property(str, notify=batteryTypeChanged)
    def batteryType(self):
        return self._battery_type

    @batteryType.setter
    def batteryType(self, value):
        if self._battery_type != value:
            self._battery_type = value
            self.batteryTypeChanged.emit()
            self._calculate()

    @Property(float, notify=currentDrawChanged)
    def currentDraw(self):
        if self._system_voltage > 0:
            return self._load / self._system_voltage
        return 0.0

    @Property(float, notify=requiredCapacityChanged)
    def requiredCapacity(self):
        try:
            if self._depth_of_discharge > 0:
                return (self.currentDraw * self._backup_time * 100) / self._depth_of_discharge
            return 0.0
        except:
            return 0.0

    @Property(float, notify=recommendedCapacityChanged)
    def recommendedCapacity(self):
        try:
            # Apply efficiency and aging factors
            efficiency = self._efficiency_factors.get(self._battery_type, 0.8)
            aging = self._aging_factors.get(self._battery_type, 1.2)
            
            return self.requiredCapacity / efficiency * aging
        except:
            return 0.0

    @Property(float, notify=energyStorageChanged)
    def energyStorage(self):
        try:
            return (self.recommendedCapacity * self._system_voltage) / 1000
        except:
            return 0.0

    def _calculate(self):
        # Trigger all dependent property updates
        self.currentDrawChanged.emit()
        self.requiredCapacityChanged.emit()
        self.recommendedCapacityChanged.emit()
        self.energyStorageChanged.emit()
