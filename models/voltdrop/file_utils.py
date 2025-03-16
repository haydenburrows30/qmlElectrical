import os
import json
import pandas as pd
from PySide6.QtCore import QObject, Signal, QUrl
from PySide6.QtWidgets import QFileDialog

class FileUtils(QObject):
    """Utility class for file operations."""
    
    saveStatusChanged = Signal(bool, str)
    fileDialogRequested = Signal(str, str, str)  # type, default_dir, default_name
    
    def __init__(self):
        super().__init__()
        self._results_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'results'))
        os.makedirs(self._results_dir, exist_ok=True)
        
    def get_results_dir(self):
        """Get the results directory path."""
        return self._results_dir
        
    def normalize_filepath(self, filepath):
        """Normalize filepath from different input types."""
        if isinstance(filepath, QUrl):
            return filepath.toLocalFile()
        elif filepath and isinstance(filepath, str) and filepath.startswith('file:///'):
            return QUrl(filepath).toLocalFile()
        return filepath
        
    def get_save_filepath(self, file_type, default_name=None, default_dir=None):
        """Show file dialog and get save filepath."""
        if default_dir is None:
            default_dir = self._results_dir
            
        if default_name is None:
            timestamp = pd.Timestamp.now().strftime('%Y-%m-%d-%H-%M-%S')
            default_name = f"voltage_drop_{timestamp}"
            
        # Choose extension and filter based on file_type
        extension = ""
        filter_str = ""
        if file_type == "csv":
            extension = "csv"
            filter_str = "CSV files (*.csv)"
            if not default_name.endswith(".csv"):
                default_name += ".csv"
        elif file_type == "json":
            extension = "json"
            filter_str = "JSON files (*.json)"
            if not default_name.endswith(".json"):
                default_name += ".json"
        elif file_type == "pdf":
            extension = "pdf"
            filter_str = "PDF files (*.pdf)"
            if not default_name.endswith(".pdf"):
                default_name += ".pdf"
        elif file_type == "png":
            extension = "png"
            filter_str = "PNG files (*.png)"
            if not default_name.endswith(".png"):
                default_name += ".png"
                
        default_path = os.path.join(default_dir, default_name)
        
        # Use QFileDialog
        dialog = QFileDialog()
        dialog.setFileMode(QFileDialog.AnyFile)
        dialog.setAcceptMode(QFileDialog.AcceptSave)
        dialog.setDefaultSuffix(extension)
        dialog.setNameFilter(filter_str)
        dialog.selectFile(default_path)
        
        if dialog.exec() == QFileDialog.Accepted:
            return dialog.selectedFiles()[0]
        
        return None

    def save_csv(self, filepath, data, metadata=None):
        """Save data to a CSV file with optional metadata."""
        try:
            filepath = self.normalize_filepath(filepath)
            
            if not filepath:
                self.saveStatusChanged.emit(False, "No filepath provided")
                return False

            # Write metadata as comments if provided
            if metadata:
                with open(filepath, 'w') as f:
                    f.write(f"# Voltage Drop Calculation - {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                    for key, value in metadata.items():
                        f.write(f"# {key}: {value}\n")
                    f.write("\n")
                
                # Convert data to DataFrame if it's not already
                if not isinstance(data, pd.DataFrame):
                    data = pd.DataFrame(data)
                
                # Append the data
                data.to_csv(filepath, mode='a', index=False)
            else:
                # If no metadata, just write the data
                if not isinstance(data, pd.DataFrame):
                    data = pd.DataFrame(data)
                data.to_csv(filepath, index=False)
                
            self.saveStatusChanged.emit(True, f"Data saved to {filepath}")
            return True
            
        except Exception as e:
            self.saveStatusChanged.emit(False, f"Error saving CSV: {e}")
            return False

    def save_json(self, filepath, data):
        """Save data to a JSON file."""
        try:
            filepath = self.normalize_filepath(filepath)
            
            if not filepath:
                self.saveStatusChanged.emit(False, "No filepath provided")
                return False

            # Save the JSON data
            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)
                
            self.saveStatusChanged.emit(True, f"Data saved to {filepath}")
            return True
            
        except Exception as e:
            self.saveStatusChanged.emit(False, f"Error saving JSON: {e}")
            return False
            
    def save_calculation_history(self, calculation_data):
        """Save calculation history to a CSV file."""
        try:
            filepath = os.path.join(self._results_dir, 'calculations_history.csv')
            
            # Convert to DataFrame
            df = pd.DataFrame([calculation_data])
            
            # Check if file exists to determine if we need headers
            file_exists = os.path.isfile(filepath)
            df.to_csv(filepath, mode='a', header=not file_exists, index=False)
            
            success_msg = f"Calculation saved to {filepath}"
            self.saveStatusChanged.emit(True, success_msg)
            return True
            
        except Exception as e:
            error_msg = f"Error saving calculation: {e}"
            self.saveStatusChanged.emit(False, error_msg)
            return False
