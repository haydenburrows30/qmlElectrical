from PySide6.QtCore import QObject, Property, Signal, Slot
import math
import numpy as np
from utils.pdf_generator import PDFGenerator
import logging

# Setup logging
logger = logging.getLogger("qmltest")

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
    pdfSaved = Signal()
    
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
        self._rated_capacity = 0.0     # kVA
        self._output_current = 0.0     # A
        self._power_curve = []         # List of (wind_speed, power) tuples

        self._pdf = "Success"
        
        # Initialize calculations
        self._calculate()

    def _calculate(self):
        """Calculate wind turbine parameters based on inputs"""
        try:
            logger = logging.getLogger("qmltest")
            logger.info("\n=== Starting Wind Turbine Calculations ===")
            logger.info(f"Input Parameters:")
            logger.info(f"• Blade Radius: {self._blade_radius} m")
            logger.info(f"• Wind Speed: {self._wind_speed} m/s")
            logger.info(f"• Air Density: {self._air_density} kg/m³")
            logger.info(f"• Power Coefficient: {self._power_coefficient}")
            logger.info(f"• Generator Efficiency: {self._efficiency*100}%")
            
            # Calculate swept area
            self._swept_area = math.pi * self._blade_radius * self._blade_radius
            logger.info(f"\nSwept Area: {self._swept_area:.2f} m²")
            
            # Calculate theoretical power
            self._theoretical_power = 0.5 * self._air_density * self._swept_area * math.pow(self._wind_speed, 3)
            logger.info(f"Theoretical Power: {self._theoretical_power/1000:.2f} kW")
            
            # Calculate actual power with proper handling of rated power
            if self._wind_speed < self._cut_in_speed:
                logger.info(f"Wind speed below cut-in speed ({self._cut_in_speed} m/s)")
                self._actual_power = 0.0
            elif self._wind_speed > self._cut_out_speed:
                logger.info(f"Wind speed above cut-out speed ({self._cut_out_speed} m/s)")
                self._actual_power = 0.0
            else:
                # Check if we have rated power and are above rated wind speed
                has_rated_specs = hasattr(self, '_rated_power') and hasattr(self, '_rated_wind_speed')
                
                if has_rated_specs:
                    # Log rated power information
                    logger.info(f"Turbine has specified rated power: {self._rated_power/1000:.2f} kW at {self._rated_wind_speed:.2f} m/s")
                    
                    # For V27 and similar commercial turbines with a fixed rated power
                    if self._wind_speed >= self._rated_wind_speed:
                        # When above rated wind speed, use the rated power (constant power region)
                        self._actual_power = self._rated_power
                        logger.info(f"Wind speed ({self._wind_speed} m/s) >= rated speed, using rated power of {self._rated_power/1000:.2f} kW")
                    else:
                        # Below rated wind speed, calculate power normally
                        calculated_power = self._theoretical_power * self._power_coefficient * self._efficiency
                        # Make sure we don't exceed rated power
                        self._actual_power = min(calculated_power, self._rated_power)
                        logger.info(f"Wind speed below rated speed, calculated power: {calculated_power/1000:.2f} kW, limited to: {self._actual_power/1000:.2f} kW")
                else:
                    # Normal power calculation based on wind speed cubed (for generic turbines)
                    self._actual_power = self._theoretical_power * self._power_coefficient * self._efficiency
                    logger.info(f"Generic turbine calculation: {self._actual_power/1000:.2f} kW")
                
                logger.info(f"Final power output: {self._actual_power/1000:.2f} kW")
            
            # Calculate annual energy
            # Fix: Use a more accurate capacity factor approach for annual energy
            hours_in_year = 8760
            capacity_factor = 0.35  # A typical capacity factor for wind turbines
            self._annual_energy = (self._actual_power / 1000) * capacity_factor * hours_in_year / 1000
            logger.info(f"\nAnnual Energy Production: {self._annual_energy:.2f} MWh")

            # Calculate generator capacity (kVA)
            # Fix: Power factor of ~0.85 is typical for wind turbines
            power_factor = 0.85
            self._rated_capacity = (self._actual_power / 1000) / power_factor
            logger.info(f"\nRated Capacity: {self._rated_capacity:.2f} kVA")

            # Calculate output current at 400V (3-phase)
            if self._actual_power > 0:
                self._output_current = (self._actual_power) / (math.sqrt(3) * 400 * power_factor)
                logger.info(f"\nOutput Current: {self._output_current:.2f} A")
            else:
                self._output_current = 0.0
                logger.info("\nOutput Current: 0.00 A (no power generation)")
            
            # Generate power curve
            logger.info("\nGenerating Power Curve...")
            self._generate_power_curve()
            
            logger.info("=== Wind Turbine Calculations Complete ===\n")
            
            # Emit signals
            self.calculationCompleted.emit()
            self.calculationsComplete.emit()
            
        except Exception as e:
            logger.error(f"Error in wind turbine calculation: {e}")
            logger.exception(e)

    def _generate_power_curve(self):
        """Generate the power curve data points"""
        try:
            # Clear existing power curve data
            self._power_curve = []
            
            # Generate points from 0 to cut-out speed + 5
            max_power = 0
            
            # Use rated wind speed and power if they are set (for commercial turbines)
            has_rated_specs = hasattr(self, '_rated_power') and hasattr(self, '_rated_wind_speed')
            
            # Print debug info about rated specs
            if has_rated_specs:
                logger.info(f"Using rated specs: Power = {self._rated_power/1000} kW at {self._rated_wind_speed} m/s")
                rated_power = self._rated_power
                rated_wind_speed = self._rated_wind_speed
            else:
                logger.info("No rated specs defined, using standard calculation")
                rated_power = None
                # Without rated specs, we'll use a calculated wind speed that gives max power
                rated_wind_speed = self._wind_speed if self._wind_speed > 0 else 12.0
            
            for speed in np.arange(0, self._cut_out_speed + 5.0, 0.5):
                # Calculate power at this wind speed
                if speed < self._cut_in_speed or speed > self._cut_out_speed:
                    power = 0.0
                else:
                    # Calculate the theoretical power at this wind speed
                    theoretical = 0.5 * self._air_density * self._swept_area * math.pow(speed, 3)
                    
                    # Apply efficiency and power coefficient
                    calculated_power = theoretical * self._power_coefficient * self._efficiency
                    
                    # Apply rated power limit if specified
                    if has_rated_specs:
                        if speed >= rated_wind_speed:
                            # At or above rated wind speed, use the exact rated power
                            power = rated_power
                        else:
                            # Below rated wind speed, calculate normally but don't exceed rated power
                            power = min(calculated_power, rated_power)
                    else:
                        # No rated power specified, use calculated power
                        power = calculated_power
                
                # Keep track of maximum power for display purposes
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
        
        # Calculate theoretical power
        theoretical = 0.5 * self._air_density * self._swept_area * math.pow(speed, 3)
        calculated_power = theoretical * self._power_coefficient * self._efficiency
        
        # Apply rated power limit if specified
        has_rated_specs = hasattr(self, '_rated_power') and hasattr(self, '_rated_wind_speed')
        if has_rated_specs and speed >= self._rated_wind_speed:
            # Print debug information
            print(f"Using rated power: {self._rated_power/1000:.2f} kW (speed: {speed} >= rated: {self._rated_wind_speed})")
            return self._rated_power
        elif has_rated_specs:
            limited_power = min(calculated_power, self._rated_power)
            print(f"Limited power: {limited_power/1000:.2f} kW (speed: {speed}, rated: {self._rated_wind_speed})")
            return limited_power
        else:
            return calculated_power
            
    def _reset_rated_power_settings(self):
        """Reset any fixed rated power settings to allow dynamic calculation"""
        if hasattr(self, '_rated_power'):
            delattr(self, '_rated_power')
        if hasattr(self, '_rated_wind_speed'):
            delattr(self, '_rated_wind_speed')
    
    @Property(float, notify=bladeRadiusChanged)
    def bladeRadius(self):
        return self._blade_radius
    
    @bladeRadius.setter
    def bladeRadius(self, value):
        if self._blade_radius != value and value > 0:
            self._blade_radius = value
            self._reset_rated_power_settings()  # Reset rated power when changing blade radius
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
            self._reset_rated_power_settings()  # Reset rated power when changing air density
            self.airDensityChanged.emit()
            self._calculate()
    
    @Property(float, notify=powerCoefficientChanged)
    def powerCoefficient(self):
        return self._power_coefficient
    
    @powerCoefficient.setter
    def powerCoefficient(self, value):
        if self._power_coefficient != value and 0 <= value <= 0.6:  # Betz limit is 0.593
            self._power_coefficient = value
            self._reset_rated_power_settings()  # Reset rated power when changing power coefficient
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
            self._reset_rated_power_settings()  # Reset rated power when changing efficiency
            self.efficiencyChanged.emit()
            self._calculate()
    
    # Read-only results properties
    @Property(float, notify=calculationsComplete)
    def sweptArea(self):
        return self._swept_area
    
    @Property(float, notify=calculationsComplete)
    def theoreticalPower(self):
        return self._theoretical_power / 1000.0  # Convert to kW
    
    @Property(float, notify=calculationsComplete)
    def actualPower(self):
        return self._actual_power / 1000.0  # Convert to kW
    
    @Property(float, notify=calculationsComplete)
    def ratedCapacity(self):
        return self._rated_capacity
    
    @Property(float, notify=calculationsComplete)
    def outputCurrent(self):
        return self._output_current

    @Property(float, notify=calculationsComplete)
    def annualEnergy(self):
        return self._annual_energy
    
    @Property(list, notify=powerCurveChanged)
    def powerCurve(self):
        """Convert power curve data to a format that QML can properly interpret"""
        try:
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
    
    @Slot()
    def resetToGenericTurbine(self):
        """Reset to generic turbine without fixed rated power"""
        try:
            self._reset_rated_power_settings()
            self._blade_radius = 25.0
            self._power_coefficient = 0.4
            self._cut_in_speed = 3.0
            self._cut_out_speed = 25.0
            self._efficiency = 0.9
            
            # Emit signals for all changed properties
            self.bladeRadiusChanged.emit()
            self.powerCoefficientChanged.emit()
            self.cutInSpeedChanged.emit()
            self.cutOutSpeedChanged.emit()
            self.efficiencyChanged.emit()
            
            # Recalculate all values
            self._calculate()
            
            print("Reset to generic turbine parameters")
            return True
        except Exception as e:
            print(f"Error resetting to generic turbine parameters: {e}")
            return False

    @Slot()
    def loadVestasV27Parameters(self):
        """Load parameters for the Vestas V27 225kW turbine"""
        try:
            # Vestas V27 specifications
            self._blade_radius = 13.5  # 27m rotor diameter / 2
            self._power_coefficient = 0.44  # Higher CP for this commercial turbine
            self._cut_in_speed = 3.5  # m/s
            self._cut_out_speed = 25.0  # m/s
            self._efficiency = 0.95  # 95% generator efficiency
            
            # Set rated power explicitly (225kW for Vestas V27)
            self._rated_power = 225.0 * 1000  # Convert kW to W
            
            # Calculate rated wind speed (the speed at which the turbine reaches rated power)
            # Using the wind power equation: P = 0.5 * rho * A * v³ * Cp * efficiency
            # Solve for v: v = (P / (0.5 * rho * A * Cp * efficiency))^(1/3)
            self._rated_wind_speed = math.pow(
                self._rated_power / (0.5 * self._air_density * math.pi * self._blade_radius**2 * 
                                    self._power_coefficient * self._efficiency), 
                1/3
            )
            
            logger.info(f"V27 Parameters loaded - Rated power: {self._rated_power/1000:.2f} kW at {self._rated_wind_speed:.2f} m/s")
            
            # Important: Set wind speed to at least the rated wind speed to show full power capability
            # This ensures the UI shows the rated power immediately
            if self._wind_speed < self._rated_wind_speed:
                self._wind_speed = self._rated_wind_speed
                self.windSpeedChanged.emit()
            
            # Emit signals for all changed properties
            self.bladeRadiusChanged.emit()
            self.powerCoefficientChanged.emit()
            self.cutInSpeedChanged.emit()
            self.cutOutSpeedChanged.emit()
            self.efficiencyChanged.emit()
            
            # Recalculate all values
            self._calculate()
            
            # Force another signal emission to ensure UI updates
            self.calculationsComplete.emit()
            self.calculationCompleted.emit()
            
            print(f"Loaded Vestas V27 parameters (rated power: 225kW at {self._rated_wind_speed:.1f} m/s)")
            return True
        except Exception as e:
            print(f"Error loading Vestas V27 parameters: {e}")
            return False
    
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
        
    @Slot()
    def debugTurbineState(self):
        """Print debug information about the turbine state"""
        has_rated_specs = hasattr(self, '_rated_power') and hasattr(self, '_rated_wind_speed')
        rated_info = f"Rated Power: {self._rated_power/1000:.2f} kW at {self._rated_wind_speed:.2f} m/s" if has_rated_specs else "No rated specs"
        
        logger.info("\n===== TURBINE DEBUG INFO =====")
        logger.info(f"Blade radius: {self._blade_radius} m")
        logger.info(f"Wind speed: {self._wind_speed} m/s")
        logger.info(f"Power coefficient: {self._power_coefficient}")
        logger.info(f"Efficiency: {self._efficiency}")
        logger.info(f"Cut-in speed: {self._cut_in_speed} m/s")
        logger.info(f"Cut-out speed: {self._cut_out_speed} m/s")
        logger.info(f"{rated_info}")
        logger.info(f"Swept area: {self._swept_area:.2f} m²")
        logger.info(f"Theoretical power: {self._theoretical_power/1000:.2f} kW")
        logger.info(f"Actual power: {self._actual_power/1000:.2f} kW")
        
        # Test calculation at current wind speed
        theoretical = 0.5 * self._air_density * self._swept_area * math.pow(self._wind_speed, 3)
        calculated_power = theoretical * self._power_coefficient * self._efficiency
        
        logger.info(f"Direct calculation:")
        logger.info(f"- Theoretical at {self._wind_speed} m/s: {theoretical/1000:.2f} kW")
        logger.info(f"- With coefficients: {calculated_power/1000:.2f} kW")
        
        if has_rated_specs:
            if self._wind_speed >= self._rated_wind_speed:
                logger.info(f"- Should be using rated power: {self._rated_power/1000:.2f} kW")
            else:
                limited = min(calculated_power, self._rated_power)
                logger.info(f"- Should be limited to: {limited/1000:.2f} kW")
        
        logger.info("==============================\n")
        
        return True
    
    @Slot(str, str)
    def exportWindTurbineReport(self, filename, chart_image_path=""):
        """Export wind turbine calculations to PDF
        
        Args:
            filename: Path to save the PDF report
            chart_image_path: Optional path to the chart image
        """
        try:
            import os
            import platform
            
            # Clean up filename - handle QML URL format
            clean_path = filename.strip()
            
            # Remove the file:/// prefix if present
            if clean_path.startswith('file:///'):
                # On Windows, file:///C:/path becomes C:/path
                if platform.system() == "Windows":
                    clean_path = clean_path[8:]
                else:
                    # On Unix-like systems, file:///path becomes /path
                    clean_path = clean_path[8:] if clean_path[8:10].startswith(":/") else clean_path[7:]

            # Handle the case with extra leading slash on Windows paths
            if clean_path.startswith('/') and ':' in clean_path[1:3]:  # Like '/C:/'
                clean_path = clean_path[1:]  # Remove leading slash
                
            # Ensure it has .pdf extension
            if not clean_path.lower().endswith('.pdf'):
                clean_path += '.pdf'
            
            print(f"Processing export to: {clean_path}")
                
            # Clean up chart image path
            if chart_image_path:
                chart_image_path = os.path.normpath(chart_image_path)
            
            # Make sure the power curve is up-to-date
            self._generate_power_curve()
            
            # Updated: Make sure we're using the most current calculations for the report
            self._calculate()
            
            # Fix: Use the corrected calculations for rated capacity and output current
            power_factor = 0.85
            rated_capacity = self._actual_power / (1000 * power_factor)  # Convert W to kVA
            output_current = self._actual_power / (math.sqrt(3) * 400 * power_factor)
            
            # Prepare power curve data (to be used if chart image isn't available)
            power_curve_data = {
                'wind_speeds': [point[0] for point in self._power_curve],
                'power_values': [point[1] for point in self._power_curve]
            }
            
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
                "rated_capacity": rated_capacity,
                "output_current": output_current,
                "capacity_factor": self.calculateCapacityFactor(self._wind_speed),
                "power_curve": power_curve_data,
                "chart_image_path": chart_image_path if chart_image_path else ""
            }
            
            generator = PDFGenerator()
            generator.generate_wind_turbine_report(data, clean_path)
            print(f"Wind turbine report exported to: {clean_path}")
            self._pdf = "Success"
            self.pdfSaved.emit()

        except Exception as e:
            print(f"Error exporting wind turbine report: {e}")
            print(f"Attempted filename: {filename}")
            # Print more details for debugging
            import traceback
            traceback.print_exc()

    @Property(str, notify=pdfSaved)
    def exportSuccess(self):
        return self._pdf

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
            # Fix: Added safety check for division by zero and negative values
            if weibull_k <= 0:
                weibull_k = 2.0  # Default to standard value if invalid
            
            # The correct formula for the Weibull scale parameter
            weibull_a = avg_wind_speed / math.gamma(1 + 1/weibull_k)
            
            # Calculate Weibull probability for each wind speed
            weibull_probs = []
            for speed in wind_speeds:
                if speed == 0:
                    prob = 0
                else:
                    # Weibull probability density function
                    try:
                        prob = (weibull_k / weibull_a) * (speed / weibull_a)**(weibull_k-1) * math.exp(-(speed/weibull_a)**weibull_k)
                    except (ValueError, ZeroDivisionError, OverflowError):
                        prob = 0  # Handle math errors gracefully
                weibull_probs.append(prob)
            
            # Normalize probabilities to ensure they sum to 1
            total_prob = sum(weibull_probs)
            if total_prob > 0:
                weibull_probs = [p / total_prob for p in weibull_probs]
            
            # Calculate energy for each wind speed bin
            energy = 0
            hours_per_year = 8760
            for speed, prob in zip(wind_speeds, weibull_probs):
                # Get power at this speed using existing method
                power_at_speed = self._calculate_power_at_speed(speed) / 1000  # kW
                energy += power_at_speed * prob * hours_per_year  # kWh
            
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
