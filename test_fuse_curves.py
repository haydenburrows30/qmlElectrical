#!/usr/bin/env python3

import sys
sys.path.append('.')

try:
    from services.database_manager import DatabaseManager
    db = DatabaseManager.get_instance()
    print('Database manager loaded successfully')
    
    # Check if fuse_curves table exists
    result = db.fetch_all('SELECT name FROM sqlite_master WHERE type="table" AND name="fuse_curves"')
    print('fuse_curves table exists:', len(result) > 0)
    
    if len(result) > 0:
        count_result = db.fetch_all('SELECT COUNT(*) as count FROM fuse_curves')
        print('Number of fuse curve rows:', count_result[0]['count'])
        
        # Test the protection relay methods
        from models.protection.protection_relay import ProtectionRelayCalculator
        relay = ProtectionRelayCalculator()
        
        print('Testing fuse curve methods...')
        fuse_types = relay.getFuseTypes('ABB')
        print('Available fuse types:', fuse_types)
        
        if fuse_types:
            ratings = relay.getFuseRatings('CEF', 'ABB')
            print('Available CEF ratings:', ratings)
            
            if ratings:
                success = relay.addFuseCurveToPlot('CEF', 10, 'ABB')
                print('Add fuse curve success:', success)
                
                loaded_fuses = relay.getLoadedFuseCurves()
                print('Loaded fuses:', loaded_fuses)
    
except Exception as e:
    print('Error:', e)
    import traceback
    traceback.print_exc()
