import os
import sys
import sqlite3
import pandas as pd
from tabulate import tabulate

# Add project root to Python path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

def view_database():
    """View contents of the application database."""
    db_path = os.path.join(project_root, 'data', 'application_data.db')
    
    if not os.path.exists(db_path):
        print(f"Database not found at: {db_path}")
        return
        
    try:
        # Connect to database
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get list of tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        
        print("\n=== Database Tables ===")
        for table in tables:
            table_name = table[0]
            print(f"\nTable: {table_name}")
            print("=" * (len(table_name) + 7))
            
            # Get table schema
            cursor.execute(f"PRAGMA table_info({table_name})")
            schema = cursor.fetchall()
            print("\nSchema:")
            print(tabulate(schema, headers=['cid', 'name', 'type', 'notnull', 'dflt_value', 'pk']))
            
            # Get table contents
            df = pd.read_sql(f"SELECT * FROM {table_name}", conn)
            if len(df) > 0:
                print("\nContents:")
                print(tabulate(df, headers='keys', tablefmt='psql', showindex=False))
            else:
                print("\nNo data in table")
            print("\n" + "-"*50)
            
        conn.close()
        
    except sqlite3.Error as e:
        print(f"Error accessing database: {e}")
    except Exception as e:
        print(f"General error: {e}")

if __name__ == "__main__":
    view_database()
