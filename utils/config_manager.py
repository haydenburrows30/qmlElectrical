import os
from pathlib import Path
from typing import Any, Dict, Optional

try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False
    
class ConfigManager:
    def __init__(self):
        self.config: Dict[str, Any] = self._get_default_config()
        self._load_config()
    
    def _get_default_config(self) -> Dict[str, Any]:
        return {
            "app": {
                "name": "ElectricalCalculator",
                "version": "1.0.0",
                "organization": "ElectricalTools"
            },
            "ui": {
                "style": "Material",
                "theme": "Light",
                "icon_path": str(Path(__file__).parent.parent / "resources" / "icons" / "app.png")
            },
            "cache": {
                "enabled": True
            },
            "qml": {
                "directories": {
                    "components": str(Path(__file__).parent.parent / "qml" / "components"),
                    "pages": str(Path(__file__).parent.parent / "qml" / "pages"),
                    "calculators": str(Path(__file__).parent.parent / "qml" / "calculators")
                }
            }
        }
    
    def _load_config(self) -> None:
        """Load configuration from YAML if available"""
        if not YAML_AVAILABLE:
            return
            
        config_file = Path(__file__).parent.parent / "config" / "config.yaml"
        if config_file.exists():
            try:
                with open(config_file) as f:
                    yaml_config = yaml.safe_load(f)
                    if yaml_config:
                        self._merge_configs(self.config, yaml_config)
            except Exception as e:
                print(f"Warning: Failed to load config.yaml: {e}")
    
    def _merge_configs(self, base: Dict, override: Dict) -> None:
        """Recursively merge override into base config"""
        for key, value in override.items():
            if isinstance(value, dict) and key in base:
                self._merge_configs(base[key], value)
            else:
                base[key] = value
    
    def get(self, path: str, default: Any = None) -> Any:
        """Get configuration value using dot notation"""
        current = self.config
        for part in path.split('.'):
            if isinstance(current, dict):
                current = current.get(part, default)
            else:
                return default
        return current

    def set(self, path: str, value: Any) -> None:
        """Set configuration value using dot notation"""
        parts = path.split('.')
        current = self.config
        for part in parts[:-1]:
            current = current.setdefault(part, {})
        current[parts[-1]] = value
