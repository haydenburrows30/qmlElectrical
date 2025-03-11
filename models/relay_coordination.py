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

    @Slot(int, float, result=float)
    def calculateOperatingTime(self, relayIndex: int, current: float) -> float:
        """Calculate relay operating time for given current."""
        try:
            if 0 <= relayIndex < len(self._relays):
                relay = self._relays[relayIndex]
                pickup = relay.pickup
                tds = relay.tds
                
                if current <= pickup:
                    return float('inf')
                
                # Standard inverse time curve equation
                multiple = current / pickup
                if multiple > 1:
                    time = (0.14 * tds) / ((multiple ** 0.02) - 1)
                    return min(time, 100.0)  # Cap at 100 seconds
                
            return float('inf')
        except:
            return float('inf')

    def _check_coordination(self):
        """Check coordination between relays."""
        self._intervals.clear()
        
        for i in range(len(self._relays) - 1):
            primary = self._relays[i]
            backup = self._relays[i + 1]
            
            # Check coordination at different current levels
            test_currents = [2, 5, 10, 20] # Multiples of pickup current
            intervals = []
            
            for mult in test_currents:
                current = primary.pickup * mult
                primary_time = self.calculateOperatingTime(i, current)
                backup_time = self.calculateOperatingTime(i + 1, current)
                if primary_time < float('inf') and backup_time < float('inf'):
                    intervals.append(backup_time - primary_time)
            
            # Use minimum interval if we found any valid points
            if intervals:
                interval = min(intervals)
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
