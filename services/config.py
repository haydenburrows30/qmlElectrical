"""Configuration settings for the application."""

import os
import argparse
from pathlib import Path
from dataclasses import dataclass
from typing import Any, Dict
import json
import asyncio
from concurrent.futures import ThreadPoolExecutor
from services.logger_config import configure_logger
from services.database_manager import DatabaseManager

# Base paths
ROOT_DIR = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA_DIR = ROOT_DIR / 'data'
LOGS_DIR = ROOT_DIR / 'logs'
QML_DIR = ROOT_DIR / 'qml'

# Ensure directories exist
DATA_DIR.mkdir(exist_ok=True)
LOGS_DIR.mkdir(exist_ok=True)

# Add logger instance with component-specific configuration
logger = configure_logger("qmltest", component="config")

@dataclass
class AppConfig:
    """Application configuration class."""
    def __init__(self):
        # Get database manager instance
        self.db_path = os.path.join(DATA_DIR, 'application_data.db')
        self.db_manager = DatabaseManager.get_instance(self.db_path)
        self._load_defaults()
        
        # Command line argument parsing
        self.args = self._parse_command_line_args()

    def _load_defaults(self):
        """Load or create default settings."""
        # Default settings are now managed by the database manager
        # in its _load_default_config method
        
        # Load all config values into attributes of this object
        config_dict = self.db_manager.get_all_config()
        for key, value in config_dict.items():
            setattr(self, key, value)
            logger.debug(f"Loaded setting {key}: {value}")
        
        # Ensure version is set correctly (always use the value from code)
        self.version = "1.1.9"
        self.db_manager.set_config("version", self.version)
        logger.info(f"Application version set to: {self.version}")

    def _parse_command_line_args(self) -> argparse.Namespace:
        """Parse command line arguments."""
        parser = argparse.ArgumentParser(description='Application launcher')
        parser.add_argument('--renderer', choices=['software', 'angle', 'desktop'], 
                            help='Override renderer selection')
        parser.add_argument('--no-cache', action='store_true', 
                            help='Disable QML disk cache')
        parser.add_argument('--debug', action='store_true',
                            help='Enable additional debug output')
        parser.add_argument('--clear-cache', action='store_true',
                            help='Clear the QML cache before starting')
        
        # Parse known args and ignore unknown ones
        args, _ = parser.parse_known_args()
        return args
        
    def setup_environment(self) -> None:
        """Set up environment variables based on configuration."""
        # Handle cache options
        if self.args.no_cache:
            os.environ["QT_QPA_DISABLE_DISK_CACHE"] = "1"
            logger.info("QML disk cache disabled")
            
        # Handle renderer option
        if self.args.renderer:
            os.environ["QT_OPENGL"] = self.args.renderer
            logger.info(f"Using renderer: {self.args.renderer}")
        
        # Handle debug option
        if self.args.debug:
            # Enable Qt debug output
            os.environ["QT_DEBUG_PLUGINS"] = "1"
            os.environ["QT_LOGGING_RULES"] = "qt.qml.connections=true"
            logger.info("Debug mode enabled")
            
    def get_qml_directories(self) -> Dict[str, Path]:
        """Get the QML directories for preloading."""
        result = {}
        
        # Add standard directories that should exist
        for subdir in ['pages', 'components', 'calculators']:
            full_path = QML_DIR / subdir
            if full_path.exists() and full_path.is_dir():
                result[subdir] = full_path
                
                # Also add subdirectories
                for item in full_path.iterdir():
                    if item.is_dir():
                        result[f"{subdir}/{item.name}"] = item
                        
        return result
        
    def save_setting(self, key: str, value: Any) -> bool:
        """Save a setting to the database."""
        # Use the database manager to save the setting
        success = self.db_manager.set_config(key, value)
        
        # Also update the local attribute
        if success:
            setattr(self, key, value)
            
        return success

    def get_setting(self, key: str, default: Any = None) -> Any:
        """Get a setting from the database."""
        # Use the database manager to get the setting
        return self.db_manager.get_config(key, default)

def print_config_info() -> None:
    """Display current config settings from database."""
    logger.info("=== Configuration Information ===")
    
    # Get database manager instance
    db_path = os.path.join(DATA_DIR, 'application_data.db')
    db_manager = DatabaseManager.get_instance(db_path)
    
    # Get all configuration
    config_dict = db_manager.get_all_config()
    
    if config_dict:
        logger.info(f"Database location: {db_path}")
        logger.info("Current configuration:")
        for key, value in config_dict.items():
            logger.info(f"  {key}: {value}")
    else:
        logger.info("No configuration settings found in database.")

# Function to expose config info to other modules
def log_config_info():
    """Log the current configuration settings."""
    print_config_info()
    return True

async def initialize_config() -> AppConfig:
    """Initialize configuration asynchronously."""
    loop = asyncio.get_event_loop()
    executor = ThreadPoolExecutor()
    
    # Load config file in background thread
    config = await loop.run_in_executor(executor, AppConfig)
    
    # Initialize logging in background
    await loop.run_in_executor(executor, configure_logger)
    
    return config

# Initialize immediately when module is imported
logger.info(f"Loading configuration module from: {ROOT_DIR}")
app_config = asyncio.run(initialize_config())

if __name__ == '__main__':
    print_config_info()