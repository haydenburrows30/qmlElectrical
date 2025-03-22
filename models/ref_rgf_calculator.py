from PySide6.QtCore import QObject, Signal, Property, Slot
import math

class RefRgfCalculator(QObject):
    """Calculator for REF (Relay Earth Fault) and RGF (Restricted Ground Fault) values"""

    calculationsComplete = Signal()
    
    # New signals for transformer and CT settings
    ctRatioChanged = Signal()
    transformerRatioChanged = Signal()
    transformerMvaChanged = Signal()
    connectionTypeChanged = Signal()
    ctSecondaryTypeChanged = Signal()
    impedanceChanged = Signal()
    faultPointChanged = Signal()
    faultPointFiveChanged = Signal()
    
    # New calculation result signals
    loadCurrentChanged = Signal()
    faultCurrentChanged = Signal()
    faultPointChanged = Signal()
    gDiffPickupChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Transformer and CT parameters
        self._ph_ct_ratio = 200  # Phase CT ratio
        self._n_ct_ratio = 200  # Neutral CT Ratio
        self._hv_transformer_voltage = 50  # hv transformer voltage in kv
        self._lv_transformer_voltage = 11  # lv transformer voltage in kv
        self._transformer_mva = 2.5  # Default transformer MVA
        self._connection_type = "Wye"  # Default transformer connection type
        self._ct_secondary_type = "5A"  # Default CT secondary type (5A or 1A)
        self._impedance = 6.33 # Impedance
        self._fault_point = 5.0 # Fault point

        # Calculated results
        self._g_diff_pickup = 0.5  # Ground diff pickup current
        self._load_current = 100
        self._fault_current = 0.0
        self._fault_point_five = 5.0 # Fault point
        
        # Initial calculation
        self._calculate()
    
    def _calculate(self):
        """Calculate all fault values"""
        try:
            # Calculate base current
            self._load_current = (self._transformer_mva * 1000000) / (math.sqrt(3) * self._lv_transformer_voltage * 1000)
            
            # Calculate fault currents
            self._fault_current = (self._transformer_mva * 1000000) / (math.sqrt(3) * self._lv_transformer_voltage * 1000 * (self._impedance / 100))
            self._fault_point_five = self._fault_current * (self._fault_point / 100)
            
            # Calculate REF and RGF values
            self._g_diff_pickup = self._fault_point_five / self._ph_ct_ratio

            self.calculationsComplete.emit()
            self.loadCurrentChanged.emit()
            self.faultPointChanged.emit()
            self.gDiffPickupChanged.emit()

        except Exception as e:
            print(f"Calculation error: {e}")
    
    @Property(float, notify=ctRatioChanged)
    def phCtRatio(self):
        return self._ph_ct_ratio
    
    @phCtRatio.setter
    def phCtRatio(self, value):
        if self._ph_ct_ratio != value:
            self._ph_ct_ratio = value
            self.ctRatioChanged.emit()
            self._calculate()

    @Property(float, notify=ctRatioChanged)
    def nCtRatio(self):
        return self._n_ct_ratio
    
    @nCtRatio.setter
    def nCtRatio(self, value):
        if self._n_ct_ratio != value:
            self._n_ct_ratio = value
            self.ctRatioChanged.emit()
            self._calculate()

    @Property(float, notify=impedanceChanged)
    def impedance(self):
        return self._impedance
    
    @impedance.setter
    def impedance(self, value):
        if self._impedance != value:
            self._impedance = value
            self.impedanceChanged.emit()
            self._calculate()

    @Property(float, notify=faultPointChanged)
    def faultPoint(self):
        return self._fault_point
    
    @faultPoint.setter
    def faultPoint(self, value):
        if self._fault_point != value:
            self._fault_point = value
            self.faultPointChanged.emit()
            self._calculate()
    
    @Property(float, notify=transformerRatioChanged)
    def hvTransformerVoltage(self):
        return self._hv_transformer_voltage
    
    @hvTransformerVoltage.setter
    def hvTransformerVoltage(self, value):
        if self._hv_transformer_voltage != value:
            self._hv_transformer_voltage = value
            self.transformerRatioChanged.emit()
            self._calculate()

    @Property(float, notify=transformerRatioChanged)
    def lvTransformerVoltage(self):
        return self._lv_transformer_voltage
    
    @lvTransformerVoltage.setter
    def lvTransformerVoltage(self, value):
        if self._lv_transformer_voltage != value:
            self._lv_transformer_voltage = value
            self.transformerRatioChanged.emit()
            self._calculate()
    
    @Property(float, notify=transformerMvaChanged)
    def transformerMva(self):
        return self._transformer_mva
    
    @transformerMva.setter
    def transformerMva(self, value):
        if value > 0 and self._transformer_mva != value:
            self._transformer_mva = value
            self.transformerMvaChanged.emit()
            self._calculate()
    
    @Property(str, notify=connectionTypeChanged)
    def connectionType(self):
        return self._connection_type
    
    @connectionType.setter
    def connectionType(self, value):
        if self._connection_type != value:
            self._connection_type = value
            self.connectionTypeChanged.emit()
            self._calculate()
    
    @Property(str, notify=ctSecondaryTypeChanged)
    def ctSecondaryType(self):
        return self._ct_secondary_type
    
    @ctSecondaryType.setter
    def ctSecondaryType(self, value):
        if self._ct_secondary_type != value:
            self._ct_secondary_type = value
            self.ctSecondaryTypeChanged.emit()
            self._calculate()
    
    # Result properties
    
    @Property(float, notify=loadCurrentChanged)
    def loadCurrent(self):
        return self._load_current
    
    @Property(float, notify=faultCurrentChanged)
    def faultCurrent(self):
        return self._fault_current
    
    @Property(float, notify=faultPointFiveChanged)
    def faultPointFive(self):
        return self._fault_point_five
    
    @Property(float, notify=gDiffPickupChanged)
    def gDiffPickup(self):
        return self._g_diff_pickup
    
    # Slots for direct QML access
    
    @Slot(float)
    def setPhCtRatio(self, value):
        self.phCtRatio = value
    
    @Slot(float)
    def setNCtRatio(self, value):
        self.nCtRatio = value
    
    @Slot(float)
    def setTransformerMva(self, value):
        self.transformerMva = value
    
    @Slot(str)
    def setConnectionType(self, value):
        self.connectionType = value
    
    @Slot(str)
    def setCtSecondaryType(self, value):
        self.ctSecondaryType = value
    
    @Slot(float)
    def setHvTransformerVoltage(self, value):
        self.hvTransformerVoltage = value

    @Slot(float)
    def setLvTransformerVoltage(self, value):
        self.lvTransformerVoltage = value

    @Slot(float)
    def setImpedance(self, value):
        self.impedance = value

    @Slot(float)
    def setFaultPoint(self, value):
        self.faultPoint = value
    
    @Slot()
    def calculate(self):
        self._calculate()
