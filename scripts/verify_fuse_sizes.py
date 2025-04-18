import os
import sys
import sqlite3
import pandas as pd

# Add project root to Python path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

def verify_fuse_sizes():
    """Compare network fuse sizes between CSV and database."""
    
    # Load CSV data
    csv_path = os.path.join(project_root, 'data', 'network_fuse_sizes.csv')
    csv_data = pd.read_csv(csv_path)
    print("\nCSV Data:")
    print(csv_data)
    
    # Load database data
    db_path = os.path.join(project_root, 'data', 'application_data.db')
    
    if not os.path.exists(db_path):
        print(f"\nDatabase not found at: {db_path}")
        return
        
    try:
        # Get data from database
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check if fuse_sizes table exists
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='fuse_sizes'")
        if not cursor.fetchone():
            print("\nNo fuse_sizes table found in database!")
            print("Current memory store values are:")
            from utils.data_store import DataStore
            store = DataStore()
            print(store._memory_store['fuse_sizes'])
            print("\nCurrent database tables:")
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor.fetchall()
            print([table[0] for table in tables])
            return
            
        # Get database data
        df = pd.read_sql("SELECT * FROM fuse_sizes", conn)
        print("\nDatabase Data:")
        print(df)
        
        # Compare data
        print("\nComparison:")
        csv_set = set(zip(csv_data['Material'], csv_data['Size (mm2)'], csv_data['Network Fuse Size (A)']))
        db_set = set(zip(df['material'], df['size'], df['fuse_size']))
        
        missing_in_db = csv_set - db_set
        extra_in_db = db_set - csv_set
        
        if missing_in_db:
            print("\nEntries in CSV but missing from database:")
            for material, size, fuse in missing_in_db:
                print(f"Material: {material}, Size: {size}mm², Fuse: {fuse}A")
        
        if extra_in_db:
            print("\nEntries in database but not in CSV:")
            for material, size, fuse in extra_in_db:
                print(f"Material: {material}, Size: {size}mm², Fuse: {fuse}A")
                
        if not missing_in_db and not extra_in_db:
            print("\nAll fuse sizes match perfectly!")
            
    except sqlite3.Error as e:
        print(f"\nSQLite error: {e}")
    except Exception as e:
        print(f"\nGeneral error: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    verify_fuse_sizes()
