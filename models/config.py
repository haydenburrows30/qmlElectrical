"""Configuration settings for the application."""

import os
from pathlib import Path
from dataclasses import dataclass
from typing import Dict, Any, List, Optional
import json
from .logger import setup_logger

# Base paths
ROOT_DIR = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA_DIR = ROOT_DIR / 'data'
RESULTS_DIR = ROOT_DIR / 'results'
LOGS_DIR = ROOT_DIR / 'logs'

# Ensure directories exist
DATA_DIR.mkdir(exist_ok=True)
RESULTS_DIR.mkdir(exist_ok=True)
LOGS_DIR.mkdir(exist_ok=True)

# Add logger instance
logger = setup_logger("config")

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
    
    # Application settings
    style: str = "Universal"
    app_name: str = "Electrical"
    org_name: str = "QtProject"
    icon_path: str = "icons/gallery/24x24/Wave_dark.ico"
    
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
            "decimal_precision": self.decimal_precision,
            "style": self.style,
            "app_name": self.app_name,
            "org_name": self.org_name,
            "icon_path": self.icon_path
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
            decimal_precision=int(config_dict.get("decimal_precision", 2)),
            style=str(config_dict.get("style", "Universal")),
            app_name=str(config_dict.get("app_name", "Electrical")),
            org_name=str(config_dict.get("org_name", "QtProject")),
            icon_path=str(config_dict.get("icon_path", "icons/gallery/24x24/Wave_dark.ico"))
        )

def load_config() -> AppConfig:
    """Load application configuration from config.json."""
    config_file = ROOT_DIR / 'config.json'
    
    if not config_file.exists():
        logger.info(f"Config file not found at {config_file}, creating default configuration")
        config = AppConfig()
        save_config(config)
        return config
        
    try:
        with open(config_file, 'r') as f:
            config_dict = json.load(f)
            return AppConfig.from_dict(config_dict)
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in config file: {e}. Using defaults.")
        return AppConfig()
    except Exception as e:
        logger.error(f"Unexpected error loading config: {e}. Using defaults.")
        return AppConfig()

def save_config(config: AppConfig) -> bool:
    """Save application configuration to config.json.
    
    Returns:
        bool: True if save was successful, False otherwise
    """
    config_file = ROOT_DIR / 'config.json'
    
    try:
        with open(config_file, 'w') as f:
            json.dump(config.to_dict(), f, indent=4)
        return True
    except Exception as e:
        logger.error(f"Error saving config to {config_file}: {e}")
        return False

def print_config_info() -> None:
    """Display current config file location and contents."""
    config_file = ROOT_DIR / 'config.json'
    print(f"\nConfig file location: {config_file}")
    
    if config_file.exists():
        try:
            with open(config_file, 'r') as f:
                print("\nCurrent config contents:")
                print(json.dumps(json.load(f), indent=2))
        except Exception as e:
            print(f"\nError reading config: {e}")
    else:
        print("\nConfig file does not exist yet. It will be created with defaults when needed.")

def ensure_config_exists() -> None:
    """Ensure config file exists, create with defaults if it doesn't."""
    config_file = ROOT_DIR / 'config.json'
    if not config_file.exists():
        logger.info(f"Creating default config file at {config_file}")
        config = AppConfig()
        if save_config(config):
            logger.info("Successfully created config file")
        else:
            logger.error("Failed to create config file")

def initialize_config() -> AppConfig:
    """Initialize the configuration system."""
    config_file = ROOT_DIR / 'config.json'
    logger.info(f"Initializing configuration system from: {config_file}")
    ensure_config_exists()
    config = load_config()
    logger.info("Configuration loaded successfully")
    return config

# Initialize immediately when module is imported
logger.info(f"Loading configuration module from: {ROOT_DIR}")
app_config = initialize_config()

if __name__ == '__main__':
    print_config_info()
