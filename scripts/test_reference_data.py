import os
import sys
import sqlite3

# Add project root to Python path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

from models.voltdrop.data_manager import DataManager

def test_reference_data():
    """Test the new reference data functionality."""
    dm = DataManager()
    
    print("\n=== Testing Installation Methods ===")
    methods = ['A1', 'B1', 'C', 'D1', 'E']
    for code in methods:
        result = dm.get_installation_factor(code)
        print(f"\n{code}:")
        print(result)
    
    print("\n=== Testing Temperature Factors ===")
    temps = [25, 35, 45]
    insulations = ['PVC', 'XLPE']
    for temp in temps:
        for insul in insulations:
            factor = dm.get_temperature_factor(temp, insul)
            print(f"\n{temp}°C, {insul}:")
            print(f"Factor: {factor}")
    
    print("\n=== Testing Material Properties ===")
    materials = ['Cu', 'Al']
    for material in materials:
        props = dm.get_material_properties(material)
        print(f"\n{material}:")
        print(props)
    
    print("\n=== Testing Standards Reference ===")
    standards = ['AS3008.1.1', 'AS3008.1.2']
    for code in standards:
        reqs = dm.get_standard_requirements(code)
        print(f"\n{code}:")
        print(reqs)

if __name__ == "__main__":
    test_reference_data()
