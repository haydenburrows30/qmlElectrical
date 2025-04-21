from PySide6.QtCore import QObject, Property, Slot, Signal
from utils.config import AppConfig
import platform
import PySide6.QtCore

class ConfigBridge(QObject):
    """Bridge to expose AppConfig properties to QML."""
    
    # Add signal for settings that can change
    settingChanged = Signal(str, arguments=['key'])
    
    def __init__(self):
        super().__init__()
        self._config = AppConfig()
        self._app_name = self._config.get_setting("app_name", "Default App Name")
        self._version = self._config.get_setting("version", "1.0.0")
        self._style = self._config.get_setting("style", "Test")

        self._system = platform.system()
        self._system_version = platform.version()
        self._platform = platform.platform()
        self._python_version = platform.python_version()
        self._processor = platform.processor()
        
        self._qt_version = PySide6.QtCore.__version__

    @Property(str, constant=True)
    def appName(self):
        return self._app_name

    @Property(str, constant=True)
    def version(self):
        return self._version
    
    @Property(str, constant=True)
    def style(self):
        return self._style
    
    @Property(str, constant=True)
    def system(self):
        return self._system
    
    @Property(str, constant=True)
    def system_version(self):
        return self._system_version
    
    @Property(str, constant=True)
    def python_version(self):
        return self._python_version
    
    @Property(str, constant=True)
    def qt_version(self):
        return self._qt_version
    
    @Property(str, constant=True)
    def platform(self):
        return self._platform
    
    @Property(str, constant=True)
    def processor(self):
        return self._processor

    @Slot(str, 'QVariant')
    def save_setting(self, key, value):
        """Save a setting to the database."""
        success = self._config.save_setting(key, value)
        if success:
            # Emit signal to notify of changed setting
            self.settingChanged.emit(key)
        return success

    @Slot(str, 'QVariant', result='QVariant')  
    def get_setting(self, key, default=None):
        """Get a setting from the database."""
        return self._config.get_setting(key, default)