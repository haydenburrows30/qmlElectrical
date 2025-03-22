import pandas as pd

class DataManager:
    """Class for managing cable data and calculation parameters."""
    
    def __init__(self, db_manager=None):
        # Use provided database manager or create a new one
        self._db_manager = db_manager
        
        # Cache for frequently accessed data
        self._cache = {
            'cable_data': {},
            'diversity_factors': None,
            'fuse_sizes': None
        }
        
        # Check if database is populated, if not, initialize with in-memory data
        self._ensure_data_initialized()
    
    def _ensure_data_initialized(self):
        """Check if database is populated, if not, load from in-memory data."""
        # Check if any cables exist in the database
        cables = self._db_manager.get_cables()
        if not cables:
            # Initialize with in-memory data
            self._initialize_with_memory_data()
        
        # Initialize cache
        self._update_cache()
    
    def _initialize_with_memory_data(self):
        """Initialize database with in-memory data if needed."""
        try:
            # Create in-memory data
            cu_1c_data = {
                'size': [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400],
                'mv_per_am': [26, 15.6, 9.8, 6.5, 3.9, 2.5, 1.6, 1.2, 0.87, 0.62, 0.46, 0.37, 0.31, 0.25, 0.20, 0.17, 0.15],
                'max_current': [19.5, 27, 36, 45, 63, 85, 110, 135, 160, 200, 240, 280, 320, 365, 430, 495, 560]
            }
            
            cu_3c_data = {
                'size': [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400],
                'mv_per_am': [26.5, 15.9, 10, 6.7, 4.0, 2.5, 1.6, 1.2, 0.93, 0.61, 0.45, 0.37, 0.33, 0.27, 0.22, 0.19, 0.17],
                'max_current': [17.5, 24, 31, 39, 54, 63, 95, 165, 140, 240, 290, 355, 280, 470, 375, 430, 485]
            }
            
            al_1c_data = {
                'size': [16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400, 500, 630],
                'mv_per_am': [2.6, 1.7, 1.9, 1.4, 0.98, 0.75, 0.60, 0.50, 0.41, 0.32, 0.27, 0.24, 0.21, 0.18],
                'max_current': [115, 150, 105, 125, 160, 190, 220, 255, 290, 345, 395, 445, 495, 555]
            }
            
            al_3c_data = {
                'size': [16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400, 500, 630],
                'mv_per_am': [4.2, 2.7, 2.0, 1.5, 1.1, 0.72, 0.58, 0.54, 0.39, 0.31, 0.27, 0.27, 0.24, 0.21],
                'max_current': [57, 75, 92, 110, 140, 240, 275, 225, 350, 410, 460, 390, 435, 485]
            }
            
            # Insert Cu 1-core cables
            for i in range(len(cu_1c_data['size'])):
                self._db_manager.add_cable({
                    'size': cu_1c_data['size'][i],
                    'mv_per_am': cu_1c_data['mv_per_am'][i],
                    'max_current': cu_1c_data['max_current'][i],
                    'material': 'Cu',
                    'core_type': '1C+E',
                    'insulation_type': 'XLPE',
                    'standard': 'AS/NZS 3008'
                })
            
            # Insert Cu 3-core cables
            for i in range(len(cu_3c_data['size'])):
                self._db_manager.add_cable({
                    'size': cu_3c_data['size'][i],
                    'mv_per_am': cu_3c_data['mv_per_am'][i],
                    'max_current': cu_3c_data['max_current'][i],
                    'material': 'Cu',
                    'core_type': '3C+E',
                    'insulation_type': 'XLPE',
                    'standard': 'AS/NZS 3008'
                })
            
            # Insert Al 1-core cables
            for i in range(len(al_1c_data['size'])):
                self._db_manager.add_cable({
                    'size': al_1c_data['size'][i],
                    'mv_per_am': al_1c_data['mv_per_am'][i],
                    'max_current': al_1c_data['max_current'][i],
                    'material': 'Al',
                    'core_type': '1C+E',
                    'insulation_type': 'XLPE',
                    'standard': 'AS/NZS 3008'
                })
            
            # Insert Al 3-core cables
            for i in range(len(al_3c_data['size'])):
                self._db_manager.add_cable({
                    'size': al_3c_data['size'][i],
                    'mv_per_am': al_3c_data['mv_per_am'][i],
                    'max_current': al_3c_data['max_current'][i],
                    'material': 'Al',
                    'core_type': '3C+E',
                    'insulation_type': 'XLPE',
                    'standard': 'AS/NZS 3008'
                })
            
            # Add diversity factors
            diversity_data = [
                (1, 1.0), (2, 0.95), (3, 0.90), (4, 0.85), (5, 0.80),
                (10, 0.65), (15, 0.55), (20, 0.50), (30, 0.45),
                (40, 0.42), (50, 0.40), (100, 0.35), (200, 0.30)
            ]
            
            for houses, factor in diversity_data:
                self._db_manager.add_diversity_factor(houses, factor)
            
            # Add fuse sizes
            fuse_sizes_data = [
                ('Cu', 16, 80), ('Cu', 25, 100), ('Cu', 35, 125), ('Cu', 50, 160), ('Cu', 95, 250),
                ('Al', 25, 63), ('Al', 35, 80), ('Al', 50, 100), ('Al', 95, 160),
                ('Al', 185, 250), ('Al', 300, 315), ('Al', 630, 500)
            ]
            
            for material, size, fuse_size in fuse_sizes_data:
                cursor = self._db_manager._connection.cursor()
                cursor.execute(
                    "INSERT INTO fuse_sizes (material, size_mm2, fuse_size_a) VALUES (?, ?, ?)",
                    (material, size, fuse_size)
                )
            
            self._db_manager._connection.commit()
            
            print("Initialized database with default cable data")
            
        except Exception as e:
            print(f"Error initializing database with memory data: {e}")
    
    def _update_cache(self):
        """Update cache with fresh data from database."""
        # Clear the cache
        self._cache['cable_data'] = {}
    
    def get_cable_data(self, material="Al", core_type="3C+E"):
        """Get cable data for the specified material and core type."""
        cache_key = f"{material}_{core_type}"
        
        # Check cache first
        if cache_key in self._cache['cable_data']:
            return self._cache['cable_data'][cache_key]
        
        # Fetch from database
        cables = self._db_manager.get_cables(material, core_type)
        
        # Convert to DataFrame for compatibility with existing code
        if cables:
            df = pd.DataFrame(cables)
            self._cache['cable_data'][cache_key] = df
            return df
        
        # Return empty DataFrame if no cables found
        return pd.DataFrame(columns=['size', 'mv_per_am', 'max_current'])
                
    def get_available_cables(self, material="Al", core_type="3C+E"):
        """Get list of available cable sizes for the specified material and core type."""
        cable_data = self.get_cable_data(material, core_type)
        if not cable_data.empty:
            return cable_data['size'].tolist()
        return []
        
    def get_cable_by_size(self, size, material="Al", core_type="3C+E"):
        """Get cable data for a specific size."""
        # Try to get from database first
        cable = self._db_manager.get_cable_by_size(float(size), material, core_type)
        
        if cable:
            # Convert to Series for compatibility with existing code
            return pd.Series(cable)
        
        # Fall back to DataFrame lookup if not found directly
        cable_data = self.get_cable_data(material, core_type)
        if not cable_data.empty:
            result = cable_data[cable_data['size'] == float(size)]
            if not result.empty:
                return result.iloc[0]
                
        return None
        
    def get_diversity_factor(self, num_houses):
        """Get diversity factor based on number of houses."""
        return self._db_manager.get_diversity_factor(num_houses)
            
    def get_fuse_size(self, cable_size, material="Al"):
        """Get network fuse size for given cable size and material."""
        try:
            # Query the database
            cursor = self._db_manager._connection.cursor()
            cursor.execute(
                "SELECT fuse_size_a FROM fuse_sizes WHERE material = ? AND size_mm2 = ?",
                (material, float(cable_size))
            )
            result = cursor.fetchone()
            
            if result:
                return f"{result['fuse_size_a']} A"
            else:
                return "Not specified"
                
        except Exception as e:
            print(f"Error looking up fuse size: {e}")
            return "Error"
            
    # def calculate_current(self, kva, voltage=415.0, num_houses=1, diversity_factor=None):
    #     """