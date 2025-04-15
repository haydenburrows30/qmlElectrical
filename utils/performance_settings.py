import json
import os

class PerformanceSettings:
    _instance = None
    
    @classmethod
    def get_instance(cls):
        """Get the singleton instance"""
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance
    
    def __init__(self):
        self._settings_file = os.path.expanduser("~/Documents/qmltest/settings/performance.json")
        self._settings = {
            "resolution": 250,
            "update_interval": 50,
            "quality_level": 1,  # 0=low, 1=medium, 2=high
            "antialiasing": False,
            "cache_size": 50
        }
        self._load_settings()
    
    def _load_settings(self):
        """Load settings from file"""
        try:
            if os.path.exists(self._settings_file):
                with open(self._settings_file, 'r') as f:
                    loaded = json.load(f)
                    self._settings.update(loaded)
        except Exception as e:
            print(f"Error loading performance settings: {e}")
    
    def save_settings(self):
        """Save settings to file"""
        try:
            os.makedirs(os.path.dirname(self._settings_file), exist_ok=True)
            with open(self._settings_file, 'w') as f:
                json.dump(self._settings, f)
        except Exception as e:
            print(f"Error saving performance settings: {e}")
    
    def get(self, key, default=None):
        """Get a setting value"""
        return self._settings.get(key, default)
    
    def set(self, key, value):
        """Set a setting value"""
        self._settings[key] = value
        self.save_settings()
