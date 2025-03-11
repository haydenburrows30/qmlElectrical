from PySide6.QtCore import QObject, Property, Signal, Slot
import math

class PowerFactorCorrectionCalculator(QObject):
    """Calculator for power factor correction capacitor sizing"""

    activePowerChanged = Signal()
    reactivePowerChanged = Signal()
    voltageChanged = Signal()
    frequencyChanged = Signal()
    currentPFChanged = Signal()
    targetPFChanged = Signal()
    calculationsComplete = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._active_power = 0.0  # kW
        self._reactive_power = 0.0  # kVAR (calculated)
        self._apparent_power_before = 0.0  # kVA (calculated)
        self._apparent_power_after = 0.0  # kVA (calculated)
        self._voltage = 400.0  # V, default to 400V three phase
        self._frequency = 50.0  # Hz, default to 50Hz
        self._current_pf = 0.8  # Default starting power factor
        self._target_pf = 0.95  # Default target power factor
        self._capacitor_size = 0.0  # kVAR
        self._capacitance = 0.0  # μF
        self._annual_savings = 0.0  # $ or local currency
        self._cost_per_kvar = 5.0  # $ per kVAR per month (default)
        
        # Initial calculation
        self._calculate()

    def _calculate(self):
        """Calculate power factor correction parameters"""
        if self._active_power <= 0 or self._current_pf <= 0 or self._current_pf >= 1:
            return

        # Calculate apparent power before correction
        self._apparent_power_before = self._active_power / self._current_pf
        
        # Calculate reactive power before correction
        phi1 = math.acos(self._current_pf)
        self._reactive_power = self._active_power * math.tan(phi1)
        
        # Calculate reactive power needed after correction
        phi2 = math.acos(self._target_pf)
        reactive_after = self._active_power * math.tan(phi2)
        
        # Calculate required capacitor size
        self._capacitor_size = self._reactive_power - reactive_after
        
        # Calculate apparent power after correction
        self._apparent_power_after = self._active_power / self._target_pf
        
        # Calculate capacitance in microfarads
        if self._voltage > 0 and self._frequency > 0:
            self._capacitance = self._capacitor_size * 1000 * 1000 / (
                2 * math.pi * self._frequency * self._voltage**2 * 3)  # For three-phase
        else:
            self._capacitance = 0.0
        
        # Calculate annual savings
        # Assuming power utility charges for kVA demand
        kva_reduction = self._apparent_power_before - self._apparent_power_after
        self._annual_savings = kva_reduction * self._cost_per_kvar * 12  # Annual savings
        
        # Notify QML of changes
        self.calculationsComplete.emit()

    # Property getters and setters
    @Property(float, notify=activePowerChanged)
    def activePower(self):
        return self._active_power
    
    @activePower.setter
    def activePower(self, power):
        if self._active_power != power and power >= 0:
            self._active_power = power
            self.activePowerChanged.emit()
            self._calculate()

    @Property(float, notify=reactivePowerChanged)
    def reactivePower(self):
        return self._reactive_power
    
    @Property(float, notify=voltageChanged)
    def voltage(self):
        return self._voltage
    
    @voltage.setter
    def voltage(self, voltage):
        if self._voltage != voltage and voltage > 0:
            self._voltage = voltage
            self.voltageChanged.emit()
            self._calculate()

    @Property(float, notify=frequencyChanged)
    def frequency(self):
        return self._frequency
    
    @frequency.setter
    def frequency(self, freq):
        if self._frequency != freq and freq > 0:
            self._frequency = freq
            self.frequencyChanged.emit()
            self._calculate()

    @Property(float, notify=currentPFChanged)
    def currentPF(self):
        return self._current_pf
    
    @currentPF.setter
    def currentPF(self, pf):
        if self._current_pf != pf and 0 < pf < 1:
            self._current_pf = pf
            self.currentPFChanged.emit()
            self._calculate()

    @Property(float, notify=targetPFChanged)
    def targetPF(self):
        return self._target_pf
    
    @targetPF.setter
    def targetPF(self, pf):
        if self._target_pf != pf and 0 < pf <= 1:
            self._target_pf = pf
            self.targetPFChanged.emit()
            self._calculate()

    @Property(float, notify=calculationsComplete)
    def capacitorSize(self):
        return self._capacitor_size

    @Property(float, notify=calculationsComplete)
    def capacitance(self):
        return self._capacitance

    @Property(float, notify=calculationsComplete)
    def apparentPowerBefore(self):
        return self._apparent_power_before

    @Property(float, notify=calculationsComplete)
    def apparentPowerAfter(self):
        return self._apparent_power_after
        
    @Property(float, notify=calculationsComplete)
    def annualSavings(self):
        return self._annual_savings
        
    # Cost per kVAR property
    @Property(float, notify=calculationsComplete)
    def costPerKvar(self):
        return self._cost_per_kvar
        
    @Slot(float)
    def setCostPerKvar(self, cost):
        if self._cost_per_kvar != cost and cost >= 0:
            self._cost_per_kvar = cost
            self._calculate()

    # Slots for QML access
    @Slot(float)
    def setActivePower(self, power):
        self.activePower = power

    @Slot(float)
    def setVoltage(self, voltage):
        self.voltage = voltage

    @Slot(float)
    def setFrequency(self, freq):
        self.frequency = freq

    @Slot(float)
    def setCurrentPF(self, pf):
        self.currentPF = pf

    @Slot(float)
    def setTargetPF(self, pf):
        self.targetPF = pf
