#!/usr/bin/env python3
"""
Verify that the fuse curves data was updated correctly.
"""

import sys
import os
sys.path.insert(0, os.path.abspath('.'))

from services.database_manager import DatabaseManager

def verify_fuse_data():
    """Verify the fuse curves data in the database."""
    
    # Get database instance
    db_manager = DatabaseManager.get_instance()
    
    print("=== Verifying Fuse Curves Data ===")
    
    # Check available fuse types
    fuse_types = db_manager.fetch_all("""
        SELECT DISTINCT fuse_type, COUNT(*) as point_count
        FROM fuse_curves 
        WHERE manufacturer = 'ABB'
        GROUP BY fuse_type
        ORDER BY fuse_type
    """)
    
    print(f"\nAvailable fuse types:")
    for fuse_type in fuse_types:
        print(f"  - {fuse_type['fuse_type']}: {fuse_type['point_count']} data points")
    
    # Check available ratings for CEF fuses
    ratings = db_manager.fetch_all("""
        SELECT DISTINCT rating
        FROM fuse_curves 
        WHERE manufacturer = 'ABB' AND fuse_type = 'CEF'
        ORDER BY rating
    """)
    
    print(f"\nAvailable CEF ratings:")
    for rating in ratings:
        print(f"  - {rating['rating']} A")
    
    # Show sample data for a few ratings
    sample_ratings = [6.3, 25, 63, 100]
    
    for rating in sample_ratings:
        print(f"\n--- Sample data for {rating}A CEF fuse ---")
        data = db_manager.fetch_all("""
            SELECT current_multiplier, melting_time
            FROM fuse_curves 
            WHERE manufacturer = 'ABB' AND fuse_type = 'CEF' AND rating = ?
            ORDER BY current_multiplier
            LIMIT 8
        """, (rating,))
        
        if data:
            print("Current Multiplier | Melting Time")
            print("-" * 30)
            for point in data:
                current = rating * point['current_multiplier']
                print(f"{point['current_multiplier']:>8.1f} x {rating}A = {current:>6.1f}A | {point['melting_time']:>8.3f}s")
        else:
            print("No data found!")
    
    # Check specific 25A at 8x rating (200A)
    print(f"\n--- SPECIFIC CHECK: 25A fuse at 8x rating (200A) ---")
    specific_result = db_manager.fetch_one("""
        SELECT current_multiplier, melting_time
        FROM fuse_curves 
        WHERE manufacturer = 'ABB' AND fuse_type = 'CEF' AND rating = 25 AND current_multiplier = 8.0
    """)
    
    if specific_result:
        print(f"✅ 25A fuse at 8x rating (200A): {specific_result['melting_time']}s")
        print(f"   This should be around 0.2s as per manufacturer data")
    else:
        print("❌ No data found for 25A fuse at 8x rating!")
    
    print("\n=== Verification Complete ===")

if __name__ == "__main__":
    verify_fuse_data()
