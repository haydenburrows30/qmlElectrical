import os
import sqlite3
import sys
import pandas as pd
from datetime import datetime
import shutil
import threading
import logging
import json

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
    - Configuration storage
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
            
            # Verify schema integrity
            self.verify_schema()
            
            logger.info("Database initialization complete")
        except Exception as e:
            logger.error(f"Error initializing database: {e}")
            # Try to recover
            try:
                logger.info("Attempting database recovery...")
                # Create schema again with improved error handling
                self._safe_create_schema()
                # Verify and fix schema
                self.verify_schema()
                logger.info("Database recovery complete")
            except Exception as recovery_error:
                logger.error(f"Database recovery failed: {recovery_error}")
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
        
        # Config table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS config (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
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
        
        # Circuit breakers table - updated to match ProtectionRelayCalculator schema
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
        
        # Protection curves table - updated to match ProtectionRelayCalculator schema
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
    
    def _safe_create_schema(self):
        """Create schema tables with individual error handling for each table."""
        cursor = self.connection.cursor()
        
        # Create each table individually and catch errors
        table_definitions = [
            ("schema_version", '''
            CREATE TABLE IF NOT EXISTS schema_version (
                version INTEGER PRIMARY KEY
            )'''),
            
            ("config", '''
            CREATE TABLE IF NOT EXISTS config (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )'''),
            
            ("cable_data", '''
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
            )'''),
            
            ("installation_methods", '''
            CREATE TABLE IF NOT EXISTS installation_methods (
                code TEXT PRIMARY KEY,
                description TEXT NOT NULL,
                base_factor REAL NOT NULL,
                notes TEXT
            )'''),
            
            ("temperature_factors", '''
            CREATE TABLE IF NOT EXISTS temperature_factors (
                temperature INTEGER,
                insulation_type TEXT,
                factor REAL NOT NULL,
                PRIMARY KEY (temperature, insulation_type)
            )'''),
            
            ("cable_materials", '''
            CREATE TABLE IF NOT EXISTS cable_materials (
                material TEXT PRIMARY KEY,
                resistivity REAL NOT NULL,
                temperature_coefficient REAL NOT NULL,
                description TEXT
            )'''),
            
            ("standards_reference", '''
            CREATE TABLE IF NOT EXISTS standards_reference (
                code TEXT PRIMARY KEY,
                description TEXT NOT NULL,
                voltage_drop_limit REAL,
                current_rating_table TEXT,
                category TEXT
            )'''),
            
            ("circuit_breakers", '''
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
            )'''),
            
            ("protection_curves", '''
            CREATE TABLE IF NOT EXISTS protection_curves (
                id INTEGER PRIMARY KEY,
                device_type TEXT NOT NULL,
                rating REAL NOT NULL,
                current_multiplier REAL NOT NULL,
                tripping_time REAL NOT NULL,
                curve_type TEXT,
                temperature TEXT,
                notes TEXT
            )'''),
            
            ("diversity_factors", '''
            CREATE TABLE IF NOT EXISTS diversity_factors (
                id INTEGER PRIMARY KEY,
                houses INTEGER NOT NULL,
                factor REAL NOT NULL
            )'''),
            
            ("fuse_sizes", '''
            CREATE TABLE IF NOT EXISTS fuse_sizes (
                id INTEGER PRIMARY KEY,
                material TEXT NOT NULL,
                size_mm2 REAL NOT NULL,
                fuse_size_a REAL NOT NULL,
                fuse_type TEXT
            )'''),
            
            ("calculation_history", '''
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
            )'''),
            
            ("settings", '''
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT
            )'''),
            
            ("voltage_systems", '''
            CREATE TABLE IF NOT EXISTS voltage_systems (
                id INTEGER PRIMARY KEY,
                voltage REAL NOT NULL,
                name TEXT NOT NULL,
                description TEXT,
                frequency INTEGER DEFAULT 50,
                phase_count INTEGER DEFAULT 3,
                category TEXT,
                notes TEXT
            )'''),
            
            ("insulation_types", '''
            CREATE TABLE IF NOT EXISTS insulation_types (
                code TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                max_temp INTEGER NOT NULL,
                description TEXT,
                material TEXT,
                standard TEXT
            )'''),
            
            ("soil_resistivity", '''
            CREATE TABLE IF NOT EXISTS soil_resistivity (
                id INTEGER PRIMARY KEY,
                soil_type TEXT NOT NULL,
                min_resistivity REAL,
                max_resistivity REAL,
                typical_value REAL,
                moisture_content TEXT,
                notes TEXT
            )''')
        ]
        
        for table_name, sql in table_definitions:
            try:
                cursor.execute(sql)
                logger.info(f"Created table: {table_name}")
            except Exception as e:
                logger.error(f"Error creating table {table_name}: {e}")
        
        # Create indexes
        try:
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_cable_material ON cable_data(material)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_cable_size ON cable_data(size)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_diversity_houses ON diversity_factors(houses)')
        except Exception as e:
            logger.error(f"Error creating indexes: {e}")
            
        self.connection.commit()
    
    def verify_schema(self):
        """Verify database schema integrity, fix issues if possible."""
        try:
            # Get list of tables
            cursor = self.connection.cursor()
            tables = cursor.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
            table_names = [table[0] for table in tables]
            
            logger.info(f"Verifying database schema: found {len(tables)} tables")
            
            # Check for expected tables
            expected_tables = [
                'schema_version', 'config', 'cable_data', 'installation_methods', 'temperature_factors',
                'cable_materials', 'standards_reference', 'circuit_breakers', 'protection_curves',
                'diversity_factors', 'fuse_sizes', 'calculation_history', 'settings',
                'voltage_systems', 'insulation_types', 'soil_resistivity'
            ]
            
            for table in expected_tables:
                if table not in table_names:
                    logger.warning(f"Missing table: {table}")
            
            # Verify table structures for critical tables
            try:
                # Check protection_curves
                cursor.execute("PRAGMA table_info(protection_curves)")
                columns = {column[1]: column for column in cursor.fetchall()}
                
                # Check if protection_curves has the right columns
                if 'device_type' not in columns and 'type' in columns:
                    logger.warning("Found old protection_curves schema, updating...")
                    # Create a temp table with correct structure
                    cursor.execute('''
                    CREATE TABLE protection_curves_new (
                        id INTEGER PRIMARY KEY,
                        device_type TEXT NOT NULL,
                        rating REAL NOT NULL,
                        current_multiplier REAL NOT NULL,
                        tripping_time REAL NOT NULL,
                        curve_type TEXT,
                        temperature TEXT,
                        notes TEXT
                    )''')
                    
                    # Migrate data if possible
                    try:
                        cursor.execute('''
                        INSERT INTO protection_curves_new 
                        (device_type, rating, current_multiplier, tripping_time, curve_type, temperature, notes)
                        SELECT type, rating, multiplier, time_seconds, curve_type, temperature, description 
                        FROM protection_curves
                        ''')
                    except:
                        logger.warning("Could not migrate protection_curves data, starting fresh")
                    
                    # Drop old table and rename new one
                    cursor.execute("DROP TABLE protection_curves")
                    cursor.execute("ALTER TABLE protection_curves_new RENAME TO protection_curves")
                    self.connection.commit()
                    logger.info("Fixed protection_curves table schema")
                    
            except Exception as e:
                logger.error(f"Error verifying protection_curves table: {e}")
            
            # Final verification - ensure we can load all reference data
            self._load_reference_data()
            return True
            
        except Exception as e:
            logger.error(f"Error during schema verification: {e}")
            return False
    
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
                try:
                    self.initialize_database()
                except Exception as e:
                    logger.error(f"Error during database initialization: {e}")
                    # Try to verify and fix
                    self.verify_schema()
            else:
                # Incremental upgrades
                if current_version < 1:
                    self._migrate_to_v1()
                
                # Update version after migration
                self._set_schema_version(self.current_version)
        else:
            # Even if version is current, verify schema integrity
            self.verify_schema()
    
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
        self._load_fuse_sizes()
        
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
        
        # Load default config values
        self._load_default_config()
        
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
    
    def _load_fuse_sizes(self):
        """Load fuse sizes from CSV if available, or use defaults."""
        cursor = self.connection.cursor()
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM fuse_sizes")
        if cursor.fetchone()[0] > 0:
            return
        
        # Try to load from CSV
        project_root = os.path.abspath(os.path.join(os.path.dirname(self.db_path), '..'))
        csv_path = os.path.join(project_root, 'data', 'network_fuse_sizes.csv')
        
        if os.path.exists(csv_path):
            try:
                logger.info(f"Loading fuse sizes from CSV: {csv_path}")
                
                # Clean approach to load the CSV
                with open(csv_path, 'r') as csv_file:
                    # Skip the first line if it starts with //
                    first_line = csv_file.readline().strip()
                    
                    # Check if first line is a comment
                    if first_line.startswith('//'):
                        # Reset file pointer to beginning and skip first line
                        csv_file.seek(0)
                        next(csv_file)
                    else:
                        # Reset file pointer to beginning
                        csv_file.seek(0)
                        
                    # Now read with pandas
                    df = pd.read_csv(csv_file)
                    
                    # Verify the CSV has the required columns
                    required_columns = ['Material', 'Size (mm2)', 'Network Fuse Size (A)']
                    if all(col in df.columns for col in required_columns):
                        for _, row in df.iterrows():
                            cursor.execute(
                                "INSERT INTO fuse_sizes (material, size_mm2, fuse_size_a) VALUES (?, ?, ?)",
                                (row['Material'], float(row['Size (mm2)']), float(row['Network Fuse Size (A)']))
                            )
                        self.connection.commit()
                        logger.info(f"Successfully loaded {len(df)} fuse sizes from {csv_path}")
                        return
                    else:
                        missing_cols = [col for col in required_columns if col not in df.columns]
                        logger.warning(f"CSV missing required columns: {missing_cols}")
                        
            except Exception as e:
                logger.warning(f"Failed to load fuse sizes from CSV: {e}")
        else:
            logger.warning(f"Fuse sizes CSV file not found at {csv_path}")
        
        # Use default values if CSV loading failed
        sample_fuses = [
            ('Cu', 16.0, 63.0, 'NH'),
            ('Cu', 25.0, 160.0, 'NH'),
            ('Cu', 35.0, 160.0, 'NH'),
            ('Cu', 70.0, 250.0, 'NH'),
            ('Cu', 95.0, 250.0, 'NH'),
            ('Cu', 120.0, 355.0, 'NH'),
            ('Cu', 185.0, 500.0, 'NH'),
            ('Al', 95.0, 200.0, 'NH'),
            ('Al', 120.0, 250.0, 'NH'),
            ('Al', 185.0, 355.0, 'NH'),
            ('Al', 240.0, 400.0, 'NH'),
            ('Al', 300.0, 500.0, 'NH')
        ]
        
        cursor.executemany('''
            INSERT INTO fuse_sizes (material, size_mm2, fuse_size_a, fuse_type)
            VALUES (?, ?, ?, ?)
        ''', sample_fuses)
        
        self.connection.commit()
        logger.info("Loaded default fuse sizes as CSV file was not loaded")
    
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
        
        # Default circuit breaker data - update to match the protection_relay data
        default_breakers = [
            # MCB ratings
            ("MCB", 6, 6000, "C", "IEC Standard Inverse", "Generic", "MCB-C6", "6A Type C MCB"),
            ("MCB", 10, 6000, "C", "IEC Standard Inverse", "Generic", "MCB-C10", "10A Type C MCB"),
            ("MCB", 16, 6000, "C", "IEC Standard Inverse", "Generic", "MCB-C16", "16A Type C MCB"),
            ("MCB", 20, 6000, "C", "IEC Standard Inverse", "Generic", "MCB-C20", "20A Type C MCB"),
            ("MCB", 25, 6000, "C", "IEC Standard Inverse", "Generic", "MCB-C25", "25A Type C MCB"),
            ("MCB", 32, 6000, "C", "IEC Standard Inverse", "Generic", "MCB-C32", "32A Type C MCB"),
            ("MCB", 40, 6000, "C", "IEC Standard Inverse", "Generic", "MCB-C40", "40A Type C MCB"),
            ("MCB", 50, 6000, "C", "IEC Standard Inverse", "Generic", "MCB-C50", "50A Type C MCB"),
            ("MCB", 63, 6000, "C", "IEC Standard Inverse", "Generic", "MCB-C63", "63A Type C MCB"),
            ("MCB", 80, 6000, "C", "IEC Standard Inverse", "Generic", "MCB-C80", "80A Type C MCB"),
            # MCCB ratings
            ("MCCB", 100, 25000, "C", "IEC Extremely Inverse", "Generic", "MCCB-100", "100A MCCB"),
            ("MCCB", 125, 25000, "C", "IEC Extremely Inverse", "Generic", "MCCB-125", "125A MCCB"),
            ("MCCB", 160, 25000, "C", "IEC Extremely Inverse", "Generic", "MCCB-160", "160A MCCB"),
            ("MCCB", 200, 25000, "C", "IEC Extremely Inverse", "Generic", "MCCB-200", "200A MCCB"),
            ("MCCB", 250, 35000, "C", "IEC Extremely Inverse", "Generic", "MCCB-250", "250A MCCB"),
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
        
        # Create table if not exists with correct columns
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
        
        # Add typical MCB curve points (B, C, D curves) to match protection_relay data
        mcb_curve_points = [
            # B Curve (3-5x In)
            ("MCB", 6, 1.05, 3600, "B", "25°C", "No trip region"),
            ("MCB", 6, 2.5, 1800, "B", "25°C", "May trip region"),
            ("MCB", 6, 3.0, 0.2, "B", "25°C", "Trip region start"),
            ("MCB", 6, 5.0, 0.05, "B", "25°C", "Must trip region"),
            ("MCB", 6, 10.0, 0.01, "B", "25°C", "Fast trip region"),
            
            # C Curve (5-10x In)
            ("MCB", 6, 1.05, 3600, "C", "25°C", "No trip region"),
            ("MCB", 6, 3.0, 1800, "C", "25°C", "May trip region"),
            ("MCB", 6, 5.0, 0.2, "C", "25°C", "Trip region start"),
            ("MCB", 6, 10.0, 0.05, "C", "25°C", "Must trip region"),
            ("MCB", 6, 20.0, 0.01, "C", "25°C", "Fast trip region"),
            
            # D Curve (10-20x In)
            ("MCB", 6, 1.05, 3600, "D", "25°C", "No trip region"),
            ("MCB", 6, 5.0, 1800, "D", "25°C", "May trip region"),
            ("MCB", 6, 10.0, 0.2, "D", "25°C", "Trip region start"),
            ("MCB", 6, 20.0, 0.05, "D", "25°C", "Must trip region"),
            ("MCB", 6, 50.0, 0.01, "D", "25°C", "Fast trip region"),
        ]
        
        cursor.executemany("""
            INSERT INTO protection_curves 
            (device_type, rating, current_multiplier, tripping_time, curve_type, temperature, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, mcb_curve_points)
        
        self.connection.commit()
        logger.info("Loaded protection curves reference data")
    
    def _load_default_config(self):
        """Load default configuration values."""
        cursor = self.connection.cursor()
        
        # Check if table has any values already
        cursor.execute("SELECT COUNT(*) FROM config")
        if cursor.fetchone()[0] > 0:
            return
        
        # Default configuration values
        default_config = {
            "default_voltage": "415V",
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
            "version": "1.1.9",
            "performance_monitor_enabled": True
        }
        
        for key, value in default_config.items():
            cursor.execute("""
                INSERT OR IGNORE INTO config (key, value) 
                VALUES (?, ?)
            """, (key, json.dumps(value)))
        
        self.connection.commit()
        logger.info("Loaded default configuration values")
    
    def get_config(self, key, default=None):
        """Get configuration value."""
        try:
            cursor = self.connection.cursor()
            cursor.execute("SELECT value FROM config WHERE key = ?", (key,))
            result = cursor.fetchone()
            
            if result:
                return json.loads(result[0])
            return default
        except Exception as e:
            logger.error(f"Error getting config value for {key}: {e}")
            return default
    
    def set_config(self, key, value):
        """Set configuration value."""
        try:
            cursor = self.connection.cursor()
            cursor.execute("""
                INSERT OR REPLACE INTO config (key, value) 
                VALUES (?, ?)
            """, (key, json.dumps(value)))
            
            self.connection.commit()
            logger.debug(f"Successfully saved config {key}: {value}")
            return True
        except Exception as e:
            logger.error(f"Error saving config value for {key}: {e}")
            return False
    
    def get_all_config(self):
        """Get all configuration values."""
        try:
            cursor = self.connection.cursor()
            cursor.execute("SELECT key, value FROM config")
            config_rows = cursor.fetchall()
            
            config_dict = {}
            for key, value in config_rows:
                config_dict[key] = json.loads(value)
            
            return config_dict
        except Exception as e:
            logger.error(f"Error retrieving all config values: {e}")
            return {}
    
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