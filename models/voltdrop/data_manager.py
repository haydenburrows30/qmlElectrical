import pandas as pd
import os
import math
import sqlite3

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
        
        # Load data from in-memory sources instead of CSV files
        self._load_all_cable_data()
        self._load_diversity_factors()
        self._load_fuse_sizes_data()
        
        self.db_path = os.path.join(os.path.dirname(__file__), '..', '..', 'data', 'application_data.db')

    def _load_all_cable_data(self):
        """Load cable data from in-memory data structures instead of CSV files."""
        try:
            # Create DataFrames from Python dictionaries - more efficient than CSV loading
            
            # Copper 1-core cable data
            cu_1c_data = {
                'size': [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400],
                'mv_per_am': [26, 15.6, 9.8, 6.5, 3.9, 2.5, 1.6, 1.2, 0.87, 0.62, 0.46, 0.37, 0.31, 0.25, 0.20, 0.17, 0.15],
                'max_current': [19.5, 27, 36, 45, 63, 85, 110, 135, 160, 200, 240, 280, 320, 365, 430, 495, 560]
            }
            
            # Copper 3-core cable data
            cu_3c_data = {
                'size': [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400],
                'mv_per_am': [26.5, 15.9, 10, 6.7, 4.0, 2.5, 1.6, 1.2, 0.93, 0.61, 0.45, 0.37, 0.33, 0.27, 0.22, 0.19, 0.17],
                'max_current': [17.5, 24, 31, 39, 54, 63, 95, 165, 140, 240, 290, 355, 280, 470, 375, 430, 485]
            }
            
            # Aluminum 1-core cable data
            al_1c_data = {
                'size': [16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400, 500, 630],
                'mv_per_am': [2.6, 1.7, 1.9, 1.4, 0.98, 0.75, 0.60, 0.50, 0.41, 0.32, 0.27, 0.24, 0.21, 0.18],
                'max_current': [115, 150, 105, 125, 160, 190, 220, 255, 290, 345, 395, 445, 495, 555]
            }
            
            # Aluminum 3-core cable data
            al_3c_data = {
                'size': [16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400, 500, 630],
                'mv_per_am': [4.2, 2.7, 2.0, 1.5, 1.1, 0.72, 0.58, 0.54, 0.39, 0.31, 0.27, 0.27, 0.24, 0.21],
                'max_current': [57, 75, 92, 110, 140, 240, 275, 225, 350, 410, 460, 390, 435, 485]
            }
            
            # Convert to DataFrames for compatibility with existing code
            self._cable_data_cu_1c = pd.DataFrame(cu_1c_data)
            self._cable_data_cu_3c = pd.DataFrame(cu_3c_data)
            self._cable_data_al_1c = pd.DataFrame(al_1c_data)
            self._cable_data_al_3c = pd.DataFrame(al_3c_data)
            
        except Exception as e:
            print(f"Error loading cable data: {e}")
            
    def _load_diversity_factors(self):
        """Load diversity factors from Python dict instead of CSV file."""
        try:
            # Create diversity factors data
            diversity_data = {
                'houses': [1, 2, 3, 4, 5, 10, 15, 20, 30, 40, 50, 100, 200],
                'factor': [1.0, 0.95, 0.90, 0.85, 0.80, 0.65, 0.55, 0.50, 0.45, 0.42, 0.40, 0.35, 0.30]
            }
            
            self._diversity_factors = pd.DataFrame(diversity_data)
        except Exception as e:
            print(f"Error loading diversity factors: {e}")
            self._diversity_factors = pd.DataFrame({'houses': [1], 'factor': [1.0]})
            
    def _load_fuse_sizes_data(self):
        """Load network fuse size data from Python dict instead of CSV."""
        try:
            # Create network fuse sizes data
            fuse_sizes_data = {
                'Material': ['Cu', 'Cu', 'Cu', 'Cu', 'Cu', 'Al', 'Al', 'Al', 'Al', 'Al', 'Al', 'Al'],
                'Size (mm2)': [16, 25, 35, 50, 95, 25, 35, 50, 95, 185, 300, 630],
                'Network Fuse Size (A)': [80, 100, 125, 160, 250, 63, 80, 100, 160, 250, 315, 500]
            }
            
            self._fuse_sizes_data = pd.DataFrame(fuse_sizes_data)
            # print(f"Loaded {len(self._fuse_sizes_data)} fuse size entries")
        except Exception as e:
            # print(f"Error loading fuse size data: {e}")
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
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get exact match with direct houses value
            cursor.execute("""
                SELECT factor 
                FROM diversity_factors 
                WHERE houses = ?
            """, (num_houses,))
            
            result = cursor.fetchone()
            if result:
                factor = float(result[0])
                # print(f"Found exact diversity factor: {factor} for {num_houses} houses")
                return factor
            
            conn.close()
            return 1.0  # Fallback default
            
        except Exception as e:
            print(f"Error getting diversity factor: {e}")
            return 1.0
            
    def get_fuse_size(self, cable_size, material="Al"):
        """Get network fuse size for given cable size and material."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Query fuse size from database
            cursor.execute("""
                SELECT fuse_size 
                FROM fuse_sizes 
                WHERE material = ? AND size = ?
            """, (material, float(cable_size)))
            
            result = cursor.fetchone()
            if result:
                return f"{result[0]} A"
            
            # print(f"No fuse size found for {material} {cable_size}mm²")
            return "Not specified"
                
        except Exception as e:
            print(f"Error looking up fuse size: {e}")
            return "Error"
        finally:
            if 'conn' in locals():
                conn.close()
                
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

    def calculate_rating_adjustments(self, cable, temperature=25.0, grouping=1.0, 
                                   installation_method="D1 - Underground direct buried"):
        """Calculate adjusted cable rating based on derating factors."""
        try:
            if cable is None:
                return 0.0
                
            base_rating = float(cable['max_current'])
            temp_factor = self._get_temperature_factor(temperature)
            install_factor = self._get_installation_factor(installation_method, cable)
            
            adjusted_rating = base_rating * temp_factor * install_factor * grouping
            return adjusted_rating
            
        except Exception as e:
            print(f"Error calculating rating adjustments: {e}")
            return 0.0
            
    def get_recommended_cable(self, current, voltage_drop_limit=5.0, length=1.0,
                            material="Al", core_type="3C+E"):
        """Get recommended cable size based on current and voltage drop limit."""
        try:
            cable_data = self.get_cable_data(material, core_type)
            if cable_data is None or cable_data.empty:
                return None
                
            # Filter cables that meet current rating
            suitable_cables = cable_data[cable_data['max_current'] >= current]
            
            if suitable_cables.empty:
                return None
                
            # Find smallest cable that meets voltage drop limit
            for _, cable in suitable_cables.iterrows():
                v_drop = self.calculate_voltage_drop(current, length, cable)
                if v_drop <= voltage_drop_limit:
                    return cable
                    
            # If no cable meets voltage drop, return largest available
            return suitable_cables.iloc[-1]
            
        except Exception as e:
            print(f"Error finding recommended cable: {e}")
            return None
            
    def calculate_derating(self, base_rating, temperature=25.0, grouping=1.0,
                          installation_method="D1 - Underground direct buried"):
        """Calculate total derating factor."""
        try:
            temp_factor = self._get_temperature_factor(temperature)
            install_factor = self._get_installation_factor(installation_method)
            
            total_factor = temp_factor * install_factor * grouping
            return base_rating * total_factor
            
        except Exception as e:
            print(f"Error calculating derating: {e}")
            return base_rating
            
    def validate_cable_selection(self, cable, current, length, voltage=415.0,
                               max_voltage_drop=5.0, temperature=25.0, grouping=1.0,
                               installation_method="D1 - Underground direct buried"):
        """Validate cable selection against current and voltage drop requirements."""
        try:
            if cable is None:
                return {
                    'valid': False,
                    'current_ok': False,
                    'voltage_ok': False,
                    'message': "No cable selected"
                }
                
            # Check current rating
            adjusted_rating = self.calculate_rating_adjustments(
                cable, temperature, grouping, installation_method
            )
            current_ok = current <= adjusted_rating
            
            # Check voltage drop
            v_drop = self.calculate_voltage_drop(
                current, length, cable, temperature,
                installation_method, grouping
            )
            drop_percent = (v_drop / voltage) * 100
            voltage_ok = drop_percent <= max_voltage_drop
            
            # Build result
            result = {
                'valid': current_ok and voltage_ok,
                'current_ok': current_ok,
                'voltage_ok': voltage_ok,
                'adjusted_rating': adjusted_rating,
                'voltage_drop': v_drop,
                'drop_percent': drop_percent
            }
            
            # Add appropriate message
            if not current_ok and not voltage_ok:
                result['message'] = "Cable undersized for both current and voltage drop"
            elif not current_ok:
                result['message'] = "Cable undersized for current"
            elif not voltage_ok:
                result['message'] = "Excessive voltage drop"
            else:
                result['message'] = "Cable selection OK"
                
            return result
            
        except Exception as e:
            print(f"Error validating cable selection: {e}")
            return {
                'valid': False,
                'current_ok': False,
                'voltage_ok': False,
                'message': f"Error: {str(e)}"
            }
            
    def export_data(self, filepath):
        """Export all cable data to CSV file."""
        try:
            # Combine all cable data into single DataFrame
            dfs = []
            
            # Add copper cables
            cu_1c = self._cable_data_cu_1c.copy()
            cu_1c['material'] = 'Cu'
            cu_1c['core_type'] = '1C+E'
            dfs.append(cu_1c)
            
            cu_3c = self._cable_data_cu_3c.copy()
            cu_3c['material'] = 'Cu'
            cu_3c['core_type'] = '3C+E'
            dfs.append(cu_3c)
            
            # Add aluminum cables
            al_1c = self._cable_data_al_1c.copy()
            al_1c['material'] = 'Al'
            al_1c['core_type'] = '1C+E'
            dfs.append(al_1c)
            
            al_3c = self._cable_data_al_3c.copy()
            al_3c['material'] = 'Al'
            al_3c['core_type'] = '3C+E'
            dfs.append(al_3c)
            
            # Combine and save
            df = pd.concat(dfs, ignore_index=True)
            df.to_csv(filepath, index=False)
            return True
            
        except Exception as e:
            print(f"Error exporting data: {e}")
            return False
            
    def import_data(self, filepath):
        """Import cable data from CSV file."""
        try:
            df = pd.read_csv(filepath)
            
            # Split data by material and core type
            for material in ['Cu', 'Al']:
                for core_type in ['1C+E', '3C+E']:
                    mask = (df['material'] == material) & (df['core_type'] == core_type)
                    subset = df[mask][['size', 'mv_per_am', 'max_current']]
                    
                    if not subset.empty:
                        # Update appropriate DataFrame
                        if material == 'Cu':
                            if core_type == '1C+E':
                                self._cable_data_cu_1c = subset.reset_index(drop=True)
                            else:
                                self._cable_data_cu_3c = subset.reset_index(drop=True)
                        else:
                            if core_type == '1C+E':
                                self._cable_data_al_1c = subset.reset_index(drop=True)
                            else:
                                self._cable_data_al_3c = subset.reset_index(drop=True)
            
            return True
            
        except Exception as e:
            print(f"Error importing data: {e}")
            return False

    def get_installation_factor(self, code: str) -> dict:
        """Get installation method data from database."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT code, description, base_factor, notes 
                FROM installation_methods 
                WHERE code = ?
            """, (code,))
            result = cursor.fetchone()
            if result:
                return {
                    'code': result[0],
                    'description': result[1],
                    'base_factor': float(result[2]),
                    'notes': result[3]
                }
            return None
        finally:
            conn.close()

    def get_temperature_factor(self, temperature: int, insulation_type: str) -> float:
        """Get temperature derating factor from database."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT factor 
                FROM temperature_factors 
                WHERE temperature <= ? AND insulation_type = ?
                ORDER BY temperature DESC 
                LIMIT 1
            """, (temperature, insulation_type))
            result = cursor.fetchone()
            return float(result[0]) if result else 1.0
        finally:
            conn.close()

    def get_material_properties(self, material: str) -> dict:
        """Get cable material properties from database."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT resistivity, temperature_coefficient, description 
                FROM cable_materials 
                WHERE material = ?
            """, (material,))
            result = cursor.fetchone()
            if result:
                return {
                    'resistivity': float(result[0]),
                    'temperature_coefficient': float(result[1]),
                    'description': result[2]
                }
            return None
        finally:
            conn.close()

    def get_standard_requirements(self, code: str) -> dict:
        """Get standard requirements from database."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT description, voltage_drop_limit, current_rating_table, category 
                FROM standards_reference 
                WHERE code = ?
            """, (code,))
            result = cursor.fetchone()
            if result:
                return {
                    'description': result[0],
                    'voltage_drop_limit': float(result[1]) if result[1] else None,
                    'current_rating_table': result[2],
                    'category': result[3]
                }
            return None
        finally:
            conn.close()

    def get_voltage_system(self, voltage: float = None) -> dict:
        """Get voltage system data from database."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            if voltage:
                cursor.execute("""
                    SELECT voltage, name, description, frequency, phase_count, category, notes
                    FROM voltage_systems WHERE voltage = ?
                """, (voltage,))
                result = cursor.fetchone()
                if result:
                    return {
                        'voltage': result[0],
                        'name': result[1],
                        'description': result[2],
                        'frequency': result[3],
                        'phase_count': result[4],
                        'category': result[5],
                        'notes': result[6]
                    }
            else:
                # Return all voltage systems
                cursor.execute("SELECT * FROM voltage_systems ORDER BY voltage")
                return cursor.fetchall()
                
            return None
        finally:
            conn.close()

    def get_circuit_breaker(self, rating: float, type: str = None) -> dict:
        """Get circuit breaker data from database."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            query = "SELECT * FROM circuit_breakers WHERE rating = ?"
            params = [rating]
            
            if type:
                query += " AND type = ?"
                params.append(type)
                
            cursor.execute(query, params)
            result = cursor.fetchone()
            
            if result:
                return {
                    'type': result[1],
                    'rating': result[2],
                    'breaking_capacity': result[3],
                    'curve_type': result[4],
                    'manufacturer': result[5],
                    'model': result[6],
                    'description': result[7]
                }
            return None
        finally:
            conn.close()

    def get_insulation_type(self, code: str) -> dict:
        """Get insulation type data from database."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT code, name, max_temp, description, material, standard
                FROM insulation_types WHERE code = ?
            """, (code,))
            result = cursor.fetchone()
            if result:
                return {
                    'code': result[0],
                    'name': result[1],
                    'max_temp': result[2],
                    'description': result[3],
                    'material': result[4],
                    'standard': result[5]
                }
            return None
        finally:
            conn.close()

    def get_soil_resistivity(self, soil_type: str = None) -> dict:
        """Get soil resistivity data from database."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            if soil_type:
                cursor.execute("""
                    SELECT soil_type, min_resistivity, max_resistivity, typical_value, 
                           moisture_content, notes
                    FROM soil_resistivity WHERE soil_type = ?
                """, (soil_type,))
                result = cursor.fetchone()
                if result:
                    return {
                        'soil_type': result[0],
                        'min_resistivity': result[1],
                        'max_resistivity': result[2],
                        'typical_value': result[3],
                        'moisture_content': result[4],
                        'notes': result[5]
                    }
            else:
                # Return all soil types
                cursor.execute("SELECT * FROM soil_resistivity")
                return cursor.fetchall()
                
            return None
        finally:
            conn.close()

    def get_protection_curve(self, device_type: str, rating: float) -> list:
        """Get protection curve points from database."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT current_multiplier, tripping_time, curve_type, temperature
                FROM protection_curves 
                WHERE device_type = ? AND rating = ?
                ORDER BY current_multiplier
            """, (device_type, rating))
            results = cursor.fetchall()
            if results:
                return [{
                    'current_multiplier': row[0],
                    'tripping_time': row[1],
                    'curve_type': row[2],
                    'temperature': row[3]
                } for row in results]
            return []
        finally:
            conn.close()

    def _calculate_voltage_drop(self):
        """Calculate voltage drop using mV/A/m method."""
        try:
            # Initial validation checks
            if self._current <= 0 or self._length <= 0:
                return 0.0

            # Current and length checks
            if self._current <= 0 or self._length <= 0:
                return 0.0

            # Cable data retrieval
            cable = self.get_cable_by_size(self._cable_size, self._conductor_material, self._core_type)
            if cable is None:
                return 0.0

            # Get temperature factor from database
            temp_factor = self.get_temperature_factor(
                self._temperature,
                'XLPE' if self._conductor_material == 'Al' else 'PVC'
            )
            
            # Get installation method factor
            install_method = self.get_installation_factor(
                self._installation_method.split(' - ')[0]
            )
            install_factor = install_method['base_factor'] if install_method else 1.0
            
            # Get material properties
            material_props = self.get_material_properties(self._conductor_material)
            resistivity_factor = material_props['resistivity'] / 1.72e-8 if material_props else 1.0
            
            # Voltage drop calculation
            mv_per_am = float(cable['mv_per_am'])
            v_drop = (
                self._current * 
                self._length * 
                mv_per_am * 
                temp_factor * 
                install_factor * 
                resistivity_factor /
                1000.0
            )

            # Table data population
            self._voltage_drop = v_drop
            self._voltage_drop_percent = (v_drop / self._voltage) * 100

            # Status determination
            self._status = "OK" if self._voltage_drop_percent <= self._voltage_drop_limit else "Excessive voltage drop"

            # Signal emissions
            self.voltageDropCalculated.emit(self._voltage_drop, self._voltage_drop_percent, self._status)
            
        except Exception as e:
            print(f"Error calculating voltage drop: {e}")
            return 0.0
