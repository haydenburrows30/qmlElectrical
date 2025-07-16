#!/usr/bin/env python3
"""
Script to update ABB CEF fuse curves in the database with corrected values.
This script will clear existing fuse curve data and reload it with the updated values.
"""

import os
import sys
import sqlite3
from services.database_manager import DatabaseManager
from services.logger_config import configure_logger

# Configure logging
logger = configure_logger("update_fuse_curves")

def update_fuse_curves():
    """Update the fuse curves data in the database."""
    try:
        # Get database manager instance
        db_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 'data', 'application_data.db'))
        logger.info(f"Updating fuse curves in database: {db_path}")
        
        db_manager = DatabaseManager.get_instance(db_path)
        
        # Clear existing fuse curve data
        logger.info("Clearing existing fuse curve data...")
        db_manager.execute_query("DELETE FROM fuse_curves")
        
        # Force reload of fuse curves
        logger.info("Reloading fuse curves with updated data...")
        db_manager._load_fuse_curves()
        
        # Verify the update
        result = db_manager.fetch_one("SELECT COUNT(*) as count FROM fuse_curves")
        count = result['count'] if result else 0
        logger.info(f"Successfully updated fuse curves. Total records: {count}")
        
        # Show sample data
        sample_data = db_manager.fetch_all("""
            SELECT fuse_type, rating, COUNT(*) as point_count
            FROM fuse_curves 
            WHERE manufacturer = 'ABB' 
            GROUP BY fuse_type, rating 
            ORDER BY rating
        """)
        
        logger.info("Updated fuse curve summary:")
        for row in sample_data:
            logger.info(f"  {row['fuse_type']} {row['rating']}A: {row['point_count']} points")
        
        return True
        
    except Exception as e:
        logger.error(f"Error updating fuse curves: {e}")
        return False

if __name__ == "__main__":
    success = update_fuse_curves()
    if success:
        print("✅ Fuse curves updated successfully!")
    else:
        print("❌ Failed to update fuse curves!")
        sys.exit(1)
