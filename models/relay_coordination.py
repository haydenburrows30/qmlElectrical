from PySide6.QtCore import QObject, Signal, Property, Slot, QAbstractListModel, Qt
from dataclasses import dataclass
from typing import List, Dict

@dataclass
class Relay:
    name: str
    pickup: float
    tds: float
    curve_type: str

@dataclass
class CoordinationInterval:
    primary: str
    backup: str
    interval: float

class RelayCoordinationCalculator(QObject):
    relaysChanged = Signal()
    coordinationIntervalsChanged = Signal()
    isCoordinatedChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._relays = []
        self._intervals = []
        self._is_coordinated = False

    @Property('QVariantList', notify=relaysChanged)
    def relays(self):
        return [{"name": r.name, "pickup": r.pickup, "tds": r.tds} for r in self._relays]

    @Property('QVariantList', notify=coordinationIntervalsChanged)
    def coordinationIntervals(self):
        return [{"primary": i.primary, "backup": i.backup, "interval": i.interval} 
                for i in self._intervals]

    @Property(bool, notify=isCoordinatedChanged)
    def isCoordinated(self):
        return self._is_coordinated

    @Slot(str, float, float, str)
    def addRelay(self, name: str, pickup: float, tds: float, curve_type: str):
        """Add a new relay to the coordination study."""
        self._relays.append(Relay(name, pickup, tds, curve_type))
        self._check_coordination()
        self.relaysChanged.emit()

    @Slot(int)
    def removeRelay(self, index: int):
        """Remove a relay by index."""
        if 0 <= index < len(self._relays):
            self._relays.pop(index)
            self._check_coordination()
            self.relaysChanged.emit()

    def _check_coordination(self):
        """Check coordination between relays."""
        self._intervals.clear()
        
        # Example coordination check
        for i in range(len(self._relays) - 1):
            primary = self._relays[i]
            backup = self._relays[i + 1]
            interval = self._calculate_interval(primary, backup)
            self._intervals.append(
                CoordinationInterval(primary.name, backup.name, interval)
            )
        
        # Consider coordinated if all intervals >= 0.3s
        self._is_coordinated = all(i.interval >= 0.3 for i in self._intervals)
        
        self.coordinationIntervalsChanged.emit()
        self.isCoordinatedChanged.emit()

    def _calculate_interval(self, primary: Relay, backup: Relay) -> float:
        """Calculate coordination interval between two relays."""
        # Simplified example - replace with actual curve calculations
        return 0.3 * (backup.tds / primary.tds)
