import os
import sys
import sqlite3

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, project_root)

def add_extended_reference_data():
    """Add extended reference data tables to database."""
    try:
        db_path = os.path.join(project_root, 'data', 'application_data.db')
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # Voltage systems
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

        voltage_data = [
            (230, "Single Phase LV", "Domestic supply", 50, 1, "LV", "Standard domestic"),
            (400, "Three Phase LV", "Commercial/industrial", 50, 3, "LV", "Standard commercial"),
            (415, "Three Phase LV+N", "Industrial with neutral", 50, 3, "LV", "With neutral"),
            (11000, "11kV", "Distribution", 50, 3, "MV", "Medium voltage"),
            (33000, "33kV", "Sub-transmission", 50, 3, "HV", "High voltage")
        ]

        # Circuit breaker types
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS circuit_breakers (
            id INTEGER PRIMARY KEY,
            type TEXT NOT NULL,
            rating REAL NOT NULL,
            breaking_capacity INTEGER NOT NULL,
            curve_type TEXT,
            manufacturer TEXT,
            model TEXT,
            description TEXT
        )''')

        breaker_data = [
            ("MCB", 6, 6000, "C", "Generic", "MCB-C6", "6A Type C MCB"),
            ("MCB", 10, 6000, "C", "Generic", "MCB-C10", "10A Type C MCB"),
            ("MCB", 16, 6000, "C", "Generic", "MCB-C16", "16A Type C MCB"),
            ("MCCB", 100, 25000, "C", "Generic", "MCCB-100", "100A MCCB")
        ]

        # Cable insulation types
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS insulation_types (
            code TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            max_temp INTEGER NOT NULL,
            description TEXT,
            material TEXT,
            standard TEXT
        )''')

        insulation_data = [
            ("PVC", "Polyvinyl Chloride", 70, "Standard PVC insulation", "Thermoplastic", "AS/NZS 5000.1"),
            ("XLPE", "Cross-linked Polyethylene", 90, "High temp rating", "Thermoset", "AS/NZS 5000.1"),
            ("EPR", "Ethylene Propylene Rubber", 90, "Flexible rubber", "Thermoset", "AS/NZS 5000.1")
        ]

        # Earth resistance values
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

        soil_data = [
            ("Clay", 5, 50, 20, "Moist", "High conductivity"),
            ("Sandy", 50, 500, 200, "Dry", "Poor conductivity"),
            ("Rock", 1000, 10000, 2000, "N/A", "Very high resistance")
        ]

        # Protection coordination times
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

        protection_data = [
            ("MCB", 32, 1.0, 3600, "C", "20°C", "Normal load"),
            ("MCB", 32, 5.0, 0.1, "C", "20°C", "Overload"),
            ("MCB", 32, 10.0, 0.01, "C", "20°C", "Short circuit")
        ]

        # Insert all data
        cursor.executemany("INSERT OR REPLACE INTO voltage_systems (voltage, name, description, frequency, phase_count, category, notes) VALUES (?, ?, ?, ?, ?, ?, ?)", voltage_data)
        cursor.executemany("INSERT OR REPLACE INTO circuit_breakers (type, rating, breaking_capacity, curve_type, manufacturer, model, description) VALUES (?, ?, ?, ?, ?, ?, ?)", breaker_data)
        cursor.executemany("INSERT OR REPLACE INTO insulation_types (code, name, max_temp, description, material, standard) VALUES (?, ?, ?, ?, ?, ?)", insulation_data)
        cursor.executemany("INSERT OR REPLACE INTO soil_resistivity (soil_type, min_resistivity, max_resistivity, typical_value, moisture_content, notes) VALUES (?, ?, ?, ?, ?, ?)", soil_data)
        cursor.executemany("INSERT OR REPLACE INTO protection_curves (device_type, rating, current_multiplier, tripping_time, curve_type, temperature, notes) VALUES (?, ?, ?, ?, ?, ?, ?)", protection_data)

        conn.commit()
        print("Successfully added extended reference data")

    except sqlite3.Error as e:
        print(f"SQLite error: {e}")
    except Exception as e:
        print(f"General error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    add_extended_reference_data()
