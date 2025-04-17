from PySide6.QtCore import QObject, Property, Signal, Slot, QAbstractListModel, Qt, QModelIndex
import math
import json
import os

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
    exportComplete = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._relays = []  # List of relays in the system
        self._fault_levels = []  # Fault current levels at different points
        self._results_model = ResultsModel(self)
        self._min_margin = 0.3  # Minimum discrimination time (seconds)
        self._curve_points_cache = {}  # Add cache for curve points
        self._chart_ranges = {         # Add default chart ranges
            "xMin": 10,
            "xMax": 10000,
            "yMin": 0.01,
            "yMax": 10
        }

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
        # Clear cache for this relay
        self._curve_points_cache.pop(relay_data['name'], None)
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
        # Emit analysis complete to clear chart
        self.analysisComplete.emit()

    @Slot(int)
    def removeRelay(self, index):
        """Remove a relay from the discrimination study"""
        if 0 <= index < len(self._relays):
            print(f"Removing relay at index {index}")
            relay_name = self._relays[index]["name"]
            self._relays.pop(index)
            # Clear cache for this relay
            self._curve_points_cache.pop(relay_name, None)
            self.relayCountChanged.emit()
            self._analyze_discrimination()

    @Slot(result=str)
    def exportResults(self):
        """Export results to a JSON file"""
        try:
            # Create a data structure to export
            export_data = {
                "relays": self._relays,
                "fault_levels": self._fault_levels,
                "min_margin": self._min_margin,
                "results": []
            }
            
            # Get results from the model
            for i in range(self._results_model.rowCount()):
                index = self._results_model.index(i, 0)
                result = self._results_model.data(index, self._results_model.DataRole)
                if result:
                    export_data["results"].append(result)
            
            # Create a timestamp for the filename
            import datetime
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get home directory
            home_dir = os.path.expanduser("~")
            export_dir = os.path.join(home_dir, "Documents", "qmltest", "exports")
            
            # Create directory if it doesn't exist
            os.makedirs(export_dir, exist_ok=True)
            
            # Create filename
            filename = os.path.join(export_dir, f"discrimination_results_{timestamp}.json")
            
            # Write to file
            with open(filename, 'w') as f:
                json.dump(export_data, f, indent=2)
            
            print(f"Results exported to {filename}")
            self.exportComplete.emit(filename)
            return filename
            
        except Exception as e:
            print(f"Error exporting results: {e}")
            self.exportComplete.emit("")
            return ""

    @Slot(float, result='QVariantList')
    def calculateFaultPoints(self, relayIndex):
        """Calculate operating points for given relay at each fault level"""
        if relayIndex < 0 or relayIndex >= len(self._relays):
            return []
            
        relay = self._relays[relayIndex]
        points = []
        
        for fault_current in self._fault_levels:
            time = self._calculate_operating_time(relay, fault_current)
            if time and time > 0 and not math.isinf(time):
                points.append({
                    "current": fault_current,
                    "time": time
                })
                
        return points

    @Property('QVariantList')
    def faultPoints(self):
        """Calculate all fault points for all relays"""
        points = []
        for i, relay in enumerate(self._relays):
            relay_points = []
            for current in self._fault_levels:
                time = self._calculate_operating_time(relay, current)
                if time and time > 0 and not math.isinf(time):
                    relay_points.append({
                        "current": current,
                        "time": time,
                        "relay": relay["name"]
                    })
            points.extend(relay_points)
        return points

    @Property('QVariantList')
    def curvePoints(self):
        """Cache and return curve points"""
        points = []
        for relay in self._relays:
            name = relay["name"]
            if name not in self._curve_points_cache:
                self._curve_points_cache[name] = self._generate_curve_points(relay)
            points.append({
                "name": name,
                "points": self._curve_points_cache[name]
            })
        return points

    def _generate_curve_points(self, relay):
        """Generate points for a single relay curve"""
        points = []
        pickup = float(relay["pickup"])
        
        # Generate multiples with fine steps near pickup and wider steps for higher currents
        multiples = []
        # Close to pickup (1.01 to 2.0)
        multiples.extend([1.01 + i * 0.1 for i in range(10)])
        # Medium range (2.0 to 10.0)
        multiples.extend([2.0 + i * 0.5 for i in range(17)])
        # High range (logarithmic steps)
        for i in range(1, 5):
            base = 10 ** i
            multiples.extend([base, 2 * base, 5 * base])

        for multiple in multiples:
            current = pickup * multiple
            time = self._calculate_operating_time(relay, current)
            if time and time > 0 and time < 100:
                points.append({"current": current, "time": time})
                
        return points

    @Property('QVariantList')
    def marginPoints(self):
        """Calculate margin analysis points"""
        points = []
        for result in self._results_model._results:
            if result.get("margins"):
                for margin in result["margins"]:
                    if (margin.get("fault_current") and margin.get("margin") and 
                        margin["margin"] > 0 and margin["margin"] < 10):
                        points.append({
                            "current": margin["fault_current"],
                            "time": margin["margin"]
                        })
        return points

    @Property('QVariantMap', constant=True)
    def defaultRanges(self):
        """Provide default chart ranges"""
        return self._chart_ranges

    @Property('QVariantMap')
    def chartRanges(self):
        """Calculate optimal chart ranges lazily"""
        if not self._relays:
            return self._chart_ranges

        xMin = float('inf')
        xMax = float('-inf')
        yMin = float('inf')
        yMax = float('-inf')

        # Process cached curve points
        for relay in self._relays:
            name = relay["name"]
            if name in self._curve_points_cache:
                points = self._curve_points_cache[name]
                for point in points:
                    xMin = min(xMin, point["current"])
                    xMax = max(xMax, point["current"])
                    yMin = min(yMin, point["time"])
                    yMax = max(yMax, point["time"])

        # Add padding and ensure reasonable limits
        if xMin < float('inf') and xMax > float('-inf'):
            self._chart_ranges = {
                "xMin": max(10, xMin * 0.5),
                "xMax": min(100000, xMax * 2.0),
                "yMin": max(0.01, yMin * 0.5),
                "yMax": min(100, yMax * 2.0)
            }

        return self._chart_ranges

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

    @Property('QVariantList', constant=True)
    def faultLevels(self):
        """Provide access to fault levels from QML"""
        return self._fault_levels
