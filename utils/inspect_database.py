#!/usr/bin/env python3
"""
Database Inspector Tool

This script helps inspect the database structure and content.
It can list tables, show schemas, and display table contents.
"""

import os
import sys
import sqlite3
import argparse
from tabulate import tabulate

# Add parent directory to path to import app modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from services.database_manager import DatabaseManager

def list_tables(db_manager):
    """List all tables in the database."""
    tables = db_manager.list_tables()
    if tables:
        print("\nTables in database:")
        for i, table in enumerate(tables, 1):
            print(f"{i}. {table}")
    else:
        print("No tables found in database.")
    return tables

def show_table_schema(db_manager, table_name):
    """Show schema for a specific table."""
    schema = db_manager.get_table_schema(table_name)
    if schema:
        headers = ["Column ID", "Name", "Type", "Not Null", "Default Value", "Primary Key"]
        rows = [[col['cid'], col['name'], col['type'], 
                "Yes" if col['notnull'] else "No", 
                col['default_value'], 
                "Yes" if col['pk'] else "No"] for col in schema]
        
        print(f"\nSchema for table '{table_name}':")
        print(tabulate(rows, headers, tablefmt="grid"))
    else:
        print(f"No schema found for table '{table_name}'.")

def show_table_contents(db_manager, table_name, limit=10):
    """Show contents of a specific table with optional limit."""
    try:
        # Get table schema first to properly format output
        schema = db_manager.get_table_schema(table_name)
        if not schema:
            print(f"No schema found for table '{table_name}'.")
            return
            
        column_names = [col['name'] for col in schema]
        
        # Get data with limit
        query = f"SELECT * FROM {table_name} LIMIT {limit}"
        rows = db_manager.fetch_all(query)
        
        if rows:
            data = []
            for row in rows:
                data.append([row[col] for col in column_names])
            
            print(f"\nContents of table '{table_name}' (limit {limit}):")
            print(tabulate(data, column_names, tablefmt="grid"))
            
            # Show count of total rows
            total = db_manager.fetch_one(f"SELECT COUNT(*) FROM {table_name}")
            print(f"Showing {min(limit, total[0])} of {total[0]} rows.")
        else:
            print(f"Table '{table_name}' is empty.")
    except Exception as e:
        print(f"Error showing table contents: {e}")

def main():
    """Main function to run the database inspector."""
    parser = argparse.ArgumentParser(description="Database Inspector Tool")
    parser.add_argument("-t", "--table", help="Inspect a specific table")
    parser.add_argument("-l", "--limit", type=int, default=10, help="Limit number of rows to display")
    parser.add_argument("-s", "--schema", action="store_true", help="Show schema for specified table")
    parser.add_argument("-d", "--database", help="Path to database file (optional)")
    args = parser.parse_args()
    
    # Get database path
    if args.database:
        db_path = args.database
    else:
        # Use default path
        project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
        db_path = os.path.join(project_root, 'data', 'application_data.db')
    
    # Check if database exists
    if not os.path.exists(db_path):
        print(f"Error: Database file not found at {db_path}")
        return 1
    
    print(f"Inspecting database: {db_path}")
    db_manager = DatabaseManager.get_instance(db_path)
    
    if args.table:
        if args.schema:
            show_table_schema(db_manager, args.table)
        else:
            show_table_contents(db_manager, args.table, args.limit)
    else:
        # List all tables
        tables = list_tables(db_manager)
        if tables:
            # Interactive mode if no specific table was provided
            try:
                choice = input("\nEnter table number to view schema, or press Enter to exit: ")
                if choice.strip():
                    table_index = int(choice) - 1
                    if 0 <= table_index < len(tables):
                        selected_table = tables[table_index]
                        show_table_schema(db_manager, selected_table)
                        
                        # Ask if user wants to see contents
                        show_contents = input(f"\nShow contents of '{selected_table}'? (y/n): ")
                        if show_contents.lower() in ('y', 'yes'):
                            limit = input("Number of rows to display (default 10): ")
                            try:
                                limit = int(limit) if limit.strip() else 10
                            except ValueError:
                                limit = 10
                            show_table_contents(db_manager, selected_table, limit)
                    else:
                        print("Invalid table number.")
            except (ValueError, IndexError):
                print("Invalid input.")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
