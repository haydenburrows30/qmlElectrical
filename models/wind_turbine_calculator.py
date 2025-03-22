from PySide6.QtCore import QObject, Property, Signal, Slot
import math
import numpy as np
from utils.pdf_generator import PDFGenerator  # Update to absolute import

class WindTurbineCalculator(QObject):
    """Calculator for wind turbine power output and performance analysis"""

    # Define signals
    bladeRadiusChanged = Signal()
    windSpeedChanged = Signal()
    airDensityChanged = Signal()
    powerCoefficientChanged = Signal()
    cutInSpeedChanged = Signal()
    cutOutSpeedChanged = Signal()
    efficiencyChanged = Signal()
    
    # Add both signal names for compatibility
    calculationCompleted = Signal()  # Standard name
    calculationsComplete = Signal()  # Legacy name
    powerCurveChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        # Initialize properties with default values - increased blade radius for more realistic power
        self._blade_radius = 25.0  # meters (increased from 25m for more realistic power)
        self._wind_speed = 8.0     # m/s
        self._air_density = 1.225  # kg/m³
        self._power_coefficient = 0.4  # Betz limit is 0.593
        self._cut_in_speed = 3.0   # m/s
        self._cut_out_speed = 25.0 # m/s
        self._efficiency = 0.9     # generator efficiency (90%)
        
        # Calculated values
        self._swept_area = 0.0         # m²
        self._theoretical_power = 0.0  # W
        self._actual_power = 0.0       # W
        self._annual_energy = 0.0      # MWh/year
        self._power_curve = []         # List of (wind_speed, power) tuples
        
        # Initialize calculations
        self._calculate()

    def _calculate(self):
        """Calculate wind turbine parameters based on inputs"""
        try:
            # Calculate swept area
            self._swept_area = math.pi * self._blade_radius * self._blade_radius
            
            # Calculate theoretical power
            self._theoretical_power = 0.5 * self._air_density * self._swept_area * math.pow(self._wind_speed, 3)
            
            # Calculate actual power considering cut-in/cut-out speeds
            if self._wind_speed < self._cut_in_speed or self._wind_speed > self._cut_out_speed:
                self._actual_power = 0.0
            else:
                self._actual_power = self._theoretical_power * self._power_coefficient * self._efficiency
            
            # Calculate annual energy production (simplified)
            # Assumes wind is at the specified speed for 35% of the year
            average_wind_speed_hours = 0.35 * 365 * 24
            power_in_kw = self._actual_power / 1000
            self._annual_energy = power_in_kw * average_wind_speed_hours / 1000  # MWh
            
            # Generate power curve data
            self._generate_power_curve()
            
            # Emit both signals for backward compatibility
            self.calculationCompleted.emit()
            self.calculationsComplete.emit()
            
        except Exception as e:
            print(f"Error in wind turbine calculation: {e}")
    
    def _generate_power_curve(self):
        """Generate the power curve data points"""
        try:
            # Clear existing power curve data
            self._power_curve = []
            
            # Generate points from 0 to cut-out speed + 5
            max_power = 0
            
            # Reference wind speed where power is at rated capacity (typically around 12-15 m/s). changes with wind speed chosen
            rated_wind_speed = self._wind_speed
            
            for speed in np.arange(0, self._cut_out_speed + 5.0, 0.5):
                # Calculate power at this wind speed
                if speed < self._cut_in_speed or speed > self._cut_out_speed:
                    power = 0.0
                else:
                    # Power increases as cube of wind speed up to rated speed
                    if speed <= rated_wind_speed:
                        power = 0.5 * self._air_density * self._swept_area * math.pow(speed, 3) * self._power_coefficient * self._efficiency
                    else:
                        # After rated speed, power is constant until cut-out
                        power = 0.5 * self._air_density * self._swept_area * math.pow(rated_wind_speed, 3) * self._power_coefficient * self._efficiency
                
                # Keep track of maximum power
                power_kw = power / 1000.0
                if power_kw > max_power:
                    max_power = power_kw
                
                # Append (speed, power in kW) tuple
                self._power_curve.append((float(speed), power_kw))
            
            self.powerCurveChanged.emit()
            
        except Exception as e:
            print(f"Error generating power curve: {e}")
            self._power_curve = []
    
    def _calculate_power_at_speed(self, speed):
        """Calculate power output at a specific wind speed"""
        if speed < self._cut_in_speed or speed > self._cut_out_speed:
            return 0.0
        
        return 0.5 * self._air_density * self._swept_area * math.pow(speed, 3) * self._power_coefficient * self._efficiency
    
    # Properties and setters
    @Property(float, notify=bladeRadiusChanged)
    def bladeRadius(self):
        return self._blade_radius
    
    @bladeRadius.setter
    def bladeRadius(self, value):
        if self._blade_radius != value and value > 0:
            self._blade_radius = value
            self.bladeRadiusChanged.emit()
            self._calculate()
    
    @Property(float, notify=windSpeedChanged)
    def windSpeed(self):
        return self._wind_speed
    
    @windSpeed.setter
    def windSpeed(self, value):
        if self._wind_speed != value and value >= 0:
            self._wind_speed = value
            self.windSpeedChanged.emit()
            self._calculate()
    
    @Property(float, notify=airDensityChanged)
    def airDensity(self):
        return self._air_density
    
    @airDensity.setter
    def airDensity(self, value):
        if self._air_density != value and value > 0:
            self._air_density = value
            self.airDensityChanged.emit()
            self._calculate()
    
    @Property(float, notify=powerCoefficientChanged)
    def powerCoefficient(self):
        return self._power_coefficient
    
    @powerCoefficient.setter
    def powerCoefficient(self, value):
        if self._power_coefficient != value and 0 <= value <= 0.6:  # Betz limit is 0.593
            self._power_coefficient = value
            self.powerCoefficientChanged.emit()
            self._calculate()
    
    @Property(float, notify=cutInSpeedChanged)
    def cutInSpeed(self):
        return self._cut_in_speed
    
    @cutInSpeed.setter
    def cutInSpeed(self, value):
        if self._cut_in_speed != value and 0 <= value < self._cut_out_speed:
            self._cut_in_speed = value
            self.cutInSpeedChanged.emit()
            self._calculate()
    
    @Property(float, notify=cutOutSpeedChanged)
    def cutOutSpeed(self):
        return self._cut_out_speed
    
    @cutOutSpeed.setter
    def cutOutSpeed(self, value):
        if self._cut_out_speed != value and value > self._cut_in_speed:
            self._cut_out_speed = value
            self.cutOutSpeedChanged.emit()
            self._calculate()
    
    @Property(float, notify=efficiencyChanged)
    def efficiency(self):
        return self._efficiency
    
    @efficiency.setter
    def efficiency(self, value):
        if self._efficiency != value and 0 < value <= 1:
            self._efficiency = value
            self.efficiencyChanged.emit()
            self._calculate()
    
    # Read-only results properties
    @Property(float, notify=calculationsComplete)
    def sweptArea(self):
        return self._swept_area
    
    @Property(float, notify=calculationsComplete)
    def theoreticalPower(self):
        return self._theoretical_power
    
    @Property(float, notify=calculationsComplete)
    def actualPower(self):
        return self._actual_power
    
    @Property(float, notify=calculationsComplete)
    def powerInKW(self):
        return self._actual_power / 1000.0
    
    @Property(float, notify=calculationsComplete)
    def annualEnergy(self):
        return self._annual_energy
    
    @Property(list, notify=powerCurveChanged)
    def powerCurve(self):
        """Convert power curve data to a format that QML can properly interpret"""
        try:
            # Debug the data being sent to QML
            first_few = self._power_curve[:5]
            last_few = self._power_curve[-5:] if len(self._power_curve) >= 5 else []
            
            # Create a new list of explicit dictionaries for better QML compatibility
            result = []
            for x, y in self._power_curve:
                # Use explicit dictionary with named keys for better QML compatibility
                result.append({"x": float(x), "y": float(y)})
            
            # Debug the converted data
            return result
        except Exception as e:
            print(f"Error converting power curve data: {e}")
            return []
    
    # QML slots
    @Slot(float)
    def setBladeRadius(self, radius):
        self.bladeRadius = radius
    
    @Slot(float)
    def setWindSpeed(self, speed):
        self.windSpeed = speed
    
    @Slot(float)
    def setAirDensity(self, density):
        self.airDensity = density
    
    @Slot(float)
    def setPowerCoefficient(self, coefficient):
        self.powerCoefficient = coefficient
    
    @Slot(float)
    def setCutInSpeed(self, speed):
        self.cutInSpeed = speed
    
    @Slot(float)
    def setCutOutSpeed(self, speed):
        self.cutOutSpeed = speed
    
    @Slot(float)
    def setEfficiency(self, efficiency):
        self.efficiency = efficiency
    
    @Slot(float, result=float)
    def calculatePowerAtSpeed(self, speed):
        """Calculate power output at a specific wind speed (QML callable)"""
        return self._calculate_power_at_speed(speed)
    
    @Slot()
    def refreshCalculations(self):
        """Force refresh of all calculations"""
        print("Refreshing wind turbine calculations")
        self._calculate()
        # Ensure the power curve is regenerated
        self._generate_power_curve()
        return True
    
    @Slot(str)
    def exportWindTurbineReport(self, filename):
        """Export wind turbine calculations to PDF"""
        try:
            # Clean up filename
            clean_path = filename.strip()
            if not clean_path.lower().endswith('.pdf'):
                clean_path += '.pdf'
                
            data = {
                "blade_radius": self._blade_radius,
                "wind_speed": self._wind_speed,
                "air_density": self._air_density,
                "power_coefficient": self._power_coefficient,
                "efficiency": self._efficiency,
                "cut_in_speed": self._cut_in_speed,
                "cut_out_speed": self._cut_out_speed,
                "swept_area": self._swept_area,
                "theoretical_power": self._theoretical_power,
                "actual_power": self._actual_power,
                "annual_energy": self._annual_energy,
                "rated_capacity": self._actual_power * 1.2 / 1000,  # kVA
                "output_current": (self._actual_power / 1000) / (math.sqrt(3) * 0.4),  # A at 400V
                "capacity_factor": self.calculateCapacityFactor(self._wind_speed)
            }
            
            generator = PDFGenerator()
            generator.generate_wind_turbine_report(data, clean_path)
            print(f"Wind turbine report exported to: {clean_path}")
            
        except Exception as e:
            print(f"Error exporting wind turbine report: {e}")
            print(f"Attempted filename: {filename}")

    # Advanced analysis methods
    @Slot(float, float, result=float)
    def estimateAEP(self, avg_wind_speed, weibull_k=2.0):
        """Estimate Annual Energy Production using Weibull distribution
        
        Args:
            avg_wind_speed: Average wind speed at hub height (m/s)
            weibull_k: Weibull shape parameter (typically 1.5-3)
            
        Returns:
            Estimated annual energy production in MWh
        """
        try:
            # Create wind speed bins (0 to 30 m/s in 1 m/s increments)
            wind_speeds = np.arange(0, 31, 1)
            
            # Calculate Weibull scale parameter
            weibull_a = avg_wind_speed / (math.gamma(1 + 1/weibull_k))
            
            # Calculate Weibull probability for each wind speed
            weibull_probs = []
            for speed in wind_speeds:
                if speed == 0:
                    prob = 0
                else:
                    # Weibull probability density function
                    prob = (weibull_k / weibull_a) * (speed / weibull_a)**(weibull_k-1) * math.exp(-(speed/weibull_a)**weibull_k)
                weibull_probs.append(prob)
            
            # Normalize probabilities to ensure they sum to 1
            total_prob = sum(weibull_probs)
            if total_prob > 0:
                weibull_probs = [p / total_prob for p in weibull_probs]
            
            # Calculate energy for each wind speed bin
            energy = 0
            hours_per_year = 8760
            for speed, prob in zip(wind_speeds, weibull_probs):
                power = self._calculate_power_at_speed(speed) / 1000  # kW
                energy += power * prob * hours_per_year  # kWh
            
            # Convert kWh to MWh
            energy_mwh = energy / 1000
            
            return energy_mwh
            
        except Exception as e:
            print(f"Error estimating AEP: {e}")
            return 0.0
    
    @Slot(float, result=float)
    def calculateCapacityFactor(self, avg_wind_speed):
        """Calculate capacity factor based on average wind speed
        
        Capacity factor = Actual annual energy production / Theoretical maximum production
        """
        try:
            # Estimate actual AEP
            aep = self.estimateAEP(avg_wind_speed)
            
            # Calculate theoretical maximum (turbine running at rated power 24/7)
            # For this calculation, we'll use a typical rated wind speed of 12 m/s
            rated_wind_speed = 12.0
            rated_power = 0.5 * self._air_density * self._swept_area * rated_wind_speed**3 * self._power_coefficient * self._efficiency
            max_production = (rated_power / 1000) * 8760 / 1000  # MWh
            
            # Calculate capacity factor
            if max_production > 0:
                return aep / max_production
            else:
                return 0.0
            
        except Exception as e:
            print(f"Error calculating capacity factor: {e}")
            return 0.0
