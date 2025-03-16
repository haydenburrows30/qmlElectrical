from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer
import os
import platform
import json

class PerformanceService(QObject):
    """Service to manage and adapt application performance"""
    
    performanceModeChanged = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._performance_mode = self._detect_optimal_mode()
        self._settings_path = os.path.expanduser("~/Documents/qmltest/performance_settings.json")
        self._load_settings()
        
        # Start periodic performance check
        self._timer = QTimer(self)
        self._timer.setInterval(5000)  # Check every 5 seconds
        self._timer.timeout.connect(self._check_performance)
        self._timer.start()
        
    def _detect_optimal_mode(self):
        """Detect best performance mode based on system capabilities"""
        try:
            # Check system specs
            import psutil
            cpu_count = psutil.cpu_count()
            memory_gb = psutil.virtual_memory().total / (1024**3)
            
            if cpu_count >= 4 and memory_gb >= 8:
                return 1  # Balanced mode
            else:
                return 0  # Maximum performance mode
        except:
            return 0  # Default to maximum performance
    
    def _load_settings(self):
        """Load performance settings from file"""
        try:
            if os.path.exists(self._settings_path):
                with open(self._settings_path, 'r') as f:
                    settings = json.load(f)
                    self._performance_mode = settings.get('performance_mode', self._performance_mode)
        except Exception as e:
            print(f"Error loading performance settings: {e}")
    
    def _save_settings(self):
        """Save performance settings to file"""
        try:
            os.makedirs(os.path.dirname(self._settings_path), exist_ok=True)
            with open(self._settings_path, 'w') as f:
                json.dump({'performance_mode': self._performance_mode}, f)
        except Exception as e:
            print(f"Error saving performance settings: {e}")
    
    def _check_performance(self):
        """Check system performance and adjust if needed"""
        try:
            import psutil
            cpu_load = psutil.cpu_percent()
            memory_percent = psutil.virtual_memory().percent
            
            # Auto-downgrade to maximum performance mode if system is under stress
            if self._performance_mode > 0 and (cpu_load > 80 or memory_percent > 85):
                self._performance_mode = 0
                self.performanceModeChanged.emit()
        except:
            pass
    
    @Property(int, notify=performanceModeChanged)
    def performanceMode(self):
        """Get current performance mode (0=Max Performance, 1=Balanced, 2=Max Quality)"""
        return self._performance_mode
    
    @performanceMode.setter
    def performanceMode(self, mode):
        """Set performance mode"""
        if 0 <= mode <= 2 and mode != self._performance_mode:
            self._performance_mode = mode
            self._save_settings()
            self.performanceModeChanged.emit()
    
    @Slot(int)
    def setPerformanceMode(self, mode):
        """Set performance mode (QML-friendly method)"""
        self.performanceMode = mode
    
    @Slot()
    def getSystemInfo(self):
        """Get system information for diagnostics"""
        info = {
            "system": platform.system(),
            "platform": platform.platform(),
            "release": platform.release(),
            "python_version": platform.python_version()
        }
        
        try:
            import psutil
            info.update({
                "cpu_count": psutil.cpu_count(),
                "cpu_freq": psutil.cpu_freq().current if psutil.cpu_freq() else "Unknown",
                "memory_total_gb": round(psutil.virtual_memory().total / (1024**3), 2),
                "memory_available_gb": round(psutil.virtual_memory().available / (1024**3), 2)
            })
        except:
            pass
            
        return info
