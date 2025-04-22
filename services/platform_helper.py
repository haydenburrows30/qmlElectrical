import platform
from PySide6.QtCore import QObject, Signal, Slot, Property

class PlatformHelper(QObject):
    """Helper class for platform-specific optimizations and workarounds"""
    
    platformChanged = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._initialize()
        
    def _initialize(self):
        """Initialize platform detection"""
        self._platform = platform.system().lower()
        self._is_windows = self._platform == 'windows'
        self._is_linux = self._platform == 'linux'
        self._is_mac = self._platform == 'darwin'
        self._win_version = platform.version() if self._is_windows else ""
        
        # Windows-specific GL debug info
        if self._is_windows:
            try:
                import ctypes
                opengl32 = ctypes.windll.opengl32
                print("OpenGL32 library loaded successfully")
            except Exception as e:
                print(f"OpenGL32 library check failed: {e}")
        
    @Property(str, notify=platformChanged)
    def platform(self):
        """Get the current platform name (windows, linux, darwin)"""
        return self._platform
        
    @Property(bool, notify=platformChanged)
    def isWindows(self):
        """Check if running on Windows"""
        return self._is_windows
        
    @Property(bool, notify=platformChanged)
    def isLinux(self):
        """Check if running on Linux"""
        return self._is_linux
        
    @Property(bool, notify=platformChanged)
    def isMac(self):
        """Check if running on macOS"""
        return self._is_mac
    
    @Property(str, notify=platformChanged)
    def windowsVersion(self):
        """Get Windows version if applicable"""
        return self._win_version
        
    @Slot(result=bool)
    def shouldUseOpenGL(self):
        """Determine if OpenGL should be used based on platform"""
        # Disable OpenGL on Windows as it can cause rendering issues
        return not self._is_windows
        
    @Slot(result=int)
    def recommendedChartPoints(self):
        """Get recommended number of chart points based on platform"""
        if self._is_windows:
            return 100  # Fewer points on Windows for better performance
        else:
            return 250  # More points on other platforms
            
    @Slot(result=int)
    def recommendedUpdateInterval(self):
        """Get recommended UI update interval in ms"""
        if self._is_windows:
            return 100  # Slower updates on Windows
        else:
            return 50   # Faster updates on other platforms
