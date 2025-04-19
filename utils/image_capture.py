import os
from PySide6.QtCore import QObject, Signal, Slot, Qt, QTimer, QSize
from PySide6.QtQuick import QQuickItem
from PySide6.QtGui import QImage, QPainter

class ImageCapture(QObject):
    captureComplete = Signal()
    
    def __init__(self):
        super().__init__()
        # Create full path to assets/images directory
        self._assets_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'assets', 'images')
        
        # Ensure directory exists
        try:
            os.makedirs(self._assets_path, exist_ok=True)
            print(f"Image directory ready: {self._assets_path}")
        except Exception as e:
            print(f"Error creating directory: {str(e)}")
    
    @Slot(QQuickItem)
    def capture_cabinet_diagram(self, canvas_item):
        """Capture the cabinet diagram canvas and save as PNG"""
        try:
            if isinstance(canvas_item, QQuickItem):
                print(f"Starting capture, canvas size: {canvas_item.width()}x{canvas_item.height()}")
                # Force a repaint
                canvas_item.update()
                # Wait for next frame
                QTimer.singleShot(50, lambda: self._do_capture(canvas_item))
                return True
        except Exception as e:
            print(f"Error capturing image: {str(e)}")
            return False
    
    def _do_capture(self, canvas_item):
        try:
            # Create image with specific size
            size = QSize(800, 600)
            print("Creating grab result...")
            
            def grab_ready():
                grab_result = canvas_item.grabToImage()
                if grab_result:
                    grab_result.ready.connect(
                        lambda: self._save_grabbed_image(grab_result)
                    )
            
            # Schedule grab for next frame
            QTimer.singleShot(50, grab_ready)
                
        except Exception as e:
            print(f"Error during capture: {str(e)}")

    def _save_grabbed_image(self, grab_result):
        """Save the grabbed image as PNG"""
        try:
            image = grab_result.image()
            if not image.isNull():
                filepath = os.path.join(self._assets_path, 'cabinet_diagram.png')
                print(f"Saving image {image.width()}x{image.height()} to {filepath}")
                success = image.save(filepath, 'PNG', -1)  # -1 means default compression
                if success:
                    print("Image saved successfully")
                    QTimer.singleShot(100, self.captureComplete.emit)  # Delay signal slightly
                else:
                    print("Failed to save image")
            else:
                print("Image is null")
        except Exception as e:
            print(f"Error saving image: {str(e)}")
