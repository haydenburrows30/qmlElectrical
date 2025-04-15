"""Configuration settings for the application."""

import os
import argparse
from pathlib import Path
from dataclasses import dataclass
from typing import Any, Dict
import json
import asyncio
from concurrent.futures import ThreadPoolExecutor
import sqlite3
from .logger import setup_logger

# Base paths
ROOT_DIR = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA_DIR = ROOT_DIR / 'data'
LOGS_DIR = ROOT_DIR / 'logs'
QML_DIR = ROOT_DIR / 'qml'

# Ensure directories exist
DATA_DIR.mkdir(exist_ok=True)
LOGS_DIR.mkdir(exist_ok=True)

# Add logger instance
logger = setup_logger("config")

@dataclass
class AppConfig:
    """Application configuration class."""
    def __init__(self):
        # Connect to database
        self.db_path = os.path.join(DATA_DIR, 'application_data.db')
        self._init_db()
        self._load_defaults()
        
        # Command line argument parsing
        self.args = self._parse_command_line_args()

    def _init_db(self):
        """Initialize config table in database."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS config (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        )
        ''')
        conn.commit()
        conn.close()

    def _load_defaults(self):
        """Load or create default settings."""
        defaults = {
            "voltage_drop_threshold": 5.0,
            "power_factor": 0.9,
            "default_sample_count": 100,
            "dark_mode": False,
            "show_tooltips": True,
            "decimal_precision": 2,
            "style": "Universal",
            "app_name": "Electrical",
            "org_name": "QtProject",
            "icon_path": "icons/gallery/24x24/Wave_dark.ico",
            "version": "1.1.5"
        }

        try:
            # Use with statement for proper connection handling
            with sqlite3.connect(self.db_path, timeout=20) as conn:
                cursor = conn.cursor()

                # Insert defaults if not exist
                for key, value in defaults.items():
                    cursor.execute("""
                        INSERT OR IGNORE INTO config (key, value) 
                        VALUES (?, ?)
                    """, (key, json.dumps(value)))
                    
                    # Load value from database
                    cursor.execute("SELECT value FROM config WHERE key = ?", (key,))
                    result = cursor.fetchone()
                    if result:
                        setattr(self, key, json.loads(result[0]))
                        logger.debug(f"Loaded setting {key}: {json.loads(result[0])}")
                
                # Force update version in the same connection
                cursor.execute("""
                    UPDATE config SET value = ? WHERE key = ?
                """, (json.dumps(defaults["version"]), "version"))
                conn.commit()
                
                # Set local attribute
                setattr(self, "version", defaults["version"])
                logger.info(f"Application version set to: {self.version}")
                
        except sqlite3.Error as e:
            logger.error(f"Database error in _load_defaults: {e}")

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
        try:
            # Use with statement for proper connection handling
            with sqlite3.connect(self.db_path, timeout=20) as conn:
                cursor = conn.cursor()
                
                cursor.execute("""
                    INSERT OR REPLACE INTO config (key, value) 
                    VALUES (?, ?)
                """, (key, json.dumps(value)))
                
                conn.commit()
            
            # Set local attribute after database save
            setattr(self, key, value)
            logger.debug(f"Successfully saved setting {key}: {value}")
            return True
            
        except Exception as e:
            logger.error(f"Error saving setting {key}: {e}")
            return False

    def get_setting(self, key: str, default: Any = None) -> Any:
        """Get a setting from the database."""
        try:
            # Use with statement for proper connection handling
            with sqlite3.connect(self.db_path, timeout=20) as conn:
                cursor = conn.cursor()
                
                cursor.execute("SELECT value FROM config WHERE key = ?", (key,))
                result = cursor.fetchone()
            
            if result:
                return json.loads(result[0])
            return default
            
        except Exception as e:
            logger.error(f"Error getting setting {key}: {e}")
            return default

def print_config_info() -> None:
    """Display current config settings from database."""
    logger.info("=== Configuration Information ===")
    
    try:
        # Use with statement for proper connection handling
        with sqlite3.connect(app_config.db_path, timeout=20) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT key, value FROM config")
            settings = cursor.fetchall()
        
        if settings:
            logger.info(f"Database location: {app_config.db_path}")
            logger.info("Current configuration:")
            for key, value in settings:
                logger.info(f"  {key}: {value}")
        else:
            logger.info("No configuration settings found in database.")
    except Exception as e:
        logger.error(f"Error reading configuration: {e}")

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
    await loop.run_in_executor(executor, setup_logger)
    
    return config

# Initialize immediately when module is imported
logger.info(f"Loading configuration module from: {ROOT_DIR}")
app_config = asyncio.run(initialize_config())

if __name__ == '__main__':
    print_config_info()
