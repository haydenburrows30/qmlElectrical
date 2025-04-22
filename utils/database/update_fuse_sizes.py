import os
import sys
import sqlite3
import pandas as pd

# Add project root to Python path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, project_root)

def update_fuse_sizes():
    """Update network fuse sizes in database from CSV file."""
    
    try:
        # Load CSV data
        csv_path = os.path.join(project_root, 'data', 'network_fuse_sizes.csv')
        csv_data = pd.read_csv(csv_path)
        
        # Connect to database
        db_path = os.path.join(project_root, 'data', 'application_data.db')
        
        if not os.path.exists(db_path):
            print(f"Database not found at: {db_path}")
            return
            
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Drop existing table if it exists
        cursor.execute("DROP TABLE IF EXISTS fuse_sizes")
        
        # Create table with correct schema
        cursor.execute('''
        CREATE TABLE fuse_sizes (
            material TEXT NOT NULL,
            size REAL NOT NULL,
            fuse_size INTEGER NOT NULL,
            PRIMARY KEY (material, size)
        )
        ''')
        
        # Insert data from CSV
        for _, row in csv_data.iterrows():
            cursor.execute(
                "INSERT INTO fuse_sizes (material, size, fuse_size) VALUES (?, ?, ?)",
                (row['Material'], float(row['Size (mm2)']), int(row['Network Fuse Size (A)']))
            )
        
        conn.commit()
        print(f"Successfully updated {len(csv_data)} fuse sizes")
        
        # Verify the update
        cursor.execute("SELECT * FROM fuse_sizes ORDER BY material, size")
        results = cursor.fetchall()
        print("\nNew fuse sizes in database:")
        for row in results:
            print(f"Material: {row[0]}, Size: {row[1]}mm², Fuse: {row[2]}A")
            
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
    update_fuse_sizes()
