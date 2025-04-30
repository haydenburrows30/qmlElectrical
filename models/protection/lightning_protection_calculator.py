from PySide6.QtCore import QObject, Signal, Property, Slot
import math
from services.logger_config import configure_logger

logger = configure_logger("qmltest", component="lightning_protection")

class LightningProtectionCalculator(QObject):
    """
    Lightning Protection System Designer.
    
    Calculates lightning protection parameters including:
    - Strike probability based on location and structure
    - Protection levels according to IEC 62305
    - Rolling sphere radius for different protection levels
    - Separation distance requirements
    - Air termination positioning
    """
    
    # Signal definitions
    configChanged = Signal()
    structureParametersChanged = Signal()
    locationParametersChanged = Signal()
    protectionLevelChanged = Signal()
    
    def __init__(self):
        super().__init__()
        
        # Initialize default values
        self._structure_height = 10.0        # meters
        self._structure_length = 20.0        # meters
        self._structure_width = 15.0         # meters
        self._structure_type = 0             # 0: Common, 1: Metal, 2: Flammable, 3: Explosive/Chemical, 4: Hospital/School
        
        self._location_thunderdays = 25      # days per year with thunder
        self._location_ground_resistivity = 100  # ohm meter
        self._location_terrain_coefficient = 1.0  # 0.1-1 for urban, 1 for flat land, 2 for hilly terrain
        
        self._protection_level = "II"        # I, II, III, or IV
        self._use_mesh_method = True
        self._use_rolling_sphere = True
        
        # Calculated values cache
        self._cache = {}
    
    # Helper methods
    def _set_and_notify(self, attr_name, value, signal):
        """Helper to set an attribute and emit a signal if changed."""
        if getattr(self, attr_name) != value:
            setattr(self, attr_name, value)
            signal.emit()
            self.configChanged.emit()
            
            # Clear calculation cache when parameters change
            self._cache = {}
    
    # Structure parameters
    @Property(float, notify=structureParametersChanged)
    def structureHeight(self):
        return self._structure_height
    
    @structureHeight.setter
    def structureHeight(self, value):
        self._set_and_notify("_structure_height", value, self.structureParametersChanged)
    
    @Property(float, notify=structureParametersChanged)
    def structureLength(self):
        return self._structure_length
    
    @structureLength.setter
    def structureLength(self, value):
        self._set_and_notify("_structure_length", value, self.structureParametersChanged)
    
    @Property(float, notify=structureParametersChanged)
    def structureWidth(self):
        return self._structure_width
    
    @structureWidth.setter
    def structureWidth(self, value):
        self._set_and_notify("_structure_width", value, self.structureParametersChanged)
    
    @Property(int, notify=structureParametersChanged)
    def structureType(self):
        return self._structure_type
    
    @structureType.setter
    def structureType(self, value):
        self._set_and_notify("_structure_type", value, self.structureParametersChanged)
    
    # Location parameters
    @Property(int, notify=locationParametersChanged)
    def locationThunderdays(self):
        return self._location_thunderdays
    
    @locationThunderdays.setter
    def locationThunderdays(self, value):
        self._set_and_notify("_location_thunderdays", value, self.locationParametersChanged)
    
    @Property(float, notify=locationParametersChanged)
    def locationGroundResistivity(self):
        return self._location_ground_resistivity
    
    @locationGroundResistivity.setter
    def locationGroundResistivity(self, value):
        self._set_and_notify("_location_ground_resistivity", value, self.locationParametersChanged)
    
    @Property(float, notify=locationParametersChanged)
    def locationTerrainCoefficient(self):
        return self._location_terrain_coefficient
    
    @locationTerrainCoefficient.setter
    def locationTerrainCoefficient(self, value):
        self._set_and_notify("_location_terrain_coefficient", value, self.locationParametersChanged)
    
    # Protection level
    @Property(str, notify=protectionLevelChanged)
    def protectionLevel(self):
        return self._protection_level
    
    @protectionLevel.setter
    def protectionLevel(self, value):
        if value in ["I", "II", "III", "IV"]:
            self._set_and_notify("_protection_level", value, self.protectionLevelChanged)
    
    @Property(bool, notify=configChanged)
    def useMeshMethod(self):
        return self._use_mesh_method
    
    @useMeshMethod.setter
    def useMeshMethod(self, value):
        self._set_and_notify("_use_mesh_method", value, self.configChanged)
    
    @Property(bool, notify=configChanged)
    def useRollingSphere(self):
        return self._use_rolling_sphere
    
    @useRollingSphere.setter
    def useRollingSphere(self, value):
        self._set_and_notify("_use_rolling_sphere", value, self.configChanged)
    
    # Calculation methods
    def _calculate_all(self):
        """Calculate all parameters and store in cache."""
        if self._cache:  # Return if already calculated
            return
        
        # Collection frequency (flashes per year) based on thunderdays
        Ng = 0.04 * self._location_thunderdays ** 1.25  # Ground flash density (flashes/km²/year)
        
        # Calculate equivalent collection area (m²)
        height = self._structure_height
        length = self._structure_length
        width = self._structure_width
        
        # Collection area according to IEC 62305
        Ae = length * width + 2 * (length + width) * height + math.pi * height ** 2
        Ae = Ae / 1000000  # Convert to km²
        
        # Environmental and structure coefficients
        Cd = self._get_environment_coefficient()
        Ct = self._location_terrain_coefficient
        
        # Structure type coefficient
        structure_coefficients = [1.0, 0.5, 2.0, 4.0, 3.0]  # Common, Metal, Flammable, Explosive, Hospital
        Cs = structure_coefficients[self._structure_type]
        
        # Annual strike probability
        Nd = Ng * Ae * Cd * Ct  # Expected annual direct strikes
        
        # Protection level requirements and parameters
        E = 1 - (1 / Cs)  # Required efficiency
        
        protection_levels = {
            "I": {"efficiency": 0.98, "rolling_sphere": 20, "mesh_size": 5, "downconductor_spacing": 10, "probability": 0.02},
            "II": {"efficiency": 0.95, "rolling_sphere": 30, "mesh_size": 10, "downconductor_spacing": 15, "probability": 0.05},
            "III": {"efficiency": 0.90, "rolling_sphere": 45, "mesh_size": 15, "downconductor_spacing": 20, "probability": 0.10},
            "IV": {"efficiency": 0.80, "rolling_sphere": 60, "mesh_size": 20, "downconductor_spacing": 25, "probability": 0.20}
        }
        
        # Determine required protection level based on efficiency
        required_level = "IV"
        for level in ["I", "II", "III", "IV"]:
            if E <= protection_levels[level]["efficiency"]:
                required_level = level
                break
        
        # Current protection parameters
        current_params = protection_levels[self._protection_level]
        
        # Calculate separation distance
        ki = 0.04 if self._protection_level == "I" else 0.06  # Coefficient based on protection level
        km = 1.0  # Material coefficient (1.0 for air)
        kc = 1.0  # Current distribution coefficient (simplified)
        
        # Simplified separation distance calculation
        separation_distance = ki * kc * current_params["downconductor_spacing"] / km
        
        # Number of down conductors
        perimeter = 2 * (length + width)
        down_conductors = math.ceil(perimeter / current_params["downconductor_spacing"])
        
        # Number of ground rods (simplified)
        ground_rods = max(4, down_conductors)
        
        # Store all calculated values in cache
        self._cache = {
            "ground_flash_density": Ng,
            "collection_area": Ae * 1000000,  # Back to m²
            "annual_strikes": Nd,
            "required_efficiency": E,
            "recommended_level": required_level,
            "rolling_sphere_radius": current_params["rolling_sphere"],
            "mesh_size": current_params["mesh_size"],
            "downconductor_spacing": current_params["downconductor_spacing"],
            "separation_distance": separation_distance,
            "down_conductors": down_conductors,
            "ground_rods": ground_rods,
            "protection_probability": current_params["probability"] * 100,  # Convert to percentage
            "ground_resistance_target": self._calculate_ground_resistance_target()
        }
    
    def _get_environment_coefficient(self):
        """Get environmental coefficient based on structure surroundings."""
        # Simplified approach - could be expanded with more options
        structure_type = self._structure_type
        
        if structure_type == 1:  # Metal structure
            return 0.5  # Lower coefficient for metal structures
        elif structure_type in [2, 3]:  # Flammable or explosive
            return 2.0  # Higher coefficient for critical structures
        else:
            return 1.0  # Default coefficient
    
    def _calculate_ground_resistance_target(self):
        """Calculate target ground resistance based on soil resistivity."""
        # Simplified calculation based on IEC recommendations
        resistivity = self._location_ground_resistivity
        
        if self._protection_level == "I":
            return min(10, resistivity / 10)
        elif self._protection_level == "II":
            return min(10, resistivity / 8)
        else:  # Level III or IV
            return min(10, resistivity / 5)
    
    # Properties for calculated values
    @Property(float, notify=configChanged)
    def groundFlashDensity(self):
        self._calculate_all()
        return self._cache.get("ground_flash_density", 0)
    
    @Property(float, notify=configChanged)
    def collectionArea(self):
        self._calculate_all()
        return self._cache.get("collection_area", 0)
    
    @Property(float, notify=configChanged)
    def annualStrikes(self):
        self._calculate_all()
        return self._cache.get("annual_strikes", 0)
    
    @Property(float, notify=configChanged)
    def requiredEfficiency(self):
        self._calculate_all()
        return self._cache.get("required_efficiency", 0)
    
    @Property(str, notify=configChanged)
    def recommendedLevel(self):
        self._calculate_all()
        return self._cache.get("recommended_level", "IV")
    
    @Property(float, notify=configChanged)
    def rollingSphereRadius(self):
        self._calculate_all()
        return self._cache.get("rolling_sphere_radius", 60)
    
    @Property(float, notify=configChanged)
    def meshSize(self):
        self._calculate_all()
        return self._cache.get("mesh_size", 20)
    
    @Property(float, notify=configChanged)
    def downConductorSpacing(self):
        self._calculate_all()
        return self._cache.get("downconductor_spacing", 25)
    
    @Property(float, notify=configChanged)
    def separationDistance(self):
        self._calculate_all()
        return self._cache.get("separation_distance", 1.5)
    
    @Property(int, notify=configChanged)
    def downConductorCount(self):
        self._calculate_all()
        return self._cache.get("down_conductors", 4)
    
    @Property(int, notify=configChanged)
    def groundRodCount(self):
        self._calculate_all()
        return self._cache.get("ground_rods", 4)
    
    @Property(float, notify=configChanged)
    def protectionProbability(self):
        self._calculate_all()
        return self._cache.get("protection_probability", 80)
    
    @Property(float, notify=configChanged)
    def groundResistanceTarget(self):
        self._calculate_all()
        return self._cache.get("ground_resistance_target", 10)
    
    # Slots for exporting results
    @Slot(str)
    def exportReport(self, file_path):
        """Export a detailed report of the lightning protection design."""
        self._calculate_all()
        
        # Generate report - basic implementation, can be expanded with PDF generation
        try:
            with open(file_path, 'w') as f:
                f.write("LIGHTNING PROTECTION SYSTEM DESIGN REPORT\n")
                f.write("=========================================\n\n")
                
                f.write("STRUCTURE PARAMETERS\n")
                f.write(f"Height: {self._structure_height} m\n")
                f.write(f"Length: {self._structure_length} m\n")
                f.write(f"Width: {self._structure_width} m\n")
                
                structure_types = ["Common", "Metal", "Flammable", "Explosive/Chemical", "Hospital/School"]
                f.write(f"Type: {structure_types[self._structure_type]}\n\n")
                
                f.write("LOCATION PARAMETERS\n")
                f.write(f"Thunderdays per year: {self._location_thunderdays}\n")
                f.write(f"Ground resistivity: {self._location_ground_resistivity} Ω·m\n")
                f.write(f"Terrain coefficient: {self._location_terrain_coefficient}\n\n")
                
                f.write("STRIKE PROBABILITY ANALYSIS\n")
                f.write(f"Ground flash density: {self._cache['ground_flash_density']:.4f} flashes/km²/year\n")
                f.write(f"Collection area: {self._cache['collection_area']:.1f} m²\n")
                f.write(f"Annual strikes: {self._cache['annual_strikes']:.4f} strikes/year\n")
                f.write(f"Required efficiency: {self._cache['required_efficiency']:.4f}\n")
                f.write(f"Recommended protection level: {self._cache['recommended_level']}\n\n")
                
                f.write("PROTECTION SYSTEM DESIGN\n")
                f.write(f"Selected protection level: {self._protection_level}\n")
                f.write(f"Rolling sphere radius: {self._cache['rolling_sphere_radius']} m\n")
                f.write(f"Mesh size: {self._cache['mesh_size']} m x {self._cache['mesh_size']} m\n")
                f.write(f"Down conductor spacing: {self._cache['downconductor_spacing']} m\n")
                f.write(f"Minimum required down conductors: {self._cache['down_conductors']}\n")
                f.write(f"Minimum ground rods: {self._cache['ground_rods']}\n")
                f.write(f"Separation distance: {self._cache['separation_distance']:.2f} m\n")
                f.write(f"Target ground resistance: {self._cache['ground_resistance_target']:.1f} Ω\n\n")
                
                f.write(f"Protection probability: {self._cache['protection_probability']:.1f}%\n\n")
                
                f.write("NOTE: This report provides basic guidance for lightning protection design.\n")
                f.write("A detailed design by a qualified professional is recommended for implementation.\n")
            
            logger.info(f"Lightning protection report saved to {file_path}")
            return True
        except Exception as e:
            logger.error(f"Error exporting lightning protection report: {e}")
            return False
