"""Bridge between QML and Python configuration."""

import sys
import platform
from PySide6.QtCore import QObject, Property, Signal, Slot
from PySide6.QtQml import QmlElement
from PySide6.QtCore import QSysInfo, qVersion

from .config import app_config, logger

QML_IMPORT_NAME = "ConfigBridge"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class ConfigBridge(QObject):
    """Bridge class to expose app config to QML."""
    
    # Signals for property changes
    appNameChanged = Signal()
    versionChanged = Signal()
    styleChanged = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        # Cache values to avoid frequent database access
        self._app_name = app_config.get_setting("app_name", "Electrical")
        self._version = app_config.get_setting("version", "1.1.0")
        self._style = app_config.get_setting("style", "Universal")
        
    @Property(str, notify=appNameChanged)
    def appName(self):
        """Get application name."""
        return self._app_name
        
    @Property(str, notify=versionChanged)
    def version(self):
        """Get application version."""
        # Always fetch the most current version directly from database
        try:
            current_version = app_config.get_setting("version", "1.1.0")
            if current_version != self._version:
                self._version = current_version
                logger.debug(f"Version updated to: {self._version}")
                # No need to emit signal here as property access doesn't change underlying data
            return self._version
        except Exception as e:
            logger.error(f"Error getting version: {e}")
            return self._version
        
    @Property(str, notify=styleChanged)
    def style(self):
        """Get application style."""
        return self._style

    @Property(str, constant=True)
    def platform(self):
        """Get current platform name."""
        return sys.platform
        
    @Property(str, constant=True)
    def system_version(self):
        """Get system version information."""
        return QSysInfo.prettyProductName()
        
    @Property(str, constant=True)
    def python_version(self):
        """Get Python version."""
        return platform.python_version()
        
    @Property(str, constant=True)
    def qt_version(self):
        """Get Qt version."""
        return qVersion()
        
    @Property(str, constant=True)
    def processor(self):
        """Get processor information."""
        return QSysInfo.currentCpuArchitecture()
        
    @Slot(str, result=str)
    def getSetting(self, key):
        """Get a setting value by key."""
        return str(app_config.get_setting(key, ""))
        
    @Slot()
    def refreshSettings(self):
        """Refresh all settings from database."""
        try:
            self._app_name = app_config.get_setting("app_name", "Electrical")
            self._version = app_config.get_setting("version", "1.1.0")
            self._style = app_config.get_setting("style", "Universal")
            
            # Emit signals after successfully refreshing all values
            self.appNameChanged.emit()
            self.versionChanged.emit()
            self.styleChanged.emit()
            
            logger.debug(f"Settings refreshed, version: {self._version}")
        except Exception as e:
            logger.error(f"Error refreshing settings: {e}")

    @Slot()
    def refreshVersion(self):
        """Refresh version from database and emit change signal."""
        old_version = self._version
        self._version = app_config.get_setting("version", "1.1.0")
        logger.debug(f"Version refreshed from {old_version} to {self._version}")
        self.versionChanged.emit()
        return self._version
