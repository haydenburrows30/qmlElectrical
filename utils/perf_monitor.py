"""Performance monitoring interface for the application."""
from PySide6.QtCore import QObject, Signal, Slot, Property
# Remove QVariant import as it's not available directly in PySide6.QtCore
import os
import time
from datetime import datetime

from .calculation_cache import CalculationCache

# QML registration decorator
from PySide6.QtQml import QmlElement

QML_IMPORT_NAME = "PerformanceMonitor"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class PerformanceMonitor(QObject):
    """QML interface for monitoring performance improvements."""
    
    # Signals for QML binding
    reportChanged = Signal()
    
    def __init__(self, parent=None):
        """Initialize the performance monitor."""
        super().__init__(parent)
        self._cache = CalculationCache.get_instance()
        self._report_data = {}
        self._log_directory = os.path.join(os.path.expanduser("~"), "Documents", "qmltest", "logs")
        
        # Create log directory if it doesn't exist
        if not os.path.exists(self._log_directory):
            try:
                os.makedirs(self._log_directory)
            except Exception as e:
                print(f"Failed to create log directory: {e}")
                self._log_directory = os.path.expanduser("~")
    
    @Slot(bool)
    def enableLogging(self, enabled):
        """Enable or disable performance logging."""
        if enabled:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            log_file = os.path.join(self._log_directory, f"cache_perf_{timestamp}.csv")
            self._cache.enable_logging(True, log_file)
        else:
            self._cache.enable_logging(False)
    
    @Slot(result=bool)
    def isLoggingEnabled(self):
        """Check if performance logging is enabled."""
        return self._cache._log_enabled
    
    @Slot(result=dict)  # Changed from QVariant to dict
    def getPerformanceReport(self):
        """Get a performance improvement report for QML."""
        self._report_data = self._cache.get_performance_report()
        self.reportChanged.emit()
        return self._report_data
    
    @Slot(result=str)
    def exportReport(self):
        """Export performance data to file and return the file path."""
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = os.path.join(self._log_directory, f"perf_report_{timestamp}.csv")
            if self._cache.export_performance_log(filename):
                return filename
            return "Export failed"
        except Exception as e:
            print(f"Error exporting report: {e}")
            return f"Error: {str(e)}"
    
    @Property(float, notify=reportChanged)
    def performanceImprovement(self):
        """Get the performance improvement factor."""
        if 'performance_improvement' in self._report_data:
            return float(self._report_data['performance_improvement'])
        return 0.0
    
    @Property(float, notify=reportChanged)
    def timeSavedMs(self):
        """Get total time saved in milliseconds."""
        if 'time_saved_ms' in self._report_data:
            return float(self._report_data['time_saved_ms'])
        return 0.0
    
    @Property(float, notify=reportChanged)
    def hitRatio(self):
        """Get the cache hit ratio."""
        if 'hit_ratio' in self._report_data:
            return float(self._report_data['hit_ratio'])
        return 0.0
    
    @Property(int, notify=reportChanged)
    def cacheHits(self):
        """Get number of cache hits."""
        if 'hit_count' in self._report_data:
            return int(self._report_data['hit_count'])
        return 0
    
    @Property(int, notify=reportChanged)
    def cacheMisses(self):
        """Get number of cache misses."""
        if 'miss_count' in self._report_data:
            return int(self._report_data['miss_count'])
        return 0
