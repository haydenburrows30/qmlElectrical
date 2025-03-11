from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class RelayCoordinationCalculator(QObject):
    """Calculator for relay coordination studies"""
    
    calculationsComplete = Signal()
    relayListChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._relays = []  # List of relay settings
        self._coordination_intervals = []  # Time intervals between relays
        self._margin = 0.3  # Minimum coordination time margin (seconds)
        
        # IEC curve constants
        self._curve_constants = {
            "Standard Inverse": {"a": 0.14, "b": 0.02},
            "Very Inverse": {"a": 13.5, "b": 1.0},
            "Extremely Inverse": {"a": 80.0, "b": 2.0},
            "Long Time Inverse": {"a": 120, "b": 1.0}
        }

    @Property(list, notify=relayListChanged)
    def relays(self):
        return self._relays

    @Slot(str, float, float, str)
    def addRelay(self, name, pickup, tds, curve_type):
        """Add a relay to the coordination study"""
        relay = {
            "name": name,
            "pickup": pickup,
            "tds": tds,
            "curve_type": curve_type,
            "operating_times": []
        }
        self._relays.append(relay)
        self._calculate_coordination()
        self.relayListChanged.emit()

    @Slot(int)
    def removeRelay(self, index):
        """Remove a relay from the coordination study"""
        if 0 <= index < len(self._relays):
            self._relays.pop(index)
            self._calculate_coordination()
            self.relayListChanged.emit()

    def _calculate_coordination(self):
        """Calculate relay coordination and operating times"""
        if not self._relays:
            return

        # Sort relays by pickup current
        self._relays.sort(key=lambda x: x["pickup"])
        
        # Calculate operating times for each relay at various fault currents
        fault_currents = [
            current for current in range(
                int(self._relays[0]["pickup"]),
                int(self._relays[-1]["pickup"] * 20),
                100
            )
        ]

        for relay in self._relays:
            constants = self._curve_constants[relay["curve_type"]]
            relay["operating_times"] = []
            
            for current in fault_currents:
                multiple = current / relay["pickup"]
                if multiple > 1:
                    time = (constants["a"] * relay["tds"]) / ((multiple ** constants["b"]) - 1)
                    relay["operating_times"].append({"current": current, "time": time})

        # Check coordination intervals
        self._coordination_intervals = []
        for i in range(len(self._relays) - 1):
            primary = self._relays[i]
            backup = self._relays[i + 1]
            
            min_interval = float('inf')
            for p_point, b_point in zip(primary["operating_times"], backup["operating_times"]):
                interval = b_point["time"] - p_point["time"]
                min_interval = min(min_interval, interval)
            
            self._coordination_intervals.append({
                "primary": primary["name"],
                "backup": backup["name"],
                "interval": min_interval
            })

        self.calculationsComplete.emit()

    @Property(list, notify=calculationsComplete)
    def coordinationIntervals(self):
        return self._coordination_intervals

    @Property(bool, notify=calculationsComplete)
    def isCoordinated(self):
        """Check if all relays are properly coordinated"""
        return all(interval["interval"] >= self._margin for interval in self._coordination_intervals)
