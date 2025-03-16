import pandas as pd
import os
import math

class DataManager:
    """Class for managing cable data and calculation parameters."""
    
    def __init__(self):
        # Cable data for different configurations
        self._cable_data_cu_1c = None
        self._cable_data_cu_3c = None
        self._cable_data_al_1c = None
        self._cable_data_al_3c = None
        self._cable_data = None
        self._diversity_factors = None
        self._fuse_sizes_data = None
        
        # Load data files
        self._load_all_cable_data()
        self._load_diversity_factors()
        self._load_fuse_sizes_data()
        
    def _load_all_cable_data(self):
        """Load all cable data variants."""
        try:
            self._cable_data_cu_1c = pd.read_csv("data/cable_data_cu_1c.csv")
            self._cable_data_cu_3c = pd.read_csv("data/cable_data_cu_3c.csv")
            self._cable_data_al_1c = pd.read_csv("data/cable_data_al_1c.csv")
            self._cable_data_al_3c = pd.read_csv("data/cable_data_al_3c.csv")
        except Exception as e:
            print(f"Error loading cable data: {e}")
            
    def _load_diversity_factors(self):
        """Load diversity factors from CSV file."""
        try:
            df = pd.read_csv("data/diversity_factor.csv")
            # Rename columns to match expected names
            df.columns = ['houses', 'factor']
            self._diversity_factors = df
        except Exception as e:
            print(f"Error loading diversity factors: {e}")
            self._diversity_factors = pd.DataFrame({'houses': [1], 'factor': [1.0]})
            
    def _load_fuse_sizes_data(self):
        """Load network fuse size data from CSV."""
        try:
            self._fuse_sizes_data = pd.read_csv("data/network_fuse_sizes.csv")
            print(f"Loaded {len(self._fuse_sizes_data)} fuse size entries")
        except Exception as e:
            print(f"Error loading fuse size data: {e}")
            self._fuse_sizes_data = pd.DataFrame(columns=["Material", "Size (mm2)", "Network Fuse Size (A)"])
            
    def get_cable_data(self, material="Al", core_type="3C+E"):
        """Get cable data for the specified material and core type."""
        if material == "Cu":
            if core_type == "1C+E":
                return self._cable_data_cu_1c
            else:
                return self._cable_data_cu_3c
        else:  # Aluminum
            if core_type == "1C+E":
                return self._cable_data_al_1c
            else:
                return self._cable_data_al_3c
                
    def get_available_cables(self, material="Al", core_type="3C+E"):
        """Get list of available cable sizes for the specified material and core type."""
        cable_data = self.get_cable_data(material, core_type)
        if cable_data is not None:
            return cable_data['size'].tolist()
        return []
        
    def get_cable_by_size(self, size, material="Al", core_type="3C+E"):
        """Get cable data for a specific size."""
        cable_data = self.get_cable_data(material, core_type)
        if cable_data is not None:
            result = cable_data[cable_data['size'] == float(size)]
            if not result.empty:
                return result.iloc[0]
        return None
        
    def get_diversity_factor(self, num_houses):
        """Get diversity factor based on number of houses."""
        try:
            if self._diversity_factors is None:
                return 1.0

            df = self._diversity_factors
            
            # Find exact match first
            exact_match = df[df['houses'] == num_houses]
            if not exact_match.empty:
                return float(exact_match.iloc[0]['factor'])

            # If no exact match, interpolate
            if num_houses <= df['houses'].min():
                return float(df.iloc[0]['factor'])
            elif num_houses >= df['houses'].max():
                return float(df.iloc[-1]['factor'])
            else:
                # Find surrounding values
                idx = df['houses'].searchsorted(num_houses)
                h1, h2 = df['houses'].iloc[idx-1:idx+1]
                f1, f2 = df['factor'].iloc[idx-1:idx+1]
                
                # Linear interpolation
                factor = f1 + (f2 - f1) * (num_houses - h1) / (h2 - h1)
                return factor

        except Exception as e:
            print(f"Error calculating diversity factor: {e}")
            return 1.0
            
    def get_fuse_size(self, cable_size, material="Al"):
        """Get network fuse size for given cable size and material."""
        try:
            if self._fuse_sizes_data is None:
                return "N/A"
                
            # Look up the fuse size
            match = self._fuse_sizes_data[
                (self._fuse_sizes_data['Material'] == material) & 
                (self._fuse_sizes_data['Size (mm2)'] == float(cable_size))
            ]
            
            if not match.empty:
                return f"{match.iloc[0]['Network Fuse Size (A)']} A"
            else:
                return "Not specified"
                
        except Exception as e:
            print(f"Error looking up fuse size: {e}")
            return "Error"
            
    def calculate_current(self, kva, voltage=415.0, num_houses=1, diversity_factor=None):
        """Calculate current from kVA with diversity factor."""
        try:
            # Apply diversity factor if provided, otherwise use 1.0
            if diversity_factor is None:
                diversity_factor = self.get_diversity_factor(num_houses)
                
            adjusted_kva = kva * diversity_factor
            
            # Calculate current
            if voltage == 230.0:  # Single phase
                current = (adjusted_kva * 1000) / voltage  # P = VI
            else:  # Three phase (usually 415V)
                current = (adjusted_kva * 1000) / (voltage * math.sqrt(3))  # P = √3 × VI
                
            return current
            
        except Exception as e:
            print(f"Error calculating current: {e}")
            return 0.0
            
    def calculate_voltage_drop(self, current, length, cable, temperature=25, 
                             installation_method="D1 - Underground direct buried", 
                             grouping_factor=1.0, admd_enabled=False, admd_factor=1.5,
                             voltage=415.0):
        """Calculate voltage drop using mV/A/m method."""
        try:
            if current <= 0 or length <= 0:
                return 0.0
                
            # Apply ADMD factor if enabled and using 415V
            admd_multiplier = admd_factor if (admd_enabled and voltage > 230) else 1.0
            
            # Get mV/A/m value from cable data
            mv_per_am = float(cable['mv_per_am'])
            
            # Calculate voltage drop
            v_drop = (
                current * 
                length * 
                mv_per_am * 
                self._get_temperature_factor(temperature) * 
                self._get_installation_factor(installation_method, cable) * 
                grouping_factor * 
                admd_multiplier /
                1000.0
            )
            
            return v_drop
            
        except Exception as e:
            print(f"Error calculating voltage drop: {e}")
            return 0.0
            
    def _get_temperature_factor(self, temperature):
        """Get temperature correction factor."""
        base_temp = 75  # °C
        return 1 + 0.004 * (temperature - base_temp)
    
    def _get_installation_factor(self, installation_method, cable=None):
        """Get installation method factor with material consideration."""
        base_factors = {
            "A1 - Enclosed in thermal insulation": 1.25,
            "A2 - Enclosed in wall/ceiling": 1.15,
            "B1 - Enclosed in conduit in wall": 1.1,
            "B2 - Enclosed in trunking/conduit": 1.1,
            "C - Clipped direct": 1.0,
            "D1 - Underground direct buried": 1.1,
            "D2 - Underground in conduit": 1.15,
            "E - Free air": 0.95,
            "F - Cable tray/ladder/cleated": 0.95,
            "G - Spaced from surface": 0.90
        }
        
        factor = base_factors.get(installation_method, 1.0)
        
        # Check if we have cable information
        if cable is not None:
            # Apply material-specific adjustments
            material = cable.get('material', None)
            if material == "Al":
                factor *= 1.6  # Aluminum has higher resistance

            # Apply core configuration adjustments
            core_type = cable.get('core_type', None)
            if core_type == "3C+E":
                factor *= 1.05  # Three-core cables have slightly higher impedance
            
        return factor
