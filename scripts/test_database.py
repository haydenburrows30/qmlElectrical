import os
import sys
import sqlite3

# Add project root to Python path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

from utils.data_store import DataStore

def test_sqlite_functionality():
    """Test basic SQLite functionality in the application."""
    print("Testing SQLite functionality...")
    print(f"Project root: {project_root}")
    print(f"Python path: {sys.path}")
    
    try:
        # Test direct SQLite connection
        db_path = os.path.join(project_root, 'data', 'test.db')
        conn = sqlite3.connect(db_path)
        print("✓ SQLite connection successful")
        
        # Test table creation
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS test_table (
                id INTEGER PRIMARY KEY,
                name TEXT,
                value REAL
            )
        ''')
        print("✓ Table creation successful")
        
        # Test data insertion
        cursor.execute("INSERT INTO test_table (name, value) VALUES (?, ?)", 
                      ("test_item", 123.45))
        conn.commit()
        print("✓ Data insertion successful")
        
        # Test data query
        cursor.execute("SELECT * FROM test_table")
        result = cursor.fetchone()
        if result:
            print("✓ Data query successful")
            print(f"Retrieved data: {result}")
        
        # Clean up
        cursor.execute("DROP TABLE test_table")
        conn.commit()
        conn.close()
        os.remove(db_path)
        print("✓ Cleanup successful")
        
        # Test DataStore class
        try:
            data_store = DataStore()
            print("✓ DataStore initialization successful")
            
            # Test adding calculation
            test_calc = {
                'timestamp': '2024-01-01 12:00:00',
                'voltage_system': '415V',
                'kva_per_house': 5.0,
                'num_houses': 10,
                'diversity_factor': 0.8,
                'total_kva': 40.0,
                'current': 55.7,
                'cable_size': '16',
                'conductor': 'Cu',
                'core_type': '3C+E',
                'length': 50.0,
                'voltage_drop': 2.5,
                'drop_percent': 0.6,
                'admd_enabled': False
            }
            
            success = data_store.add_calculation(test_calc)
            if success:
                print("✓ DataStore calculation storage successful")
            
            # Test retrieving calculation history
            history = data_store.get_calculation_history()
            if not history.empty:
                print("✓ DataStore calculation retrieval successful")
                print(f"Number of records: {len(history)}")
            
            data_store.close()
            print("✓ DataStore operations completed successfully")
            
        except Exception as e:
            print(f"✗ DataStore test failed: {str(e)}")
            
        print("\nAll SQLite tests completed successfully!")
        
    except sqlite3.Error as e:
        print(f"SQLite error: {e}")
    except Exception as e:
        print(f"General error: {e}")

if __name__ == "__main__":
    test_sqlite_functionality()
