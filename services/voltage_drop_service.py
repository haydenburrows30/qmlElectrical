import math
import logging
import os
import pandas as pd
from services.database_manager import DatabaseManager

logger = logging.getLogger("qmltest.voltage_drop")

class VoltageDropService:
    """
    Service for voltage drop calculations using the central database manager.
    
    This service replaces the separate DataManager class in the voltage drop module.
    """
    
    def __init__(self, db_path=None):
        """Initialize with optional database path."""
        # Get the singleton instance of DatabaseManager
        if db_path is None:
            project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
            db_path = os.path.join(project_root, 'data', 'application_data.db')
        
        self.db_manager = DatabaseManager.get_instance(db_path)
        
        # Cable data for different configurations
        self._cable_data_cu_1c = None
        self._cable_data_cu_3c = None
        self._cable_data_al_1c = None
        self._cable_data_al_3c = None
        
        # Load cable data in memory
        self._load_all_cable_data()
    
    def _load_all_cable_data(self):
        """Load cable data from in-memory data structures for performance."""
        try:
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
            logger.error(f"Error loading cable data: {e}")
    
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
            # Try exact match first
            result = self.db_manager.fetch_one(
                "SELECT factor FROM diversity_factors WHERE houses = ?", 
                (num_houses,)
            )
            
            if result:
                return float(result['factor'])
            
            # If no exact match, get next lower and higher values for interpolation
            closest = self.db_manager.fetch_all(
                """
                SELECT houses, factor, ABS(houses - ?) as diff 
                FROM diversity_factors 
                ORDER BY diff ASC 
                LIMIT 2
                """, 
                (num_houses,)
            )
            
            if closest:
                if len(closest) == 1:
                    return float(closest[0]['factor'])
                else:
                    # Interpolate between values
                    h1, f1 = closest[0]['houses'], closest[0]['factor']
                    h2, f2 = closest[1]['houses'], closest[1]['factor']
                    # Linear interpolation
                    factor = f1 + (f2 - f1) * (num_houses - h1) / (h2 - h1)
                    return factor
            
            # Default if no matching data
            return 1.0
            
        except Exception as e:
            logger.error(f"Error getting diversity factor: {e}")
            return 1.0
    
    def get_fuse_size(self, cable_size, material="Al"):
        """Get network fuse size for given cable size and material."""
        try:
            # Handle pandas Series objects
            if isinstance(cable_size, pd.Series):
                cable_size = float(cable_size.iloc[0])
            else:
                cable_size = float(cable_size)
                
            # First check if we have the exact size in the database
            result = self.db_manager.fetch_one(
                """
                SELECT fuse_size_a AS fuse_size 
                FROM fuse_sizes 
                WHERE material = ? AND size_mm2 = ?
                """, 
                (material, cable_size)
            )
            
            if result:
                return f"{result['fuse_size']} A"
                
            # If exact size not found, find the next larger size
            result = self.db_manager.fetch_one(
                """
                SELECT fuse_size_a AS fuse_size 
                FROM fuse_sizes 
                WHERE material = ? AND size_mm2 >= ?
                ORDER BY size_mm2 ASC
                LIMIT 1
                """, 
                (material, cable_size)
            )
            
            if result:
                return f"{result['fuse_size']} A"
                
            # If no larger size found, use the largest available size
            result = self.db_manager.fetch_one(
                """
                SELECT fuse_size_a AS fuse_size 
                FROM fuse_sizes 
                WHERE material = ?
                ORDER BY size_mm2 DESC
                LIMIT 1
                """, 
                (material,)
            )
            
            if result:
                return f"{result['fuse_size']} A"
                
            return "Not specified"
                
        except Exception as e:
            logger.error(f"Error looking up fuse size: {e}")
            return "Error"
    
    def calculate_current(self, kva, voltage=415.0, num_houses=1, diversity_factor=None):
        """Calculate current from kVA with diversity factor."""
        try:
            # Apply diversity factor if provided, otherwise use from database
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
            logger.error(f"Error calculating current: {e}")
            return 0.0
    
    def get_temperature_factor(self, temperature, insulation_type):
        """Get temperature derating factor."""
        try:
            result = self.db_manager.fetch_one(
                """
                SELECT factor 
                FROM temperature_factors 
                WHERE temperature <= ? AND insulation_type = ?
                ORDER BY temperature DESC 
                LIMIT 1
                """, 
                (temperature, insulation_type)
            )
            
            return float(result['factor']) if result else 1.0
        except Exception as e:
            logger.error(f"Error getting temperature factor: {e}")
            return 1.0
    
    def get_installation_factor(self, code):
        """Get installation method factor."""
        try:
            result = self.db_manager.fetch_one(
                """
                SELECT code, description, base_factor, notes 
                FROM installation_methods 
                WHERE code = ?
                """, 
                (code,)
            )
            
            if result:
                return {
                    'code': result['code'],
                    'description': result['description'],
                    'base_factor': float(result['base_factor']),
                    'notes': result['notes']
                }
            return {'base_factor': 1.0}  # Default factor if not found
        except Exception as e:
            logger.error(f"Error getting installation factor: {e}")
            return {'base_factor': 1.0}
    
    def get_material_properties(self, material):
        """Get cable material properties."""
        try:
            result = self.db_manager.fetch_one(
                """
                SELECT resistivity, temperature_coefficient, description 
                FROM cable_materials 
                WHERE material = ?
                """, 
                (material,)
            )
            
            if result:
                return {
                    'resistivity': float(result['resistivity']),
                    'temperature_coefficient': float(result['temperature_coefficient']),
                    'description': result['description']
                }
            return None
        except Exception as e:
            logger.error(f"Error getting material properties: {e}")
            return None
    
    def get_standard_requirements(self, code):
        """Get standard requirements."""
        try:
            result = self.db_manager.fetch_one(
                """
                SELECT description, voltage_drop_limit, current_rating_table, category 
                FROM standards_reference 
                WHERE code = ?
                """, 
                (code,)
            )
            
            if result:
                return {
                    'description': result['description'],
                    'voltage_drop_limit': float(result['voltage_drop_limit']) if result['voltage_drop_limit'] else None,
                    'current_rating_table': result['current_rating_table'],
                    'category': result['category']
                }
            return None
        except Exception as e:
            logger.error(f"Error getting standard requirements: {e}")
            return None
    
    def calculate_voltage_drop(self, current, length, cable_data, 
                              temperature=25, installation_code="C", 
                              grouping_factor=1.0, admd_enabled=False, 
                              admd_factor=1.5, voltage=415.0):
        """Calculate voltage drop using mV/A/m method."""
        try:
            if current <= 0 or length <= 0 or cable_data is None:
                return 0.0
                
            # Convert any Series values to scalar values
            mv_per_am = cable_data['mv_per_am']
            if isinstance(mv_per_am, pd.Series):
                mv_per_am = mv_per_am.iloc[0]
            else:
                mv_per_am = float(mv_per_am)
                
            # Extract material for insulation type determination
            material = cable_data.get('material')
            if isinstance(material, pd.Series):
                material = material.iloc[0]
                
            # Apply ADMD factor if enabled and using 415V
            admd_multiplier = admd_factor if (admd_enabled and voltage > 230) else 1.0
            
            # Get temperature factor
            insulation = 'XLPE' if material == 'Al' else 'PVC'
            temp_factor = self.get_temperature_factor(temperature, insulation)
            
            # Get installation factor - extract code from installation_method string if needed
            if ' - ' in installation_code:
                install_code = installation_code.split(' - ')[0]
            else:
                install_code = installation_code
                
            install_data = self.get_installation_factor(install_code)
            install_factor = install_data.get('base_factor', 1.0)
            
            # Calculate voltage drop
            v_drop = (
                current * 
                length * 
                mv_per_am * 
                temp_factor * 
                install_factor * 
                grouping_factor * 
                admd_multiplier /
                1000.0
            )
            
            return v_drop
            
        except Exception as e:
            logger.error(f"Error calculating voltage drop: {e}")
            return 0.0
    
    def calculate_rating_adjustments(self, cable, temperature=25.0, grouping=1.0, 
                                   installation_method="C"):
        """Calculate adjusted cable rating based on derating factors."""
        try:
            if cable is None:
                return 0.0
                
            # Handle Series objects for max_current
            max_current = cable['max_current']
            if isinstance(max_current, pd.Series):
                max_current = max_current.iloc[0]
            else:
                max_current = float(max_current)
                
            # Handle material for insulation type
            material = cable.get('material')
            if isinstance(material, pd.Series):
                material = material.iloc[0]
                
            # Get temperature factor
            insulation = 'XLPE' if material == 'Al' else 'PVC'
            temp_factor = self.get_temperature_factor(temperature, insulation)
            
            # Get installation factor - extract code from installation_method string if needed
            if ' - ' in installation_method:
                install_code = installation_method.split(' - ')[0]
            else:
                install_code = installation_method
                
            install_data = self.get_installation_factor(install_code)
            install_factor = install_data.get('base_factor', 1.0)
            
            adjusted_rating = max_current * temp_factor * install_factor * grouping
            return adjusted_rating
            
        except Exception as e:
            logger.error(f"Error calculating rating adjustments: {e}")
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
            logger.error(f"Error finding recommended cable: {e}")
            return None
    
    def validate_cable_selection(self, cable, current, length, voltage=415.0,
                               max_voltage_drop=5.0, temperature=25.0, grouping=1.0,
                               installation_method="C"):
        """Validate cable selection against current and voltage drop requirements."""
        try:
            if cable is None:
                return {
                    'valid': False,
                    'current_ok': False,
                    'voltage_ok': False,
                    'message': "No cable selected"
                }
                
            # Handle Series objects for max_current
            max_current = cable['max_current']
            if isinstance(max_current, pd.Series):
                max_current = max_current.iloc[0]
            else:
                max_current = float(max_current)
                
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
            logger.error(f"Error validating cable selection: {e}")
            return {
                'valid': False,
                'current_ok': False,
                'voltage_ok': False,
                'message': f"Error: {str(e)}"
            }
    
    def get_voltage_system(self, voltage=None):
        """Get voltage system data from database."""
        try:
            if voltage:
                result = self.db_manager.fetch_one(
                    """
                    SELECT voltage, name, description, frequency, phase_count, category, notes
                    FROM voltage_systems WHERE voltage = ?
                    """, 
                    (voltage,)
                )
                if result:
                    return {
                        'voltage': result['voltage'],
                        'name': result['name'],
                        'description': result['description'],
                        'frequency': result['frequency'],
                        'phase_count': result['phase_count'],
                        'category': result['category'],
                        'notes': result['notes']
                    }
            else:
                # Return all voltage systems
                return self.db_manager.fetch_all("SELECT * FROM voltage_systems ORDER BY voltage")
                
            return None
        except Exception as e:
            logger.error(f"Error getting voltage system: {e}")
            return None
    
    def get_circuit_breaker(self, rating, type=None):
        """Get circuit breaker data from database."""
        try:
            query = "SELECT * FROM circuit_breakers WHERE rating = ?"
            params = [rating]
            
            if type:
                query += " AND type = ?"
                params.append(type)
                
            result = self.db_manager.fetch_one(query, params)
            
            if result:
                return {
                    'type': result['type'],
                    'rating': result['rating'],
                    'breaking_capacity': result['breaking_capacity'],
                    'curve_type': result['curve_type'],
                    'manufacturer': result['manufacturer'],
                    'model': result['model'],
                    'description': result['description']
                }
            return None
        except Exception as e:
            logger.error(f"Error getting circuit breaker: {e}")
            return None
    
    def get_insulation_type(self, code):
        """Get insulation type data from database."""
        try:
            result = self.db_manager.fetch_one(
                """
                SELECT code, name, max_temp, description, material, standard
                FROM insulation_types WHERE code = ?
                """, 
                (code,)
            )
            if result:
                return {
                    'code': result['code'],
                    'name': result['name'],
                    'max_temp': result['max_temp'],
                    'description': result['description'],
                    'material': result['material'],
                    'standard': result['standard']
                }
            return None
        except Exception as e:
            logger.error(f"Error getting insulation type: {e}")
            return None
    
    def get_soil_resistivity(self, soil_type=None):
        """Get soil resistivity data from database."""
        try:
            if soil_type:
                result = self.db_manager.fetch_one(
                    """
                    SELECT soil_type, min_resistivity, max_resistivity, typical_value, 
                           moisture_content, notes
                    FROM soil_resistivity WHERE soil_type = ?
                    """, 
                    (soil_type,)
                )
                if result:
                    return {
                        'soil_type': result['soil_type'],
                        'min_resistivity': result['min_resistivity'],
                        'max_resistivity': result['max_resistivity'],
                        'typical_value': result['typical_value'],
                        'moisture_content': result['moisture_content'],
                        'notes': result['notes']
                    }
            else:
                # Return all soil types
                return self.db_manager.fetch_all("SELECT * FROM soil_resistivity")
                
            return None
        except Exception as e:
            logger.error(f"Error getting soil resistivity: {e}")
            return None
    
    def get_protection_curve(self, device_type, rating):
        """Get protection curve points from database."""
        try:
            results = self.db_manager.fetch_all(
                """
                SELECT current_multiplier, tripping_time, curve_type, temperature
                FROM protection_curves 
                WHERE device_type = ? AND rating = ?
                ORDER BY current_multiplier
                """, 
                (device_type, rating)
            )
            if results:
                return [{
                    'current_multiplier': row['current_multiplier'],
                    'tripping_time': row['tripping_time'],
                    'curve_type': row['curve_type'],
                    'temperature': row['temperature']
                } for row in results]
            return []
        except Exception as e:
            logger.error(f"Error getting protection curve: {e}")
            return []
