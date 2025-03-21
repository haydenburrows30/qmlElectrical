import os
import sys
import sqlite3
import pandas as pd

# Add project root to Python path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

def init_reference_data():
    """Initialize reference data tables in database."""
    try:
        db_path = os.path.join(project_root, 'data', 'application_data.db')
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # Clear existing data first
        cursor.execute("DROP TABLE IF EXISTS circuit_breakers")
        cursor.execute("DROP TABLE IF EXISTS protection_curves")

        # Installation methods
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS installation_methods (
            code TEXT PRIMARY KEY,
            description TEXT NOT NULL,
            base_factor REAL NOT NULL,
            notes TEXT
        )''')

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

        # Temperature factors
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS temperature_factors (
            temperature INTEGER,
            insulation_type TEXT,
            factor REAL NOT NULL,
            PRIMARY KEY (temperature, insulation_type)
        )''')

        temp_data = [
            (25, 'PVC', 1.0),
            (35, 'PVC', 0.94),
            (45, 'PVC', 0.87),
            (25, 'XLPE', 1.0),
            (35, 'XLPE', 0.96),
            (45, 'XLPE', 0.91)
        ]

        # Cable materials
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS cable_materials (
            material TEXT PRIMARY KEY,
            resistivity REAL NOT NULL,
            temperature_coefficient REAL NOT NULL,
            description TEXT
        )''')

        material_data = [
            ('Cu', 1.72e-8, 0.00393, 'Copper conductor'),
            ('Al', 2.82e-8, 0.00403, 'Aluminum conductor')
        ]

        # Standards reference
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS standards_reference (
            code TEXT PRIMARY KEY,
            description TEXT NOT NULL,
            voltage_drop_limit REAL,
            current_rating_table TEXT,
            category TEXT
        )''')

        standards_data = [
            ('AS3008.1.1', 'Selection of cables - Voltage drop', 5.0, 'Table 3', 'Voltage Drop'),
            ('AS3008.1.2', 'Current carrying capacity', None, 'Table 4', 'Current Rating')
        ]

        # Create tables
        cursor.execute('''
        CREATE TABLE circuit_breakers (
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

        # Insert data
        cursor.executemany("INSERT OR REPLACE INTO installation_methods VALUES (?, ?, ?, ?)", installation_data)
        cursor.executemany("INSERT OR REPLACE INTO temperature_factors VALUES (?, ?, ?)", temp_data)
        cursor.executemany("INSERT OR REPLACE INTO cable_materials VALUES (?, ?, ?, ?)", material_data)
        cursor.executemany("INSERT OR REPLACE INTO standards_reference VALUES (?, ?, ?, ?, ?)", standards_data)

        # Insert updated default data with proper curve types per breaker type
        default_breakers = [
            # MCB ratings with curve-specific types and full range
            # B Type MCBs
            ("MCB", 6, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B6", "6A Type B MCB"),
            ("MCB", 10, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B10", "10A Type B MCB"),
            ("MCB", 16, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B16", "16A Type B MCB"),
            ("MCB", 20, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B20", "20A Type B MCB"),
            ("MCB", 25, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B25", "25A Type B MCB"),
            ("MCB", 32, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B32", "32A Type B MCB"),
            ("MCB", 40, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B40", "40A Type B MCB"),
            ("MCB", 50, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B50", "50A Type B MCB"),
            ("MCB", 63, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B63", "63A Type B MCB"),
            ("MCB", 80, 6000, "B", "IEC Standard Inverse", "Generic", "MCB-B80", "80A Type B MCB"),
            
            # C Type MCBs
            ("MCB", 6, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C6", "6A Type C MCB"),
            ("MCB", 10, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C10", "10A Type C MCB"),
            ("MCB", 16, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C16", "16A Type C MCB"),
            ("MCB", 20, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C20", "20A Type C MCB"),
            ("MCB", 25, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C25", "25A Type C MCB"),
            ("MCB", 32, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C32", "32A Type C MCB"),
            ("MCB", 40, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C40", "40A Type C MCB"),
            ("MCB", 50, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C50", "50A Type C MCB"),
            ("MCB", 63, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C63", "63A Type C MCB"),
            ("MCB", 80, 6000, "C", "IEC Very Inverse", "Generic", "MCB-C80", "80A Type C MCB"),
            
            # D Type MCBs
            ("MCB", 6, 6000, "D", "IEC Extremely Inverse", "Generic", "MCB-D6", "6A Type D MCB"),
            ("MCB", 10, 6000, "D", "IEC Extremely Inverse", "Generic", "MCB-D10", "10A Type D MCB"),
            ("MCB", 16, 6000, "D", "IEC Extremely Inverse", "Generic", "MCB-D16", "16A Type D MCB"),
            ("MCB", 20, 6000, "D", "IEC Extremely Inverse", "Generic", "MCB-D20", "20A Type D MCB"),
            ("MCB", 25, 6000, "D", "IEC Extremely Inverse", "Generic", "MCB-D25", "25A Type D MCB"),
            ("MCB", 32, 6000, "D", "IEC Extremely Inverse", "Generic", "MCB-D32", "32A Type D MCB"),
            ("MCB", 40, 6000, "D", "IEC Extremely Inverse", "Generic", "MCB-D40", "40A Type D MCB"),
            ("MCB", 50, 6000, "D", "IEC Extremely Inverse", "Generic", "MCB-D50", "50A Type D MCB"),
            ("MCB", 63, 6000, "D", "IEC Extremely Inverse", "Generic", "MCB-D63", "63A Type D MCB"),
            ("MCB", 80, 6000, "D", "IEC Extremely Inverse", "Generic", "MCB-D80", "80A Type D MCB"),
            
            # MCCB ratings with full range
            ("MCCB", 100, 25000, "S", "IEC Extremely Inverse", "Generic", "MCCB-100", "100A MCCB"),
            ("MCCB", 125, 25000, "S", "IEC Extremely Inverse", "Generic", "MCCB-125", "125A MCCB"),
            ("MCCB", 160, 25000, "S", "IEC Extremely Inverse", "Generic", "MCCB-160", "160A MCCB"),
            ("MCCB", 200, 25000, "S", "IEC Extremely Inverse", "Generic", "MCCB-200", "200A MCCB"),
            ("MCCB", 250, 35000, "S", "IEC Extremely Inverse", "Generic", "MCCB-250", "250A MCCB"),
            ("MCCB", 320, 35000, "S", "IEC Extremely Inverse", "Generic", "MCCB-320", "320A MCCB"),
            ("MCCB", 400, 35000, "S", "IEC Extremely Inverse", "Generic", "MCCB-400", "400A MCCB"),
            ("MCCB", 500, 40000, "S", "IEC Extremely Inverse", "Generic", "MCCB-500", "500A MCCB"),
            ("MCCB", 630, 40000, "S", "IEC Extremely Inverse", "Generic", "MCCB-630", "630A MCCB"),
            ("MCCB", 800, 42000, "S", "IEC Extremely Inverse", "Generic", "MCCB-800", "800A MCCB"),
            ("MCCB", 1000, 45000, "S", "IEC Extremely Inverse", "Generic", "MCCB-1000", "1000A MCCB"),
            ("MCCB", 1250, 50000, "S", "IEC Extremely Inverse", "Generic", "MCCB-1250", "1250A MCCB"),
            ("MCCB", 1600, 50000, "S", "IEC Extremely Inverse", "Generic", "MCCB-1600", "1600A MCCB"),
        ]

        cursor.executemany("""
            INSERT INTO circuit_breakers 
            (type, rating, breaking_capacity, breaker_curve, curve_type, manufacturer, model, description)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, default_breakers)

        conn.commit()
        print("Successfully initialized reference data")

    except sqlite3.Error as e:
        print(f"SQLite error: {e}")
    except Exception as e:
        print(f"General error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    init_reference_data()
