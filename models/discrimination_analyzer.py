from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class DiscriminationAnalyzer(QObject):
    """Analyzer for relay discrimination studies"""
    
    analysisComplete = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._relays = []  # List of relays in the system
        self._fault_levels = []  # Fault current levels at different points
        self._discrimination_results = []  # Analysis results
        self._min_margin = 0.3  # Minimum discrimination time (seconds)

    @Slot(dict)
    def addRelay(self, relay_data):
        """Add a relay to the discrimination study"""
        self._relays.append(relay_data)
        self._analyze_discrimination()

    @Slot(float)
    def addFaultLevel(self, current):
        """Add a fault current level to analyze"""
        self._fault_levels.append(current)
        self._analyze_discrimination()

    def _analyze_discrimination(self):
        """Perform discrimination analysis between relays"""
        self._discrimination_results = []
        
        if len(self._relays) < 2 or not self._fault_levels:
            return
            
        # Analyze each pair of relays
        for i in range(len(self._relays) - 1):
            primary = self._relays[i]
            backup = self._relays[i + 1]
            
            result = {
                "primary": primary["name"],
                "backup": backup["name"],
                "margins": [],
                "coordinated": True
            }
            
            # Check margin at each fault level
            for fault_current in self._fault_levels:
                primary_time = self._calculate_operating_time(primary, fault_current)
                backup_time = self._calculate_operating_time(backup, fault_current)
                margin = backup_time - primary_time
                
                result["margins"].append({
                    "fault_current": fault_current,
                    "margin": margin,
                    "coordinated": margin >= self._min_margin
                })
                
                if margin < self._min_margin:
                    result["coordinated"] = False
            
            self._discrimination_results.append(result)
        
        self.analysisComplete.emit()

    def _calculate_operating_time(self, relay, fault_current):
        """Calculate relay operating time for given fault current"""
        multiple = fault_current / relay["pickup"]
        if multiple <= 1:
            return float('inf')
            
        constants = relay["curve_constants"]
        return (constants["a"] * relay["tds"]) / ((multiple ** constants["b"]) - 1)

    @Property(list, notify=analysisComplete)
    def results(self):
        return self._discrimination_results

    @Property(bool, notify=analysisComplete)
    def isFullyCoordinated(self):
        return all(result["coordinated"] for result in self._discrimination_results)
