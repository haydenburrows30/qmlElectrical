from PySide6.QtCore import QObject, Signal, Property, Slot
from .time_curve_calculator import TimeCurveCalculator
import math
import tempfile
import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from datetime import datetime
from services.file_saver import FileSaver

class OvercurrentProtectionCalculator(QObject):
    """Calculator for overcurrent protection settings for MV cables."""
    
    # Individual signals for each property
    cableCrossSectionChanged = Signal()
    cableLengthChanged = Signal()
    cableVoltageChanged = Signal()
    cableMaterialChanged = Signal()
    cableTypeChanged = Signal()
    cableInstallationChanged = Signal()
    soilResistivityChanged = Signal()
    ambientTemperatureChanged = Signal()
    systemFaultLevelChanged = Signal()
    transformerRatingChanged = Signal()
    ctRatioChanged = Signal()
    usePercentageChanged = Signal()
    earthSystemChanged = Signal()
    cableRChanged = Signal()  # Add this signal
    cableXChanged = Signal()  # Add this signal
    calculationsComplete = Signal()
    transformerImpedanceChanged = Signal()
    transformerXRRatioChanged = Signal()
    transformerVectorGroupChanged = Signal()
    curveStandardChanged = Signal()
    availableCurvesChanged = Signal()
    pdfExportStatusChanged = Signal(bool, str)  # Add PDF export status signal

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
        self._curve_type_51 = "Standard Inverse"  # Changed default
        
        self._i_pickup_50n = 0.0
        self._time_delay_50n = 0.0
        self._i_pickup_51n = 0.0
        self._time_dial_51n = 0.0
        self._curve_type_51n = "Very Inverse"  # Changed default
        
        self._i_pickup_50q = 0.0
        self._time_delay_50q = 0.0
        
        # New properties for custom impedance
        self._custom_cable_r = 0.0
        self._custom_cable_x = 0.0

        # Add new transformer parameters
        self._transformer_impedance = 6.0  # Default Z% = 6%
        self._transformer_x_r_ratio = 10.0  # Default X/R = 10
        self._transformer_vector_group = "Dyn11"  # Default vector group
        
        # Curve selection parameters
        self._curve_standard = "IEC"  # or "ANSI"
        self._available_curves = {
            "IEC": ["Standard Inverse", "Very Inverse", "Extremely Inverse", "Long Time Inverse"],
            "ANSI": ["Moderate Inverse", "Inverse", "Very Inverse", "Extremely Inverse"]
        }
        
        # Coordination properties
        self._time_curve_calculator = TimeCurveCalculator(self)
        self._upstream_device = None
        self._downstream_device = None
        self._grading_margin = 0.4  # seconds
        
        # Initialize FileSaver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our pdfExportStatusChanged signal
        self._file_saver.saveStatusChanged.connect(self.pdfExportStatusChanged)
        
        # Calculate initial values
        self._calculate()

    @Slot(float)
    def setGradingMargin(self, margin):
        """Set grading time margin"""
        if self._grading_margin != margin:
            self._grading_margin = max(0.2, min(margin, 1.0))
            self._calculate()
            self.calculationsComplete.emit()

    @Slot(QObject)
    def setUpstreamDevice(self, device):
        """Set upstream device for coordination"""
        self._upstream_device = device
        self._calculate()
        self.calculationsComplete.emit()

    @Slot(QObject)
    def setDownstreamDevice(self, device):
        """Set downstream device for coordination"""
        self._downstream_device = device
        self._calculate()
        self.calculationsComplete.emit()

    def _calculate(self):
        """Calculate all protection parameters"""
        self._calculate_cable_parameters()
        self._calculate_fault_currents()
        self._calculate_protection_settings()
        self.calculationsComplete.emit()

    def _calculate_cable_parameters(self):
        """Calculate impedance and max current carrying capacity of the cable"""
        # Default resistivity calculations
        resistivities = {
            "Copper": 0.0175,
            "Aluminum": 0.0283
        }
        
        temp_correction = 1.0 + 0.004 * (self._ambient_temperature - 20)
        
        # Use custom R and X if provided, otherwise calculate from parameters
        if self._custom_cable_r > 0 and self._custom_cable_x > 0:
            r_ac = self._custom_cable_r
            x_cable = self._custom_cable_x
        else:
            r_dc = resistivities.get(self._cable_material, 0.0283) * 1000 / self._cable_cross_section
            r_ac = r_dc * 1.02
            
            if self._cable_type == "XLPE":
                x_cable = 0.08
            else:
                x_cable = 0.1
                
            soil_factor = math.sqrt(self._soil_resistivity / 100)
            x_cable = x_cable * soil_factor
        
        # Calculate total impedance using length
        self._cable_impedance = math.sqrt((r_ac * self._cable_length)**2 + 
                                        (x_cable * self._cable_length)**2)
        
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
        
        sizes = list(base_ampacity.keys())
        closest_size = min(sizes, key=lambda x: abs(x - self._cable_cross_section))
        base_current = base_ampacity.get(closest_size, 0)
        
        installation_factors = {
            "Direct Buried": 0.9,
            "Duct": 0.8,
            "Tray": 0.95,
            "Aerial": 1.0
        }
        
        k_total = installation_factors.get(self._cable_installation, 0.9) / temp_correction
        self._max_load_current = base_current * k_total

    @Slot(result='QVariantList')
    def getCurvePoints(self):
        """Get points for plotting time-current curve"""
        return self._time_curve_calculator.generate_curve_points(
            self._i_pickup_51,
            self._time_dial_51,
            self._curve_type_51,
            self._curve_standard
        )

    def _calculate_minimum_time_dial(self, upstream_points):
        """Calculate minimum time dial to maintain grading margin with upstream device"""
        currents, times = upstream_points
        min_dial = 0.1
        
        # Find minimum time dial that maintains grading margin
        for i in range(len(currents)):
            if times[i] is not None:
                required_dial = (times[i] - self._grading_margin) / \
                              self._time_curve_calculator.calculate_operating_time(
                                  self._curve_type_51,
                                  self._curve_standard,
                                  currents[i] / self._i_pickup_51,
                                  1.0  # Base time dial
                              )
                min_dial = max(min_dial, required_dial)
        
        return min_dial

    def _calculate_maximum_time_dial(self, downstream_points):
        """Calculate maximum time dial to maintain grading margin with downstream device"""
        currents, times = downstream_points
        max_dial = 10.0  # Maximum reasonable time dial setting
        
        for i in range(len(currents)):
            if times[i] is not None:
                required_dial = (times[i] + self._grading_margin) / \
                              self._time_curve_calculator.calculate_operating_time(
                                  self._curve_type_51,
                                  self._curve_standard,
                                  currents[i] / self._i_pickup_51,
                                  1.0  # Base time dial
                              )
                max_dial = min(max_dial, required_dial)
        
        return max_dial

    def _calculate_fault_currents(self):
        """Calculate fault currents with transformer characteristics"""
        s_base_mva = self._system_fault_level
        v_base_kv = self._cable_voltage / 1000
        z_base = (v_base_kv**2) / s_base_mva
        
        # System impedance
        z_system_mag = z_base
        z_system_r = z_system_mag / math.sqrt(101)
        z_system_x = z_system_r * 10
        
        # Transformer impedance using actual Z% and X/R ratio
        z_tx = (self._transformer_impedance / 100) * (v_base_kv**2) / self._transformer_rating
        z_tx_x = z_tx * (self._transformer_x_r_ratio / math.sqrt(1 + self._transformer_x_r_ratio**2))
        z_tx_r = z_tx * (1 / math.sqrt(1 + self._transformer_x_r_ratio**2))
        
        # Total impedance including cable
        z_total_r = z_system_r + z_tx_r + (self._cable_impedance * 0.1)
        z_total_x = z_system_x + z_tx_x + (self._cable_impedance * 0.995)
        z_total = math.sqrt(z_total_r**2 + z_total_x**2)
        
        # Base current
        i_base = (s_base_mva * 1000) / (math.sqrt(3) * v_base_kv)
        self._fault_current_3ph = i_base / (z_total / z_base)
        
        # Phase-phase fault current
        self._fault_current_2ph = self._fault_current_3ph * 0.866  # sqrt(3)/2
        
        # Ground fault current based on vector group
        if self._transformer_vector_group.startswith(('Yn', 'yn')):
            earth_factor = 1.0  # Solidly grounded wye
        elif self._transformer_vector_group.startswith(('D', 'd')):
            earth_factor = 0.0  # Delta - no ground fault current
        else:
            earth_factor = 0.6  # Other configurations
            
        if self._earth_system == "Solidly Grounded":
            self._fault_current_1ph = self._fault_current_3ph * earth_factor
        elif self._earth_system == "Resistance Grounded":
            self._fault_current_1ph = min(300, self._fault_current_3ph * 0.6 * earth_factor)
        else:  # Isolated
            self._fault_current_1ph = self._fault_current_3ph * 0.05 * earth_factor

    def _calculate_protection_settings(self):
        """Calculate protection settings with coordination"""
        # Calculate transformer rated current
        tx_rated_current = (self._transformer_rating * 1000000) / (math.sqrt(3) * self._cable_voltage)
        
        # Phase overcurrent settings
        self._i_pickup_50 = min(
            max(self._fault_current_3ph * 0.8, tx_rated_current * 6),
            self._fault_current_2ph * 0.9
        )
        self._time_delay_50 = 0.05  # <100ms for fast fault clearing
        
        # Time overcurrent settings
        min_pickup = min(20, tx_rated_current * 0.05)
        self._i_pickup_51 = max(
            min_pickup,
            min(tx_rated_current * 1.2, self._max_load_current * 1.1)
        )
        
        # Time dial based on fault current level
        fault_ratio = self._fault_current_3ph / self._i_pickup_51
        
        # Curve selection based on application
        if self._curve_standard == "IEC":
            if fault_ratio > 20:
                self._curve_type_51 = "Standard Inverse"
            elif fault_ratio > 10:
                self._curve_type_51 = "Very Inverse"
            else:
                self._curve_type_51 = "Extremely Inverse"
        else:  # ANSI curves
            if fault_ratio > 20:
                self._curve_type_51 = "Inverse"
            elif fault_ratio > 10:
                self._curve_type_51 = "Very Inverse"
            else:
                self._curve_type_51 = "Extremely Inverse"
        
        # Set base time dial based on fault ratio
        if fault_ratio > 20:
            self._time_dial_51 = 0.1
        elif fault_ratio > 10:
            self._time_dial_51 = 0.2
        else:
            self._time_dial_51 = 0.3
        
        # Adjust time dial for coordination
        if self._upstream_device:
            upstream_points = self._upstream_device.getCurvePoints()
            self._time_dial_51 = max(
                self._time_dial_51,
                self._calculate_minimum_time_dial(upstream_points)
            )
        
        if self._downstream_device:
            downstream_points = self._downstream_device.getCurvePoints()
            self._time_dial_51 = min(
                self._time_dial_51,
                self._calculate_maximum_time_dial(downstream_points)
            )
        
        # Earth fault protection
        if self._earth_system == "Solidly Grounded":
            self._i_pickup_50n = min(self._fault_current_1ph * 0.5, tx_rated_current * 0.4)
            self._i_pickup_51n = min(
                max(tx_rated_current * 0.1, 10),
                self._fault_current_1ph * 0.2
            )
            self._time_dial_51n = 0.1
        elif self._earth_system == "Resistance Grounded":
            self._i_pickup_50n = min(self._fault_current_1ph * 0.7, tx_rated_current * 0.3)
            self._i_pickup_51n = min(
                max(tx_rated_current * 0.08, 10),
                self._fault_current_1ph * 0.3
            )
            self._time_dial_51n = 0.15
        else:  # Isolated
            self._i_pickup_50n = min(self._fault_current_1ph * 0.8, tx_rated_current * 0.1)
            self._i_pickup_51n = min(
                max(tx_rated_current * 0.05, 10),
                self._fault_current_1ph * 0.4
            )
            self._time_dial_51n = 0.2
        
        self._time_delay_50n = 0.15
        self._curve_type_51n = "IEC Very Inverse"
        
        # Negative sequence protection
        unbalance_current = self._fault_current_2ph * 0.1
        self._i_pickup_50q = min(
            max(tx_rated_current * 0.15, 20),
            unbalance_current
        )
        
        vector_group_delay = {
            "Dyn11": 0.2,
            "Yyn0": 0.25,
            "Dyn1": 0.2,
            "Ynd11": 0.3
        }
        self._time_delay_50q = vector_group_delay.get(self._transformer_vector_group, 0.2)

    # Add missing property bindings
    @Property(str, notify=cableMaterialChanged)
    def cableMaterial(self):
        """Get cable material with safe default"""
        return self._cable_material or "Aluminum"

    @cableMaterial.setter
    def cableMaterial(self, value):
        """Set cable material with validation"""
        if value in ["Copper", "Aluminum"] and value != self._cable_material:
            self._cable_material = value
            self.cableMaterialChanged.emit()
            self._calculate()

    @Property(int, notify=calculationsComplete)
    def cableCrossSection(self):
        """Get cable cross section with safe default"""
        try:
            return max(1, int(self._cable_cross_section))
        except (TypeError, ValueError):
            return 25  # Safe default
    
    @cableCrossSection.setter
    def cableCrossSection(self, value):
        try:
            value = int(value)
            if value != self._cable_cross_section and value > 0:
                self._cable_cross_section = value
                self.cableCrossSectionChanged.emit()
                self._calculate()
        except (TypeError, ValueError):
            pass

    @Property(float, notify=calculationsComplete)
    def cableLength(self):
        return self._cable_length

    @Property(float, notify=calculationsComplete)
    def cableVoltage(self):
        return self._cable_voltage

    @Property(float, notify=calculationsComplete)
    def systemFaultLevel(self):
        return self._system_fault_level

    @Property(float, notify=calculationsComplete)
    def transformerRating(self):
        return self._transformer_rating

    @Property(float, notify=calculationsComplete)
    def ctRatio(self):
        return self._ct_ratio

    @Property(float, notify=calculationsComplete)
    def transformerImpedance(self):
        return self._transformer_impedance

    @Property(float, notify=calculationsComplete)
    def transformerXRRatio(self):
        return self._transformer_x_r_ratio

    @Property(str, notify=curveStandardChanged)
    def transformerVectorGroup(self):
        return self._transformer_vector_group

    @Property(str, notify=curveStandardChanged)
    def curveStandard(self):
        """Get curve standard with safe default"""
        return self._curve_standard or "IEC"
    
    @curveStandard.setter
    def curveStandard(self, value):
        """Set curve standard with validation"""
        if value in ["IEC", "ANSI"]:
            if value != self._curve_standard:
                self._curve_standard = value
                self.curveStandardChanged.emit()
                self._calculate()

    @Property('QVariantMap', notify=calculationsComplete)
    def availableCurves(self):
        """Get available curves for current standard"""
        try:
            return {
                self._curve_standard: self._available_curves.get(self._curve_standard, [])
            }
        except:
            return {"IEC": ["Standard Inverse"]}  # Safe default

    @Property(bool, notify=calculationsComplete)
    def usePercentage(self):
        return self._use_percentage

    @Property(float, notify=calculationsComplete)
    def soilResistivity(self):
        return self._soil_resistivity

    @Property(float, notify=calculationsComplete)
    def gradingMargin(self):
        return self._grading_margin

    @Property(float, notify=ambientTemperatureChanged)
    def ambientTemperature(self):
        """Get ambient temperature with safe default"""
        return self._ambient_temperature

    @ambientTemperature.setter
    def ambientTemperature(self, value):
        """Set ambient temperature with validation"""
        if value != self._ambient_temperature and -10 <= value <= 60:
            self._ambient_temperature = value
            self.ambientTemperatureChanged.emit()
            self._calculate()

    # Add result property bindings
    @Property(float, notify=calculationsComplete)
    def maxLoadCurrent(self):
        """Get max load current with safe default"""
        return max(0.0, self._max_load_current)

    @Property(float, notify=calculationsComplete)
    def faultCurrent3Ph(self):
        return self._fault_current_3ph

    @Property(float, notify=calculationsComplete)
    def faultCurrent2Ph(self):
        return self._fault_current_2ph

    @Property(float, notify=calculationsComplete)
    def faultCurrent1Ph(self):
        return self._fault_current_1ph

    @Property(float, notify=calculationsComplete)
    def iPickup50(self):
        return self._i_pickup_50

    @Property(float, notify=calculationsComplete)
    def timeDelay50(self):
        return self._time_delay_50

    @Property(float, notify=calculationsComplete)
    def iPickup51(self):
        return self._i_pickup_51

    @Property(float, notify=calculationsComplete)
    def timeDial51(self):
        return self._time_dial_51

    @Property(str, notify=calculationsComplete)
    def curveType51(self):
        """Get curve type with safe default"""
        if not self._curve_type_51 or self._curve_type_51 not in self._available_curves.get(self._curve_standard, []):
            # Set safe default based on standard
            self._curve_type_51 = "Standard Inverse" if self._curve_standard == "IEC" else "Inverse"
        return self._curve_type_51
    
    @curveType51.setter
    def curveType51(self, value):
        """Set curve type with validation"""
        if value and value != self._curve_type_51:
            if value in self._available_curves.get(self._curve_standard, []):
                self._curve_type_51 = value
                self._calculate()
                self.calculationsComplete.emit()

    @Property(float, notify=calculationsComplete)
    def iPickup50N(self):
        return self._i_pickup_50n

    @Property(float, notify=calculationsComplete)
    def timeDelay50N(self):
        return self._time_delay_50n

    @Property(float, notify=calculationsComplete)
    def iPickup51N(self):
        return self._i_pickup_51n

    @Property(float, notify=calculationsComplete)
    def timeDial51N(self):
        return self._time_dial_51n

    @Property(str, notify=calculationsComplete)
    def curveType51N(self):
        """Get earth fault curve type with safety check"""
        return self._curve_type_51n or "IEC Very Inverse"

    @Property(float, notify=calculationsComplete)
    def iPickup50Q(self):
        return self._i_pickup_50q

    @Property(float, notify=calculationsComplete)
    def timeDelay50Q(self):
        return self._time_delay_50q

    @Slot(float, result=float)
    def convertToPercentage(self, amperes):
        """Convert primary amperes to percentage of CT rating"""
        try:
            if self._ct_ratio <= 0:
                return 0
            return (amperes / self._ct_ratio) * 100
        except (TypeError, ZeroDivisionError):
            return 0

    # Corresponding setters for each property
    @cableLength.setter
    def cableLength(self, value):
        if value != self._cable_length and value > 0:
            self._cable_length = value
            self._calculate()

    @cableVoltage.setter
    def cableVoltage(self, value):
        if value != self._cable_voltage and value > 0:
            self._cable_voltage = value
            self._calculate()

    @systemFaultLevel.setter
    def systemFaultLevel(self, value):
        if value != self._system_fault_level and value > 0:
            self._system_fault_level = value
            self._calculate()

    @transformerRating.setter
    def transformerRating(self, value):
        if value != self._transformer_rating and value > 0:
            self._transformer_rating = value
            self._calculate()

    @ctRatio.setter
    def ctRatio(self, value):
        if value != self._ct_ratio and value > 0:
            self._ct_ratio = value
            self._calculate()

    @transformerImpedance.setter
    def transformerImpedance(self, value):
        if value != self._transformer_impedance and value > 0:
            self._transformer_impedance = value
            self._calculate()

    @transformerXRRatio.setter
    def transformerXRRatio(self, value):
        if value != self._transformer_x_r_ratio and value > 0:
            self._transformer_x_r_ratio = value
            self._calculate()

    @transformerVectorGroup.setter
    def transformerVectorGroup(self, value):
        if value != self._transformer_vector_group:
            self._transformer_vector_group = value
            self._calculate()

    @curveStandard.setter
    def curveStandard(self, value):
        if value != self._curve_standard:
            self._curve_standard = value
            self._calculate()

    @usePercentage.setter
    def usePercentage(self, value):
        if value != self._use_percentage:
            self._use_percentage = value
            self.calculationsComplete.emit()

    @soilResistivity.setter
    def soilResistivity(self, value):
        if value != self._soil_resistivity and value > 0:
            self._soil_resistivity = value
            self._calculate()

    @Property(str, notify=cableTypeChanged)
    def cableType(self):
        """Get cable type with safe default"""
        return self._cable_type or "XLPE"

    @cableType.setter
    def cableType(self, value):
        """Set cable type with validation"""
        if value in ["XLPE", "PVC", "EPR", "Custom"] and value != self._cable_type:
            self._cable_type = value
            self.cableTypeChanged.emit()
            self._calculate()

    @Property(str, notify=cableInstallationChanged)
    def cableInstallation(self):
        """Get cable installation type with safe default"""
        return self._cable_installation or "Direct Buried"

    @cableInstallation.setter
    def cableInstallation(self, value):
        """Set cable installation type with validation"""
        if value in ["Direct Buried", "Duct", "Tray", "Aerial"] and value != self._cable_installation:
            self._cable_installation = value
            self.cableInstallationChanged.emit()
            self._calculate()

    @Property(float, notify=cableRChanged)
    def cableR(self):
        """Get cable R value with safe default"""
        return self._custom_cable_r

    @cableR.setter
    def cableR(self, value):
        """Set cable R value with validation"""
        if value != self._custom_cable_r and value >= 0:
            self._custom_cable_r = value
            self.cableRChanged.emit()
            self._calculate()

    @Property(float, notify=cableXChanged)
    def cableX(self):
        """Get cable X value with safe default"""
        return self._custom_cable_x

    @cableX.setter
    def cableX(self, value):
        """Set cable X value with validation"""
        if value != self._custom_cable_x and value >= 0:
            self._custom_cable_x = value
            self.cableXChanged.emit()
            self._calculate()

    @Property(float, notify=calculationsComplete)
    def cableImpedance(self):
        """Get cable impedance value"""
        return self._cable_impedance

    @Slot()
    def exportToReport(self):
        """Export protection settings to a PDF report"""
        try:
            # Create timestamp for filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"overcurrent_protection_{timestamp}")
            if not pdf_file:
                self.pdfExportStatusChanged.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create temporary directory for chart image
            temp_dir = tempfile.mkdtemp()
            chart_image_path = os.path.join(temp_dir, "time_current_curves.png")
            
            # Generate matplotlib chart
            self._generate_chart(chart_image_path)
            
            # Prepare data for PDF
            data = {
                'cable_cross_section': self._cable_cross_section,
                'cable_length': self._cable_length,
                'cable_voltage': self._cable_voltage,
                'cable_material': self._cable_material,
                'cable_type': self._cable_type,
                'cable_installation': self._cable_installation,
                'soil_resistivity': self._soil_resistivity,
                'ambient_temperature': self._ambient_temperature,
                'system_fault_level': self._system_fault_level,
                'transformer_rating': self._transformer_rating,
                'transformer_impedance': self._transformer_impedance,
                'transformer_xr_ratio': self._transformer_x_r_ratio,
                'transformer_vector_group': self._transformer_vector_group,
                'ct_ratio': self._ct_ratio,
                'curve_standard': self._curve_standard,
                'cable_r': self._custom_cable_r,
                'cable_x': self._custom_cable_x,
                'cable_impedance': self._cable_impedance,
                'max_load_current': self._max_load_current,
                'fault_current_3ph': self._fault_current_3ph,
                'fault_current_2ph': self._fault_current_2ph,
                'fault_current_1ph': self._fault_current_1ph,
                'i_pickup_50': self._i_pickup_50,
                'time_delay_50': self._time_delay_50,
                'i_pickup_51': self._i_pickup_51,
                'time_dial_51': self._time_dial_51,
                'curve_type_51': self._curve_type_51,
                'i_pickup_50n': self._i_pickup_50n,
                'time_delay_50n': self._time_delay_50n,
                'i_pickup_51n': self._i_pickup_51n,
                'time_dial_51n': self._time_dial_51n,
                'curve_type_51n': self._curve_type_51n,
                'i_pickup_50q': self._i_pickup_50q,
                'time_delay_50q': self._time_delay_50q,
                'chart_image_path': chart_image_path if os.path.exists(chart_image_path) else None
            }
            
            # Generate PDF using the specialized PDF generator
            from utils.pdf.pdf_generator_overcurrent_protection import OvercurrentPdfGenerator
            pdf_generator = OvercurrentPdfGenerator()
            success = pdf_generator.generate_report(data, pdf_file)
            
            # Clean up temporary files
            try:
                if os.path.exists(chart_image_path):
                    os.unlink(chart_image_path)
                os.rmdir(temp_dir)
            except Exception as e:
                print(f"Error cleaning up temp files: {e}")
            
            # Force garbage collection to ensure resources are freed
            import gc
            gc.collect()
            
            # Signal success or failure
            if success:
                self._file_saver._emit_success_with_path(pdf_file, "PDF saved")
                return True
            else:
                self._file_saver._emit_failure_with_path(pdf_file, "Error saving PDF")
                return False
                
        except Exception as e:
            error_msg = f"Error exporting report: {str(e)}"
            import traceback
            traceback.print_exc()
            self.pdfExportStatusChanged.emit(False, error_msg)
            return False
    
    def _generate_chart(self, filepath):
        """Generate time-current curve chart using matplotlib
        
        Args:
            filepath: Path to save the chart image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Create figure with logarithmic axes
            plt.figure(figsize=(10, 8))
            plt.grid(True, which="both", ls="-", alpha=0.7)
            plt.loglog()
            
            # Set labels and title
            plt.title('Time-Current Curves')
            plt.xlabel('Current (A)')
            plt.ylabel('Time (s)')
            
            # Generate curve points
            curve_points = self.getCurvePoints()
            if len(curve_points) > 0:
                # Extract currents and times
                currents = [point[0] for point in curve_points if len(point) >= 2]
                times = [point[1] for point in curve_points if len(point) >= 2]
                
                # Plot the overcurrent curve
                if currents and times:
                    plt.plot(currents, times, 'r-', linewidth=2, label=f'51: {self._curve_type_51}')
                
                # Add instantaneous setting (horizontal and vertical lines)
                if self._i_pickup_50 > 0:
                    y_min, y_max = plt.ylim()
                    plt.axvline(x=self._i_pickup_50, color='b', linestyle='--', 
                             label=f'50: {self._i_pickup_50:.1f}A')
                    # Add horizontal time delay line
                    x_min, x_max = plt.xlim()
                    plt.axhline(y=self._time_delay_50, color='g', linestyle=':', 
                             label=f'TD: {self._time_delay_50:.2f}s')
                
                # Add earth fault settings if they exist
                if self._i_pickup_51n > 0:
                    # Generate earth fault curve using similar timepoints but different pickup
                    ef_currents = []
                    ef_times = []
                    # Use 20 points for a smooth curve
                    for current_multiple in range(11, 210, 10):
                        current = self._i_pickup_51n * current_multiple / 10
                        # Use formula from TimeCurveCalculator based on curve type and time dial
                        if self._curve_type_51n == "IEC Very Inverse":
                            time = 13.5 * self._time_dial_51n / ((current / self._i_pickup_51n) - 1)
                        elif self._curve_type_51n == "IEC Extremely Inverse":
                            time = 80 * self._time_dial_51n / ((current / self._i_pickup_51n)**2 - 1)
                        else:  # Standard/Normal Inverse as default
                            time = 0.14 * self._time_dial_51n / ((current / self._i_pickup_51n)**0.02 - 1)
                        
                        ef_currents.append(current)
                        ef_times.append(time)
                    
                    plt.plot(ef_currents, ef_times, 'g-', linewidth=2, label=f'51N: {self._curve_type_51n}')
                    
                    # Add 50N instantaneous line
                    if self._i_pickup_50n > 0:
                        plt.axvline(x=self._i_pickup_50n, color='m', linestyle='--', 
                                 label=f'50N: {self._i_pickup_50n:.1f}A')
            
            # Set reasonable plot limits
            plt.xlim(self._i_pickup_51 * 0.5, self._fault_current_3ph * 1.5)
            plt.ylim(0.01, 10)
            
            # Add legend
            plt.legend(loc='upper right')
            
            # Save the figure and explicitly close all matplotlib resources
            plt.tight_layout()
            plt.savefig(filepath, dpi=150)
            plt.close('all')  # Close all figures to prevent resource leaks
            
            # Force garbage collection to clean up any remaining resources
            import gc
            gc.collect()
            
            return True
            
        except Exception as e:
            print(f"Error generating matplotlib chart: {e}")
            # Make sure to close any open figures even on error
            plt.close('all')
            return False