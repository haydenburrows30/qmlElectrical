#!/usr/bin/env python3
"""
Script to verify the updated ABB CEF fuse curves data.
"""

import os
import sys
from services.database_manager import DatabaseManager
from services.logger_config import configure_logger

# Configure logging
logger = configure_logger("verify_fuse_curves")

def verify_fuse_curves():
    """Verify the fuse curves data in the database."""
    try:
        # Get database manager instance
        db_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 'data', 'application_data.db'))
        db_manager = DatabaseManager.get_instance(db_path)
        
        # Check total count
        result = db_manager.fetch_one("SELECT COUNT(*) as count FROM fuse_curves")
        total_count = result['count'] if result else 0
        print(f"Total fuse curve records: {total_count}")
        
        # Check available ratings
        ratings = db_manager.fetch_all("""
            SELECT DISTINCT rating 
            FROM fuse_curves 
            WHERE manufacturer = 'ABB' AND fuse_type = 'CEF'
            ORDER BY rating
        """)
        
        print("\nAvailable ABB CEF ratings:")
        for row in ratings:
            rating = row['rating']
            
            # Get sample data points for this rating
            sample_points = db_manager.fetch_all("""
                SELECT current_multiplier, melting_time 
                FROM fuse_curves 
                WHERE manufacturer = 'ABB' AND fuse_type = 'CEF' AND rating = ?
                ORDER BY current_multiplier
                LIMIT 5
            """, (rating,))
            
            print(f"  {rating}A fuse:")
            for point in sample_points:
                current = rating * point['current_multiplier']
                time = point['melting_time']
                print(f"    {current:6.1f}A -> {time:8.3f}s")
        
        # Test specific values that should match the screenshot
        print("\nTesting specific values from screenshot:")
        
        # Test 6.3A fuse at 2x rated current (should be around 30s)
        test_point = db_manager.fetch_one("""
            SELECT melting_time FROM fuse_curves 
            WHERE manufacturer = 'ABB' AND fuse_type = 'CEF' AND rating = 6.3
            AND current_multiplier = 2.0
        """)
        if test_point:
            print(f"  6.3A fuse at 2x (12.6A): {test_point['melting_time']}s")
        
        # Test 25A fuse at 3x rated current (should be around 15s)
        test_point = db_manager.fetch_one("""
            SELECT melting_time FROM fuse_curves 
            WHERE manufacturer = 'ABB' AND fuse_type = 'CEF' AND rating = 25
            AND current_multiplier = 3.0
        """)
        if test_point:
            print(f"  25A fuse at 3x (75A): {test_point['melting_time']}s")
        
        # Test 100A fuse at 5x rated current (should be around 6s)
        test_point = db_manager.fetch_one("""
            SELECT melting_time FROM fuse_curves 
            WHERE manufacturer = 'ABB' AND fuse_type = 'CEF' AND rating = 100
            AND current_multiplier = 5.0
        """)
        if test_point:
            print(f"  100A fuse at 5x (500A): {test_point['melting_time']}s")
        
        return True
        
    except Exception as e:
        logger.error(f"Error verifying fuse curves: {e}")
        return False

if __name__ == "__main__":
    success = verify_fuse_curves()
    if not success:
        sys.exit(1)
