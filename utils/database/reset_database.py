import os
import sys
import sqlite3
import signal
import time

# Add project root to Python path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..','..'))
sys.path.insert(0, project_root)

# Import required initialization scripts
from init_reference_data import init_reference_data
from add_extended_reference_data import add_extended_reference_data
from update_cable_data import update_cable_data
from update_diversity_factors import update_diversity_factors
from update_fuse_sizes import update_fuse_sizes

def signal_handler(signum, frame):
    print("\nReceived interrupt signal. Cleaning up...")
    db_path = os.path.join(project_root, 'data', 'application_data.db')
    if os.path.exists(db_path):
        try:
            # Close any open connections
            for conn in sqlite3.connect(db_path).execute("PRAGMA database_list"):
                sqlite3.connect(db_path).close()
            # Remove incomplete database
            os.remove(db_path)
            print("Cleaned up incomplete database.")
        except:
            pass
    sys.exit(1)

def reset_database():
    """Remove and recreate the database with all required data."""
    
    # Setup interrupt handler
    signal.signal(signal.SIGINT, signal_handler)
    
    db_path = os.path.join(project_root, 'data', 'application_data.db')
    
    # Remove existing database
    if os.path.exists(db_path):
        print(f"Removing existing database: {db_path}")
        os.remove(db_path)
        # Small delay to ensure file is removed
        time.sleep(1.0)  # Increased delay for safety
    
    try:
        print("\nInitializing new database...")
        
        # Run initialization in order with progress tracking
        steps = [
            ("Initializing reference data", init_reference_data),
            ("Adding extended reference data", add_extended_reference_data),
            ("Updating cable data", update_cable_data),
            ("Updating diversity factors", update_diversity_factors),
            ("Updating fuse sizes", update_fuse_sizes)
        ]
        
        for i, (message, func) in enumerate(steps, 1):
            print(f"\n{i}. {message}...")
            func()
            # Small delay between operations
            time.sleep(0.2)
        
        # Verify the database
        verify_database(db_path)
        print("\nDatabase reset completed successfully!")
        return True
        
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")
        signal_handler(signal.SIGINT, None)
        return False
    except Exception as e:
        print(f"\nError during database reset: {e}")
        signal_handler(signal.SIGINT, None)
        return False

def verify_database(db_path):
    """Verify database contents after reset."""
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        
        print("\nVerification:")
        print("Created tables:", [table[0] for table in tables])
        
        # Verify each critical table
        table_counts = {
            'circuit_breakers': 'Circuit breakers',
            'protection_curves': 'Protection curves',
            'cable_data': 'Cable entries',
            'diversity_factors': 'Diversity factors',
            'fuse_sizes': 'Fuse sizes'
        }
        
        for table, description in table_counts.items():
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"{description}: {count} entries")
            
    except sqlite3.Error as e:
        print(f"Error verifying database: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    if reset_database():
        sys.exit(0)
    else:
        sys.exit(1)
