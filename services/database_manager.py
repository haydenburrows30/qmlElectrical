import os
import sqlite3
import sys
import pandas as pd
from datetime import datetime
import shutil
import threading
import logging

# Set up logger
logger = logging.getLogger("qmltest.database")

class DatabaseManager:
    """
    Centralized database manager for the application.
    
    Provides:
    - Single point of database initialization
    - Schema versioning
    - Reference data loading
    - Thread-safe connections
    """
    
    _instance = None
    _lock = threading.Lock()
    
    @classmethod
    def get_instance(cls, db_path=None):
        """Get singleton instance of DatabaseManager."""
        with cls._lock:
            if cls._instance is None:
                if db_path is None:
                    # Use default path if none provided
                    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
                    db_path = os.path.join(project_root, 'data', 'application_data.db')
                cls._instance = cls(db_path)
            return cls._instance
    
    def __init__(self, db_path):
        """Initialize database manager with the database path."""
        self.db_path = db_path
        self._local = threading.local()
        self._ensure_db_directory()
        self.current_version = 1  # Increment this when schema changes
        
        # Initialize on first creation if the file doesn't exist
        if not os.path.exists(db_path):
            self.initialize_database()
        else:
            # Check and update schema if needed
            self._check_and_update_schema()
    
    def _ensure_db_directory(self):
        """Make sure the database directory exists."""
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
    
    @property
    def connection(self):
        """Get thread-local database connection."""
        if not hasattr(self._local, 'connection'):
            self._local.connection = sqlite3.connect(self.db_path)
            self._local.connection.row_factory = sqlite3.Row
        return self._local.connection
    
    def initialize_database(self):
        """Initialize the entire database from scratch."""
        logger.info(f"Initializing database at {self.db_path}")
        
        try:
            # Create schema
            self._create_schema()
            
            # Set schema version
            self._set_schema_version(self.current_version)
            
            # Load reference data
            self._load_reference_data()
            
            logger.info("Database initialization complete")
        except Exception as e:
            logger.error(f"Error initializing database: {e}")
            raise
    
    def _create_schema(self):
        """Create all database tables."""
        logger.info("Creating database schema")
        
        cursor = self.connection.cursor()
        
        # Schema version table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS schema_version (
            version INTEGER PRIMARY KEY
        )''')
        
        # Cable data table
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
        
        # Installation methods table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS installation_methods (
            code TEXT PRIMARY KEY,
            description TEXT NOT NULL,
            base_factor REAL NOT NULL,
            notes TEXT
        )''')
        
        # Temperature factors table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS temperature_factors (
            temperature INTEGER,
            insulation_type TEXT,
            factor REAL NOT NULL,
            PRIMARY KEY (temperature, insulation_type)
        )''')
        
        # Cable materials table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS cable_materials (
            material TEXT PRIMARY KEY,
            resistivity REAL NOT NULL,
            temperature_coefficient REAL NOT NULL,
            description TEXT
        )''')
        
        # Standards reference table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS standards_reference (
            code TEXT PRIMARY KEY,
            description TEXT NOT NULL,
            voltage_drop_limit REAL,
            current_rating_table TEXT,
            category TEXT
        )''')
        
        # Circuit breakers table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS circuit_breakers (
            id INTEGER PRIMARY KEY,
            type TEXT NOT NULL,
            rating REAL NOT NULL,
            breaking_capacity INTEGER NOT NULL,
            breaker_curve TEXT,
            curve_type TEXT,
            manufacturer TEXT,
            model TEXT,
            description TEXT
        )''')
        
        # Protection curves table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS protection_curves (
            id INTEGER PRIMARY KEY,
            type TEXT NOT NULL,
            multiplier REAL NOT NULL,
            time_seconds REAL NOT NULL,
            description TEXT
        )''')
        
        # Diversity factors table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS diversity_factors (
            id INTEGER PRIMARY KEY,
            houses INTEGER NOT NULL,
            factor REAL NOT NULL
        )''')
        
        # Fuse sizes table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS fuse_sizes (
            id INTEGER PRIMARY KEY,
            material TEXT NOT NULL,
            size_mm2 REAL NOT NULL,
            fuse_size_a REAL NOT NULL,
            fuse_type TEXT
        )''')
        
        # Calculation history table
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
        
        # Settings table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT
        )''')
        
        # Create indexes for performance
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_cable_material ON cable_data(material)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_cable_size ON cable_data(size)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_diversity_houses ON diversity_factors(houses)')
        
        self.connection.commit()
        logger.info("Schema creation complete")
    
    def _set_schema_version(self, version):
        """Set the schema version."""
        cursor = self.connection.cursor()
        cursor.execute("DELETE FROM schema_version")
        cursor.execute("INSERT INTO schema_version (version) VALUES (?)", (version,))
        self.connection.commit()
        logger.info(f"Schema version set to {version}")
    
    def _get_schema_version(self):
        """Get the current schema version."""
        try:
            cursor = self.connection.cursor()
            cursor.execute("SELECT version FROM schema_version LIMIT 1")
            result = cursor.fetchone()
            if result:
                return result[0]
            return 0
        except:
            return 0
    
    def _check_and_update_schema(self):
        """Check and update schema if needed."""
        current_version = self._get_schema_version()
        
        if current_version < self.current_version:
            logger.info(f"Upgrading schema from v{current_version} to v{self.current_version}")
            
            # Perform schema migrations based on version
            if current_version == 0:
                # Fresh install or legacy database without version
                self.initialize_database()
            else:
                # Incremental upgrades
                if current_version < 1:
                    self._migrate_to_v1()
                
                # Update version after migration
                self._set_schema_version(self.current_version)
    
    def _migrate_to_v1(self):
        """Migrate schema to version 1."""
        # Example migration code
        cursor = self.connection.cursor()
        # Add migration SQL statements here
        self.connection.commit()
    
    def _load_reference_data(self):
        """Load all reference data into database."""
        logger.info("Loading reference data")
        
        # Load from CSV files if available
        self._load_diversity_factors()
        
        # Then load hard-coded reference data
        self._load_installation_methods()
        self._load_temperature_factors()
        self._load_cable_materials()
        self._load_standards_reference()
        self._load_circuit_breakers()
        
        # Load extended reference data
        self._load_voltage_systems()
        self._load_insulation_types()
        self._load_soil_resistivity()
        self._load_protection_curves()
        
        logger.info("Reference data loading complete")
    
    def _load_diversity_factors(self):
        """Load diversity factors from CSV if available, or use defaults."""
        cursor = self.connection.cursor()
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM diversity_factors")
        if cursor.fetchone()[0] > 0:
            return
        
        # Try to load from CSV
        project_root = os.path.abspath(os.path.join(os.path.dirname(self.db_path), '..'))
        csv_path = os.path.join(project_root, 'data', 'diversity_factor.csv')
        
        if os.path.exists(csv_path):
            try:
                df = pd.read_csv(csv_path)
                for _, row in df.iterrows():
                    cursor.execute(
                        "INSERT INTO diversity_factors (houses, factor) VALUES (?, ?)",
                        (int(row['No Houses']), float(row['Diversity Factor']))
                    )
                self.connection.commit()
                logger.info(f"Loaded diversity factors from {csv_path}")
                return
            except Exception as e:
                logger.warning(f"Failed to load diversity factors from CSV: {e}")
        
        # Use default values if CSV loading failed
        sample_factors = [
            (1, 1.0),
            (2, 0.95),
            (5, 0.80),
            (10, 0.65),
            (15, 0.55),
            (20, 0.50),
            (30, 0.45),
            (40, 0.42),
            (50, 0.40),
            (100, 0.35)
        ]
        
        cursor.executemany('''
            INSERT INTO diversity_factors (houses, factor)
            VALUES (?, ?)
        ''', sample_factors)
        
        self.connection.commit()
        logger.info("Loaded default diversity factors")
    
    def _load_installation_methods(self):
        """Load installation methods reference data."""
        cursor = self.connection.cursor()
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM installation_methods")
        if cursor.fetchone()[0] > 0:
            return
        
        installation_data = [
            ('A1', 'Enclosed in thermal insulation', 1.25, 'Worst case thermal environment'),
            ('A2', 'Enclosed in wall/ceiling', 1.15, 'Limited heat dissipation'),
            ('B1', 'Enclosed in conduit in wall', 1.1, 'Some heat dissipation'),
            ('B2', 'Enclosed in trunking/conduit', 1.1, 'Similar to B1'),
            ('C', 'Clipped direct', 1.0, 'Reference method'),
            ('D1', 'Underground direct buried', 1.1, 'Soil thermal resistivity dependent'),
            ('D2', 'Underground in conduit', 1.15, 'Higher than D1 due to air gap'),
            ('E', 'Free air', 0.95, 'Good heat dissipation'),
            ('F', 'Cable tray/ladder/cleated', 0.95, 'Similar to method E'),
            ('G', 'Spaced from surface', 0.90, 'Best heat dissipation')
        ]
        
        cursor.executemany("""
            INSERT INTO installation_methods (code, description, base_factor, notes)
            VALUES (?, ?, ?, ?)
        """, installation_data)
        
        self.connection.commit()
        logger.info("Loaded installation methods reference data")
    
    def _load_temperature_factors(self):
        """Load temperature factors reference data."""
        cursor = self.connection.cursor()
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM temperature_factors")
        if cursor.fetchone()[0] > 0:
            return
        
        temp_data = [
            (25, 'PVC', 1.0),
            (35, 'PVC', 0.94),
            (45, 'PVC', 0.87),
            (25, 'XLPE', 1.0),
            (35, 'XLPE', 0.96),
            (45, 'XLPE', 0.91)
        ]
        
        cursor.executemany("""
            INSERT INTO temperature_factors (temperature, insulation_type, factor)
            VALUES (?, ?, ?)
        """, temp_data)
        
        self.connection.commit()
        logger.info("Loaded temperature factors reference data")
    
    def _load_cable_materials(self):
        """Load cable materials reference data."""
        cursor = self.connection.cursor()
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM cable_materials")
        if cursor.fetchone()[0] > 0:
            return
        
        material_data = [
            ('Cu', 1.72e-8, 0.00393, 'Copper conductor'),
            ('Al', 2.82e-8, 0.00403, 'Aluminum conductor')
        ]
        
        cursor.executemany("""
            INSERT INTO cable_materials (material, resistivity, temperature_coefficient, description)
            VALUES (?, ?, ?, ?)
        """, material_data)
        
        self.connection.commit()
        logger.info("Loaded cable materials reference data")
    
    def _load_standards_reference(self):
        """Load standards reference data."""
        cursor = self.connection.cursor()
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM standards_reference")
        if cursor.fetchone()[0] > 0:
            return
        
        standards_data = [
            ('AS3008.1.1', 'Selection of cables - Voltage drop', 5.0, 'Table 3', 'Voltage Drop'),
            ('AS3008.1.2', 'Current carrying capacity', None, 'Table 4', 'Current Rating')
        ]
        
        cursor.executemany("""
            INSERT INTO standards_reference (code, description, voltage_drop_limit, current_rating_table, category)
            VALUES (?, ?, ?, ?, ?)
        """, standards_data)
        
        self.connection.commit()
        logger.info("Loaded standards reference data")
    
    def _load_circuit_breakers(self):
        """Load circuit breakers reference data."""
        cursor = self.connection.cursor()
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM circuit_breakers")
        if cursor.fetchone()[0] > 0:
            return
        
        # Default circuit breaker data
        default_breakers = [
            # MCB ratings with curve-specific types and full range
            # B Type MCBs
            ("MCB", 6, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B6", "6A Type B MCB"),
            ("MCB", 10, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B10", "10A Type B MCB"),
            ("MCB", 16, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B16", "16A Type B MCB"),
            ("MCB", 20, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B20", "20A Type B MCB"),
            ("MCB", 25, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B25", "25A Type B MCB"),
            # C Type MCBs
            ("MCB", 6, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C6", "6A Type C MCB"),
            ("MCB", 10, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C10", "10A Type C MCB"),
            ("MCB", 16, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C16", "16A Type C MCB"),
            # MCCB ratings with full range
            ("MCCB", 100, 25000, "S", "IEC Extremely Inverse", "Generic", "MCCB-100", "100A MCCB"),
            ("MCCB", 160, 25000, "S", "IEC Extremely Inverse", "Generic", "MCCB-160", "160A MCCB"),
            ("MCCB", 250, 35000, "S", "IEC Extremely Inverse", "Generic", "MCCB-250", "250A MCCB"),
        ]
        
        cursor.executemany("""
            INSERT INTO circuit_breakers 
            (type, rating, breaking_capacity, breaker_curve, curve_type, manufacturer, model, description)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, default_breakers)
        
        self.connection.commit()
        logger.info("Loaded circuit breakers reference data")
    
    def _load_voltage_systems(self):
        """Load voltage systems reference data."""
        cursor = self.connection.cursor()
        
        # Create table if not exists
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS voltage_systems (
            id INTEGER PRIMARY KEY,
            voltage REAL NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            frequency INTEGER DEFAULT 50,
            phase_count INTEGER DEFAULT 3,
            category TEXT,
            notes TEXT
        )''')
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM voltage_systems")
        if cursor.fetchone()[0] > 0:
            return
        
        voltage_data = [
            (230, "Single Phase LV", "Domestic supply", 50, 1, "LV", "Standard domestic"),
            (400, "Three Phase LV", "Commercial/industrial", 50, 3, "LV", "Standard commercial"),
            (415, "Three Phase LV+N", "Industrial with neutral", 50, 3, "LV", "With neutral"),
            (11000, "11kV", "Distribution", 50, 3, "MV", "Medium voltage"),
            (33000, "33kV", "Sub-transmission", 50, 3, "HV", "High voltage")
        ]
        
        cursor.executemany("""
            INSERT INTO voltage_systems (voltage, name, description, frequency, phase_count, category, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, voltage_data)
        
        self.connection.commit()
        logger.info("Loaded voltage systems reference data")
    
    def _load_insulation_types(self):
        """Load insulation types reference data."""
        cursor = self.connection.cursor()
        
        # Create table if not exists
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS insulation_types (
            code TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            max_temp INTEGER NOT NULL,
            description TEXT,
            material TEXT,
            standard TEXT
        )''')
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM insulation_types")
        if cursor.fetchone()[0] > 0:
            return
        
        insulation_data = [
            ("PVC", "Polyvinyl Chloride", 70, "Standard PVC insulation", "Thermoplastic", "AS/NZS 5000.1"),
            ("XLPE", "Cross-linked Polyethylene", 90, "High temp rating", "Thermoset", "AS/NZS 5000.1"),
            ("EPR", "Ethylene Propylene Rubber", 90, "Flexible rubber", "Thermoset", "AS/NZS 5000.1")
        ]
        
        cursor.executemany("""
            INSERT INTO insulation_types (code, name, max_temp, description, material, standard)
            VALUES (?, ?, ?, ?, ?, ?)
        """, insulation_data)
        
        self.connection.commit()
        logger.info("Loaded insulation types reference data")
    
    def _load_soil_resistivity(self):
        """Load soil resistivity reference data."""
        cursor = self.connection.cursor()
        
        # Create table if not exists
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS soil_resistivity (
            id INTEGER PRIMARY KEY,
            soil_type TEXT NOT NULL,
            min_resistivity REAL,
            max_resistivity REAL,
            typical_value REAL,
            moisture_content TEXT,
            notes TEXT
        )''')
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM soil_resistivity")
        if cursor.fetchone()[0] > 0:
            return
        
        soil_data = [
            ("Clay", 5, 50, 20, "Moist", "High conductivity"),
            ("Sandy", 50, 500, 200, "Dry", "Poor conductivity"),
            ("Rock", 1000, 10000, 2000, "N/A", "Very high resistance")
        ]
        
        cursor.executemany("""
            INSERT INTO soil_resistivity (soil_type, min_resistivity, max_resistivity, typical_value, moisture_content, notes)
            VALUES (?, ?, ?, ?, ?, ?)
        """, soil_data)
        
        self.connection.commit()
        logger.info("Loaded soil resistivity reference data")
    
    def _load_protection_curves(self):
        """Load protection curves reference data."""
        cursor = self.connection.cursor()
        
        # Create table if not exists
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS protection_curves (
            id INTEGER PRIMARY KEY,
            device_type TEXT NOT NULL,
            rating REAL NOT NULL,
            current_multiplier REAL NOT NULL,
            tripping_time REAL NOT NULL,
            curve_type TEXT,
            temperature TEXT,
            notes TEXT
        )''')
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM protection_curves")
        if cursor.fetchone()[0] > 0:
            return
        
        protection_data = [
            ("MCB", 32, 1.0, 3600, "C", "20°C", "Normal load"),
            ("MCB", 32, 5.0, 0.1, "C", "20°C", "Overload"),
            ("MCB", 32, 10.0, 0.01, "C", "20°C", "Short circuit")
        ]
        
        cursor.executemany("""
            INSERT INTO protection_curves (device_type, rating, current_multiplier, tripping_time, curve_type, temperature, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, protection_data)
        
        self.connection.commit()
        logger.info("Loaded protection curves reference data")
    
    # Database operation methods
    def execute_query(self, query, params=None):
        """Execute a query and return results."""
        try:
            cursor = self.connection.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            # For SELECT queries, return the results
            if query.strip().upper().startswith('SELECT'):
                return cursor.fetchall()
            else:
                self.connection.commit()
                return cursor.rowcount
        except Exception as e:
            logger.error(f"Query error: {e}")
            raise
    
    def fetch_one(self, query, params=None):
        """Fetch a single row from the database."""
        try:
            cursor = self.connection.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            return cursor.fetchone()
        except Exception as e:
            logger.error(f"Query error: {e}")
            raise
    
    def fetch_all(self, query, params=None):
        """Fetch all rows from the database."""
        try:
            cursor = self.connection.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            return cursor.fetchall()
        except Exception as e:
            logger.error(f"Query error: {e}")
            raise
    
    def backup_database(self, backup_dir=None):
        """Create a backup of the database."""
        if backup_dir is None:
            backup_dir = os.path.join(os.path.dirname(self.db_path), 'backups')
        
        os.makedirs(backup_dir, exist_ok=True)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_path = os.path.join(backup_dir, f'application_data_{timestamp}.db')
        
        # Close connection before backup
        if hasattr(self._local, 'connection'):
            self._local.connection.close()
            delattr(self._local, 'connection')
        
        shutil.copy2(self.db_path, backup_path)
        logger.info(f"Database backed up to {backup_path}")
        return backup_path
    
    def close(self):
        """Close the database connection."""
        if hasattr(self._local, 'connection'):
            try:
                self._local.connection.close()
                delattr(self._local, 'connection')
            except Exception as e:
                logger.warning(f"Error closing database connection: {e}")
