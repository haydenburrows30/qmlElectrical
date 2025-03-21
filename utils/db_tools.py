import sqlite3
import os
import json
import pandas as pd
from datetime import datetime
import shutil

class DatabaseTools:
    """Database maintenance and viewing tools."""
    
    def __init__(self, db_path):
        self.db_path = db_path
        self._conn = None
        self._ensure_schema()
        
    @property
    def conn(self):
        if self._conn is None:
            self._conn = sqlite3.connect(self.db_path)
            self._conn.row_factory = sqlite3.Row
        return self._conn
    
    def _ensure_schema(self):
        """Initialize database schema if it doesn't exist."""
        try:
            cursor = self.conn.cursor()
            
            # Create schema version table
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS schema_version (
                version INTEGER PRIMARY KEY
            )''')
            
            # Create cable data table
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS cable_data (
                id INTEGER PRIMARY KEY,
                size REAL NOT NULL,
                mv_per_am REAL NOT NULL,
                max_current REAL NOT NULL,
                material TEXT NOT NULL,
                core_type TEXT NOT NULL,
                description TEXT,
                insulation_type TEXT,
                standard TEXT,
                dc_resistance REAL,
                ac_resistance REAL,
                reactance REAL,
                mass_kg_per_km REAL,
                temperature_rating REAL
            )''')
            
            # Create diversity factors table
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS diversity_factors (
                id INTEGER PRIMARY KEY,
                houses INTEGER NOT NULL,
                factor REAL NOT NULL
            )''')
            
            # Create fuse sizes table
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS fuse_sizes (
                id INTEGER PRIMARY KEY,
                material TEXT NOT NULL,
                size_mm2 REAL NOT NULL,
                fuse_size_a REAL NOT NULL,
                fuse_type TEXT
            )''')
            
            # Create calculation history table
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
            )''')
            
            # Create settings table
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT
            )''')
            
            # Create indexes for performance
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_cable_material ON cable_data(material)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_cable_size ON cable_data(size)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_diversity_houses ON diversity_factors(houses)')
            
            self.conn.commit()
            
            # Initialize with sample data if tables are empty
            self._init_sample_data()
            
        except Exception as e:
            print(f"Error initializing schema: {e}")
            raise
    
    def _init_sample_data(self):
        """Initialize tables with sample data if they're empty."""
        cursor = self.conn.cursor()
        
        # Check if cable_data is empty
        cursor.execute("SELECT COUNT(*) FROM cable_data")
        if cursor.fetchone()[0] == 0:
            # Insert sample cable data
            sample_cables = [
                (1.5, 26.0, 19.5, 'Cu', '1C+E', 'XLPE', 'AS/NZS 3008'),
                (2.5, 15.6, 27.0, 'Cu', '1C+E', 'XLPE', 'AS/NZS 3008'),
                (16.0, 2.6, 115.0, 'Al', '1C+E', 'XLPE', 'AS/NZS 3008'),
                (25.0, 1.7, 150.0, 'Al', '1C+E', 'XLPE', 'AS/NZS 3008')
            ]
            
            cursor.executemany('''
                INSERT INTO cable_data (size, mv_per_am, max_current, material, 
                                     core_type, insulation_type, standard)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', sample_cables)
        
        # Check if diversity_factors is empty
        cursor.execute("SELECT COUNT(*) FROM diversity_factors")
        if cursor.fetchone()[0] == 0:
            # Insert sample diversity factors
            sample_factors = [
                (1, 1.0),
                (2, 0.95),
                (5, 0.80),
                (10, 0.65)
            ]
            
            cursor.executemany('''
                INSERT INTO diversity_factors (houses, factor)
                VALUES (?, ?)
            ''', sample_factors)
        
        # Check if fuse_sizes is empty
        cursor.execute("SELECT COUNT(*) FROM fuse_sizes")
        if cursor.fetchone()[0] == 0:
            # Insert sample fuse sizes
            sample_fuses = [
                ('Cu', 16.0, 80.0, 'NH'),
                ('Cu', 25.0, 100.0, 'NH'),
                ('Al', 25.0, 63.0, 'NH'),
                ('Al', 35.0, 80.0, 'NH')
            ]
            
            cursor.executemany('''
                INSERT INTO fuse_sizes (material, size_mm2, fuse_size_a, fuse_type)
                VALUES (?, ?, ?, ?)
            ''', sample_fuses)
        
        self.conn.commit()
    
    def get_table_info(self):
        """Get information about all tables."""
        cursor = self.conn.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        
        info = {}
        for table in tables:
            table_name = table[0]
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = cursor.fetchall()
            cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            row_count = cursor.fetchone()[0]
            
            info[table_name] = {
                'columns': [dict(col) for col in columns],
                'row_count': row_count
            }
        return info
        
    def backup_database(self, backup_dir=None):
        """Create timestamped backup of database."""
        if backup_dir is None:
            backup_dir = os.path.join(os.path.dirname(self.db_path), 'backups')
        
        os.makedirs(backup_dir, exist_ok=True)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_path = os.path.join(backup_dir, f'application_data_{timestamp}.db')
        
        self.conn.close()
        self._conn = None
        shutil.copy2(self.db_path, backup_path)
        return backup_path
        
    def restore_database(self, backup_path):
        """Restore database from backup."""
        if not os.path.exists(backup_path):
            raise FileNotFoundError(f"Backup file not found: {backup_path}")
            
        self.conn.close()
        self._conn = None
        shutil.copy2(backup_path, self.db_path)
        return True
        
    def export_table_to_csv(self, table_name, filepath):
        """Export table data to CSV."""
        df = pd.read_sql_query(f"SELECT * FROM {table_name}", self.conn)
        df.to_csv(filepath, index=False)
        return True
        
    def import_table_from_csv(self, table_name, filepath):
        """Import data from CSV into table."""
        df = pd.read_csv(filepath)
        df.to_sql(table_name, self.conn, if_exists='replace', index=False)
        return True
        
    def vacuum_database(self):
        """Optimize database by removing unused space."""
        self.conn.execute("VACUUM")
        return True
        
    def get_table_data(self, table_name, limit=1000):
        """Get data from table with optional limit."""
        cursor = self.conn.cursor()
        cursor.execute(f"SELECT * FROM {table_name} LIMIT {limit}")
        columns = [description[0] for description in cursor.description]
        rows = cursor.fetchall()
        return {
            'columns': columns,
            'rows': [dict(row) for row in rows]
        }
        
    def execute_query(self, query):
        """Execute custom SQL query."""
        try:
            cursor = self.conn.cursor()
            cursor.execute(query)
            if query.strip().upper().startswith('SELECT'):
                columns = [description[0] for description in cursor.description]
                rows = cursor.fetchall()
                return {
                    'columns': columns,
                    'rows': [dict(row) for row in rows]
                }
            else:
                self.conn.commit()
                return {'affected_rows': cursor.rowcount}
        except Exception as e:
            return {'error': str(e)}
            
    def close(self):
        """Close database connection."""
        if self._conn:
            self._conn.close()
            self._conn = None
