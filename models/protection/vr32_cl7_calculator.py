import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from PySide6.QtCore import QObject, Signal, Slot, Property

from utils.logger_config import configure_logger

# Setup component-specific logger
logger = configure_logger("qmltest", component="vr32")

class VR32CL7Calculator(QObject):
    """
    Calculator for determining R and X values for a VR32 CL-7 voltage regulator
    based on wind generation parameters, cable specifications, and load distance.
    """
    
    # Signals for notifying UI of changes
    resultsChanged = Signal()
    generationCapacityChanged = Signal()
    cableLengthChanged = Signal()
    cableRPerKmChanged = Signal()
    cableXPerKmChanged = Signal()
    loadDistanceChanged = Signal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Default parameters
        self._generation_capacity_kw = 500  # Default 500kW wind generation
        self._cable_length_km = 8  # Default 8km cable length
        self._cable_r_per_km = 1.15  # Default R of 1.15 Ω/km
        self._cable_x_per_km = 0.126  # Default X of 0.126 Ω/km
        self._load_distance_km = 3  # Default 3km load distance
        
        # Initialize results
        self._results = {
            'resistance': 0.0,
            'reactance': 0.0,
            'impedance': 0.0,
            'impedance_angle': 0.0
        }
        
        # Initial calculation
        self.calculate()
    
    # PySide6 property getters and setters
    def _get_generation_capacity_kw(self):
        return self._generation_capacity_kw
        
    def _set_generation_capacity_kw(self, value):
        if self._generation_capacity_kw != value:
            self._generation_capacity_kw = value
            self.generationCapacityChanged.emit()
            self.calculate()
    
    generation_capacity_kw = Property(float, _get_generation_capacity_kw, 
                              _set_generation_capacity_kw, notify=generationCapacityChanged)
    
    def _get_cable_length_km(self):
        return self._cable_length_km
        
    def _set_cable_length_km(self, value):
        if self._cable_length_km != value:
            self._cable_length_km = value
            self.cableLengthChanged.emit()
            self.calculate()
    
    cable_length_km = Property(float, _get_cable_length_km, 
                      _set_cable_length_km, notify=cableLengthChanged)
    
    def _get_cable_r_per_km(self):
        return self._cable_r_per_km
        
    def _set_cable_r_per_km(self, value):
        if self._cable_r_per_km != value:
            self._cable_r_per_km = value
            self.cableRPerKmChanged.emit()
            self.calculate()
    
    cable_r_per_km = Property(float, _get_cable_r_per_km, 
                     _set_cable_r_per_km, notify=cableRPerKmChanged)
    
    def _get_cable_x_per_km(self):
        return self._cable_x_per_km
        
    def _set_cable_x_per_km(self, value):
        if self._cable_x_per_km != value:
            self._cable_x_per_km = value
            self.cableXPerKmChanged.emit()
            self.calculate()
    
    cable_x_per_km = Property(float, _get_cable_x_per_km, 
                     _set_cable_x_per_km, notify=cableXPerKmChanged)
    
    def _get_load_distance_km(self):
        return self._load_distance_km
        
    def _set_load_distance_km(self, value):
        if self._load_distance_km != value:
            self._load_distance_km = value
            self.loadDistanceChanged.emit()
            self.calculate()
    
    load_distance_km = Property(float, _get_load_distance_km, 
                       _set_load_distance_km, notify=loadDistanceChanged)
    
    # Results properties
    @Property(float, notify=resultsChanged)
    def resistance(self):
        return self._results['resistance']
    
    @Property(float, notify=resultsChanged)
    def reactance(self):
        return self._results['reactance']
    
    @Property(float, notify=resultsChanged)
    def impedance(self):
        return self._results['impedance']
    
    @Property(float, notify=resultsChanged)
    def impedance_angle(self):
        return self._results['impedance_angle']
    
    @Property(list, notify=resultsChanged)
    def results_table(self):
        """Return results as a list of dictionaries for QML TableView"""
        return [
            {"parameter": "Resistance (R)", "value": f"{self._results['resistance']:.4f} Ω"},
            {"parameter": "Reactance (X)", "value": f"{self._results['reactance']:.4f} Ω"},
            {"parameter": "Impedance (Z)", "value": f"{self._results['impedance']:.4f} Ω"},
            {"parameter": "Impedance Angle", "value": f"{self._results['impedance_angle']:.2f}°"}
        ]
    
    @Slot()
    def calculate(self):
        """
        Calculate the R and X values based on the current parameters
        """
        # Calculate total length
        total_length_km = self._cable_length_km + self._load_distance_km
        
        # Calculate resistance and reactance
        total_resistance = self._cable_r_per_km * total_length_km
        total_reactance = self._cable_x_per_km * total_length_km
        
        # Factor in generation capacity (MW) - adjust reactance and resistance based on power
        # Using a simplified model where impedance is adjusted by the ratio of nominal power
        power_factor = self._generation_capacity_kw / 1000  # convert kW to MW
        
        # Apply power factor to adjust impedance values
        adjusted_resistance = total_resistance * (1 + 0.05 * power_factor)  # Example adjustment
        adjusted_reactance = total_reactance * (1 + 0.08 * power_factor)    # Example adjustment
        
        # Calculate impedance and angle
        total_impedance = np.sqrt(adjusted_resistance**2 + adjusted_reactance**2)
        impedance_angle = np.arctan2(adjusted_reactance, adjusted_resistance) * (180 / np.pi)
        
        # Update results
        self._results = {
            'resistance': adjusted_resistance,
            'reactance': adjusted_reactance,
            'impedance': total_impedance,
            'impedance_angle': impedance_angle
        }
        
        # Notify UI of changes
        self.resultsChanged.emit()
        
        return self._results
    
    @Slot()
    def generate_plot(self):
        """
        Generate a bar chart showing R and X values and save to file
        """
        try:
            output_path = "vr32_cl7_plot.png"
            
            results_df = pd.DataFrame({
                'Parameter': ['Resistance (R)', 'Reactance (X)', 'Impedance (Z)'],
                'Value (Ω)': [
                    round(self._results['resistance'], 4),
                    round(self._results['reactance'], 4),
                    round(self._results['impedance'], 4)
                ]
            })
            
            plt.figure(figsize=(8, 5))
            bars = plt.bar(results_df['Parameter'], results_df['Value (Ω)'], color=['blue', 'orange', 'green'])
            
            # Add values on top of the bars
            for bar in bars:
                height = bar.get_height()
                plt.text(bar.get_x() + bar.get_width()/2., height + 0.01,
                         f'{height:.4f} Ω', ha='center', fontweight='bold')
            
            plt.title('VR32 CL-7 Voltage Regulator: R and X Values')
            plt.ylabel('Value (Ω)')
            plt.grid(axis='y', linestyle='--', alpha=0.7)
            plt.tight_layout()
            
            plt.savefig(output_path)
            plt.close()
            
            return output_path
        except Exception as e:
            logger.error(f"Error generating plot: {e}")
            return None
    
    @Slot(str)
    def generate_plot_with_path(self, folder_path):
        """
        Generate a bar chart showing R and X values and save to the specified folder
        
        Args:
            folder_path (str): Path to the folder where the plot will be saved
        """
        try:
            # Use os.path to handle path separators correctly
            import os
            output_path = os.path.join(folder_path, "vr32_cl7_plot.png")
            
            results_df = pd.DataFrame({
                'Parameter': ['Resistance (R)', 'Reactance (X)', 'Impedance (Z)'],
                'Value (Ω)': [
                    round(self._results['resistance'], 4),
                    round(self._results['reactance'], 4),
                    round(self._results['impedance'], 4)
                ]
            })
            
            plt.figure(figsize=(8, 5))
            bars = plt.bar(results_df['Parameter'], results_df['Value (Ω)'], color=['blue', 'orange', 'green'])
            
            # Add values on top of the bars
            for bar in bars:
                height = bar.get_height()
                plt.text(bar.get_x() + bar.get_width()/2., height + 0.01,
                         f'{height:.4f} Ω', ha='center', fontweight='bold')
            
            plt.title('VR32 CL-7 Voltage Regulator: R and X Values')
            plt.ylabel('Value (Ω)')
            plt.grid(axis='y', linestyle='--', alpha=0.7)
            plt.tight_layout()
            
            plt.savefig(output_path)
            plt.close()
            
            logger.info(f"Plot saved to: {output_path}")
            return output_path
        except Exception as e:
            logger.error(f"Error generating plot: {e}")
            return None
    
    @Slot(str)
    def generate_plot_with_url(self, url):
        """
        Generate a plot using a URL from QML which works cross-platform
        
        Args:
            url (str): URL of the folder (file:/// format)
        """
        try:
            from urllib.parse import urlparse
            import os
            import platform
            
            # Parse the URL to get the path component
            parsed_url = urlparse(url)
            path = parsed_url.path
            
            # Handle Windows vs Unix paths
            if platform.system() == "Windows":
                # Windows URLs start with a /, so we remove it
                if path.startswith('/'):
                    path = path[1:]
            
            # Create output filename
            filename = "vr32_cl7_plot.png"
            output_path = os.path.join(path, filename)
            
            # Generate the plot
            results_df = pd.DataFrame({
                'Parameter': ['Resistance (R)', 'Reactance (X)', 'Impedance (Z)'],
                'Value (Ω)': [
                    round(self._results['resistance'], 4),
                    round(self._results['reactance'], 4),
                    round(self._results['impedance'], 4)
                ]
            })
            
            plt.figure(figsize=(8, 5))
            bars = plt.bar(results_df['Parameter'], results_df['Value (Ω)'], color=['blue', 'orange', 'green'])
            
            # Add values on top of the bars
            for bar in bars:
                height = bar.get_height()
                plt.text(bar.get_x() + bar.get_width()/2., height + 0.01,
                         f'{height:.4f} Ω', ha='center', fontweight='bold')
            
            plt.title('VR32 CL-7 Voltage Regulator: R and X Values')
            plt.ylabel('Value (Ω)')
            plt.grid(axis='y', linestyle='--', alpha=0.7)
            plt.tight_layout()
            
            plt.savefig(output_path)
            plt.close()
            
            logger.info(f"Plot saved to: {output_path}")
            return output_path
        except Exception as e:
            logger.error(f"Error generating plot: {e}")
            return None