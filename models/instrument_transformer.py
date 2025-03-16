from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class InstrumentTransformerCalculator(QObject):
    """Calculator for CT and VT parameters"""

    primaryCurrentChanged = Signal()
    secondaryCurrentChanged = Signal()
    primaryVoltageChanged = Signal()
    secondaryVoltageChanged = Signal()
    burdenChanged = Signal()
    accuracyChanged = Signal()
    calculationsComplete = Signal()
    standardCtRatiosChanged = Signal()
    standardVtRatiosChanged = Signal()
    accuracyClassesChanged = Signal()  # New signal

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
                self._knee_point_voltage = (knee_multiplier * 
                    self._secondary_current * 
                    math.sqrt(self._burden_va) * 
                    base_factor * 
                    voltage_factor)
                
                # Adjust ALF for protection class
                if self._current_ct_type == "protection":
                    # Extract ALF from accuracy class (e.g., "5P20" -> 20)
                    if "P" in self._accuracy_class:
                        self._alf = float(self._accuracy_class.split("P")[1])
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
                base_error = float(self._accuracy_class.split('P')[0])
            elif self._current_ct_type == "combined":
                # For combined class, use measurement part (e.g., 0.5/5P10 -> 0.5)
                base_error = float(self._accuracy_class.split('/')[0])
            else:
                base_error = float(self._accuracy_class)
                
            pf_compensation = (1 - self._power_factor) * base_error * 0.5
            temp_compensation = self._temperature_effect * 0.5
            self._error_margin = base_error + pf_compensation + temp_compensation
            
            # Adjust knee point voltage for temperature
            temp_factor = 1 + (temp_diff * self._temp_coefficient)
            self._knee_point_voltage *= temp_factor

            # VT calculations
            if self._primary_voltage > 0 and self._secondary_voltage > 0:
                vt_ratio = self._primary_voltage / self._secondary_voltage
                
                # Calculate VT rated voltage
                rated_factor = self._rated_voltage_factors.get(self._rated_voltage_factor, 1.2)
                self._rated_secondary_voltage = self._secondary_voltage * rated_factor
                
                # Calculate VT burden impedance
                self._vt_impedance = (self._vt_burden / (self._secondary_voltage ** 2)) * 1000  # in ohms
                
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
                
                # Calculate burden utilization percentage
                self._vt_burden_utilization = (self._vt_burden / burden_range["max"]) * 100
                
                # Adjust existing calculations with VT effects
                if self._current_ct_type == "protection":
                    # Higher voltage CTs need more margin
                    self._knee_point_voltage *= (1 + (vt_ratio / 1000))
                    self._min_accuracy_burden *= (1 + (vt_ratio / 10000))
            
            self.calculationsComplete.emit()
            
        except Exception as e:
            print(f"Calculation error: {e}")
            self._knee_point_voltage = 0.0
            self._max_fault_current = 0.0
            self._min_accuracy_burden = 0.0

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
            self.primaryCurrent = primary
            self._secondary_current = secondary
            self._calculate()
        except:
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
