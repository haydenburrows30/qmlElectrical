import os
import sys
import sqlite3
import pandas as pd

# Add project root to Python path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, project_root)

def update_cable_data():
    """Update all cable data in database from CSV files."""
    
    # Define all cable types to update
    cable_types = [
        ('Al', '1C+E', 'cable_data_al_1c.csv'),
        ('Al', '3C+E', 'cable_data_al_3c.csv'),
        ('Cu', '1C+E', 'cable_data_cu_1c.csv'),
        ('Cu', '3C+E', 'cable_data_cu_3c.csv')
    ]
    
    try:
        # Connect to database
        db_path = os.path.join(project_root, 'data', 'application_data.db')
        
        if not os.path.exists(db_path):
            print(f"Database not found at: {db_path}")
            return
            
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Create table with correct schema
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS cable_data (
            material TEXT NOT NULL,
            core_type TEXT NOT NULL,
            size REAL NOT NULL,
            mv_per_am REAL NOT NULL,
            max_current REAL NOT NULL,
            PRIMARY KEY (material, core_type, size)
        )
        ''')
        
        total_entries = 0
        
        # Process each cable type
        for material, core_type, csv_file in cable_types:
            print(f"\nUpdating {material} {core_type} cable data...")
            
            # Load CSV data
            csv_path = os.path.join(project_root, 'data', csv_file)
            csv_data = pd.read_csv(csv_path)
            
            # Clear existing data for this cable type
            cursor.execute("""
                DELETE FROM cable_data 
                WHERE material = ? AND core_type = ?
            """, (material, core_type))
            
            # Insert new data
            for _, row in csv_data.iterrows():
                cursor.execute("""
                    INSERT INTO cable_data (material, core_type, size, mv_per_am, max_current) 
                    VALUES (?, ?, ?, ?, ?)
                """, (material, core_type, float(row['size']), float(row['mv_per_am']), float(row['max_current'])))
                
            total_entries += len(csv_data)
            print(f"Added {len(csv_data)} entries for {material} {core_type}")
        
        conn.commit()
        print(f"\nSuccessfully updated {total_entries} total cable entries")
        
        # Verify all updates
        print("\nVerifying updates...")
        for material, core_type, _ in cable_types:
            cursor.execute("""
                SELECT COUNT(*) FROM cable_data 
                WHERE material = ? AND core_type = ?
            """, (material, core_type))
            count = cursor.fetchone()[0]
            print(f"{material} {core_type}: {count} entries")
            
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
    update_cable_data()
