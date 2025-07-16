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
        self.current_version = 2  # Increment this when schema changes
        
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
        
        # Fuse curves table for ABB CEF and other fuse types
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS fuse_curves (
            id INTEGER PRIMARY KEY,
            fuse_type TEXT NOT NULL,
            rating REAL NOT NULL,
            current_multiplier REAL NOT NULL,
            melting_time REAL NOT NULL,
            clearing_time REAL,
            manufacturer TEXT,
            series TEXT,
            voltage_rating REAL,
            breaking_capacity REAL,
            temperature TEXT DEFAULT '25°C',
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
        
        # Relay settings table for protection relay calculations
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS relay_settings (
            id TEXT PRIMARY KEY,
            name TEXT,
            device_type TEXT,
            rating REAL,
            curve_type TEXT,
            time_dial REAL,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            additional_data TEXT
        )''')
        
        # Create indexes for performance
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_cable_material ON cable_data(material)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_cable_size ON cable_data(size)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_diversity_houses ON diversity_factors(houses)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_relay_settings_created ON relay_settings(created_at)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_fuse_curves_type_rating ON fuse_curves(fuse_type, rating)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_fuse_curves_manufacturer ON fuse_curves(manufacturer, series)')
        
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
            
            ("fuse_curves", '''
            CREATE TABLE IF NOT EXISTS fuse_curves (
                id INTEGER PRIMARY KEY,
                fuse_type TEXT NOT NULL,
                rating REAL NOT NULL,
                current_multiplier REAL NOT NULL,
                melting_time REAL NOT NULL,
                clearing_time REAL,
                manufacturer TEXT,
                series TEXT,
                voltage_rating REAL,
                breaking_capacity REAL,
                temperature TEXT DEFAULT '25°C',
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
            
            ("relay_settings", '''
            CREATE TABLE IF NOT EXISTS relay_settings (
                id TEXT PRIMARY KEY,
                name TEXT,
                device_type TEXT,
                rating REAL,
                curve_type TEXT,
                time_dial REAL,
                description TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                additional_data TEXT
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
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_relay_settings_created ON relay_settings(created_at)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_fuse_curves_type_rating ON fuse_curves(fuse_type, rating)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_fuse_curves_manufacturer ON fuse_curves(manufacturer, series)')
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
                'fuse_curves', 'diversity_factors', 'fuse_sizes', 'calculation_history', 'settings', 'relay_settings',
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
                if current_version < 2:
                    self._migrate_to_v2()
                
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
    
    def _migrate_to_v2(self):
        """Migrate schema to version 2 - Add fuse_curves table."""
        logger.info("Migrating to schema version 2: Adding fuse_curves table")
        cursor = self.connection.cursor()
        
        try:
            # Create fuse_curves table if it doesn't exist
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS fuse_curves (
                id INTEGER PRIMARY KEY,
                fuse_type TEXT NOT NULL,
                rating REAL NOT NULL,
                current_multiplier REAL NOT NULL,
                melting_time REAL NOT NULL,
                clearing_time REAL,
                manufacturer TEXT,
                series TEXT,
                voltage_rating REAL,
                breaking_capacity REAL,
                temperature TEXT DEFAULT '25°C',
                notes TEXT
            )''')
            
            # Create indexes for fuse_curves
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_fuse_curves_type_rating ON fuse_curves(fuse_type, rating)')
            cursor.execute('CREATE INDEX IF NOT EXISTS idx_fuse_curves_manufacturer ON fuse_curves(manufacturer, series)')
            
            self.connection.commit()
            logger.info("Successfully migrated to schema version 2")
            
            # Load fuse curves data
            self._load_fuse_curves()
            
        except Exception as e:
            logger.error(f"Error migrating to version 2: {e}")
            self.connection.rollback()
            raise
    
    def _load_reference_data(self):
        """Load all reference data into database."""
        logger.info("Loading reference data")
        
        # Load from CSV files if available
        self._load_diversity_factors()
        self._load_fuse_sizes()
        
        # Then load hard-coded reference data
        self._load_cable_data()
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
        self._load_fuse_curves()
        
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

    def _load_cable_data(self):
        """Load circuit breakers reference data."""
        cursor = self.connection.cursor()
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM cable_data")
        if cursor.fetchone()[0] > 0:
            return
        
        default_cables = [(1,0.56,100,"Al","3C+E","PVC","XLPE","3001",0.43,0.23,0.19,512,95)]

        cursor.executemany("""
            INSERT INTO cable_data 
            (size, mv_per_am, max_current, material, core_type, description, insulation_type, standard,dc_resistance, ac_resistance, reactance, mass_kg_per_km, temperature_rating)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, default_cables)
        
        self.connection.commit()
        logger.info("Loaded cable data reference data")
    
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
    
    def _load_fuse_curves(self):
        """Load ABB CEF fuse curves and other fuse types."""
        cursor = self.connection.cursor()
        
        # Check if table is already populated
        cursor.execute("SELECT COUNT(*) FROM fuse_curves")
        if cursor.fetchone()[0] > 0:
            return
        
        # ABB CEF fuse curves - based on manufacturer datasheet curves
        # These values are extracted from the time-current characteristic curves
        abb_cef_curves = [
            # ABB CEF 6.3A fuse - CORRECTED
            ("CEF", 6.3, 1.0, 3600, 3600, "ABB", "CEF-S", 400, 100000, "25°C", "No melt at rated current"),
            ("CEF", 6.3, 1.1, 1800, 1800, "ABB", "CEF-S", 400, 100000, "25°C", "May melt region"),
            ("CEF", 6.3, 1.35, 300, 300, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 6.3, 1.6, 100, 100, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 6.3, 2.0, 25, 30, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 6.3, 3.0, 6, 8, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 6.3, 5.0, 1.5, 2.0, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 6.3, 8.0, 0.15, 0.2, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 6.3, 10.0, 0.08, 0.1, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 6.3, 20.0, 0.02, 0.025, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 6.3, 50.0, 0.005, 0.008, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 6.3, 100.0, 0.002, 0.004, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            
            # ABB CEF 10A fuse - CORRECTED
            ("CEF", 10, 1.0, 3600, 3600, "ABB", "CEF-S", 400, 100000, "25°C", "No melt at rated current"),
            ("CEF", 10, 1.1, 1800, 1800, "ABB", "CEF-S", 400, 100000, "25°C", "May melt region"),
            ("CEF", 10, 1.35, 400, 400, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 10, 1.6, 120, 120, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 10, 2.0, 30, 35, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 10, 3.0, 8, 10, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 10, 5.0, 2.0, 2.5, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 10, 8.0, 0.18, 0.22, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 10, 10.0, 0.1, 0.12, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 10, 20.0, 0.025, 0.03, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 10, 50.0, 0.006, 0.008, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 10, 100.0, 0.003, 0.004, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            
            # ABB CEF 16A fuse
            ("CEF", 16, 1.0, 3600, 3600, "ABB", "CEF-S", 400, 100000, "25°C", "No melt at rated current"),
            ("CEF", 16, 1.1, 1800, 1800, "ABB", "CEF-S", 400, 100000, "25°C", "May melt region"),
            ("CEF", 16, 1.35, 500, 500, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 16, 1.6, 150, 150, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 16, 2.0, 45, 50, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 16, 3.0, 12, 15, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 16, 5.0, 3.0, 3.5, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 16, 10.0, 0.5, 0.6, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 16, 20.0, 0.12, 0.15, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 16, 50.0, 0.03, 0.04, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 16, 100.0, 0.015, 0.02, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            
            # ABB CEF 25A fuse - CORRECTED TO MATCH MANUFACTURER DATA
            ("CEF", 25, 2.179, 982, 982, "ABB", "CEF-S", 400, 100000, "25°C", "No melt at rated current"),
            ("CEF", 25, 2.405, 388.67, 388.67, "ABB", "CEF-S", 400, 100000, "25°C", "May melt region"),
            ("CEF", 25, 2.828, 89.182, 89.182, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 25, 3.211, 32.823, 32.823, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 25, 3.57, 16.908, 16.908, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 25, 3.859, 10.073, 10.073, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 25, 4.0, 7.881, 7.881, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 25, 4.8, 2.981, 2.981, "ABB", "CEF-S", 400, 100000, "25°C", "8x rating - corrected to match manufacturer"),
            ("CEF", 25, 6.285, 0.798, 0.798, "ABB", "CEF-S", 400, 100000, "25°C", "8x rating - corrected to match manufacturer"),
            ("CEF", 25, 7.993, 0.222, 0.222, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 25, 10.093, 0.072, 0.072, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 25, 11.875, 0.03, 0.03, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 25, 15.211, 0.01, 0.01, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            
            # ABB CEF 40A fuse
            ("CEF", 40, 1.77, 982, 982, "ABB", "CEF-S", 400, 100000, "25°C", "No melt at rated current"),
            ("CEF", 40, 2.01, 293.254, 293.254, "ABB", "CEF-S", 400, 100000, "25°C", "May melt region"),
            ("CEF", 40, 2.364, 74.362, 74.362, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 40, 2.781, 22.41, 22.41, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 40, 3.158, 8.87, 8.87, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 40, 3.822, 3.294, 3.294, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 40, 4.465, 1.508, 1.508, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 40, 5.180, 0.756, 0.756, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 40, 6.358, 0.252, 0.252, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 40, 7.376, 0.119, 0.1195, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 40, 8.436, 0.059, 0.059, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 40, 10.882, 0.018, 0.018, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 40, 12.359, 0.01, 0.01, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            
            # ABB CEF 63A fuse - CORRECTED
            ("CEF", 63, 1.915, 990, 990, "ABB", "CEF-S", 400, 100000, "25°C", "No melt at rated current"),
            ("CEF", 63, 2.098, 299, 299, "ABB", "CEF-S", 400, 100000, "25°C", "May melt region"),
            ("CEF", 63, 2.416, 97.7, 97.7, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 63, 3.0, 32.8, 32.8, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 63, 3.719, 9.7, 9.7, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 63, 4.194, 5.7, 5.7, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 63, 4.798, 3.18, 3.18, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 63, 6.549, 0.85, 0.85, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 63, 7.761, 0.389, 0.389, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 63, 9.732, 0.143, 0.143, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 63, 13.667, 0.037, 0.037, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 63, 16.082, 0.019, 0.019, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 63, 19.195, 0.01, 0.01, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),

            # ABB CEF 100A fuse - CORRECTED
            ("CEF", 100, 1.0, 3600, 3600, "ABB", "CEF-S", 400, 100000, "25°C", "No melt at rated current"),
            ("CEF", 100, 1.1, 1800, 1800, "ABB", "CEF-S", 400, 100000, "25°C", "May melt region"),
            ("CEF", 100, 1.35, 1200, 1200, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 100, 1.6, 360, 360, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 100, 2.0, 85, 95, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 100, 3.0, 22, 25, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 100, 5.0, 5.0, 6.0, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 100, 8.0, 0.5, 0.6, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 100, 10.0, 0.25, 0.3, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 100, 20.0, 0.06, 0.08, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 100, 50.0, 0.015, 0.02, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 100, 100.0, 0.008, 0.01, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            
            # ABB CEF 125A fuse
            ("CEF", 125, 1.0, 3600, 3600, "ABB", "CEF-S", 400, 100000, "25°C", "No melt at rated current"),
            ("CEF", 125, 1.1, 1800, 1800, "ABB", "CEF-S", 400, 100000, "25°C", "May melt region"),
            ("CEF", 125, 1.35, 1400, 1400, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 125, 1.6, 420, 420, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 125, 2.0, 120, 130, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 125, 3.0, 30, 35, "ABB", "CEF-S", 400, 100000, "25°C", "Pre-arcing time"),
            ("CEF", 125, 5.0, 7.0, 8.0, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 125, 10.0, 1.2, 1.4, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 125, 20.0, 0.3, 0.35, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 125, 50.0, 0.07, 0.09, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
            ("CEF", 125, 100.0, 0.035, 0.045, "ABB", "CEF-S", 400, 100000, "25°C", "Fast melt region"),
        ]

        eaton_elf_curves = [
            # Eaton ELF 25A fuse
            ("ELF", 25, 0.972, 986, 986, "EATON", "ELF", 400, 100000, "25°C", "No melt at rated current"),
            ("ELF", 25, 1.107, 135.4, 135.4, "EATON", "ELF", 400, 100000, "25°C", "May melt region"),
            ("ELF", 25, 1.13, 104.5, 104.5, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 25, 1.154, 82.9, 82.9, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 25, 1.193, 60.9, 60.9, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 25, 1.27, 36.9, 36.9, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 25, 1.35, 23.8, 23.8, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 25, 1.42, 16.7, 16.7, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 25, 1.506, 12.2, 12.2, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 25, 1.63, 8.52, 8.52, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 25, 1.726, 7.0, 7.0, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 25, 1.888, 5.31, 5.31, "EATON", "ELF", 400, 100000, "25°C", "No melt at rated current"),
            ("ELF", 25, 2.1, 3.97, 3.97, "EATON", "ELF", 400, 100000, "25°C", "May melt region"),
            ("ELF", 25, 2.436, 2.83, 2.83, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 25, 3.056, 1.83, 1.83, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 25, 3.801, 1.29, 1.29, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 25, 4.328, 1.03, 1.03, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 25, 4.894, 0.81, 0.81, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 25, 5.362, 0.63, 0.63, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 25, 5.709, 0.51, 0.51, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 25, 6.013, 0.38, 0.38, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 25, 6.82, 0.2049, 0.2049, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 25, 7.795, 0.1125, 0.1125, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 25, 9.3525, 0.0513, 0.0513, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 25, 10.46, 0.0339, 0.0339, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 25, 11.81, 0.0222, 0.0222, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 25, 13.35, 0.0152, 0.0152, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 25, 15.55, 0.01, 0.01, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),

            # Eaton ELF 40A fuse
            ("ELF", 40, 1.56, 986, 986, "EATON", "ELF", 400, 100000, "25°C", "No melt at rated current"),
            ("ELF", 40, 1.77, 135.4, 135.4, "EATON", "ELF", 400, 100000, "25°C", "May melt region"),
            ("ELF", 40, 1.81, 104.5, 104.5, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 40, 1.85, 82.9, 82.9, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 40, 1.91, 60.9, 60.9, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 40, 2.03, 36.9, 36.9, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 40, 2.16, 23.8, 23.8, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 40, 2.29, 16.7, 16.7, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 40, 2.41, 12.2, 12.2, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 40, 2.61, 8.52, 8.52, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 40, 2.76, 7.0, 7.0, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 40, 3.02, 5.31, 5.31, "EATON", "ELF", 400, 100000, "25°C", "No melt at rated current"),
            ("ELF", 40, 3.36, 3.97, 3.97, "EATON", "ELF", 400, 100000, "25°C", "May melt region"),
            ("ELF", 40, 3.90, 2.83, 2.83, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 40, 4.89, 1.83, 1.83, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 40, 6.08, 1.29, 1.29, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 40, 6.93, 1.03, 1.03, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 40, 7.83, 0.81, 0.81, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 40, 8.58, 0.63, 0.63, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 40, 9.13, 0.51, 0.51, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 40, 9.62, 0.38, 0.38, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 40, 10.91, 0.2049, 0.2049, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 40, 12.47, 0.1125, 0.1125, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 40, 14.96, 0.0513, 0.0513, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 40, 16.74, 0.0339, 0.0339, "EATON", "ELF", 400, 100000, "25°C", "Pre-arcing time"),
            ("ELF", 40, 18.95, 0.0222, 0.0222, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 40, 21.37, 0.0152, 0.0152, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
            ("ELF", 40, 24.89, 0.01, 0.01, "EATON", "ELF", 400, 100000, "25°C", "Fast melt region"),
        ]
        
        cursor.executemany("""
            INSERT INTO fuse_curves 
            (fuse_type, rating, current_multiplier, melting_time, clearing_time, manufacturer, series, voltage_rating, breaking_capacity, temperature, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, abb_cef_curves)

        logger.info("Loaded ABB CEF fuse curves reference data")

        cursor.executemany("""
            INSERT INTO fuse_curves 
            (fuse_type, rating, current_multiplier, melting_time, clearing_time, manufacturer, series, voltage_rating, breaking_capacity, temperature, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, eaton_elf_curves)

        logger.info("Loaded Eaton ELF fuse curves reference data")

        self.connection.commit()
    
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
            "version": "1.4.1",
            "performance_monitor_enabled": True
        }
        
        for key, value in default_config.items():
            cursor.execute("""
                INSERT OR IGNORE INTO config (key, value) 
                VALUES (?, ?)
            """, (key, json.dumps(value)))
        
        self.connection.commit()
        logger.info("Loaded default configuration values")
    
    def list_tables(self):
        """List all tables in the database."""
        try:
            cursor = self.connection.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
            return [table[0] for table in cursor.fetchall()]
        except Exception as e:
            logger.error(f"Error listing tables: {e}")
            return []
    
    def get_table_schema(self, table_name):
        """Get the schema for a specific table."""
        try:
            cursor = self.connection.cursor()
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = cursor.fetchall()
            
            schema = []
            for col in columns:
                schema.append({
                    'cid': col[0],
                    'name': col[1],
                    'type': col[2],
                    'notnull': col[3],
                    'default_value': col[4],
                    'pk': col[5]
                })
            return schema
        except Exception as e:
            logger.error(f"Error getting schema for table {table_name}: {e}")
            return []
    
    def table_exists(self, table_name):
        """Check if a table exists in the database."""
        try:
            cursor = self.connection.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?", (table_name,))
            return cursor.fetchone() is not None
        except Exception as e:
            logger.error(f"Error checking if table {table_name} exists: {e}")
            return False
    
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