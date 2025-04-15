#!/usr/bin/env python
"""
check_calculators.py - Utility to find calculators not being preloaded
"""

import os
import sys
from pathlib import Path

# Add the project root to the Python path
project_root = Path(__file__).parent.parent
sys.path.append(str(project_root))

from utils.preload_manager import PreloadManager

def main():
    """Find calculators that aren't being preloaded"""
    print("Checking for calculators that aren't being preloaded...")
    
    # Create a preload manager instance
    manager = PreloadManager()
    
    # Add directories that are normally loaded in your application
    qml_dir = os.path.join(project_root, "qml")
    manager.add_directory(os.path.join(qml_dir, "components"))
    manager.add_directory(os.path.join(qml_dir, "style"))
    manager.add_directory(os.path.join(qml_dir, "calculators"))
    
    # Find missing calculators
    missing = manager.find_missing_calculators(project_root)
    
    if not missing:
        print("All calculators are being properly preloaded!")
    else:
        print(f"Found {len(missing)} calculators that aren't being preloaded:")
        for calc in missing:
            rel_path = os.path.relpath(calc, project_root)
            print(f"  - {rel_path}")
            
        # Offer to add them
        choice = input("\nWould you like to update your main.py to preload these calculators? (y/n): ")
        if choice.lower() == 'y':
            update_main_file(missing)
            
def update_main_file(missing_calculators):
    """Update the main.py file to preload missing calculators"""
    main_file = os.path.join(project_root, "main.py")
    
    if not os.path.exists(main_file):
        print(f"Error: Could not find {main_file}")
        return
        
    try:
        with open(main_file, 'r') as f:
            lines = f.readlines()
            
        # Find where preloading happens
        preload_index = -1
        for i, line in enumerate(lines):
            if "preload_manager.add_directory" in line and "calculators" in line:
                preload_index = i
                break
                
        if preload_index == -1:
            print("Could not find where calculator preloading happens in main.py")
            return
            
        # Add individual components after the directory loading
        new_lines = []
        for calc in missing_calculators:
            rel_path = os.path.relpath(calc, project_root)
            new_lines.append(f'    preload_manager.add_component(os.path.join(base_path, "{rel_path}"))\n')
            
        # Insert the new lines
        lines[preload_index+1:preload_index+1] = new_lines
        
        # Write the updated file
        with open(main_file, 'w') as f:
            f.writelines(lines)
            
        print(f"Updated {main_file} to preload {len(missing_calculators)} additional calculators.")
        
    except Exception as e:
        print(f"Error updating main.py: {e}")

if __name__ == "__main__":
    main()