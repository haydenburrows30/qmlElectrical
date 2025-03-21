import pandas as pd
import sqlite3
import os
import json
import threading
from PySide6.QtCore import QObject, Signal, QThread

class DataStore(QObject):
    """
    Centralized data storage for the application.
    
    Provides in-memory and SQLite storage options as alternatives to CSV files.
    This class serves as a single point of access for all data in the application.
    """
    
    dataChanged = Signal(str)  # Emitted when data in a particular category changes
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Ensure we're in the main thread for Qt objects
        if QThread.currentThread() != parent.thread() if parent else None:
            raise RuntimeError("DataStore must be created in the application's main thread")
        
        # In-memory storage
        self._memory_store = {
            'cable_data': {},
            'diversity_factors': [],
            'fuse_sizes': [],
            'calculation_history': [],
            'settings': {}
        }
        
        # SQLite connection (for larger datasets if needed)
        db_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'application_data.db')
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        
        # Use a thread-local storage for SQLite connections to ensure thread safety
        self._local = threading.local()
        self._db_path = db_path
        
        # Initialize database if needed
        self._init_database()
        
        # Initialize with default data
        self._init_default_data()
    
    @property
    def _connection(self):
        """Get a thread-local database connection."""
        if not hasattr(self._local, 'connection'):
            self._local.connection = sqlite3.connect(self._db_path)
        return self._local.connection
    
    def _init_database(self):
        """Initialize SQLite database tables if they don't exist."""
        cursor = self._connection.cursor()
        
        # Create tables
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS calculation_history (
            id INTEGER PRIMARY KEY,
            timestamp TEXT,
            voltage_system TEXT,
            kva_per_house REAL,
            num_houses INTEGER,
            diversity_factor REAL,
            total_kva REAL,
            current REAL,
            cable_size TEXT,
            conductor TEXT,
            core_type TEXT,
            length REAL,
            voltage_drop REAL,
            drop_percent REAL,
            admd_enabled INTEGER
        )
        ''')
        
        # Create settings table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT
        )
        ''')
        
        self._connection.commit()

    def _init_default_data(self):
        """Initialize default data for the application."""
        # Setup cable data
        self._memory_store['cable_data'] = {
            'cu_1c': {
                'size': [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400],
                'mv_per_am': [26, 15.6, 9.8, 6.5, 3.9, 2.5, 1.6, 1.2, 0.87, 0.62, 0.46, 0.37, 0.31, 0.25, 0.20, 0.17, 0.15],
                'max_current': [19.5, 27, 36, 45, 63, 85, 110, 135, 160, 200, 240, 280, 320, 365, 430, 495, 560]
            },
            'cu_3c': {
                'size': [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400],
                'mv_per_am': [26.5, 15.9, 10, 6.7, 4.0, 2.5, 1.6, 1.2, 0.93, 0.61, 0.45, 0.37, 0.33, 0.27, 0.22, 0.19, 0.17],
                'max_current': [17.5, 24, 31, 39, 54, 63, 95, 165, 140, 240, 290, 355, 280, 470, 375, 430, 485]
            },
            'al_1c': {
                'size': [16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400, 500, 630],
                'mv_per_am': [2.6, 1.7, 1.9, 1.4, 0.98, 0.75, 0.60, 0.50, 0.41, 0.32, 0.27, 0.24, 0.21, 0.18],
                'max_current': [115, 150, 105, 125, 160, 190, 220, 255, 290, 345, 395, 445, 495, 555]
            },
            'al_3c': {
                'size': [16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400, 500, 630],
                'mv_per_am': [4.2, 2.7, 2.0, 1.5, 1.1, 0.72, 0.58, 0.54, 0.39, 0.31, 0.27, 0.27, 0.24, 0.21],
                'max_current': [57, 75, 92, 110, 140, 240, 275, 225, 350, 410, 460, 390, 435, 485]
            }
        }
        
        # Set up diversity factors data
        self._memory_store['diversity_factors'] = {
            'houses': [1, 2, 3, 4, 5, 10, 15, 20, 30, 40, 50, 100, 200],
            'factor': [1.0, 0.95, 0.90, 0.85, 0.80, 0.65, 0.55, 0.50, 0.45, 0.42, 0.40, 0.35, 0.30]
        }
        
        # Setup fuse sizes data
        self._memory_store['fuse_sizes'] = {
            'Material': ['Cu', 'Cu', 'Cu', 'Cu', 'Cu', 'Al', 'Al', 'Al', 'Al', 'Al', 'Al', 'Al'],
            'Size (mm2)': [16, 25, 35, 50, 95, 25, 35, 50, 95, 185, 300, 630],
            'Network Fuse Size (A)': [80, 100, 125, 160, 250, 63, 80, 100, 160, 250, 315, 500]
        }
    
    def get_cable_data(self, material, core_type):
        """Get cable data for specified material and core type."""
        key = f"{material.lower()}_{'1c' if core_type == '1C+E' else '3c'}"
        data = self._memory_store['cable_data'].get(key)
        if data:
            return pd.DataFrame(data)
        return None
    
    def get_diversity_factors(self):
        """Get diversity factors as DataFrame."""
        return pd.DataFrame(self._memory_store['diversity_factors'])
    
    def get_fuse_sizes(self):
        """Get fuse sizes as DataFrame."""
        return pd.DataFrame(self._memory_store['fuse_sizes'])
    
    def add_calculation(self, data):
        """Add calculation to history in both memory and SQLite."""
        # Add to in-memory store
        self._memory_store['calculation_history'].append(data)
        
        # Add to SQLite database
        try:
            cursor = self._connection.cursor()
            columns = ','.join(data.keys())
            placeholders = ','.join(['?'] * len(data))
            query = f"INSERT INTO calculation_history ({columns}) VALUES ({placeholders})"
            cursor.execute(query, list(data.values()))
            self._connection.commit()
        except sqlite3.Error as e:
            print(f"SQLite error adding calculation: {e}")
            # Continue with in-memory storage even if SQLite fails
        
        # Notify listeners (using the thread-safe Qt signal system)
        self.dataChanged.emit('calculation_history')
        return True
    
    def get_calculation_history(self):
        """Get calculation history as DataFrame."""
        try:
            # Get from SQLite for persistence
            cursor = self._connection.cursor()
            cursor.execute("SELECT * FROM calculation_history ORDER BY timestamp DESC")
            columns = [col[0] for col in cursor.description]
            results = cursor.fetchall()
            
            # Convert to DataFrame
            df = pd.DataFrame(results, columns=columns)
            return df
        except sqlite3.Error as e:
            print(f"SQLite error getting calculation history: {e}")
            # Fall back to in-memory data if SQLite fails
            if self._memory_store['calculation_history']:
                return pd.DataFrame(self._memory_store['calculation_history'])
            return pd.DataFrame()
    
    def clear_calculation_history(self):
        """Clear calculation history from both memory and SQLite."""
        # Clear in-memory store
        self._memory_store['calculation_history'].clear()
        
        # Clear SQLite database
        cursor = self._connection.cursor()
        cursor.execute("DELETE FROM calculation_history")
        self._connection.commit()
        
        # Notify listeners
        self.dataChanged.emit('calculation_history')
        return True
    
    def get_setting(self, key, default=None):
        """Get a setting value from storage."""
        # Check in-memory cache first
        if key in self._memory_store['settings']:
            return self._memory_store['settings'][key]
        
        # Check SQLite database
        cursor = self._connection.cursor()
        cursor.execute("SELECT value FROM settings WHERE key = ?", (key,))
        result = cursor.fetchone()
        
        if result:
            # Cache the result in memory
            value = json.loads(result[0])
            self._memory_store['settings'][key] = value
            return value
        
        return default
    
    def set_setting(self, key, value):
        """Save a setting value to storage."""
        # Update in-memory cache
        self._memory_store['settings'][key] = value
        
        # Update SQLite database
        value_json = json.dumps(value)
        cursor = self._connection.cursor()
        cursor.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
            (key, value_json)
        )
        self._connection.commit()
        
        # Notify listeners
        self.dataChanged.emit('settings')
        return True
    
    def export_data(self, data_type, filepath=None):
        """Export data to a file."""
        if data_type not in self._memory_store:
            return False
        
        if not filepath:
            return False
        
        data = self._memory_store[data_type]
        
        # Convert to appropriate format and export
        if isinstance(data, dict):
            # Export as JSON for dictionaries
            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)
        else:
            # Export as CSV for lists
            df = pd.DataFrame(data)
            df.to_csv(filepath, index=False)
        
        return True
    
    def import_data(self, data_type, filepath):
        """Import data from a file."""
        if not os.path.exists(filepath):
            return False
        
        # Determine file type
        if filepath.endswith('.json'):
            with open(filepath, 'r') as f:
                data = json.load(f)
        elif filepath.endswith('.csv'):
            df = pd.read_csv(filepath)
            data = df.to_dict('list')
        else:
            return False
        
        # Update data store
        self._memory_store[data_type] = data
        
        # Notify listeners
        self.dataChanged.emit(data_type)
        return True
    
    def close(self):
        """Close database connection."""
        if hasattr(self._local, 'connection'):
            try:
                self._local.connection.close()
                del self._local.connection
            except:
                pass