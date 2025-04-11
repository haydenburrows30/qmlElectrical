from PySide6.QtCore import QObject, Signal, Property, Slot
import math

class OvercurrentProtectionCalculator(QObject):
    """Calculator for overcurrent protection settings for MV cables.
    
    This calculator computes protection settings for phase and earth fault protection
    for medium voltage cables, specifically handling:
    - Phase overcurrent protection (50/51)
    - Earth fault protection (50N/51N)
    - Negative sequence protection (50Q)
    """
    
    # Signals for notifying QML of changes
    dataChanged = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Cable parameters
        self._cable_cross_section = 25.0  # mm²
        self._cable_length = 8.0  # km
        self._cable_voltage = 11000.0  # V
        self._cable_material = "Aluminum"  # or "Copper"
        self._cable_type = "XLPE"
        self._cable_installation = "Direct Buried"  # or "Duct", "Tray", "Aerial"
        self._soil_resistivity = 100.0  # Ω·m
        self._ambient_temperature = 20.0  # °C
        
        # System parameters
        self._system_fault_level = 250.0  # MVA
        self._transformer_rating = 5.0  # MVA
        self._ct_ratio = 400  # 400:1
        self._use_percentage = False  # Calculate in A or % of CT
        self._earth_system = "Solidly Grounded"  # or "Resistance Grounded", "Isolated"
        
        # Results (will be calculated)
        self._cable_impedance = 0.0
        self._max_load_current = 0.0
        self._fault_current_3ph = 0.0
        self._fault_current_1ph = 0.0
        self._fault_current_2ph = 0.0
        
        # Protection settings
        self._i_pickup_50 = 0.0
        self._time_delay_50 = 0.0
        self._i_pickup_51 = 0.0
        self._time_dial_51 = 0.0
        self._curve_type_51 = "IEC Standard Inverse"
        
        self._i_pickup_50n = 0.0
        self._time_delay_50n = 0.0
        self._i_pickup_51n = 0.0
        self._time_dial_51n = 0.0
        self._curve_type_51n = "IEC Standard Inverse"
        
        self._i_pickup_50q = 0.0
        self._time_delay_50q = 0.0
        
        # Calculate initial values
        self.calculate()
    
    # Cable Cross Section
    def getCableCrossSection(self):
        return self._cable_cross_section
    
    def setCableCrossSection(self, value):
        if value != self._cable_cross_section and value > 0:
            self._cable_cross_section = value
            self.calculate()
            self.dataChanged.emit()
    
    cableCrossSection = Property(float, getCableCrossSection, setCableCrossSection, notify=dataChanged)
    
    # Cable Length
    def getCableLength(self):
        return self._cable_length
    
    def setCableLength(self, value):
        if value != self._cable_length and value > 0:
            self._cable_length = value
            self.calculate()
            self.dataChanged.emit()
    
    cableLength = Property(float, getCableLength, setCableLength, notify=dataChanged)
    
    # Cable Voltage
    def getCableVoltage(self):
        return self._cable_voltage
    
    def setCableVoltage(self, value):
        if value != self._cable_voltage and value > 0:
            self._cable_voltage = value
            self.calculate()
            self.dataChanged.emit()
    
    cableVoltage = Property(float, getCableVoltage, setCableVoltage, notify=dataChanged)
    
    # Cable Material
    def getCableMaterial(self):
        return self._cable_material
    
    def setCableMaterial(self, value):
        if value != self._cable_material:
            self._cable_material = value
            self.calculate()
            self.dataChanged.emit()
    
    cableMaterial = Property(str, getCableMaterial, setCableMaterial, notify=dataChanged)
    
    # Cable Type
    def getCableType(self):
        return self._cable_type
    
    def setCableType(self, value):
        if value != self._cable_type:
            self._cable_type = value
            self.calculate()
            self.dataChanged.emit()
    
    cableType = Property(str, getCableType, setCableType, notify=dataChanged)
    
    # Installation Type
    def getCableInstallation(self):
        return self._cable_installation
    
    def setCableInstallation(self, value):
        if value != self._cable_installation:
            self._cable_installation = value
            self.calculate()
            self.dataChanged.emit()
    
    cableInstallation = Property(str, getCableInstallation, setCableInstallation, notify=dataChanged)
    
    # Soil Resistivity
    def getSoilResistivity(self):
        return self._soil_resistivity
    
    def setSoilResistivity(self, value):
        if value != self._soil_resistivity and value > 0:
            self._soil_resistivity = value
            self.calculate()
            self.dataChanged.emit()
    
    soilResistivity = Property(float, getSoilResistivity, setSoilResistivity, notify=dataChanged)
    
    # Ambient Temperature
    def getAmbientTemperature(self):
        return self._ambient_temperature
    
    def setAmbientTemperature(self, value):
        if value != self._ambient_temperature:
            self._ambient_temperature = value
            self.calculate()
            self.dataChanged.emit()
    
    ambientTemperature = Property(float, getAmbientTemperature, setAmbientTemperature, notify=dataChanged)
    
    # System Fault Level
    def getSystemFaultLevel(self):
        return self._system_fault_level
    
    def setSystemFaultLevel(self, value):
        if value != self._system_fault_level and value > 0:
            self._system_fault_level = value
            self.calculate()
            self.dataChanged.emit()
    
    systemFaultLevel = Property(float, getSystemFaultLevel, setSystemFaultLevel, notify=dataChanged)
    
    # Transformer Rating
    def getTransformerRating(self):
        return self._transformer_rating
    
    def setTransformerRating(self, value):
        if value != self._transformer_rating and value > 0:
            self._transformer_rating = value
            # Make sure calculate() gets called to update fault currents based on the new transformer rating
            self.calculate()
            self.dataChanged.emit()
    
    transformerRating = Property(float, getTransformerRating, setTransformerRating, notify=dataChanged)
    
    # CT Ratio
    def getCtRatio(self):
        return self._ct_ratio
    
    def setCtRatio(self, value):
        if value != self._ct_ratio and value > 0:
            old_ratio = self._ct_ratio
            self._ct_ratio = value
            
            # If we're manually adjusting values, adjust them proportionally to maintain the same percentage
            if not self._use_percentage:
                # No need to adjust manual values
                pass
            else:
                # Adjust manual values to keep the same CT percentage
                ratio_factor = value / old_ratio
                # Don't adjust pickup values here as they're in primary amperes
                
            # No need to recalculate protection settings, just notify QML to update
            self.dataChanged.emit()
    
    ctRatio = Property(float, getCtRatio, setCtRatio, notify=dataChanged)
    
    # Use Percentage
    def getUsePercentage(self):
        return self._use_percentage
    
    def setUsePercentage(self, value):
        if value != self._use_percentage:
            self._use_percentage = value
            self.dataChanged.emit()
    
    usePercentage = Property(bool, getUsePercentage, setUsePercentage, notify=dataChanged)
    
    # Earth System
    def getEarthSystem(self):
        return self._earth_system
    
    def setEarthSystem(self, value):
        if value != self._earth_system:
            self._earth_system = value
            self.calculate()
            self.dataChanged.emit()
    
    earthSystem = Property(str, getEarthSystem, setEarthSystem, notify=dataChanged)
    
    # Cable Impedance (result)
    def getCableImpedance(self):
        return self._cable_impedance
    
    cableImpedance = Property(float, getCableImpedance, notify=dataChanged)
    
    # Max Load Current (result)
    def getMaxLoadCurrent(self):
        return self._max_load_current
    
    maxLoadCurrent = Property(float, getMaxLoadCurrent, notify=dataChanged)
    
    # Three-phase Fault Current (result)
    def getFaultCurrent3Ph(self):
        return self._fault_current_3ph
    
    faultCurrent3Ph = Property(float, getFaultCurrent3Ph, notify=dataChanged)
    
    # Single-phase Fault Current (result)
    def getFaultCurrent1Ph(self):
        return self._fault_current_1ph
    
    faultCurrent1Ph = Property(float, getFaultCurrent1Ph, notify=dataChanged)
    
    # Two-phase Fault Current (result)
    def getFaultCurrent2Ph(self):
        return self._fault_current_2ph
    
    faultCurrent2Ph = Property(float, getFaultCurrent2Ph, notify=dataChanged)
    
    # Phase Overcurrent - Instantaneous (50)
    def getIPickup50(self):
        return self._i_pickup_50
    
    iPickup50 = Property(float, getIPickup50, notify=dataChanged)
    
    def getTimeDelay50(self):
        return self._time_delay_50
    
    timeDelay50 = Property(float, getTimeDelay50, notify=dataChanged)
    
    # Phase Overcurrent - Time-delayed (51)
    def getIPickup51(self):
        return self._i_pickup_51
    
    iPickup51 = Property(float, getIPickup51, notify=dataChanged)
    
    def getTimeDial51(self):
        return self._time_dial_51
    
    timeDial51 = Property(float, getTimeDial51, notify=dataChanged)
    
    def getCurveType51(self):
        return self._curve_type_51
    
    curveType51 = Property(str, getCurveType51, notify=dataChanged)
    
    # Earth Fault - Instantaneous (50N)
    def getIPickup50N(self):
        return self._i_pickup_50n
    
    iPickup50N = Property(float, getIPickup50N, notify=dataChanged)
    
    def getTimeDelay50N(self):
        return self._time_delay_50n
    
    timeDelay50N = Property(float, getTimeDelay50N, notify=dataChanged)
    
    # Earth Fault - Time-delayed (51N)
    def getIPickup51N(self):
        return self._i_pickup_51n
    
    iPickup51N = Property(float, getIPickup51N, notify=dataChanged)
    
    def getTimeDial51N(self):
        return self._time_dial_51n
    
    timeDial51N = Property(float, getTimeDial51N, notify=dataChanged)
    
    def getCurveType51N(self):
        return self._curve_type_51n
    
    curveType51N = Property(str, getCurveType51N, notify=dataChanged)
    
    # Negative Sequence - Instantaneous (50Q)
    def getIPickup50Q(self):
        return self._i_pickup_50q
    
    iPickup50Q = Property(float, getIPickup50Q, notify=dataChanged)
    
    def getTimeDelay50Q(self):
        return self._time_delay_50q
    
    timeDelay50Q = Property(float, getTimeDelay50Q, notify=dataChanged)
    
    @Slot()
    def calculate(self):
        """Calculate all protection parameters based on current inputs"""
        self._calculate_cable_parameters()
        self._calculate_fault_currents()
        self._calculate_protection_settings()
    
    def _calculate_cable_parameters(self):
        """Calculate impedance and max current carrying capacity of the cable"""
        # Resistivity multipliers by material (Ω·mm²/m)
        resistivities = {
            "Copper": 0.0175,
            "Aluminum": 0.0283
        }
        
        # Temperature correction factors
        temp_correction = 1.0 + 0.004 * (self._ambient_temperature - 20)
        
        # Calculate cable resistance (Ω/km)
        r_dc = resistivities.get(self._cable_material, 0.0283) * 1000 / self._cable_cross_section
        r_ac = r_dc * 1.02  # AC resistance factor
        
        # Calculate cable reactance (approximate values for MV cables in Ω/km)
        if self._cable_type == "XLPE":
            x_cable = 0.08  # Typical XLPE reactance
        else:
            x_cable = 0.1   # Default reactance
            
        # Adjust reactance based on soil resistivity (approximate effect)
        soil_factor = math.sqrt(self._soil_resistivity / 100)  # Reference soil resistivity of 100 Ω·m
        x_cable = x_cable * soil_factor  # Higher soil resistivity increases reactance
        
        # Total cable impedance
        self._cable_impedance = math.sqrt((r_ac * self._cable_length)**2 + 
                                          (x_cable * self._cable_length)**2)
        
        # Approximate maximum current capacity based on cable size and type
        base_ampacity = {
            16: 75,
            25: 101,
            35: 123,
            50: 155,
            70: 191,
            95: 233,
            120: 271,
            150: 306
        }
        
        # Find the closest cable size in the table
        sizes = list(base_ampacity.keys())
        closest_size = min(sizes, key=lambda x: abs(x - self._cable_cross_section))
        
        # Get base ampacity and apply correction factors
        base_current = base_ampacity.get(closest_size, 0)
        
        # Installation correction factors
        installation_factors = {
            "Direct Buried": 0.9,
            "Duct": 0.8,
            "Tray": 0.95,
            "Aerial": 1.0
        }
        
        # Total correction factor
        k_total = installation_factors.get(self._cable_installation, 0.9) / temp_correction
        
        # Calculate maximum permissible load current
        self._max_load_current = base_current * k_total
    
    def _calculate_fault_currents(self):
        """Calculate fault currents for different fault types"""
        # System base impedance at rated voltage
        s_base_mva = self._system_fault_level
        v_base_kv = self._cable_voltage / 1000
        z_base = (v_base_kv**2) / s_base_mva  # Ω
        
        # System impedance (assumed X/R ratio of 10)
        z_system_mag = z_base
        z_system_r = z_system_mag / math.sqrt(101)  # R component with X/R=10
        z_system_x = z_system_r * 10  # X component with X/R=10
        
        # Transformer impedance (typical 6% for MV transformers)
        z_tx = 0.06 * (v_base_kv**2) / self._transformer_rating  # Transformer impedance in Ohms
        z_tx_r = z_tx * 0.1  # Assuming R is 10% of Z
        z_tx_x = z_tx * 0.995  # Assuming X is 99.5% of Z
        
        # Total impedance including system, transformer and cable
        z_total_r = z_system_r + z_tx_r + (self._cable_impedance * 0.1)  # Cable R is 10% of Z
        z_total_x = z_system_x + z_tx_x + (self._cable_impedance * 0.995)  # Cable X is 99.5% of Z
        z_total = math.sqrt(z_total_r**2 + z_total_x**2)
        
        # 3-phase fault current calculation
        i_base = (s_base_mva * 1000) / (math.sqrt(3) * v_base_kv)  # Base current in A
        self._fault_current_3ph = i_base / (z_total / z_base)  # Fault current in A
        
        # Calculate line-to-line fault current
        self._fault_current_2ph = self._fault_current_3ph * math.sqrt(3) / 2
        
        # Calculate single-phase-to-ground fault current based on earthing
        if self._earth_system == "Solidly Grounded":
            self._fault_current_1ph = self._fault_current_3ph * 1.0
        elif self._earth_system == "Resistance Grounded":
            # Typically limited to 200-400A for resistance grounding
            self._fault_current_1ph = min(300, self._fault_current_3ph * 0.6)
        else:  # Isolated
            # Very low fault current for isolated systems
            self._fault_current_1ph = self._fault_current_3ph * 0.05
    
    def _calculate_protection_settings(self):
        """Calculate recommended protection settings"""
        # Phase instantaneous overcurrent (50)
        self._i_pickup_50 = max(self._fault_current_3ph * 0.8, self._max_load_current * 6)
        self._time_delay_50 = 0.05  # 50ms delay
        
        # Phase time-overcurrent (51)
        self._i_pickup_51 = max(self._max_load_current * 1.2, 20)  # Min 20A or 120% of load
        self._time_dial_51 = 0.1  # Starting point
        self._curve_type_51 = "IEC Standard Inverse"
        
        # Earth fault instantaneous (50N)
        if self._earth_system == "Solidly Grounded":
            self._i_pickup_50n = min(self._fault_current_1ph * 0.5, 200)
        elif self._earth_system == "Resistance Grounded":
            self._i_pickup_50n = min(self._fault_current_1ph * 0.7, 150)
        else:  # Isolated
            self._i_pickup_50n = min(self._fault_current_1ph * 0.8, 10)
        
        self._time_delay_50n = 0.1  # 100ms delay
        
        # Earth fault time-delayed (51N)
        self._i_pickup_51n = max(10, self._max_load_current * 0.1)  # 10% of load or min 10A
        self._time_dial_51n = 0.05
        self._curve_type_51n = "IEC Very Inverse"
        
        # Negative sequence (50Q)
        self._i_pickup_50q = self._max_load_current * 0.3  # 30% of load
        self._time_delay_50q = 0.2  # 200ms delay
    
    # Setters for protection settings (for manual adjustments from QML)
    @Slot(float)
    def setIPickup50(self, value):
        if value != self._i_pickup_50 and value > 0:
            self._i_pickup_50 = value
            self.dataChanged.emit()
    
    @Slot(float)
    def setTimeDelay50(self, value):
        if value != self._time_delay_50 and value >= 0:
            self._time_delay_50 = value
            self.dataChanged.emit()
    
    @Slot(float)
    def setIPickup51(self, value):
        if value != self._i_pickup_51 and value > 0:
            self._i_pickup_51 = value
            self.dataChanged.emit()
    
    @Slot(float)
    def setTimeDial51(self, value):
        if value != self._time_dial_51 and value > 0:
            self._time_dial_51 = value
            self.dataChanged.emit()
    
    @Slot(str)
    def setCurveType51(self, value):
        if value != self._curve_type_51:
            self._curve_type_51 = value
            self.dataChanged.emit()
    
    @Slot(float)
    def setIPickup50N(self, value):
        if value != self._i_pickup_50n and value > 0:
            self._i_pickup_50n = value
            self.dataChanged.emit()
    
    @Slot(float)
    def setTimeDelay50N(self, value):
        if value != self._time_delay_50n and value >= 0:
            self._time_delay_50n = value
            self.dataChanged.emit()
    
    @Slot(float)
    def setIPickup51N(self, value):
        if value != self._i_pickup_51n and value > 0:
            self._i_pickup_51n = value
            self.dataChanged.emit()
    
    @Slot(float)
    def setTimeDial51N(self, value):
        if value != self._time_dial_51n and value > 0:
            self._time_dial_51n = value
            self.dataChanged.emit()
    
    @Slot(str)
    def setCurveType51N(self, value):
        if value != self._curve_type_51n:
            self._curve_type_51n = value
            self.dataChanged.emit()
    
    @Slot(float)
    def setIPickup50Q(self, value):
        if value != self._i_pickup_50q and value > 0:
            self._i_pickup_50q = value
            self.dataChanged.emit()
    
    @Slot(float)
    def setTimeDelay50Q(self, value):
        if value != self._time_delay_50q and value >= 0:
            self._time_delay_50q = value
            self.dataChanged.emit()
    
    # Helper methods for QML display
    @Slot(float, result=float)
    def convertToPercentage(self, amperes):
        """Convert amperes to percentage of CT primary"""
        if self._ct_ratio > 0:
            return (amperes / self._ct_ratio) * 100
        return 0
    
    @Slot(float, result=float)
    def convertToAmperes(self, percentage):
        """Convert percentage of CT primary to amperes"""
        return (percentage * self._ct_ratio) / 100