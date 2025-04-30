from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class InstrumentTransformerCalculator(QObject):
    """Calculator for CT and VT parameters"""

    # Existing signals
    primaryCurrentChanged = Signal()
    secondaryCurrentChanged = Signal()
    primaryVoltageChanged = Signal()
    secondaryVoltageChanged = Signal()
    burdenChanged = Signal()
    accuracyChanged = Signal()
    calculationsComplete = Signal()
    standardCtRatiosChanged = Signal()
    standardVtRatiosChanged = Signal()
    accuracyClassesChanged = Signal()
    
    # New signals
    validationError = Signal(str)
    resetCompleted = Signal()
    saturationCurveChanged = Signal()
    harmonicsChanged = Signal()
    pdfExportStatusChanged = Signal(bool, str)  # Add new signal for PDF export status

    def __init__(self, parent=None):
        super().__init__(parent)
        self._primary_current = 100.0
        self._secondary_current = 5.0
        self._primary_voltage = 11000.0
        self._secondary_voltage = 110.0
        self._burden_va = 15.0
        self._accuracy_class = "0.5"
        self._protection_class = ""  # For combined classes like 0.5/5P10
        
        # Combined accuracy classes
        self._accuracy_classes = {
            "measurement": ["0.1", "0.2", "0.5", "1.0"],
            "protection": ["5P10", "5P20", "10P10", "10P20"],
            "combined": ["0.2/5P10", "0.5/5P10", "0.5/5P20", "0.2/10P10", "0.5/10P20"]
        }
        
        # Accuracy factors now include protection classes
        self._accuracy_factors = {
            "0.1": 1.5,
            "0.2": 1.3,
            "0.5": 1.2,
            "1.0": 1.1,
            "5P10": 2.0,  # Higher factors for protection class
            "5P20": 2.5,
            "10P10": 3.0,
            "10P20": 3.5
        }
        
        self._ct_ratio = 20.0
        self._vt_ratio = 100.0
        self._knee_point_voltage = 0.0
        self._min_accuracy_burden = 0.0  # Initialize missing attribute
        self._alf = 20.0
        
        self._standard_ct_ratios = [
            "5/5", "10/5", "15/5", "20/5", "25/5", "30/5", "40/5", "50/5",
            "60/5", "75/5", "100/5", "150/5", "200/5", "300/5", "400/5",
            "500/5", "600/5", "800/5", "1000/5", "1200/5", "1500/5", "2000/5"
        ]
        
        self._protection_ct_ratios = [
            "100/1", "200/1", "400/1", "600/1", "800/1", "1000/1", 
            "1200/1", "1500/1", "2000/1", "3000/1", "4000/1", "5000/1"
        ]
        
        self._current_ct_type = "measurement"  # or "protection"
        
        self._standard_vt_ratios = [
            "11000/110", "22000/110", "33000/110", "66000/110",
            "110000/110", "132000/110", "220000/110", "400000/110"
        ]
        
        self._power_factor = 0.8
        self._temperature = 25.0
        self._error_margin = 0.0
        self._temperature_effect = 0.0
        self._reference_temp = 25.0
        self._temp_coefficient = 0.004  # 0.4% per degree C

        # Voltage level factors for knee point adjustment
        self._voltage_level_factors = {
            11000: 1.0,    # Base reference
            22000: 1.2,
            33000: 1.5,
            66000: 2.0,
            110000: 2.5,
            132000: 2.8,
            220000: 3.5,
            400000: 4.0
        }

        # VT specific properties
        self._vt_accuracy_classes = {
            "measurement": ["0.1", "0.2", "0.5", "1.0"],
            "protection": ["3P", "6P"],
            "combined": ["0.2/3P", "0.5/3P", "1.0/3P"]
        }
        
        self._vt_burden_ranges = {
            11000: {"min": 25, "max": 100},
            22000: {"min": 50, "max": 200},
            33000: {"min": 100, "max": 300},
            66000: {"min": 200, "max": 500},
            110000: {"min": 300, "max": 750},
            220000: {"min": 500, "max": 1000},
            400000: {"min": 1000, "max": 2000}
        }
        
        self._rated_voltage_factors = {
            "continuous": 1.2,
            "30s": 1.5,
            "ground_fault": 1.9
        }
        
        self._vt_burden = 100.0  # VA
        self._vt_accuracy_class = "0.5"
        self._rated_voltage_factor = "continuous"

        # Save default values for reset functionality
        self._default_values = {
            "primary_current": 100.0,
            "secondary_current": 5.0,
            "primary_voltage": 11000.0,
            "secondary_voltage": 110.0,
            "burden_va": 15.0,
            "accuracy_class": "0.5",
            "power_factor": 0.8,
            "temperature": 25.0,
            "vt_burden": 100.0,
            "rated_voltage_factor": "continuous",
            "current_ct_type": "measurement"
        }
        
        # Add harmonics analysis data
        self._harmonics = {
            "1st": 100.0,  # Fundamental (%)
            "3rd": 0.0,    # 3rd harmonic (%)
            "5th": 0.0,    # 5th harmonic (%)
            "7th": 0.0     # 7th harmonic (%)
        }
        
        # Saturation curve data points
        self._saturation_curve = []
        
        # Initialize FileSaver
        from services.file_saver import FileSaver
        self._file_saver = FileSaver()
        
        # Connect file saver signal to our pdfExportStatusChanged signal
        self._file_saver.saveStatusChanged.connect(self.pdfExportStatusChanged)
        
        self._calculate()

    @Property(float, notify=primaryVoltageChanged)
    def primaryVoltage(self):
        return self._primary_voltage

    @primaryVoltage.setter
    def primaryVoltage(self, value):
        if value > 0:
            self._primary_voltage = value
            self.primaryVoltageChanged.emit()
            self._calculate()

    @Property(str, notify=accuracyChanged)
    def accuracyClass(self):
        return self._accuracy_class

    @accuracyClass.setter
    def accuracyClass(self, value):
        if self._accuracy_class != value:
            self._accuracy_class = value
            self.accuracyChanged.emit()
            self._calculate()

    @Property(float)
    def powerFactor(self):
        return self._power_factor

    @powerFactor.setter
    def powerFactor(self, value):
        if 0 < value <= 1:
            self._power_factor = value
            self._calculate()

    @Property(float)
    def temperature(self):
        return self._temperature

    @temperature.setter
    def temperature(self, value):
        self._temperature = value
        self._calculate()

    @Property(float, notify=calculationsComplete)
    def errorMargin(self):
        return self._error_margin

    @Property(float, notify=calculationsComplete)
    def temperatureEffect(self):
        return self._temperature_effect

    def _calculate(self):
        """Calculate transformer parameters based on inputs"""
        try:
            if self._primary_current > 0 and self._secondary_current > 0:
                # Get accuracy factor based on CT type
                if self._current_ct_type == "protection":
                    base_factor = self._accuracy_factors.get(self._accuracy_class, 2.0)
                    # Protection CTs have higher knee points
                    knee_multiplier = 3.0
                    
                    # Additional multiplier for high voltage protection CTs
                    voltage_factor = 1.0
                    if self._primary_voltage >= 66000:
                        # Find closest voltage level
                        closest_voltage = min(self._voltage_level_factors.keys(), 
                                           key=lambda x: abs(x - self._primary_voltage))
                        voltage_factor = self._voltage_level_factors[closest_voltage]
                        
                        # Additional factor for high ratio CTs
                        if self._ct_ratio > 1000:
                            voltage_factor *= 1.2
                else:
                    base_factor = self._accuracy_factors.get(self._accuracy_class, 1.2)
                    knee_multiplier = 2.0
                    voltage_factor = 1.0
                
                # Adjusted knee point calculation including voltage level effects
                if self._burden_va > 0:  # Add check to prevent math domain error
                    self._knee_point_voltage = (knee_multiplier * 
                        self._secondary_current * 
                        math.sqrt(self._burden_va) * 
                        base_factor * 
                        voltage_factor)
                else:
                    self._knee_point_voltage = 0.0
                
                # Calculate minimum accuracy burden
                self._min_accuracy_burden = (self._knee_point_voltage / (20 * self._secondary_current))
                
                # Adjust ALF for protection class
                if self._current_ct_type == "protection":
                    # Extract ALF from accuracy class (e.g., "5P20" -> 20)
                    if "P" in self._accuracy_class:
                        # Fix: Extract the number after P properly
                        try:
                            self._alf = float(self._accuracy_class.split("P")[1])
                        except (ValueError, IndexError):
                            # Default ALF if conversion fails
                            self._alf = 20.0
                    else:
                        self._alf = 20.0
                
                self._max_fault_current = self._primary_current * self._alf
                
                # VT affects calculations
                if self._primary_voltage > 0 and self._secondary_voltage > 0:
                    vt_ratio = self._primary_voltage / self._secondary_voltage
                    self._knee_point_voltage *= (1 + (vt_ratio / 1000))
                    self._min_accuracy_burden *= (1 + (vt_ratio / 10000))
            
            # Calculate temperature effect
            temp_diff = self._temperature - self._reference_temp
            self._temperature_effect = abs(temp_diff * self._temp_coefficient * 100)
            
            # Calculate error margin considering power factor
            if self._current_ct_type == "protection":
                # For protection class, extract number after P (e.g., 5P20 -> 5)
                try:
                    if "P" in self._accuracy_class:
                        base_error = float(self._accuracy_class.split('P')[0])
                    else:
                        base_error = 5.0  # Default for protection class
                except (ValueError, IndexError):
                    base_error = 5.0  # Default if conversion fails
            elif self._current_ct_type == "combined":
                # For combined class, use measurement part (e.g., 0.5/5P10 -> 0.5)
                try:
                    if "/" in self._accuracy_class:
                        base_error = float(self._accuracy_class.split('/')[0])
                    else:
                        base_error = 0.5  # Default for combined class
                except (ValueError, IndexError):
                    base_error = 0.5  # Default if conversion fails
            else:
                try:
                    base_error = float(self._accuracy_class)
                except (ValueError, IndexError):
                    base_error = 0.5  # Default for measurement class
                
            # Ensure base_error is not zero to prevent calculation issues
            base_error = max(0.1, base_error)
            
            pf_compensation = (1 - self._power_factor) * base_error * 0.5
            temp_compensation = self._temperature_effect * 0.5
            self._error_margin = base_error + pf_compensation + temp_compensation
            
            # Adjust knee point voltage for temperature
            temp_factor = 1 + (temp_diff * self._temp_coefficient)
            self._knee_point_voltage *= temp_factor

            # VT calculations
            if self._primary_voltage > 0 and self._secondary_voltage > 0:
                vt_ratio = self._primary_voltage / self._secondary_voltage
                
                # Initialize variables to prevent reference errors
                self._vt_burden_status = ""
                self._vt_burden_within_range = False
                self._vt_burden_utilization = 0.0
                
                # Calculate VT rated voltage
                rated_factor = self._rated_voltage_factors.get(self._rated_voltage_factor, 1.2)
                self._rated_secondary_voltage = self._secondary_voltage * rated_factor
                
                # Calculate VT burden impedance (prevent division by zero)
                if self._secondary_voltage > 0:
                    self._vt_impedance = (self._vt_burden / (self._secondary_voltage ** 2)) * 1000  # in ohms
                else:
                    self._vt_impedance = 0.0
                
                # Find recommended burden range and detailed status
                closest_voltage = min(self._vt_burden_ranges.keys(), 
                                   key=lambda x: abs(x - self._primary_voltage))
                burden_range = self._vt_burden_ranges[closest_voltage]
                
                if self._vt_burden < burden_range["min"]:
                    self._vt_burden_status = f"Under-burdened (min: {burden_range['min']} VA)"
                    self._vt_burden_within_range = False
                elif self._vt_burden > burden_range["max"]:
                    self._vt_burden_status = f"Over-burdened (max: {burden_range['max']} VA)"
                    self._vt_burden_within_range = False
                else:
                    self._vt_burden_status = f"Within range ({burden_range['min']}-{burden_range['max']} VA)"
                    self._vt_burden_within_range = True
                
                # Calculate burden utilization percentage (prevent division by zero)
                if burden_range["max"] > 0:
                    self._vt_burden_utilization = (self._vt_burden / burden_range["max"]) * 100
                else:
                    self._vt_burden_utilization = 0.0
                
                # Adjust existing calculations with VT effects
                if self._current_ct_type == "protection":
                    # Higher voltage CTs need more margin
                    self._knee_point_voltage *= (1 + (vt_ratio / 1000))
                    self._min_accuracy_burden *= (1 + (vt_ratio / 10000))
            
            # Generate saturation curve data
            self._saturation_curve = self._calculate_saturation_curve()
            
            # Calculate harmonic effects based on saturation level
            self._calculate_harmonics()
            
            self.calculationsComplete.emit()
            self.saturationCurveChanged.emit()
            self.harmonicsChanged.emit()
            
        except Exception as e:
            print(f"Calculation error: {e}")
            self.validationError.emit(f"Calculation error: {str(e)}")
            self._knee_point_voltage = 0.0
            self._max_fault_current = 0.0
            self._min_accuracy_burden = 0.0

    def _calculate_saturation_curve(self):
        """Generate CT saturation curve data points"""
        curve_points = []
        if self._knee_point_voltage > 0:
            # Generate 20 points for the curve
            for i in range(21):
                # Normalized voltage (0 to 2 times knee point)
                v_norm = i * 0.1 * self._knee_point_voltage * 2
                
                # Linear region (below knee point)
                if v_norm <= self._knee_point_voltage:
                    i_norm = v_norm / (0.1 * self._secondary_current) if self._secondary_current > 0 else 0
                else:
                    # Saturation region (above knee point)
                    # I = k * (V - Vknee)^0.3 + Iknee
                    excess = v_norm - self._knee_point_voltage
                    i_norm = self._secondary_current + 2 * math.pow(excess / max(0.001, self._knee_point_voltage), 0.3) * self._secondary_current
                    
                curve_points.append({"voltage": v_norm, "current": i_norm})
        return curve_points

    def _calculate_harmonics(self):
        """Calculate harmonic content based on CT saturation"""
        # Start with clean signal
        self._harmonics = {
            "1st": 100.0,  # Fundamental always present
            "3rd": 0.0,
            "5th": 0.0,
            "7th": 0.0
        }
        
        # If we have a burden and knee point, calculate harmonics
        if self._burden_va > 0 and self._knee_point_voltage > 0:
            # Estimate operating point as a fraction of knee point
            op_voltage = self._secondary_current * math.sqrt(self._burden_va)
            saturation_level = op_voltage / self._knee_point_voltage
            
            # Harmonics increase with saturation
            if saturation_level > 0.8:
                # Highly saturated - significant harmonics
                self._harmonics["3rd"] = min(40.0, (saturation_level - 0.8) * 200)
                self._harmonics["5th"] = min(20.0, (saturation_level - 0.8) * 100)
                self._harmonics["7th"] = min(10.0, (saturation_level - 0.8) * 50)
            elif saturation_level > 0.5:
                # Moderately saturated - some harmonics
                self._harmonics["3rd"] = (saturation_level - 0.5) * 100
                self._harmonics["5th"] = (saturation_level - 0.5) * 50
                self._harmonics["7th"] = (saturation_level - 0.5) * 25

    @Property(list, notify=standardCtRatiosChanged)
    def standardCtRatios(self):
        return self._protection_ct_ratios if self._current_ct_type == "protection" else self._standard_ct_ratios

    @Property(list, notify=standardVtRatiosChanged)
    def standardVtRatios(self):
        return self._standard_vt_ratios

    @Property(float, notify=primaryCurrentChanged)
    def primaryCurrent(self):
        return self._primary_current
    
    @primaryCurrent.setter
    def primaryCurrent(self, current):
        if current > 0:
            self._primary_current = current
            self.primaryCurrentChanged.emit()
            self._calculate()

    @Property(float, notify=burdenChanged)
    def burden(self):
        return self._burden_va
    
    @burden.setter
    def burden(self, va):
        if va > 0:
            self._burden_va = va
            self.burdenChanged.emit()
            self._calculate()

    @Property(float, notify=calculationsComplete)
    def kneePointVoltage(self):
        return self._knee_point_voltage

    @Property(float, notify=calculationsComplete)
    def maxFaultCurrent(self):
        return self._max_fault_current

    @Property(float, notify=calculationsComplete)
    def minAccuracyBurden(self):
        return self._min_accuracy_burden

    @Property(str)
    def currentCtType(self):
        return self._current_ct_type

    @currentCtType.setter
    def currentCtType(self, ct_type):
        if ct_type in ["measurement", "protection", "combined"]:  # Add combined
            self._current_ct_type = ct_type
            self.standardCtRatiosChanged.emit()
            self.accuracyClassesChanged.emit()  # Emit when type changes

    @Slot(str)
    def setCtRatio(self, ratio):
        """Set CT ratio from standard format (e.g., '100/5')"""
        try:
            primary, secondary = map(float, ratio.split('/'))
            self._primary_current = primary
            self._secondary_current = secondary
            
            # Calculate CT ratio for scaling
            self._ct_ratio = primary / secondary
            
            # Recalculate knee point voltage based on ratio
            if self._current_ct_type == "protection":
                # Scale knee point multiplier based on ratio
                ratio_factor = self._ct_ratio / 20  # Normalize to 100/5 ratio
                knee_multiplier = 2.0 + math.log10(max(1, ratio_factor))
                
                # Additional multiplier for high ratio CTs
                if primary > 1000:
                    knee_multiplier *= 1.5
                    
                # Protection class affects base accuracy factor
                base_factor = self._accuracy_factors.get(self._accuracy_class, 2.0)
                
                # Calculate new knee point
                if self._burden_va > 0:
                    self._knee_point_voltage = (knee_multiplier * 
                        self._secondary_current * 
                        math.sqrt(self._burden_va) * 
                        base_factor)
                    
                    # Emit that calculations are complete
                    self.calculationsComplete.emit()
            
            self._calculate()
            self.primaryCurrentChanged.emit()
            
        except Exception as e:
            print(f"Error setting CT ratio: {e}")
            pass

    @Slot(str)
    def setVtRatio(self, ratio):
        """Set VT ratio from standard format (e.g., '11000/110')"""
        try:
            primary, secondary = map(float, ratio.split('/'))
            self._primary_voltage = primary
            self._secondary_voltage = secondary
            self._calculate()
        except:
            pass

    @Slot(float)
    def setBurden(self, va):
        self.burden = va

    @Property(list, notify=accuracyClassesChanged)  # Add notify signal
    def availableAccuracyClasses(self):
        """Return accuracy classes based on CT type"""
        if self._current_ct_type == "protection":
            return self._accuracy_classes["protection"]
        elif self._current_ct_type == "combined":
            return self._accuracy_classes["combined"]
        return self._accuracy_classes["measurement"]

    # Add new properties for VT calculations
    @Property(float, notify=calculationsComplete)
    def vtRatedVoltage(self):
        return self._rated_secondary_voltage

    @Property(float, notify=calculationsComplete)
    def vtImpedance(self):
        return self._vt_impedance

    @Property(bool, notify=calculationsComplete)
    def vtBurdenWithinRange(self):
        return self._vt_burden_within_range

    @Property(float, notify=burdenChanged)
    def vtBurden(self):
        return self._vt_burden
    
    @vtBurden.setter
    def vtBurden(self, va):
        if va > 0:
            self._vt_burden = va
            self.burdenChanged.emit()
            self._calculate()

    @Property(str, notify=calculationsComplete)
    def vtBurdenStatus(self):
        """Return detailed burden status message"""
        return self._vt_burden_status

    @Property(float, notify=calculationsComplete)
    def vtBurdenUtilization(self):
        """Return burden utilization as percentage"""
        return self._vt_burden_utilization

    @Property(str)
    def ratedVoltageFactor(self):
        return self._rated_voltage_factor
    
    @ratedVoltageFactor.setter
    def ratedVoltageFactor(self, factor):
        if factor in self._rated_voltage_factors:
            self._rated_voltage_factor = factor
            self._calculate()

    @Slot()
    def resetToDefaults(self):
        """Reset all parameters to default values"""
        self._primary_current = self._default_values["primary_current"]
        self._secondary_current = self._default_values["secondary_current"]
        self._primary_voltage = self._default_values["primary_voltage"]
        self._secondary_voltage = self._default_values["secondary_voltage"]
        self._burden_va = self._default_values["burden_va"]
        self._accuracy_class = self._default_values["accuracy_class"]
        self._power_factor = self._default_values["power_factor"]
        self._temperature = self._default_values["temperature"]
        self._vt_burden = self._default_values["vt_burden"]
        self._rated_voltage_factor = self._default_values["rated_voltage_factor"]
        self._current_ct_type = self._default_values["current_ct_type"]
        
        self._calculate()
        self.resetCompleted.emit()
        self.primaryCurrentChanged.emit()
        self.burdenChanged.emit()
        self.primaryVoltageChanged.emit()
        self.standardCtRatiosChanged.emit()
        self.accuracyClassesChanged.emit()

    @Property(list, notify=saturationCurveChanged)
    def saturationCurve(self):
        """Return the saturation curve data for visualization"""
        return self._saturation_curve
    
    @Property("QVariantMap", notify=harmonicsChanged)
    def harmonics(self):
        """Return harmonic content for visualization"""
        return self._harmonics
        
    @Slot(str, float, result=bool)
    def validateInput(self, field, value):
        """Validate input values with specific constraints"""
        try:
            if field == "burden":
                if value < 3.0 or value > 100.0:
                    self.validationError.emit(f"Burden must be between 3.0 and 100.0 VA")
                    return False
            elif field == "vtBurden":
                if value < 25.0 or value > 2000.0:
                    self.validationError.emit(f"VT Burden must be between 25.0 and 2000.0 VA")
                    return False
            elif field == "temperature":
                if value < -40.0 or value > 120.0:
                    self.validationError.emit(f"Temperature must be between -40.0 and 120.0 °C")
                    return False
            # Add more validation as needed
            return True
        except Exception as e:
            self.validationError.emit(f"Validation error: {str(e)}")
            return False
    
    @Slot(float, result=float)
    def convertCtoF(self, celsius):
        """Convert Celsius to Fahrenheit"""
        try:
            return (celsius * 9/5) + 32
        except:
            return 0.0
    
    @Slot(float, result=float)
    def convertFtoC(self, fahrenheit):
        """Convert Fahrenheit to Celsius"""
        try:
            return (fahrenheit - 32) * 5/9
        except:
            return 0.0
            
    @Property(float, notify=calculationsComplete)
    def saturationFactor(self):
        """Calculate and return CT saturation factor"""
        if self._burden_va > 0 and self._knee_point_voltage > 0:
            op_voltage = self._secondary_current * math.sqrt(self._burden_va)
            return op_voltage / self._knee_point_voltage
        return 0.0
    
    @Property(str, notify=calculationsComplete)
    def saturationStatus(self):
        """Return CT saturation status as a string"""
        saturation = self.saturationFactor
        if saturation < 0.2:
            return "Linear (Unsaturated)"
        elif saturation < 0.5:
            return "Slightly Saturated"
        elif saturation < 0.8:
            return "Moderately Saturated"
        else:
            return "Highly Saturated"
            
    @Property(str, notify=calculationsComplete)
    def accuracyRecommendation(self):
        """Provides recommendations for improving accuracy"""
        messages = []
        
        # Error margin exceeds accuracy class
        if self._error_margin > float(self._accuracy_class.split('/')[0].split('P')[0]):
            messages.append("Error margin exceeds accuracy class.")
            
            # Check potential causes
            if abs(self._temperature - self._reference_temp) > 20:
                messages.append("Consider operating closer to reference temperature (25°C).")
                
            if self._power_factor < 0.8:
                messages.append("Improve power factor for better accuracy.")
                
        # CT saturation issues
        saturation = self.saturationFactor
        if saturation > 0.8:
            messages.append("CT is operating near saturation. Consider higher burden or different CT ratio.")
        
        # VT burden issues
        if not self._vt_burden_within_range:
            if self._vt_burden < self._vt_burden_ranges[min(self._vt_burden_ranges.keys(), 
                             key=lambda x: abs(x - self._primary_voltage))]["min"]:
                messages.append("VT is under-burdened. Consider increasing the burden.")
            else:
                messages.append("VT is over-burdened. Consider decreasing the burden or using a VT with higher VA rating.")
        
        return "\n".join(messages) if messages else "No issues detected. Operation within specifications."
    
    @Property(list, notify=calculationsComplete)
    def environmentalFactors(self):
        """Return data about environmental effects"""
        return [
            {"factor": "Temperature Deviation", "value": abs(self._temperature - self._reference_temp), 
             "unit": "°C", "effect": self._temperature_effect},
            {"factor": "Power Quality", "value": 100 - self._harmonics["3rd"] - self._harmonics["5th"] - self._harmonics["7th"], 
             "unit": "%", "effect": sum([self._harmonics[h] for h in ["3rd", "5th", "7th"]]) * 0.05},
            {"factor": "Saturation", "value": self.saturationFactor * 100, 
             "unit": "%", "effect": self.saturationFactor * 5 if self.saturationFactor > 0.5 else 0}
        ]
    
    @Slot()
    def exportToPdf(self):
        """Export instrument transformer calculations to PDF"""
        try:
            from datetime import datetime
            import tempfile
            import os
            
            # Create timestamp for filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            # Get save location using FileSaver
            pdf_file = self._file_saver.get_save_filepath("pdf", f"instrument_transformer_{timestamp}")
            if not pdf_file:
                self.pdfExportStatusChanged.emit(False, "PDF export canceled")
                return False
            
            # Clean up and ensure proper filepath extension
            pdf_file = self._file_saver.clean_filepath(pdf_file)
            pdf_file = self._file_saver.ensure_file_extension(pdf_file, "pdf")
            
            # Create temporary directory for chart images
            temp_dir = tempfile.mkdtemp()
            chart_image_path = os.path.join(temp_dir, "saturation_curve.png")
            harmonics_image_path = os.path.join(temp_dir, "harmonics.png")
            
            # Import the PDF generator
            from utils.pdf.pdf_generator_instrument_transformer import InstrumentTransformerPdfGenerator
            pdf_generator = InstrumentTransformerPdfGenerator()
            
            # Generate charts first
            saturation_generated = pdf_generator.generate_saturation_curve(
                {
                    'knee_point_voltage': self._knee_point_voltage,
                    'secondary_current': self._secondary_current,
                    'saturation_curve': self._saturation_curve,
                    'ct_ratio': f"{self._primary_current}/{self._secondary_current}",
                    'accuracy_class': self._accuracy_class
                },
                chart_image_path
            )
            
            harmonics_generated = pdf_generator.generate_harmonics_chart(
                {
                    'harmonics': self._harmonics,
                    'saturation_status': self.saturationStatus,
                    'saturation_factor': self.saturationFactor
                },
                harmonics_image_path
            )
            
            # Prepare data for PDF generation
            data = {
                # CT parameters
                'ct_type': self._current_ct_type.capitalize(),
                'ct_ratio': f"{self._primary_current}/{self._secondary_current}",
                'ct_burden': self._burden_va,
                'power_factor': self._power_factor,
                'temperature': self._temperature,
                'accuracy_class': self._accuracy_class,
                
                # CT results
                'knee_point_voltage': self._knee_point_voltage,
                'max_fault_current': self._max_fault_current,
                'min_accuracy_burden': self._min_accuracy_burden,
                'error_margin': self._error_margin,
                'temperature_effect': self._temperature_effect,
                'saturation_status': self.saturationStatus,
                'saturation_factor': self.saturationFactor,
                'harmonics': self._harmonics,
                
                # VT parameters
                'vt_ratio': f"{self._primary_voltage}/{self._secondary_voltage}",
                'vt_burden': self._vt_burden,
                'rated_voltage_factor': self._rated_voltage_factor,
                
                # VT results
                'vt_rated_voltage': getattr(self, '_rated_secondary_voltage', 0),
                'vt_impedance': getattr(self, '_vt_impedance', 0),
                'vt_burden_status': getattr(self, '_vt_burden_status', ''),
                'vt_burden_utilization': getattr(self, '_vt_burden_utilization', 0),
                
                # Additional info
                'accuracy_recommendation': self.accuracyRecommendation,
                'environmental_factors': self.environmentalFactors,
                
                # Chart images
                'chart_image_path': chart_image_path if saturation_generated and os.path.exists(chart_image_path) else None,
                'harmonics_image_path': harmonics_image_path if harmonics_generated and os.path.exists(harmonics_image_path) else None
            }
            
            # Generate the PDF
            success = pdf_generator.generate_report(data, pdf_file)
            
            # Clean up temporary files
            try:
                if os.path.exists(chart_image_path):
                    os.unlink(chart_image_path)
                if os.path.exists(harmonics_image_path):
                    os.unlink(harmonics_image_path)
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
            error_msg = f"Error exporting to PDF: {str(e)}"
            print(error_msg)
            self.pdfExportStatusChanged.emit(False, error_msg)
            return False
