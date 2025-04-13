from PySide6.QtCore import QObject, Property, Signal, Slot

class CableAmpacityCalculator(QObject):
    """Calculator for cable current carrying capacity with derating factors"""

    cableSizeChanged = Signal()
    insulationTypeChanged = Signal()
    installMethodChanged = Signal()
    ambientTempChanged = Signal()
    groupingNumberChanged = Signal()
    conductorMaterialChanged = Signal()
    calculationsComplete = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._cable_size = 10.0  # mm²
        self._insulation_type = "PVC"  # PVC or XLPE
        self._install_method = "Conduit"  # Conduit, Tray, Direct Buried, etc.
        self._ambient_temp = 30.0  # °C
        self._grouping_number = 1  # Number of cables in group
        self._conductor_material = "Copper"  # Copper or Aluminum
        
        # Base ampacity values for various cable sizes (mm²) with PVC insulation in conduit
        # Format: {size: [copper_amps, aluminum_amps]}
        self._base_ampacity_pvc_conduit = {
            1.5: [17.5, 13.5],
            2.5: [24, 18.5],
            4: [32, 25],
            6: [41, 32],
            10: [57, 44],
            16: [76, 59],
            25: [101, 78],
            35: [125, 97],
            50: [151, 118],
            70: [192, 149],
            95: [232, 179],
            120: [269, 206],
            150: [309, 236],
            185: [353, 268],
            240: [415, 315]
        }
        
        # Base ampacity values for XLPE insulation in conduit
        self._base_ampacity_xlpe_conduit = {
            1.5: [19.5, 15],
            2.5: [27, 21],
            4: [36, 28],
            6: [46, 36],
            10: [63, 49],
            16: [85, 66],
            25: [112, 87],
            35: [138, 107],
            50: [168, 130],
            70: [213, 165],
            95: [258, 199],
            120: [299, 230],
            150: [344, 263],
            185: [392, 300],
            240: [461, 351]
        }
        
        # Ambient temperature correction factors
        self._ambient_temp_factors_pvc = {
            25: 1.03,
            30: 1.0,
            35: 0.94,
            40: 0.87,
            45: 0.79,
            50: 0.71,
            55: 0.61
        }
        
        self._ambient_temp_factors_xlpe = {
            25: 1.02,
            30: 1.0,
            35: 0.96,
            40: 0.91,
            45: 0.87,
            50: 0.82,
            55: 0.76
        }
        
        # Grouping correction factors
        self._grouping_factors = {
            1: 1.0,
            2: 0.8,
            3: 0.7,
            4: 0.65,
            5: 0.6,
            6: 0.57,
            7: 0.54,
            8: 0.52,
            9: 0.5,
            12: 0.45,
            16: 0.41,
            20: 0.38
        }
        
        # Installation method correction factors (simplified)
        self._install_method_factors = {
            "Conduit": 1.0,
            "Tray": 1.0,
            "Direct Buried": 0.95,
            "Free Air": 1.15,
            "Wall Surface": 0.95
        }
        
        # Economic current density - A/mm² (for economic sizing)
        self._economic_density = {
            "Copper": 4.5,
            "Aluminum": 3.0
        }
        
        # Perform initial calculation
        self._calculate()
        
    def _calculate(self):
        """Calculate cable ampacity with all derating factors applied"""
        # Get the base ampacity for the selected cable size and material
        material_index = 0 if self._conductor_material == "Copper" else 1
        
        # Find the closest cable size in our tables
        sizes = list(self._base_ampacity_pvc_conduit.keys())
        closest_size = min(sizes, key=lambda x: abs(x - self._cable_size))
        
        # Get base ampacity based on insulation type
        if self._insulation_type == "PVC":
            self._base_ampacity = self._base_ampacity_pvc_conduit.get(closest_size, [0, 0])[material_index]
            
            # Get ambient temperature correction factor - use exact match or interpolate
            if self._ambient_temp in self._ambient_temp_factors_pvc:
                temp_factor = self._ambient_temp_factors_pvc[self._ambient_temp]
            else:
                # Find closest temperatures for interpolation
                temps = sorted(list(self._ambient_temp_factors_pvc.keys()))
                if self._ambient_temp < temps[0]:
                    temp_factor = self._ambient_temp_factors_pvc[temps[0]]
                elif self._ambient_temp > temps[-1]:
                    temp_factor = self._ambient_temp_factors_pvc[temps[-1]]
                else:
                    # Linear interpolation
                    for i in range(len(temps) - 1):
                        if temps[i] <= self._ambient_temp <= temps[i + 1]:
                            t1, t2 = temps[i], temps[i + 1]
                            f1 = self._ambient_temp_factors_pvc[t1]
                            f2 = self._ambient_temp_factors_pvc[t2]
                            temp_factor = f1 + (f2 - f1) * (self._ambient_temp - t1) / (t2 - t1)
                            break
        else:  # XLPE
            self._base_ampacity = self._base_ampacity_xlpe_conduit.get(closest_size, [0, 0])[material_index]
            
            # Get ambient temperature correction factor - use exact match or interpolate
            if self._ambient_temp in self._ambient_temp_factors_xlpe:
                temp_factor = self._ambient_temp_factors_xlpe[self._ambient_temp]
            else:
                # Find closest temperatures for interpolation
                temps = sorted(list(self._ambient_temp_factors_xlpe.keys()))
                if self._ambient_temp < temps[0]:
                    temp_factor = self._ambient_temp_factors_xlpe[temps[0]]
                elif self._ambient_temp > temps[-1]:
                    temp_factor = self._ambient_temp_factors_xlpe[temps[-1]]
                else:
                    # Linear interpolation
                    for i in range(len(temps) - 1):
                        if temps[i] <= self._ambient_temp <= temps[i + 1]:
                            t1, t2 = temps[i], temps[i + 1]
                            f1 = self._ambient_temp_factors_xlpe[t1]
                            f2 = self._ambient_temp_factors_xlpe[t2]
                            temp_factor = f1 + (f2 - f1) * (self._ambient_temp - t1) / (t2 - t1)
                            break
        
        # Get grouping factor - use exact match or interpolate between closest values
        if self._grouping_number in self._grouping_factors:
            grouping_factor = self._grouping_factors[self._grouping_number]
        else:
            groups = sorted(list(self._grouping_factors.keys()))
            if self._grouping_number > groups[-1]:
                # Use the factor for the highest number of groups available
                grouping_factor = self._grouping_factors[groups[-1]]
            else:
                # Find the closest values and interpolate
                for i in range(len(groups) - 1):
                    if groups[i] < self._grouping_number < groups[i + 1]:
                        g1, g2 = groups[i], groups[i + 1]
                        f1 = self._grouping_factors[g1]
                        f2 = self._grouping_factors[g2]
                        grouping_factor = f1 + (f2 - f1) * (self._grouping_number - g1) / (g2 - g1)
                        break
        
        # Get installation method factor
        install_factor = self._install_method_factors.get(self._install_method, 1.0)
        
        # Calculate total derated ampacity
        self._derated_ampacity = self._base_ampacity * temp_factor * grouping_factor * install_factor
        
        # Calculate voltage drop (estimated per 100m at full load)
        # Improved model with resistive and reactive components
        if self._conductor_material == "Copper":
            r_per_km = 18.0 / self._cable_size  # ohms/km (approximate)
            x_per_km = 0.08  # ohms/km (typical reactance for LV cables)
        else:  # Aluminum
            r_per_km = 30.0 / self._cable_size  # ohms/km (approximate)
            x_per_km = 0.08  # ohms/km (typical reactance for LV cables)
        
        # Assume power factor of 0.85 for typical loads
        pf = 0.85
        sin_phi = (1 - pf**2) ** 0.5
        
        # Voltage drop with both resistance and reactance components
        # ΔV = I × (R×cosφ + X×sinφ)
        self._voltage_drop_per_100m = self._derated_ampacity * (r_per_km * pf + x_per_km * sin_phi) * 0.1  # V per 100m (0.1 km)
        
        # Calculate economic sizing recommendation based on economic current density
        self._economic_recommendation = self._cable_size
        econ_current_density = self._economic_density.get(self._conductor_material, 4.0)
        
        # Find the optimal size based on current and economic density
        for size in sorted(sizes):
            if size >= (self._derated_ampacity / econ_current_density):
                self._economic_recommendation = size
                break
        
        # Calculate recommended size for given current
        self._recommended_size = None
        for size in sorted(sizes):
            if self._insulation_type == "PVC":
                amp_capacity = self._base_ampacity_pvc_conduit.get(size, [0, 0])[material_index]
            else:
                amp_capacity = self._base_ampacity_xlpe_conduit.get(size, [0, 0])[material_index]
            
            amp_capacity *= temp_factor * grouping_factor * install_factor
            
            if amp_capacity >= self._derated_ampacity:
                self._recommended_size = size
                break
        
        # If no size is adequate, recommend the largest available
        if self._recommended_size is None:
            self._recommended_size = sizes[-1]
        
        # Notify QML of changes
        self.calculationsComplete.emit()

    # Property getters and setters
    @Property(float, notify=cableSizeChanged)
    def cableSize(self):
        return self._cable_size
    
    @cableSize.setter
    def cableSize(self, size):
        if self._cable_size != size and size > 0:
            self._cable_size = size
            self.cableSizeChanged.emit()
            self._calculate()

    @Property(str, notify=insulationTypeChanged)
    def insulationType(self):
        return self._insulation_type
    
    @insulationType.setter
    def insulationType(self, insulation):
        if self._insulation_type != insulation:
            self._insulation_type = insulation
            self.insulationTypeChanged.emit()
            self._calculate()

    @Property(str, notify=installMethodChanged)
    def installMethod(self):
        return self._install_method
    
    @installMethod.setter
    def installMethod(self, method):
        if self._install_method != method:
            self._install_method = method
            self.installMethodChanged.emit()
            self._calculate()

    @Property(float, notify=ambientTempChanged)
    def ambientTemp(self):
        return self._ambient_temp
    
    @ambientTemp.setter
    def ambientTemp(self, temp):
        if self._ambient_temp != temp:
            self._ambient_temp = temp
            self.ambientTempChanged.emit()
            self._calculate()

    @Property(int, notify=groupingNumberChanged)
    def groupingNumber(self):
        return self._grouping_number
    
    @groupingNumber.setter
    def groupingNumber(self, num):
        if self._grouping_number != num and num > 0:
            self._grouping_number = num
            self.groupingNumberChanged.emit()
            self._calculate()

    @Property(str, notify=conductorMaterialChanged)
    def conductorMaterial(self):
        return self._conductor_material
    
    @conductorMaterial.setter
    def conductorMaterial(self, material):
        if self._conductor_material != material:
            self._conductor_material = material
            self.conductorMaterialChanged.emit()
            self._calculate()

    @Property(float, notify=calculationsComplete)
    def baseAmpacity(self):
        return self._base_ampacity

    @Property(float, notify=calculationsComplete)
    def deratedAmpacity(self):
        return self._derated_ampacity

    @Property(float, notify=calculationsComplete)
    def voltageDropPer100m(self):
        return self._voltage_drop_per_100m

    @Property(float, notify=calculationsComplete)
    def economicRecommendation(self):
        return self._economic_recommendation
        
    @Property(float, notify=calculationsComplete)
    def recommendedSize(self):
        return self._recommended_size

    # Slots for QML access
    @Slot(float)
    def setCableSize(self, size):
        self.cableSize = size

    @Slot(str)
    def setInsulationType(self, insulation):
        self.insulationType = insulation

    @Slot(str)
    def setInstallMethod(self, method):
        self.installMethod = method

    @Slot(float)
    def setAmbientTemp(self, temp):
        self.ambientTemp = temp

    @Slot(int)
    def setGroupingNumber(self, num):
        self.groupingNumber = num

    @Slot(str)
    def setConductorMaterial(self, material):
        self.conductorMaterial = material
