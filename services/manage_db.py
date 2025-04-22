#!/usr/bin/env python3
import os
import sys
import argparse
from tabulate import tabulate
import logging

# Add parent directory to Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from services.database_tools import DatabaseTools
from services.database_manager import DatabaseManager

# Set up logger
logger = logging.getLogger("qmltest.database.manage")

def get_db_path():
    """Get path to application database."""
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'application_data.db'))

def print_table(data):
    """Print data in tabular format."""
    if 'error' in data:
        print(f"Error: {data['error']}")
        return
        
    if 'columns' in data and 'rows' in data:
        print(tabulate([row.values() for row in data['rows']], 
                      headers=data['columns'],
                      tablefmt='psql'))
    elif 'affected_rows' in data:
        print(f"Affected rows: {data['affected_rows']}")

def main():
    parser = argparse.ArgumentParser(description='Database Management Tool')
    parser.add_argument('command', choices=['info', 'backup', 'restore', 'vacuum', 
                                          'export', 'import', 'query', 'view', 'init'],
                       help='Command to execute')
    parser.add_argument('--table', help='Table name for export/import/view')
    parser.add_argument('--file', help='File path for backup/restore/export/import')
    parser.add_argument('--query', help='SQL query to execute')
    
    args = parser.parse_args()
    
    # Special case for init command which uses DatabaseManager
    if args.command == 'init':
        try:
            print("Initializing database with all reference data...")
            db_path = get_db_path()
            # This will create and initialize the database with all reference data
            db_manager = DatabaseManager.get_instance(db_path)
            print("Database initialization complete")
            return
        except Exception as e:
            print(f"Error initializing database: {e}")
            sys.exit(1)
    
    # For other commands, use DatabaseTools
    db = DatabaseTools(get_db_path())
    
    try:
        if args.command == 'info':
            info = db.get_table_info()
            for table, details in info.items():
                print(f"\nTable: {table}")
                print(f"Row count: {details['row_count']}")
                print("Columns:")
                print(tabulate(details['columns'], headers='keys', tablefmt='psql'))
                
        elif args.command == 'backup':
            backup_path = db.backup_database()
            print(f"Database backed up to: {backup_path}")
            
        elif args.command == 'restore':
            if not args.file:
                print("Error: --file required for restore")
                return
            db.restore_database(args.file)
            print("Database restored successfully")
            
        elif args.command == 'vacuum':
            db.vacuum_database()
            print("Database optimized")
            
        elif args.command == 'export':
            if not args.table or not args.file:
                print("Error: --table and --file required for export")
                return
            db.export_table_to_csv(args.table, args.file)
            print(f"Table {args.table} exported to {args.file}")
            
        elif args.command == 'import':
            if not args.table or not args.file:
                print("Error: --table and --file required for import")
                return
            db.import_table_from_csv(args.table, args.file)
            print(f"Data imported into table {args.table}")
            
        elif args.command == 'query':
            if not args.query:
                print("Error: --query required")
                return
            result = db.execute_query(args.query)
            print_table(result)
            
        elif args.command == 'view':
            if not args.table:
                print("Error: --table required for view")
                return
            data = db.get_table_data(args.table)
            print_table(data)
            
    finally:
        db.close()

if __name__ == '__main__':
    main()
