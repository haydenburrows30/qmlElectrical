from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class FaultCurrentCalculator(QObject):
    """Calculator for fault current analysis including system, transformer and cable impedances"""
    
    # Define signals for QML
    calculationComplete = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # System parameters
        self._system_voltage = 11.0  # kV
        self._system_mva = 500.0  # MVA
        self._transformer_mva = 5.0  # MVA
        self._transformer_z = 6.0  # %
        self._cable_length = 0.5  # km
        self._cable_z = 0.25  # Ω/km
        self._xr_ratio = 15.0  # X/R ratio
        self._fault_type = "3-Phase"
        
        # Calculated results
        self._initial_sym_current = 0.0  # kA
        self._peak_fault_current = 0.0  # kA
        self._breaking_current = 0.0  # kA
        self._thermal_current = 0.0  # kA
        self._total_impedance = 0.0  # Ω
        
        # Initial calculation
        self._calculate()

    def _calculate(self):
        """Perform fault current calculations"""
        try:
            # Calculate system impedance
            z_base = (self._system_voltage * 1000) ** 2 / (self._system_mva * 1e6)
            z_system = z_base / self._system_mva
            
            # Calculate transformer impedance
            z_tx_base = (self._system_voltage * 1000) ** 2 / (self._transformer_mva * 1e6)
            z_transformer = (self._transformer_z / 100.0) * z_tx_base
            
            # Calculate cable impedance
            z_cable = self._cable_z * self._cable_length
            
            # Total impedance
            self._total_impedance = z_system + z_transformer + z_cable
            
            # Calculate fault currents based on type
            base_current = (self._system_voltage * 1000) / (math.sqrt(3) * self._total_impedance)
            fault_factors = {
                "3-Phase": 1.0,
                "Line-Line": 0.866,  # √3/2
                "Line-Ground": 0.577  # 1/√3
            }
            
            factor = fault_factors.get(self._fault_type, 1.0)
            self._initial_sym_current = base_current * factor / 1000  # Convert to kA
            
            # Calculate peak fault current (includes DC component)
            peak_factor = math.sqrt(2) * (1.02 + 0.98 * math.exp(-3.0/self._xr_ratio))
            self._peak_fault_current = self._initial_sym_current * peak_factor
            
            # Breaking current (after DC decay)
            breaking_factor = 1.0 + math.exp(-0.5/self._xr_ratio)
            self._breaking_current = self._initial_sym_current * breaking_factor
            
            # Thermal equivalent current (1 second)
            m_factor = 0.07  # Typical value for MV systems
            n_factor = 1.0   # For 1 second duration
            thermal_factor = math.sqrt((1 + 2*m_factor)/(1 + 2*n_factor))
            self._thermal_current = self._initial_sym_current * thermal_factor
            
            # Notify QML that calculation is complete
            self.calculationComplete.emit()
            
        except Exception as e:
            print(f"Fault current calculation error: {e}")
    
    # Property getters for QML
    @Property(float, notify=calculationComplete)
    def initialSymCurrent(self):
        return self._initial_sym_current
    
    @Property(float, notify=calculationComplete)
    def peakFaultCurrent(self):
        return self._peak_fault_current
    
    @Property(float, notify=calculationComplete)  
    def breakingCurrent(self):
        return self._breaking_current
    
    @Property(float, notify=calculationComplete)
    def thermalCurrent(self):
        return self._thermal_current
    
    @Property(float, notify=calculationComplete)
    def totalImpedance(self):
        return self._total_impedance
    
    # Slots for receiving values from QML
    @Slot(float)
    def setSystemVoltage(self, voltage):
        self._system_voltage = voltage
        self._calculate()
    
    @Slot(float)
    def setSystemMva(self, mva):
        self._system_mva = mva
        self._calculate()
    
    @Slot(float)
    def setTransformerMva(self, mva):
        self._transformer_mva = mva
        self._calculate()
    
    @Slot(float)
    def setTransformerZ(self, z):
        self._transformer_z = z
        self._calculate()
    
    @Slot(float)
    def setCableLength(self, length):
        self._cable_length = length
        self._calculate()
    
    @Slot(float)
    def setCableZ(self, z):
        self._cable_z = z
        self._calculate()
    
    @Slot(str)
    def setFaultType(self, fault_type):
        self._fault_type = fault_type
        self._calculate()
    
    @Slot(float)
    def setXrRatio(self, ratio):
        self._xr_ratio = ratio
        self._calculate()
