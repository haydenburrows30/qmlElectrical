"""System resource monitoring and management utilities."""
import platform
import psutil
import threading
import time
from typing import Dict, Any
from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer

class SystemResources(QObject):
    """Monitor system resources and adjust application behavior accordingly."""
    
    # Signals for QML
    cpuUsageChanged = Signal()
    memoryUsageChanged = Signal()
    performanceModeChanged = Signal()
    
    def __init__(self, parent=None):
        """Initialize the resource monitor."""
        super().__init__(parent)
        self._cpu_usage = 0.0
        self._memory_usage = 0.0
        self._memory_total = psutil.virtual_memory().total / (1024 * 1024)  # MB
        self._performance_mode = "balanced"  # "high_performance", "balanced", "power_saving"
        self._update_interval = 2000  # ms
        self._process_memory = 0.0
        self._process_cpu = 0.0
        
        # Setup update timer
        self._timer = QTimer(self)
        self._timer.setInterval(self._update_interval)
        self._timer.timeout.connect(self._update_stats)
        
        # Platform specific settings
        self._is_windows = platform.system() == "Windows"
        self._is_mobile = platform.machine().startswith(('arm', 'aarch'))
        
        # Set initial performance mode based on platform
        if self._is_mobile:
            self._performance_mode = "power_saving"
        elif self._is_windows:
            self._performance_mode = "balanced"
        else:
            self._performance_mode = "high_performance"
        
        # Start update cycle
        self._timer.start()
    
    @Property(float, notify=cpuUsageChanged)
    def cpuUsage(self):
        """Get current CPU usage percentage."""
        return self._cpu_usage
    
    @Property(float, notify=memoryUsageChanged)
    def memoryUsage(self):
        """Get current memory usage in MB."""
        return self._memory_usage
    
    @Property(float, constant=True)
    def memoryTotal(self):
        """Get total system memory in MB."""
        return self._memory_total
    
    @Property(str, notify=performanceModeChanged)
    def performanceMode(self):
        """Get current performance mode."""
        return self._performance_mode
    
    @performanceMode.setter
    def performanceMode(self, mode):
        """Set performance mode."""
        if mode in ["high_performance", "balanced", "power_saving"] and mode != self._performance_mode:
            self._performance_mode = mode
            self.performanceModeChanged.emit()
    
    @Slot()
    def _update_stats(self):
        """Update system resource statistics."""
        try:
            # Update CPU usage (average across cores)
            new_cpu = psutil.cpu_percent(interval=None)
            if abs(new_cpu - self._cpu_usage) > 1.0:  # Only update if changed significantly
                self._cpu_usage = new_cpu
                self.cpuUsageChanged.emit()
            
            # Update memory usage
            mem = psutil.virtual_memory()
            new_memory = mem.used / (1024 * 1024)  # MB
            if abs(new_memory - self._memory_usage) > 10.0:  # Only update if changed by 10MB+
                self._memory_usage = new_memory
                self.memoryUsageChanged.emit()
            
            # Also collect per-process data for the current process
            try:
                process = psutil.Process()
                self._process_memory = process.memory_info().rss / (1024 * 1024)  # MB
                self._process_cpu = process.cpu_percent(interval=0.1)
            except Exception as e:
                print(f"Error getting process stats: {e}")
                self._process_memory = 0
                self._process_cpu = 0
            
            # Automatically adjust performance mode if CPU usage is very high or low
            if self._cpu_usage > 85 and self._performance_mode != "power_saving":
                self.performanceMode = "power_saving"
            elif self._cpu_usage < 20 and self._performance_mode == "power_saving":
                self.performanceMode = "balanced"
        except Exception as e:
            print(f"Error updating system stats: {e}")
    
    @Slot(result=dict)
    def getDetailedStats(self):
        """Get detailed system statistics for diagnostics."""
        try:
            # Get process-specific information
            try:
                process = psutil.Process()
                process_info = {
                    "process_memory_mb": self._process_memory,
                    "process_cpu_percent": self._process_cpu,
                    "process_threads": process.num_threads(),
                    "process_open_files": len(process.open_files()),
                    "process_uptime": time.time() - process.create_time()
                }
            except Exception:
                process_info = {}
                
            # Return combined system and process info
            return {
                "cpu_usage": self._cpu_usage,
                "memory_usage_mb": self._memory_usage,
                "memory_total_mb": self._memory_total,
                "memory_percent": (self._memory_usage / self._memory_total * 100) if self._memory_total else 0,
                "performance_mode": self._performance_mode,
                "logical_cores": psutil.cpu_count(logical=True),
                "physical_cores": psutil.cpu_count(logical=False),
                "platform": platform.system(),
                "platform_release": platform.release(),
                "python_version": platform.python_version(),
                **process_info  # Include process-specific information
            }
        except Exception as e:
            print(f"Error getting detailed stats: {e}")
            return {}
