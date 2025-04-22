import os
import sys
import sqlite3
import pandas as pd

# Add project root to Python path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, project_root)

def verify_diversity_factors():
    """Compare diversity factors between CSV and database."""
    
    # Load CSV data
    csv_path = os.path.join(project_root, 'data', 'diversity_factor.csv')
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
        
        # Check if diversity_factors table exists
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='diversity_factors'")
        if not cursor.fetchone():
            print("\nNo diversity_factors table found in database!")
            print("Current memory store values are:")
            from utils.database.data_store import DataStore
            store = DataStore()
            print(store._memory_store['diversity_factors'])
            return
            
        # Get database data
        df = pd.read_sql("SELECT * FROM diversity_factors", conn)
        print("\nDatabase Data:")
        print(df)
        
        # Compare data
        print("\nComparison:")
        csv_set = set(zip(csv_data['No Houses'], csv_data['Diversity Factor']))
        db_set = set(zip(df['houses'], df['factor']))
        
        missing_in_db = csv_set - db_set
        extra_in_db = db_set - csv_set
        
        if missing_in_db:
            print("\nEntries in CSV but missing from database:")
            for houses, factor in missing_in_db:
                print(f"Houses: {houses}, Factor: {factor}")
        
        if extra_in_db:
            print("\nEntries in database but not in CSV:")
            for houses, factor in extra_in_db:
                print(f"Houses: {houses}, Factor: {factor}")
                
        if not missing_in_db and not extra_in_db:
            print("\nAll diversity factors match perfectly!")
            
    except sqlite3.Error as e:
        print(f"\nSQLite error: {e}")
    except Exception as e:
        print(f"\nGeneral error: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    verify_diversity_factors()
