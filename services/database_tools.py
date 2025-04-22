import os
import pandas as pd
import sqlite3
import logging
from datetime import datetime
import shutil
from .database_manager import DatabaseManager

logger = logging.getLogger("qmltest.database.tools")

class DatabaseTools:
    """Database maintenance and viewing tools."""
    
    def __init__(self, db_path=None):
        if db_path is None:
            # Use default database path
            project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
            db_path = os.path.join(project_root, 'data', 'application_data.db')
        
        self.db_path = db_path
        self.db_manager = DatabaseManager.get_instance(db_path)
    
    def get_table_info(self):
        """Get information about all tables."""
        result = {}
        
        # Get list of tables
        tables = self.db_manager.fetch_all("SELECT name FROM sqlite_master WHERE type='table'")
        
        for table in tables:
            table_name = table['name']
            # Get column info
            columns = self.db_manager.fetch_all(f"PRAGMA table_info({table_name})")
            # Get row count
            row_count = self.db_manager.fetch_one(f"SELECT COUNT(*) as count FROM {table_name}")['count']
            
            result[table_name] = {
                'columns': [dict(col) for col in columns],
                'row_count': row_count
            }
            
        return result
    
    def backup_database(self, backup_dir=None):
        """Create timestamped backup of database."""
        return self.db_manager.backup_database(backup_dir)
    
    def restore_database(self, backup_path):
        """Restore database from backup."""
        if not os.path.exists(backup_path):
            raise FileNotFoundError(f"Backup file not found: {backup_path}")
            
        # Close connection
        self.db_manager.close()
        
        # Copy backup file to database location
        shutil.copy2(backup_path, self.db_path)
        logger.info(f"Database restored from {backup_path}")
        
        # Reinitialize database manager
        self.db_manager = DatabaseManager.get_instance(self.db_path)
        return True
    
    def export_table_to_csv(self, table_name, filepath):
        """Export table data to CSV."""
        try:
            # Get all data from table
            data = self.db_manager.fetch_all(f"SELECT * FROM {table_name}")
            
            # Convert to pandas DataFrame
            if data:
                # Convert list of Row objects to list of dicts
                data_dicts = [dict(row) for row in data]
                df = pd.DataFrame(data_dicts)
                df.to_csv(filepath, index=False)
                logger.info(f"Exported {table_name} to {filepath}")
                return True
            else:
                logger.warning(f"No data in table {table_name} to export")
                return False
        except Exception as e:
            logger.error(f"Error exporting {table_name} to CSV: {e}")
            return False
    
    def import_table_from_csv(self, table_name, filepath):
        """Import data from CSV into table."""
        try:
            if not os.path.exists(filepath):
                logger.error(f"CSV file not found: {filepath}")
                return False
                
            # Read CSV file
            df = pd.read_csv(filepath)
            
            # Get table schema
            columns_info = self.db_manager.fetch_all(f"PRAGMA table_info({table_name})")
            if not columns_info:
                logger.error(f"Table {table_name} not found in database")
                return False
                
            # Clear existing data
            self.db_manager.execute_query(f"DELETE FROM {table_name}")
            
            # Convert DataFrame to list of tuples for insertion
            columns = df.columns.tolist()
            placeholders = ', '.join(['?'] * len(columns))
            insert_query = f"INSERT INTO {table_name} ({', '.join(columns)}) VALUES ({placeholders})"
            
            # Insert data row by row
            cursor = self.db_manager.connection.cursor()
            for _, row in df.iterrows():
                cursor.execute(insert_query, tuple(row))
                
            self.db_manager.connection.commit()
            logger.info(f"Imported data into {table_name} from {filepath}")
            return True
        except Exception as e:
            logger.error(f"Error importing data from CSV: {e}")
            return False
    
    def vacuum_database(self):
        """Optimize database by removing unused space."""
        try:
            self.db_manager.execute_query("VACUUM")
            logger.info("Database vacuumed successfully")
            return True
        except Exception as e:
            logger.error(f"Error vacuuming database: {e}")
            return False
    
    def get_table_data(self, table_name, limit=1000):
        """Get data from table with optional limit."""
        try:
            data = self.db_manager.fetch_all(f"SELECT * FROM {table_name} LIMIT {limit}")
            
            if not data:
                return {'columns': [], 'rows': []}
                
            # Extract column names from first row
            columns = [key for key in dict(data[0]).keys()]
            
            # Convert to list of dicts
            rows = [dict(row) for row in data]
            
            return {
                'columns': columns,
                'rows': rows
            }
        except Exception as e:
            logger.error(f"Error getting table data: {e}")
            return {'columns': [], 'rows': [], 'error': str(e)}
    
    def execute_query(self, query):
        """Execute custom SQL query."""
        try:
            if query.strip().upper().startswith('SELECT'):
                data = self.db_manager.fetch_all(query)
                
                if not data:
                    return {'columns': [], 'rows': []}
                    
                # Extract column names from first row
                columns = [key for key in dict(data[0]).keys()]
                
                # Convert to list of dicts
                rows = [dict(row) for row in data]
                
                return {
                    'columns': columns,
                    'rows': rows
                }
            else:
                affected_rows = self.db_manager.execute_query(query)
                return {'affected_rows': affected_rows}
        except Exception as e:
            logger.error(f"Error executing query: {e}")
            return {'error': str(e)}
    
    def close(self):
        """Close database connection."""
        self.db_manager.close()
