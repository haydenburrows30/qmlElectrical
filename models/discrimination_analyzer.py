from PySide6.QtCore import QObject, Property, Signal, Slot, QAbstractListModel, Qt, QModelIndex
import math

class ResultsModel(QAbstractListModel):
    DataRole = Qt.UserRole + 1

    def __init__(self, parent=None):
        super().__init__(parent)
        self._results = []

    def roleNames(self):
        roles = super().roleNames()
        roles[self.DataRole] = b'resultData'
        return roles

    def rowCount(self, parent=QModelIndex()):
        return len(self._results)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or index.row() >= len(self._results):
            print(f"Invalid data access: index={index.row()}, role={role}")
            return None
        if role == self.DataRole or role == Qt.DisplayRole:
            result = self._results[index.row()]
            print(f"Returning data for index {index.row()}: {result}")
            return result
        return None

    def setResults(self, results):
        print(f"Setting new results: {results}")
        self.beginResetModel()
        self._results = results
        self.endResetModel()

class DiscriminationAnalyzer(QObject):
    """Analyzer for relay discrimination studies"""
    
    # Add curve definitions
    CURVE_TYPES = {
        "IEC Standard Inverse": {"a": 0.14, "b": 0.02},
        "IEC Very Inverse": {"a": 13.5, "b": 1.0},
        "IEC Extremely Inverse": {"a": 80.0, "b": 2.0},
        "IEEE Moderately Inverse": {"a": 0.0515, "b": 0.02},
        "IEEE Very Inverse": {"a": 19.61, "b": 2.0},
        "IEEE Extremely Inverse": {"a": 28.2, "b": 2.0}
    }

    analysisComplete = Signal()
    relayCountChanged = Signal()
    marginChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._relays = []  # List of relays in the system
        self._fault_levels = []  # Fault current levels at different points
        self._results_model = ResultsModel(self)
        self._min_margin = 0.3  # Minimum discrimination time (seconds)

    @Property(int, notify=relayCountChanged)
    def relayCount(self):
        return len(self._relays)

    @Property('QVariantList', notify=relayCountChanged)
    def relayList(self):
        return self._relays

    @Slot(dict)
    def addRelay(self, relay_data):
        """Add a relay to the discrimination study"""
        if not all(key in relay_data for key in ['name', 'pickup', 'tds', 'curve_constants']):
            print("Invalid relay data")
            return
        print(f"Adding relay: {relay_data}")
        self._relays.append(relay_data)
        print(f"Total relays: {len(self._relays)}")
        self.relayCountChanged.emit()
        self._analyze_discrimination()

    @Slot(float)
    def addFaultLevel(self, current):
        """Add a fault current level to analyze"""
        print(f"Adding fault level: {current}")
        self._fault_levels.append(current)
        self._analyze_discrimination()

    @Slot()
    def reset(self):
        """Reset all data"""
        print("Resetting analyzer")
        self._relays.clear()
        self._fault_levels.clear()
        self._results_model.setResults([])
        self.relayCountChanged.emit()
        self.analysisComplete.emit()

    def _analyze_discrimination(self):
        print(f"Starting discrimination analysis...")
        results = []
        
        if len(self._relays) < 2 or not self._fault_levels:
            print(f"Not enough data: relays={len(self._relays)}, fault_levels={len(self._fault_levels)}")
            self._results_model.setResults([])
            self.analysisComplete.emit()
            return
            
        # Analyze each pair of relays
        for i in range(len(self._relays) - 1):
            primary = self._relays[i]
            backup = self._relays[i + 1]
            
            if not primary.get('name') or not backup.get('name'):
                continue
            
            result = {
                "primary": primary["name"],
                "backup": backup["name"],
                "margins": [],
                "coordinated": True
            }
            
            # Check margin at each fault level
            for fault_current in self._fault_levels:
                print(f"Analyzing fault current: {fault_current}")
                if not fault_current or fault_current <= 0:
                    continue

                primary_time = self._calculate_operating_time(primary, fault_current)
                backup_time = self._calculate_operating_time(backup, fault_current)
                
                if primary_time is None or backup_time is None or math.isinf(primary_time) or math.isinf(backup_time):
                    continue

                margin = backup_time - primary_time
                
                result["margins"].append({
                    "fault_current": fault_current,
                    "margin": margin,
                    "coordinated": margin >= self._min_margin
                })
                
                if margin < self._min_margin:
                    result["coordinated"] = False
            
            if result["margins"]:  # Only add results if there are valid margins
                results.append(result)
        
        self._results_model.setResults(results)
        print(f"Analysis complete with {len(results)} results")
        self.analysisComplete.emit()

    def _calculate_operating_time(self, relay, fault_current):
        """Calculate relay operating time for given fault current"""
        try:
            pickup = float(relay["pickup"])
            if pickup <= 0:
                print(f"Invalid pickup current: {pickup}")
                return None
                
            multiple = fault_current / pickup
            if multiple <= 1.0:
                return float('inf')  # Current is below pickup threshold
                
            constants = relay["curve_constants"]
            tds = float(relay["tds"])
            
            # Calculation using the standard formula
            denominator = (multiple ** constants["b"]) - 1
            if denominator <= 0:
                print(f"Invalid calculation: multiple={multiple}, b={constants['b']}, denominator={denominator}")
                return None
                
            time = (constants["a"] * tds) / denominator
            return time if time >= 0 else None
            
        except Exception as e:
            print(f"Error in relay time calculation: {e}")
            return None

    @Property(QObject, notify=analysisComplete)
    def results(self):
        return self._results_model

    @Property(bool, notify=analysisComplete)
    def isFullyCoordinated(self):
        return all(result["coordinated"] for result in self._results_model._results)

    @Property(float, notify=marginChanged)
    def minimumMargin(self):
        return self._min_margin

    @minimumMargin.setter
    def minimumMargin(self, value):
        if self._min_margin != value:
            self._min_margin = value
            self.marginChanged.emit()
            self._analyze_discrimination()

    @Property('QVariantList', constant=True)
    def curveTypes(self):
        return list(self.CURVE_TYPES.keys())

    @Slot(str, result='QVariant')
    def getCurveConstants(self, curve_name):
        """Get curve constants for the given curve type"""
        return self.CURVE_TYPES.get(curve_name, self.CURVE_TYPES["IEC Standard Inverse"])
