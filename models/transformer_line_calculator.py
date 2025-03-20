from PySide6.QtCore import QObject, Property, Signal, Slot
import math
import cmath

class TransformerLineCalculator(QObject):
    """Calculator for transformer-line system analysis including protection parameters"""

    # Define signals
    transformerChanged = Signal()
    lineChanged = Signal()
    loadChanged = Signal()
    calculationCompleted = Signal()  # Main signal
    calculationsComplete = Signal()  # Additional alias signal for QML compatibility
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Transformer parameters (400V/11kV)
        self._transformer_lv_voltage = 400.0  # V
        self._transformer_hv_voltage = 11000.0  # V
        self._transformer_rating = 1000.0  # kVA
        self._transformer_impedance = 6.0  # %
        self._transformer_x_r_ratio = 8.0  # X/R ratio
        
        # Line parameters (5km cable)
        self._line_length = 5.0  # km
        self._line_r = 0.25  # Ohm/km
        self._line_x = 0.20  # Ohm/km
        self._line_c = 0.3  # μF/km
        
        # Load parameters
        self._load_mva = 0.8  # MVA
        self._load_pf = 0.85  # Power factor
        
        # Calculated values
        self._transformer_z = 0.0  # Ohm
        self._transformer_r = 0.0  # Ohm
        self._transformer_x = 0.0  # Ohm
        self._line_total_z = 0.0  # Ohm
        self._voltage_drop = 0.0  # %
        self._fault_current_lv = 0.0  # kA
        self._fault_current_hv = 0.0  # kA
        self._relay_pickup_current = 0.0  # A
        self._relay_time_dial = 0.0
        self._relay_curve_type = "Very Inverse"
        self._relay_ct_ratio = "300/5"
        
        # Perform initial calculations
        self._calculate()
    
    def _calculate(self):
        """Calculate transformer-line-load parameters"""
        try:
            # 1. Calculate transformer impedance in Ohms (referred to HV side)
            transformer_z_pu = self._transformer_impedance / 100.0
            transformer_z_base = (self._transformer_hv_voltage**2) / (self._transformer_rating * 1000)
            self._transformer_z = transformer_z_pu * transformer_z_base
            
            # Calculate R and X components using X/R ratio
            angle = math.atan(self._transformer_x_r_ratio)
            self._transformer_r = self._transformer_z * math.cos(angle)
            self._transformer_x = self._transformer_z * math.sin(angle)
            
            # 2. Calculate line impedance
            self._line_total_z = complex(self._line_r * self._line_length, 
                                       self._line_x * self._line_length)
            
            # 3. Calculate charging current
            line_charging_current = 2 * math.pi * 50 * self._line_c * 1e-6 * self._transformer_hv_voltage * self._line_length
            
            # 4. Calculate voltage drop
            load_current = (self._load_mva * 1e6) / (math.sqrt(3) * self._transformer_hv_voltage)
            load_angle = math.acos(self._load_pf)
            load_current_complex = load_current * complex(math.cos(load_angle), -math.sin(load_angle))
            
            voltage_drop_complex = load_current_complex * (complex(self._transformer_r, self._transformer_x) + self._line_total_z)
            self._voltage_drop = (abs(voltage_drop_complex) / self._transformer_hv_voltage) * 100.0
            
            # 5. Calculate fault currents
            # LV fault current
            system_z_lv = 1.1 * 1e-6  # Assumed source impedance at LV (400V)
            fault_z_lv = system_z_lv + (complex(self._transformer_r, self._transformer_x) * 
                                     (self._transformer_lv_voltage/self._transformer_hv_voltage)**2)
            self._fault_current_lv = (self._transformer_lv_voltage / math.sqrt(3)) / abs(fault_z_lv) / 1000  # kA
            
            # HV fault current
            fault_z_hv = complex(self._transformer_r, self._transformer_x) + self._line_total_z
            self._fault_current_hv = (self._transformer_hv_voltage / math.sqrt(3)) / abs(fault_z_hv) / 1000  # kA
            
            # 6. Calculate relay settings
            # Set pickup current at 120% of full load current
            transformer_full_load_current = (self._transformer_rating * 1000) / (math.sqrt(3) * self._transformer_hv_voltage)
            self._relay_pickup_current = 1.2 * transformer_full_load_current
            
            # CT ratio selection (select standard ratio higher than pickup)
            ct_primary = math.ceil(self._relay_pickup_current / 100) * 100
            self._relay_ct_ratio = f"{ct_primary}/5"
            
            # Time dial setting (using typical Very Inverse curve)
            # Time dial depends on coordination study, using typical value
            self._relay_time_dial = 0.3
            
            # Emit completion signal - emit both signals for compatibility
            self.calculationCompleted.emit()
            self.calculationsComplete.emit()  # Backwards compatibility
            
        except Exception as e:
            print(f"Error in transformer-line calculations: {e}")
            
    @Property(float, notify=transformerChanged)
    def transformerRating(self):
        return self._transformer_rating
    
    @transformerRating.setter
    def transformerRating(self, value):
        if self._transformer_rating != value and value > 0:
            self._transformer_rating = value
            self.transformerChanged.emit()
            self._calculate()
    
    @Property(float, notify=transformerChanged)
    def transformerImpedance(self):
        return self._transformer_impedance
    
    @transformerImpedance.setter
    def transformerImpedance(self, value):
        if self._transformer_impedance != value and value > 0:
            self._transformer_impedance = value
            self.transformerChanged.emit()
            self._calculate()
    
    @Property(float, notify=transformerChanged)
    def transformerXRRatio(self):
        return self._transformer_x_r_ratio
    
    @transformerXRRatio.setter
    def transformerXRRatio(self, value):
        if self._transformer_x_r_ratio != value and value > 0:
            self._transformer_x_r_ratio = value
            self.transformerChanged.emit()
            self._calculate()
    
    @Property(float, notify=lineChanged)
    def lineLength(self):
        return self._line_length
    
    @lineLength.setter
    def lineLength(self, value):
        if self._line_length != value and value >= 0:
            self._line_length = value
            self.lineChanged.emit()
            self._calculate()
    
    @Property(float, notify=lineChanged)
    def lineR(self):
        return self._line_r
    
    @lineR.setter
    def lineR(self, value):
        if self._line_r != value and value >= 0:
            self._line_r = value
            self.lineChanged.emit()
            self._calculate()
    
    @Property(float, notify=lineChanged)
    def lineX(self):
        return self._line_x
    
    @lineX.setter
    def lineX(self, value):
        if self._line_x != value and value >= 0:
            self._line_x = value
            self.lineChanged.emit()
            self._calculate()
    
    @Property(float, notify=loadChanged)
    def loadMVA(self):
        return self._load_mva
    
    @loadMVA.setter
    def loadMVA(self, value):
        if self._load_mva != value and value >= 0:
            self._load_mva = value
            self.loadChanged.emit()
            self._calculate()
    
    @Property(float, notify=loadChanged)
    def loadPowerFactor(self):
        return self._load_pf
    
    @loadPowerFactor.setter
    def loadPowerFactor(self, value):
        if self._load_pf != value and 0 < value <= 1:
            self._load_pf = value
            self.loadChanged.emit()
            self._calculate()
    
    # Read-only results
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def transformerZOhms(self):
        return self._transformer_z
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def transformerROhms(self):
        return self._transformer_r
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def transformerXOhms(self):
        return self._transformer_x
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def lineTotalZ(self):
        return abs(self._line_total_z)
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def voltageDrop(self):
        return self._voltage_drop
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def faultCurrentLV(self):
        return self._fault_current_lv
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def faultCurrentHV(self):
        return self._fault_current_hv
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def relayPickupCurrent(self):
        return self._relay_pickup_current
    
    @Property(float, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def relayTimeDial(self):
        return self._relay_time_dial
    
    @Property(str, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def relayCtRatio(self):
        return self._relay_ct_ratio
    
    @Property(str, notify=calculationCompleted)  # Fix notify to use the renamed signal
    def relayCurveType(self):
        return self._relay_curve_type
    
    # QML slots for setters
    @Slot(float)
    def setTransformerRating(self, value):
        self.transformerRating = value
        
    @Slot(float)
    def setTransformerImpedance(self, value):
        self.transformerImpedance = value
        
    @Slot(float)
    def setTransformerXRRatio(self, value):
        self.transformerXRRatio = value
        
    @Slot(float)
    def setLineLength(self, value):
        self.lineLength = value
        
    @Slot(float)
    def setLineR(self, value):
        self.lineR = value
        
    @Slot(float)
    def setLineX(self, value):
        self.lineX = value
        
    @Slot(float)
    def setLoadMVA(self, value):
        self.loadMVA = value
        
    @Slot(float)
    def setLoadPowerFactor(self, value):
        self.loadPowerFactor = value
        
    @Slot()
    def refreshCalculations(self):
        """Force refresh of all calculations"""
        self._calculate()
        return True
