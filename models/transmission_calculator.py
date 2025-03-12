from PySide6.QtCore import QObject, Property, Signal, Slot
import numpy as np
import cmath
import math

class TransmissionLineCalculator(QObject):
    # Define signals
    lengthChanged = Signal()
    resistanceChanged = Signal()
    inductanceChanged = Signal()
    capacitanceChanged = Signal()
    conductanceChanged = Signal()
    frequencyChanged = Signal()
    resultsCalculated = Signal()

    # Add new signals
    bundleConfigChanged = Signal()
    temperatureChanged = Signal()
    earthResistivityChanged = Signal()
    silCalculated = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        # Initialize properties
        self._length = 100.0  # km
        self._resistance = 0.1  # Ω/km
        self._inductance = 1.0  # mH/km
        self._capacitance = 0.01  # µF/km
        self._conductance = 0.0  # S/km
        self._frequency = 50.0  # Hz
        
        # Results
        self._Z = complex(0, 0)  # Characteristic impedance
        self._gamma = complex(0, 0)  # Propagation constant
        self._alpha = 0.0  # Attenuation constant
        self._beta = 0.0  # Phase constant
        self._A = complex(1, 0)  # ABCD parameters
        self._B = complex(0, 0)
        self._C = complex(0, 0)
        self._D = complex(1, 0)
        
        # Add new properties
        self._bundle_spacing = 0.4  # meters
        self._sub_conductors = 2    # conductors per bundle
        self._conductor_gmr = 0.0078  # meters
        self._conductor_temperature = 75.0  # °C
        self._earth_resistivity = 100.0  # Ω⋅m
        self._nominal_voltage = 400.0  # kV
        
        # Additional results
        self._skin_factor = 1.0
        self._sil = 0.0  # Surge impedance loading
        self._earth_impedance = complex(0, 0)
        self._voltage_profile = []
        self._current_profile = []

        self._calculate()

    def _calculate(self):
        try:
            # Calculate skin effect factor
            f = self._frequency
            self._skin_factor = 1 + (f/60) * 0.00125 * math.sqrt(self._conductor_temperature/75)
            
            # Apply skin effect to resistance
            R_ac = self._resistance * self._skin_factor
            
            # Calculate bundle GMR
            if self._sub_conductors > 1:
                bundle_gmr = (self._conductor_gmr * (self._bundle_spacing ** 
                            (self._sub_conductors - 1))) ** (1/self._sub_conductors)
            else:
                bundle_gmr = self._conductor_gmr
            
            # Calculate earth return impedance
            De = 658.5 * math.sqrt(self._earth_resistivity/f)
            Ze = complex(math.pi**2 * f/60, 0.0386 * f * math.log(De/bundle_gmr))
            self._earth_impedance = Ze
            
            # Update Z with bundling and earth effects
            w = 2 * np.pi * f
            Z = complex(R_ac, w * self._inductance * 1e-3) + Ze/3
            Y = complex(self._conductance, w * self._capacitance * 1e-6)
            
            # Calculate characteristic impedance with corrections
            self._Z = cmath.sqrt(Z / Y)
            
            # Calculate SIL
            self._sil = (self._nominal_voltage * 1000) ** 2 / abs(self._Z)
            
            # Calculate voltage and current profiles
            self._calculate_profiles()
            
            # Calculate propagation constant
            self._gamma = cmath.sqrt(Z * Y)
            self._alpha = self._gamma.real
            self._beta = self._gamma.imag
            
            # Calculate ABCD parameters
            gamma_l = self._gamma * self._length
            self._A = cmath.cosh(gamma_l)
            self._B = self._Z * cmath.sinh(gamma_l)
            self._C = cmath.sinh(gamma_l) / self._Z
            self._D = self._A  # For symmetrical lines
            
            self.resultsCalculated.emit()
            
        except Exception as e:
            print(f"Error in transmission line calculation: {e}")

    def _calculate_profiles(self):
        """Calculate voltage and current profiles along the line"""
        points = 100
        self._voltage_profile = []
        self._current_profile = []
        
        for i in range(points + 1):
            z = i * self._length / points
            gamma_z = self._gamma * z
            
            # Calculate V(z) and I(z) assuming V(0)=1.0 pu
            v = cmath.cosh(gamma_z)
            i = (1/self._Z) * cmath.sinh(gamma_z)
            
            self._voltage_profile.append((z, abs(v)))
            self._current_profile.append((z, abs(i)))

    # Properties
    @Property(float, notify=lengthChanged)
    def length(self):
        return self._length
    
    @length.setter
    def length(self, value):
        if value > 0:
            self._length = value
            self.lengthChanged.emit()
            self._calculate()

    @Property(float, notify=resistanceChanged)
    def resistance(self):
        return self._resistance
    
    @resistance.setter
    def resistance(self, value):
        if value >= 0:
            self._resistance = value
            self.resistanceChanged.emit()
            self._calculate()

    @Property(float, notify=inductanceChanged)
    def inductance(self):
        return self._inductance
    
    @inductance.setter
    def inductance(self, value):
        if value >= 0:
            self._inductance = value
            self.inductanceChanged.emit()
            self._calculate()

    @Property(float, notify=capacitanceChanged)
    def capacitance(self):
        return self._capacitance
    
    @capacitance.setter
    def capacitance(self, value):
        if value >= 0:
            self._capacitance = value
            self.capacitanceChanged.emit()
            self._calculate()

    @Property(float, notify=conductanceChanged)
    def conductance(self):
        return self._conductance
    
    @conductance.setter
    def conductance(self, value):
        if value >= 0:
            self._conductance = value
            self.conductanceChanged.emit()
            self._calculate()

    @Property(float, notify=frequencyChanged)
    def frequency(self):
        return self._frequency
    
    @frequency.setter
    def frequency(self, value):
        if value > 0:
            self._frequency = value
            self.frequencyChanged.emit()
            self._calculate()

    # Results properties
    @Property(complex, notify=resultsCalculated)
    def characteristicImpedance(self):
        return self._Z
    
    @Property(float, notify=resultsCalculated)
    def attenuationConstant(self):
        return self._alpha
    
    @Property(float, notify=resultsCalculated)
    def phaseConstant(self):
        return self._beta
    
    @Property(complex, notify=resultsCalculated)
    def parameterA(self):
        return self._A
    
    @Property(complex, notify=resultsCalculated)
    def parameterB(self):
        return self._B
    
    @Property(complex, notify=resultsCalculated)
    def parameterC(self):
        return self._C
    
    @Property(complex, notify=resultsCalculated)
    def parameterD(self):
        return self._D

    @Property(float, notify=resultsCalculated)
    def zMagnitude(self):
        """Get magnitude of characteristic impedance"""
        return abs(self._Z)
    
    @Property(float, notify=resultsCalculated)
    def zAngle(self):
        """Get angle of characteristic impedance in degrees"""
        return math.degrees(cmath.phase(self._Z))
    
    @Property(float, notify=resultsCalculated)
    def aMagnitude(self):
        return abs(self._A)
    
    @Property(float, notify=resultsCalculated)
    def aAngle(self):
        return math.degrees(cmath.phase(self._A))
    
    @Property(float, notify=resultsCalculated)
    def bMagnitude(self):
        return abs(self._B)
    
    @Property(float, notify=resultsCalculated)
    def bAngle(self):
        return math.degrees(cmath.phase(self._B))
    
    @Property(float, notify=resultsCalculated)
    def cMagnitude(self):
        return abs(self._C)
    
    @Property(float, notify=resultsCalculated)
    def cAngle(self):
        return math.degrees(cmath.phase(self._C))
    
    @Property(float, notify=resultsCalculated)
    def dMagnitude(self):
        return abs(self._D)
    
    @Property(float, notify=resultsCalculated)
    def dAngle(self):
        return math.degrees(cmath.phase(self._D))

    @Property(int, notify=bundleConfigChanged)
    def subConductors(self):
        return self._sub_conductors
    
    @subConductors.setter
    def subConductors(self, value):
        if 1 <= value <= 4:
            self._sub_conductors = value
            self.bundleConfigChanged.emit()
            self._calculate()

    @Property(float, notify=silCalculated)
    def surgeImpedanceLoading(self):
        return self._sil

    @Property(list, notify=resultsCalculated)
    def voltageProfile(self):
        return self._voltage_profile

    @Property(list, notify=resultsCalculated)
    def currentProfile(self):
        return self._current_profile

    @Property(float, notify=bundleConfigChanged)
    def bundleSpacing(self):
        return self._bundle_spacing
    
    @bundleSpacing.setter
    def bundleSpacing(self, value):
        if value > 0:
            self._bundle_spacing = value
            self.bundleConfigChanged.emit()
            self._calculate()

    @Property(float, notify=temperatureChanged)
    def conductorTemperature(self):
        return self._conductor_temperature
    
    @conductorTemperature.setter
    def conductorTemperature(self, value):
        if value > 0:
            self._conductor_temperature = value
            self.temperatureChanged.emit()
            self._calculate()

    @Property(float, notify=earthResistivityChanged)
    def earthResistivity(self):
        return self._earth_resistivity
    
    @earthResistivity.setter
    def earthResistivity(self, value):
        if value > 0:
            self._earth_resistivity = value
            self.earthResistivityChanged.emit()
            self._calculate()

    # QML slots
    @Slot(float)
    def setLength(self, value):
        self.length = value
    
    @Slot(float)
    def setResistance(self, value):
        self.resistance = value

    @Slot(float)
    def setInductance(self, value):
        self.inductance = value

    @Slot(float)
    def setCapacitance(self, value):
        self.capacitance = value

    @Slot(float)
    def setConductance(self, value):
        self.conductance = value

    @Slot(float)
    def setFrequency(self, value):
        self.frequency = value

    @Slot(int)
    def setSubConductors(self, value):
        self.subConductors = value

    @Slot(float)
    def setBundleSpacing(self, value):
        self.bundleSpacing = value

    @Slot(float)
    def setConductorTemperature(self, value):
        self.conductorTemperature = value

    @Slot(float)
    def setEarthResistivity(self, value):
        self.earthResistivity = value

    # ...similar slots for other new parameters...
