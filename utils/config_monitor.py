import json
from PySide6.QtCore import QObject, Signal, Slot, Property

class ConfigMonitor(QObject):
    """
    Utility class to monitor and debug configuration loading/saving
    """
    configUpdated = Signal(str)
    
    def __init__(self):
        super().__init__()
        self._last_config = {}
        
    @Slot('QVariant')
    def log_config(self, config):
        """Log a configuration object to the console and emit signal"""
        try:
            # Convert QJSValue to Python if needed
            if hasattr(config, 'toVariant'):
                config = config.toVariant()
                
            # Pretty format as JSON
            formatted_json = json.dumps(config, indent=2)
            print(f"Configuration:\n{formatted_json}")
            
            # Store for later reference
            self._last_config = config
            
            # Emit signal with formatted JSON
            self.configUpdated.emit(formatted_json)
            
            return True
        except Exception as e:
            print(f"Error logging config: {e}")
            return False
            
    @Property('QVariant')
    def lastConfig(self):
        """Return the last logged configuration"""
        return self._last_config
