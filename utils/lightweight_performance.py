import os
import time
from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer, QElapsedTimer

class LightweightPerformanceMonitor(QObject):
    """Non-intrusive performance monitoring that doesn't interfere with input"""
    
    # Signals for QML updates
    fpsChanged = Signal(float)
    renderTimeChanged = Signal(float)
    memoryUsageChanged = Signal(float)
    cpuUsageChanged = Signal(float)
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Performance metrics
        self._fps = 0.0
        self._render_time = 0.0
        self._memory_usage = 0.0
        self._cpu_usage = 0.0
        
        # Frame counting
        self._frame_counter = 0
        self._last_frame_time = time.time()
        
        # Render timing
        self._render_times = []
        self._render_timer = QElapsedTimer()
        
        # Resource monitoring
        self._resource_timer = QTimer(self)
        self._resource_timer.timeout.connect(self._update_resource_usage)
        self._resource_timer.start(2000)  # Update every 2 seconds
        
        # FPS calculation
        self._fps_timer = QTimer(self)
        self._fps_timer.timeout.connect(self._calculate_fps)
        self._fps_timer.start(1000)  # Calculate FPS every second
        
        # Auto-optimization (disabled by default)
        self._auto_optimize = False
        self._optimizations_applied = False
    
    @Slot()
    def frameRendered(self):
        """Called when a frame is rendered"""
        self._frame_counter += 1
    
    @Slot()
    def beginRenderTiming(self):
        """Start timing a render operation"""
        self._render_timer.restart()
    
    @Slot()
    def endRenderTiming(self):
        """End timing a render operation"""
        elapsed = self._render_timer.elapsed()
        
        # Keep a rolling window of render times
        self._render_times.append(elapsed)
        if len(self._render_times) > 60:
            self._render_times.pop(0)
        
        # Calculate average render time
        if self._render_times:
            avg_time = sum(self._render_times) / len(self._render_times)
            if avg_time != self._render_time:
                self._render_time = avg_time
                self.renderTimeChanged.emit(avg_time)
    
    def _calculate_fps(self):
        """Calculate FPS based on frame count in the last second"""
        current_time = time.time()
        elapsed = current_time - self._last_frame_time
        
        if elapsed > 0:
            fps = self._frame_counter / elapsed
            self._fps = fps
            self.fpsChanged.emit(fps)
        
        # Reset counters
        self._frame_counter = 0
        self._last_frame_time = current_time
        
        # Auto-optimize if enabled and performance is poor
        if self._auto_optimize and self._fps < 30 and not self._optimizations_applied:
            self.applyOptimizations()
    
    def _update_resource_usage(self):
        """Update memory and CPU usage statistics"""
        try:
            import psutil
            
            # Memory usage
            memory_percent = psutil.virtual_memory().percent
            if memory_percent != self._memory_usage:
                self._memory_usage = memory_percent
                self.memoryUsageChanged.emit(memory_percent)
            
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=None)
            if cpu_percent != self._cpu_usage:
                self._cpu_usage = cpu_percent
                self.cpuUsageChanged.emit(cpu_percent)
        except ImportError:
            # psutil not available
            pass
    
    @Slot(bool)
    def setAutoOptimize(self, enabled):
        """Enable or disable automatic optimization"""
        self._auto_optimize = enabled
    
    @Slot()
    def applyOptimizations(self):
        """Apply performance optimizations based on current platform"""
        if self._optimizations_applied:
            return
        
        import platform
        is_windows = platform.system() == "Windows"
        
        # Platform-specific optimizations
        if is_windows:
            # Windows optimizations
            os.environ["QSG_RENDER_LOOP"] = "basic"  # Use basic render loop for stability
            os.environ["QT_OPENGL"] = "software"     # Use software renderer for compatibility
            
            # Boost process priority
            try:
                import ctypes
                ctypes.windll.kernel32.SetPriorityClass(
                    ctypes.windll.kernel32.GetCurrentProcess(), 
                    0x00008000  # ABOVE_NORMAL_PRIORITY_CLASS
                )
            except:
                pass
        
        # Mark optimizations as applied
        self._optimizations_applied = True
    
    # Properties for QML
    def fps(self):
        return self._fps
    
    def renderTime(self):
        return self._render_time
    
    def memoryUsage(self):
        return self._memory_usage
    
    def cpuUsage(self):
        return self._cpu_usage
    
    # Property definitions
    fps = Property(float, fps, notify=fpsChanged)
    renderTime = Property(float, renderTime, notify=renderTimeChanged)
    memoryUsage = Property(float, memoryUsage, notify=memoryUsageChanged)
    cpuUsage = Property(float, cpuUsage, notify=cpuUsageChanged)