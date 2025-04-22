import os
import sys
import sqlite3
import pandas as pd

# Add project root to Python path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

def verify_cable_data():
    """Compare all cable data between CSV and database."""
    
    # Define all cable types to verify
    cable_types = [
        ('Al', '1C+E', 'cable_data_al_1c.csv'),
        ('Al', '3C+E', 'cable_data_al_3c.csv'),
        ('Cu', '1C+E', 'cable_data_cu_1c.csv'),
        ('Cu', '3C+E', 'cable_data_cu_3c.csv')
    ]
    
    for material, core_type, csv_file in cable_types:
        print(f"\n=== Verifying {material} {core_type} Cable Data ===")
        
        # Load CSV data
        csv_path = os.path.join(project_root, 'data', csv_file)
        csv_data = pd.read_csv(csv_path)
        print("\nCSV Data:")
        print(csv_data)
        
        # Load database data
        db_path = os.path.join(project_root, 'data', 'application_data.db')
        
        if not os.path.exists(db_path):
            print(f"\nDatabase not found at: {db_path}")
            return
            
        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            # Check if cable_data table exists
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='cable_data'")
            if not cursor.fetchone():
                print("\nNo cable_data table found in database!")
                print("Current memory store values from DataManager:")
                from models.voltdrop.data_manager import DataManager
                dm = DataManager()
                print(f"\n{material} {core_type} cable data from memory:")
                df = dm.get_cable_data(material, core_type)
                print(df)
                return
                
            # Get database data for specific cable type
            df = pd.read_sql("""
                SELECT size, mv_per_am, max_current 
                FROM cable_data 
                WHERE material = ? AND core_type = ?
                ORDER BY size
            """, conn, params=(material, core_type))
            print("\nDatabase Data:")
            print(df)
            
            # Compare data
            print("\nComparison:")
            csv_set = set(zip(csv_data['size'], csv_data['mv_per_am'], csv_data['max_current']))
            db_set = set(zip(df['size'], df['mv_per_am'], df['max_current']))
            
            missing_in_db = csv_set - db_set
            extra_in_db = db_set - csv_set
            
            if missing_in_db:
                print("\nEntries in CSV but missing from database:")
                for size, mv, current in missing_in_db:
                    print(f"Size: {size}mm², mV/A/m: {mv}, Max Current: {current}A")
            
            if extra_in_db:
                print("\nEntries in database but not in CSV:")
                for size, mv, current in extra_in_db:
                    print(f"Size: {size}mm², mV/A/m: {mv}, Max Current: {current}A")
                    
            if not missing_in_db and not extra_in_db:
                print("\nAll cable data matches perfectly!")
                
        except Exception as e:
            print(f"Error verifying {material} {core_type} cable data: {e}")
        finally:
            if 'conn' in locals():
                conn.close()

if __name__ == "__main__":
    verify_cable_data()
