import os
import sys
import sqlite3
import pandas as pd

# Add project root to Python path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

def update_diversity_factors():
    """Update diversity factors in database from CSV file."""
    
    try:
        # Load CSV data with explicit column names
        csv_path = os.path.join(project_root, 'data', 'diversity_factor.csv')
        csv_data = pd.read_csv(csv_path)
        
        if 'No Houses' not in csv_data.columns or 'Diversity Factor' not in csv_data.columns:
            print("Error: CSV file must have 'No Houses' and 'Diversity Factor' columns")
            return
            
        # Connect to database
        db_path = os.path.join(project_root, 'data', 'application_data.db')
        
        if not os.path.exists(db_path):
            print(f"Database not found at: {db_path}")
            return
            
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Create table with explicit column types
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS diversity_factors (
            houses INTEGER PRIMARY KEY,
            factor REAL NOT NULL
        )
        ''')
        
        # Clear existing data
        cursor.execute("DELETE FROM diversity_factors")
        
        # Prepare all data for insertion
        data_to_insert = []
        for _, row in csv_data.iterrows():
            try:
                houses = int(row['No Houses'])
                factor = float(row['Diversity Factor'])
                data_to_insert.append((houses, factor))
            except ValueError as e:
                print(f"Error converting data: {e}")
                continue
        
        # Insert all data at once
        cursor.executemany(
            "INSERT INTO diversity_factors (houses, factor) VALUES (?, ?)",
            data_to_insert
        )
        
        conn.commit()
        print(f"Successfully updated {len(data_to_insert)} diversity factors")
        
        # Verify the update
        cursor.execute("SELECT houses, factor FROM diversity_factors ORDER BY houses")
        results = cursor.fetchall()
        print("\nNew diversity factors in database:")
        for row in results:
            print(f"Houses: {row[0]}, Factor: {row[1]}")
            
    except sqlite3.Error as e:
        print(f"SQLite error: {e}")
    except Exception as e:
        print(f"General error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    update_diversity_factors()
