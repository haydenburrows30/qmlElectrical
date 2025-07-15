from PySide6.QtCore import QObject, Property, Signal, Slot, QAbstractListModel, Qt, QModelIndex
import os
import math
import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt
import tempfile
import gc
from datetime import datetime
from services.file_saver import FileSaver
from services.logger_config import configure_logger
from services.database_manager import DatabaseManager


logger = configure_logger("qmltest", component="discrimination")

from utils.pdf.pdf_generator_overcurrent import generate_pdf

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
            return None
        if role == self.DataRole or role == Qt.DisplayRole:
            result = self._results[index.row()]
            return result
        return None

    def setResults(self, results):
        self.beginResetModel()
        self._results = results
        self.endResetModel()

class DiscriminationAnalyzer(QObject):
    """Analyzer for relay discrimination studies"""
    
    # Add curve definitions
    CURVE_TYPES = {
        "Definite Time": {"a": 1.0, "b": 0.0, "type": "definite"},
        "IEC Standard Inverse": {"a": 0.14, "b": 0.02},
        "IEC Very Inverse": {"a": 13.5, "b": 1.0},
        "IEC Extremely Inverse": {"a": 80.0, "b": 2.0},
        "IEEE Moderately Inverse": {"a": 0.0515, "b": 0.02},
        "IEEE Very Inverse": {"a": 19.61, "b": 2.0},
        "IEEE Extremely Inverse": {"a": 28.2, "b": 2.0},
        "BS142": {"a": 0.15, "b": 0.02, "type": "inverse"},
        "BS1361": {"a": 0.075, "b": 0.02, "type": "inverse"},
        "BS3871": {"a": 0.025, "b": 0.02, "type": "inverse"},
        "BS88": {"a": 0.004, "b": 0.02, "type": "inverse"}
    }

    analysisComplete = Signal()
    relayCountChanged = Signal()
    marginChanged = Signal()
    exportComplete = Signal(bool, str)
    exportChart = Signal(str)
    chartRangesChanged = Signal()
    currentLevelChanged = Signal()
    fuseCurvesChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._relays = []  # List of relays in the system
        self._fault_levels = []  # Fault current levels at different points
        self._results_model = ResultsModel(self)
        self._min_margin = 0.3  # Minimum discrimination time (seconds)
        self._current_level = 10  # Default current level for analysis
        self._curve_points_cache = {}  # Add cache for curve points
        self._chart_ranges = {         # Add default chart ranges
            "xMin": 10,
            "xMax": 10000,
            "yMin": 0.01,
            "yMax": 10
        }
        # Initialize fuse curves storage
        self._fuse_curves = []
        
        # Get database instance
        self.db_manager = DatabaseManager.get_instance()
        
        # Initialize the file saver
        self._file_saver = FileSaver()

        # Connect file saver signal to our exportComplete signal
        self._file_saver.saveStatusChanged.connect(self.exportComplete)

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
            return
        self._relays.append(relay_data)
        # Clear cache for this relay
        self._curve_points_cache.pop(relay_data['name'], None)
        self.relayCountChanged.emit()
        self.chartRangesChanged.emit()  # Emit to update chart ranges
        self._analyze_discrimination()

    @Slot(float)
    def addFaultLevel(self, current):
        """Add a fault current level to analyze"""
        self._fault_levels.append(current)
        self._analyze_discrimination()

    @Slot()
    def reset(self):
        """Reset all data"""
        self._relays.clear()
        self._fault_levels.clear()
        self._results_model.setResults([])
        self._curve_points_cache.clear()  # Clear cache on reset
        self._fuse_curves.clear()  # Clear fuse curves on reset
        self.relayCountChanged.emit()
        self.chartRangesChanged.emit()  # Emit to update chart ranges
        self.fuseCurvesChanged.emit()  # Emit to update fuse curves
        self.analysisComplete.emit()
        # Emit analysis complete to clear chart
        self.analysisComplete.emit()

    @Slot(int)
    def removeRelay(self, index):
        """Remove a relay from the discrimination study"""
        if 0 <= index < len(self._relays):
            relay_name = self._relays[index]["name"]
            self._relays.pop(index)
            # Clear cache for this relay
            self._curve_points_cache.pop(relay_name, None)
            self.relayCountChanged.emit()
            self.chartRangesChanged.emit()  # Emit to update chart ranges
            self._analyze_discrimination()

    @Slot()
    def exportResults(self):
        """Export results to a PDF file
        Args:
            filename: Path to save the PDF report
            image_data: File path to the chart image
        """
        try:
            # Create timestamp for filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Use FileSaver to get save location
            pdf_file = self._file_saver.get_save_filepath("pdf", f"discrimination_results_{timestamp}")
            if not pdf_file:
                self.exportComplete.emit(False, "PDF export canceled")
                return ""
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create chart using matplotlib instead of relying on the QML chart image
            temp_dir = tempfile.mkdtemp()
            chart_image_path = os.path.join(temp_dir, "discrimination_chart.png")
            temp_image = True
            
            # Generate the matplotlib chart
            self._generate_matplotlib_chart(chart_image_path)
            
            # Generate PDF with chart image
            result = generate_pdf(
                pdf_file, 
                self._relays,
                self._fault_levels,
                self._results_model._results,
                self.CURVE_TYPES,
                chart_image_path
            )
            
            # Clean up temporary files after PDF is generated
            if temp_image and os.path.exists(chart_image_path):
                try:
                    os.unlink(chart_image_path)
                    os.rmdir(temp_dir)
                except Exception:
                    pass
            
            # Force garbage collection to ensure resources are freed
            gc.collect()
            
            # Signal success or failure
            if result:
                self._file_saver._emit_success_with_path(pdf_file, "PDF saved")
                return True
            else:
                self._file_saver._emit_failure_with_path(pdf_file, "Error saving PDF")
                return False

        except Exception as e:
            error_msg = f"Error exporting report: {str(e)}"
            logger.error(error_msg)
            # Send error to QML
            self.exportComplete.emit(False, error_msg)
            return ""
            
    def _generate_matplotlib_chart(self, filepath):
        """Generate a discrimination chart using matplotlib and save it to a file
        
        Args:
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create figure with logarithmic axes
            plt.figure(figsize=(10, 8))
            plt.grid(True, which="both", ls="-", alpha=0.7)
            plt.loglog()
            
            # Set labels and title
            plt.title('Time-Current Curves and Discrimination Analysis')
            plt.xlabel('Current (A)')
            plt.ylabel('Operating Time (s)')
            
            # Generate curves for all relays
            colors = ['blue', 'red', 'green', 'orange', 'purple', 'brown', 'cyan', 'magenta']
            
            # Add each relay's curve
            for i, relay in enumerate(self._relays):
                color = colors[i % len(colors)]
                name = relay["name"]
                pickup = float(relay["pickup"])
                constants = relay["curve_constants"]
                
                # Check if this is a definite time relay
                if constants.get("type") == "definite":
                    # For definite time relays, generate a horizontal line
                    tds = float(relay["tds"])
                    current_multipliers = [1.01, 1.5, 2, 3, 5, 7, 10, 15, 20, 30, 50, 70, 100, 150, 200, 300, 500, 1000]
                    currents = [pickup * multiplier for multiplier in current_multipliers]
                    times = [tds] * len(currents)
                else:
                    # Create current range (logarithmic, more points in critical areas)
                    currents = []
                    # Close to pickup (1.01 to 2.0)
                    currents.extend([pickup * (1.01 + i * 0.1) for i in range(10)])
                    # Medium range (2.0 to 10.0)
                    currents.extend([pickup * (2.0 + i * 0.5) for i in range(17)])
                    # High range (logarithmic steps)
                    for j in range(1, 5):
                        base = pickup * (10 ** j)
                        currents.extend([base, 2 * base, 5 * base])
                    
                    # Calculate trip time for each current value
                    times = []
                    for current in currents:
                        time = self._calculate_operating_time(relay, current)
                        if time and time > 0 and time < 100:
                            times.append(time)
                        else:
                            # Handle invalid time values - skip them
                            continue
                    
                    # Ensure currents and times have the same length
                    currents = currents[:len(times)]
                
                # Plot the relay curve
                plt.plot(currents, times, color=color, linewidth=2, label=name)
            
            # Plot fuse curves if available
            if hasattr(self, '_fuse_curves') and self._fuse_curves:
                fuse_colors = ['orange', 'purple', 'brown', 'pink', 'gray', 'olive']
                for i, fuse_curve in enumerate(self._fuse_curves):
                    if fuse_curve['points']:
                        fuse_currents = [point['current'] for point in fuse_curve['points']]
                        fuse_times = [point['time'] for point in fuse_curve['points']]
                        
                        color = fuse_colors[i % len(fuse_colors)]
                        plt.plot(fuse_currents, fuse_times, color=color, linewidth=2, 
                               linestyle='-', label=f"Fuse: {fuse_curve['label']}")
                
            # Add fault points and margins if available
            margin_points = []
            for result in self._results_model._results:
                if result.get("margins"):
                    for margin in result["margins"]:
                        if (margin.get("fault_current") and margin.get("margin") and 
                            margin["margin"] > 0 and margin["margin"] < 10):
                            margin_points.append((margin["fault_current"], margin["margin"]))
            
            # Plot margin points if available
            if margin_points:
                x_vals = [point[0] for point in margin_points]
                y_vals = [point[1] for point in margin_points]
                plt.scatter(x_vals, y_vals, color='black', marker='o', s=50, label='Margin Points')
            
            # Add minimum margin line
            if self._min_margin > 0:
                plt.axhline(y=self._min_margin, color='black', linestyle='--', 
                          label=f'Min Margin: {self._min_margin:.2f}s')
                
            # Add minimum margin line
            if self._current_level > 0:
                plt.axhline(y=self._current_level, color='black', linestyle='--', 
                          label=f'Current Levek: {self._current_level:.2f}s')
            
            # Plot fault levels as vertical lines
            for fault in self._fault_levels:
                plt.axvline(x=fault, color='gray', linestyle=':', alpha=0.6)
            
            # Set reasonable plot limits based on data
            x_min = min([float(relay["pickup"]) for relay in self._relays]) * 0.8 if self._relays else 10
            x_max = max(self._fault_levels) * 1.5 if self._fault_levels else 10000
            y_min = 0.01
            y_max = 10
            
            plt.xlim(x_min, x_max)
            plt.ylim(y_min, y_max)
            
            # Add legend
            plt.legend(loc='upper right')
            
            # Save the figure and explicitly close all matplotlib resources
            plt.tight_layout()
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection to clean up any remaining resources
            gc.collect()
            
            return True
            
        except Exception as e:
            logger.error(f"Error generating matplotlib chart: {e}")
            # Make sure to close any open figures even on error
            plt.close('all')
            return False

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
        constants = relay["curve_constants"]
        
        # Check if this is a definite time relay
        if constants.get("type") == "definite":
            # For definite time relays, generate a horizontal line at TDS value
            tds = float(relay["tds"])
            # Generate points across a wider current range for better visibility
            current_multipliers = [1.01, 1.5, 2, 3, 5, 7, 10, 15, 20, 30, 50, 70, 100, 150, 200, 300, 500, 1000]
            for multiplier in current_multipliers:
                current = pickup * multiplier
                points.append({"current": current, "time": tds})
            return points
        
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

    @Property('QVariantMap', notify=chartRangesChanged)
    def chartRanges(self):
        """Calculate optimal chart ranges lazily"""
        if not self._relays:
            return self._chart_ranges

        xMin = float('inf')
        xMax = float('-inf')
        yMin = float('inf')
        yMax = float('-inf')

        # Process curve points for all relays (generate if not cached)
        for relay in self._relays:
            name = relay["name"]
            if name not in self._curve_points_cache:
                self._curve_points_cache[name] = self._generate_curve_points(relay)
            
            points = self._curve_points_cache[name]
            for point in points:
                xMin = min(xMin, point["current"])
                xMax = max(xMax, point["current"])
                yMin = min(yMin, point["time"])
                yMax = max(yMax, point["time"])

        # Add padding and ensure reasonable limits
        if xMin < float('inf') and xMax > float('-inf'):
            new_ranges = {
                "xMin": max(10, xMin * 0.5),
                "xMax": min(100000, xMax * 2.0),
                "yMin": max(0.01, yMin * 0.5),
                "yMax": min(100, yMax * 2.0)
            }
            # Only emit signal if ranges actually changed
            if new_ranges != self._chart_ranges:
                self._chart_ranges = new_ranges
                self.chartRangesChanged.emit()

        return self._chart_ranges

    def _analyze_discrimination(self):
        results = []
        
        if len(self._relays) < 2 or not self._fault_levels:
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
        self.analysisComplete.emit()

    def _calculate_operating_time(self, relay, fault_current):
        """Calculate relay operating time for given fault current"""
        try:
            pickup = float(relay["pickup"])
            if pickup <= 0:
                return None
                
            multiple = fault_current / pickup
            if multiple <= 1.0:
                return float('inf')  # Current is below pickup threshold
                
            constants = relay["curve_constants"]
            tds = float(relay["tds"])
            
            # Check if this is a definite time relay
            if constants.get("type") == "definite":
                # For definite time relays, operating time is constant (TDS value)
                return tds
            
            # Calculation using the standard formula for inverse time curves
            denominator = (multiple ** constants["b"]) - 1
            if denominator <= 0:
                return None
                
            time = (constants["a"] * tds) / denominator
            return time if time >= 0 else None
            
        except Exception:
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

    @Property(float, notify=currentLevelChanged)
    def currentLevel(self):
        return self._current_level

    @currentLevel.setter
    def currentLevel(self, value):
        if self._current_level != value:
            self._current_level = value
            self.currentLevelChanged.emit()

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
    
    # Fuse curve methods
    @Slot(str, result=list)
    def getFuseTypes(self, manufacturer="ABB"):
        """Get available fuse types for the specified manufacturer."""
        try:
            results = self.db_manager.fetch_all("""
                SELECT DISTINCT fuse_type
                FROM fuse_curves
                WHERE manufacturer = ?
                ORDER BY fuse_type
            """, (manufacturer,))
            
            return [row['fuse_type'] for row in results] if results else []
        except Exception as e:
            logger.error(f"Error getting fuse types: {e}")
            return []
    
    @Slot(str, str, result=list)
    def getFuseRatings(self, fuse_type, manufacturer="ABB"):
        """Get available fuse ratings for the specified type and manufacturer."""
        try:
            results = self.db_manager.fetch_all("""
                SELECT DISTINCT rating
                FROM fuse_curves
                WHERE fuse_type = ? AND manufacturer = ?
                ORDER BY rating
            """, (fuse_type, manufacturer))
            
            return [row['rating'] for row in results] if results else []
        except Exception as e:
            logger.error(f"Error getting fuse ratings: {e}")
            return []
    
    @Slot(str, float, str, result=list)
    def getFuseCurveData(self, fuse_type, rating, manufacturer="ABB"):
        """Get fuse curve data for plotting."""
        try:
            results = self.db_manager.fetch_all("""
                SELECT current_multiplier, melting_time, clearing_time, notes
                FROM fuse_curves 
                WHERE fuse_type = ? AND rating = ? AND manufacturer = ?
                ORDER BY current_multiplier
            """, (fuse_type, rating, manufacturer))
            
            curve_data = []
            for row in results:
                current = rating * row['current_multiplier']
                curve_data.append({
                    'current': current,
                    'melting_time': row['melting_time'],
                    'clearing_time': row['clearing_time'] if row['clearing_time'] else row['melting_time'],
                    'notes': row['notes'] or ''
                })
            
            return curve_data
        except Exception as e:
            logger.error(f"Error getting fuse curve data: {e}")
            return []
    
    @Slot(str, float, str, result=bool)
    def addFuseCurveToPlot(self, fuse_type, rating, manufacturer="ABB"):
        """Add a fuse curve to the current plot data."""
        try:
            curve_data = self.getFuseCurveData(fuse_type, rating, manufacturer)
            
            if not curve_data:
                return False
            
            # Convert to plot format
            fuse_curve_points = []
            for point in curve_data:
                fuse_curve_points.append({
                    'current': point['current'],
                    'time': point['melting_time']
                })
            
            # Store fuse curve data for plotting
            if not hasattr(self, '_fuse_curves'):
                self._fuse_curves = []
            
            self._fuse_curves.append({
                'type': fuse_type,
                'rating': rating,
                'manufacturer': manufacturer,
                'points': fuse_curve_points,
                'label': f"{manufacturer} {fuse_type} {rating}A"
            })
            
            # Emit signal for chart update
            self.fuseCurvesChanged.emit()
            return True
            
        except Exception as e:
            logger.error(f"Error adding fuse curve to plot: {e}")
            return False
    
    @Slot()
    def clearFuseCurves(self):
        """Clear all fuse curves from the plot."""
        if hasattr(self, '_fuse_curves'):
            self._fuse_curves = []
            self.fuseCurvesChanged.emit()
    
    @Slot(result=list)
    def getLoadedFuseCurves(self):
        """Get list of currently loaded fuse curves."""
        if hasattr(self, '_fuse_curves'):
            return [
                {
                    'type': curve['type'],
                    'rating': curve['rating'],
                    'manufacturer': curve['manufacturer'],
                    'label': curve['label']
                }
                for curve in self._fuse_curves
            ]
        return []
