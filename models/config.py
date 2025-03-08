"""Configuration settings for the application."""

import os
from pathlib import Path
from dataclasses import dataclass
from typing import Dict, Any, List, Optional
import json

# Base paths
ROOT_DIR = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA_DIR = ROOT_DIR / 'data'
RESULTS_DIR = ROOT_DIR / 'results'
LOGS_DIR = ROOT_DIR / 'logs'

# Ensure directories exist
DATA_DIR.mkdir(exist_ok=True)
RESULTS_DIR.mkdir(exist_ok=True)
LOGS_DIR.mkdir(exist_ok=True)

@dataclass
class AppConfig:
    """Application configuration class."""
    # Default values
    voltage_drop_threshold: float = 5.0
    power_factor: float = 0.9
    default_sample_count: int = 100
    default_cable_data_file: str = str(DATA_DIR / 'cable_data.csv')
    results_file: str = str(RESULTS_DIR / 'calculations_history.csv')
    
    # UI settings
    dark_mode: bool = False
    show_tooltips: bool = True
    decimal_precision: int = 2
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert config to dictionary."""
        return {
            "voltage_drop_threshold": self.voltage_drop_threshold,
            "power_factor": self.power_factor,
            "default_sample_count": self.default_sample_count,
            "default_cable_data_file": self.default_cable_data_file,
            "results_file": self.results_file,
            "dark_mode": self.dark_mode,
            "show_tooltips": self.show_tooltips,
            "decimal_precision": self.decimal_precision
        }
    
    @classmethod
    def from_dict(cls, config_dict: Dict[str, Any]) -> 'AppConfig':
        """Create config from dictionary."""
        return cls(
            voltage_drop_threshold=float(config_dict.get("voltage_drop_threshold", 5.0)),
            power_factor=float(config_dict.get("power_factor", 0.9)),
            default_sample_count=int(config_dict.get("default_sample_count", 100)),
            default_cable_data_file=str(config_dict.get("default_cable_data_file", str(DATA_DIR / 'cable_data.csv'))),
            results_file=str(config_dict.get("results_file", str(RESULTS_DIR / 'calculations_history.csv'))),
            dark_mode=bool(config_dict.get("dark_mode", False)),
            show_tooltips=bool(config_dict.get("show_tooltips", True)),
            decimal_precision=int(config_dict.get("decimal_precision", 2))
        )

def load_config() -> AppConfig:
    """Load application configuration from config.json."""
    config_file = ROOT_DIR / 'config.json'
    
    if not config_file.exists():
        # Create default config if it doesn't exist
        config = AppConfig()
        save_config(config)
        return config
        
    try:
        with open(config_file, 'r') as f:
            config_dict = json.load(f)
            return AppConfig.from_dict(config_dict)
    except Exception as e:
        print(f"Error loading config: {e}. Using defaults.")
        return AppConfig()

def save_config(config: AppConfig) -> None:
    """Save application configuration to config.json."""
    config_file = ROOT_DIR / 'config.json'
    
    try:
        with open(config_file, 'w') as f:
            json.dump(config.to_dict(), f, indent=4)
    except Exception as e:
        print(f"Error saving config: {e}")

# Default configuration instance
app_config = load_config()
