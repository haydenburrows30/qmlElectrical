import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from PySide6.QtCore import QObject, Signal, Slot, Property

from services.logger_config import configure_logger

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
    exportComplete = Signal(bool, str)  # Add signal for export status
    
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
    
    @Slot(str, result=str)
    def generate_plot_for_file_saver(self, filepath):
        """
        Generate a bar chart showing R and X values and save to the specified filepath.
        Designed to work with FileSaver service.
        
        Args:
            filepath (str): Complete filepath where the plot will be saved
            
        Returns:
            str: The filepath if successful, empty string if failed
        """
        try:
            # If the filepath doesn't end with .png, add the extension
            if not filepath.lower().endswith('.png'):
                filepath += '.png'
                
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
            
            plt.savefig(filepath)
            plt.close()
            
            logger.info(f"Plot saved to: {filepath}")
            # Emit success signal for QML
            self.exportComplete.emit(True, f"Plot saved to: {filepath}")
            return filepath
        except Exception as e:
            error_msg = f"Error generating plot: {e}"
            logger.error(error_msg)
            # Emit failure signal for QML
            self.exportComplete.emit(False, error_msg)
            return ""
    
    @Slot(result=str)
    def exportPlot(self):
        """
        Export the plot to a file selected by the user.
        Handles file dialog and saving internally.
        
        Returns:
            str: Path to saved file or empty string if failed/canceled
        """
        try:
            from datetime import datetime
            from services.file_saver import FileSaver
            
            # Create a timestamp for the filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            default_filename = f"vr32_cl7_plot_{timestamp}"
            
            # Get the file_saver instance
            file_saver = FileSaver()
            
            # Get save filepath from user using FileSaver service
            filepath = file_saver.get_save_filepath("png", default_filename)
            
            if not filepath:
                self.exportComplete.emit(False, "Export canceled")
                return ""
            
            # Clean up filepath using FileSaver's helper methods
            filepath = file_saver.clean_filepath(filepath)
            filepath = file_saver.ensure_file_extension(filepath, "png")
            
            # Generate the plot directly
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
            
            plt.savefig(filepath)
            plt.close()
            
            logger.info(f"Plot saved to: {filepath}")
            self.exportComplete.emit(True, f"Plot saved to: {filepath}")
            return filepath
                
        except Exception as e:
            error_msg = f"Error exporting plot: {e}"
            logger.error(error_msg)
            self.exportComplete.emit(False, error_msg)
            return ""