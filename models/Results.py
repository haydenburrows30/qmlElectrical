from PySide6.QtCore import Slot, Signal, Property, QObject
from PySide6.QtGui import QImage
import json
import os
import shutil
import datetime
import traceback

class ResultsManager(QObject):
    """Manager for calculation results and image saving."""
    
    saveStatusChanged = Signal(bool, str)  # For reporting save status
    
    def __init__(self):
        super().__init__()
        self._results = []
        self._load_results()
    
    @Slot(dict)
    def save_calculation(self, result_dict):
        """Save calculation to results"""
        try:
            # Add timestamp
            result_dict["timestamp"] = datetime.datetime.now().isoformat()
            
            # Store in memory
            self._results.append(result_dict)
            
            # Ensure directory exists
            os.makedirs("results", exist_ok=True)
            
            # Save to file
            with open("results/calculations.json", "w") as f:
                json.dump(self._results, f, indent=2)
            
            self.saveStatusChanged.emit(True, "Calculation saved successfully")
        except Exception as e:
            self.saveStatusChanged.emit(False, f"Error saving calculation: {e}")
    
    def _load_results(self):
        """Load saved results"""
        try:
            if os.path.exists("results/calculations.json"):
                with open("results/calculations.json", "r") as f:
                    self._results = json.load(f)
        except Exception as e:
            print(f"Error loading results: {e}")
            self._results = []
    
    @Slot(str, str)
    def save_image(self, source_path, destination_path):
        """Helper to save image from temp location to final destination"""
        try:
            print(f"Received request to move image from {source_path} to {destination_path}")
            # Copy the file (shutil works better for cross-device moves)
            shutil.copy2(source_path, destination_path)
            # Remove the temporary file
            if os.path.exists(source_path):
                os.remove(source_path)
            self.saveStatusChanged.emit(True, f"Image saved to {destination_path}")
            return True
        except Exception as e:
            error_msg = f"Error saving image: {e}"
            print(error_msg)
            self.saveStatusChanged.emit(False, error_msg)
            return False
    
    @Slot(QImage, str, result=bool)
    def save_qimage(self, qimage, file_path):
        """Save QImage directly to a file path
           
        This bypasses the need for a temporary file and avoids path conversion issues.
        """
        try:
            print(f"Saving QImage directly to: {file_path}")
            
            # Ensure the directory exists
            dir_path = os.path.dirname(os.path.abspath(file_path))
            if dir_path:
                os.makedirs(dir_path, exist_ok=True)
            
            # Handle potential None image
            if qimage is None:
                print("Error: QImage object is None")
                self.saveStatusChanged.emit(False, "Error: Image data is empty")
                return False
                
            # Log image properties
            print(f"Image size: {qimage.width()}x{qimage.height()}, Format: {qimage.format()}")
            
            # Add debugging for file path
            print(f"Absolute path: {os.path.abspath(file_path)}")
            print(f"Directory exists: {os.path.exists(dir_path)}")
            print(f"Have write permission: {os.access(dir_path, os.W_OK) if dir_path else 'N/A'}")
            
            # Save the image directly with format specified
            success = qimage.save(file_path, "PNG")
            
            if success:
                print(f"Successfully saved image to {file_path}")
                self.saveStatusChanged.emit(True, f"Image saved to {file_path}")
                return True
            else:
                error_msg = f"Failed to save image to {file_path}"
                print(error_msg)
                self.saveStatusChanged.emit(False, error_msg)
                return False
                
        except Exception as e:
            error_msg = f"Error saving image: {e}"
            print(error_msg)
            print(traceback.format_exc())  # Print full traceback for debugging
            self.saveStatusChanged.emit(False, error_msg)
            return False
