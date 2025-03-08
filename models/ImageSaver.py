from PySide6.QtCore import QObject, Slot, Signal
from PySide6.QtGui import QImage
import os
import tempfile
import shutil
import traceback

class ImageSaver(QObject):
    """Fallback image saving utility for QtQuick"""
    
    saveComplete = Signal(bool, str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
    
    @Slot(QImage, str)
    def saveImage(self, image, filePath):
        """Save a QImage to the specified file path"""
        try:
            print(f"ImageSaver: Saving image to {filePath}")
            
            # Create directory if it doesn't exist
            directory = os.path.dirname(filePath)
            if directory and not os.path.exists(directory):
                os.makedirs(directory, exist_ok=True)
            
            # Try direct save first
            if image.save(filePath, "PNG"):
                print(f"ImageSaver: Successfully saved to {filePath}")
                self.saveComplete.emit(True, f"Image saved to {filePath}")
                return
            
            # If direct save fails, try using a temporary file
            print("ImageSaver: Direct save failed, trying with temporary file")
            with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as tmp:
                temp_path = tmp.name
            
            print(f"ImageSaver: Using temporary file {temp_path}")
            if image.save(temp_path, "PNG"):
                # Copy from temp location to final destination
                shutil.copy2(temp_path, filePath)
                # Clean up temp file
                os.remove(temp_path)
                print(f"ImageSaver: Successfully saved via temp file to {filePath}")
                self.saveComplete.emit(True, f"Image saved to {filePath}")
            else:
                raise RuntimeError("Failed to save image to temporary location")
                
        except Exception as e:
            print(f"ImageSaver Error: {str(e)}")
            print(traceback.format_exc())
            self.saveComplete.emit(False, f"Error saving image: {str(e)}")
