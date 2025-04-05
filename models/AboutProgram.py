from PySide6.QtCore import QObject, Property
from .config import AppConfig  # Using relative import since both are in the models package

class ConfigBridge(QObject):
    """Bridge to expose AppConfig properties to QML."""
    def __init__(self):
        super().__init__()
        self._config = AppConfig()
        self._app_name = self._config.get_setting("app_name", "Default App Name")
        self._version = self._config.get_setting("version", "1.0.0")
        self._style = self._config.get_setting("style", "Test")

    @Property(str, constant=True)
    def appName(self):
        return self._app_name

    @Property(str, constant=True)
    def version(self):
        return self._version
    
    @Property(str, constant=True)
    def style(self):
        return self._style