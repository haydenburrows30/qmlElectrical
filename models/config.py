"""Configuration settings for the application."""

import os
from pathlib import Path
from dataclasses import dataclass
from typing import Any
import json
import asyncio
from concurrent.futures import ThreadPoolExecutor
import sqlite3
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
    def __init__(self):
        # Connect to database
        self.db_path = os.path.join(DATA_DIR, 'application_data.db')
        self._init_db()
        self._load_defaults()

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
            "icon_path": "icons/gallery/24x24/Wave_dark.ico"
        }

        conn = sqlite3.connect(self.db_path)
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

        conn.commit()
        conn.close()

    def save_setting(self, key: str, value: Any) -> bool:
        """Save a setting to the database."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT OR REPLACE INTO config (key, value) 
                VALUES (?, ?)
            """, (key, json.dumps(value)))
            
            conn.commit()
            conn.close()
            
            setattr(self, key, value)
            return True
        except Exception as e:
            logger.error(f"Error saving setting {key}: {e}")
            return False

    def get_setting(self, key: str, default: Any = None) -> Any:
        """Get a setting from the database."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("SELECT value FROM config WHERE key = ?", (key,))
            result = cursor.fetchone()
            
            conn.close()
            
            if result:
                return json.loads(result[0])
            return default
            
        except Exception as e:
            logger.error(f"Error getting setting {key}: {e}")
            return default

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
