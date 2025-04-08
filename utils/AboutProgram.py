from PySide6.QtCore import QObject, Property
from utils.config import AppConfig  # Using relative import since both are in the models package
import platform
import PySide6.QtCore

class ConfigBridge(QObject):
    """Bridge to expose AppConfig properties to QML."""
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