import os
import threading
from PySide6.QtCore import QObject, Signal, Slot, QUrl
import logging

logger = logging.getLogger("qmltest")

class LogFileHelper(QObject):
    """Helper class for file operations on logs."""
    
    saveComplete = Signal(bool, str)
    
    def __init__(self, parent=None):
        super().__init__(parent)
    
    @Slot(QUrl, str, result=bool)
    def saveLogsToFile(self, file_url, content):
        """Save logs to a file.
        
        Args:
            file_url: QUrl of the file to save
            content: The log content to save
            
        Returns:
            bool: True if successful, False otherwise
        """
        # Convert QUrl to local path for thread
        if file_url.isLocalFile():
            path = file_url.toLocalFile()
        else:
            path = str(file_url).replace('file://', '')
        
        # Use a thread to avoid blocking the UI
        def save_thread():
            try:
                # Ensure directory exists
                os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
                
                # Write content to file
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                # Signal completion on the main thread
                self.saveComplete.emit(True, path)
                
            except Exception as e:
                logger.error(f"Error saving logs: {e}")
                self.saveComplete.emit(False, str(e))
        
        # Start the thread
        thread = threading.Thread(target=save_thread)
        thread.daemon = True
        thread.start()
        
        return True  # Return immediately, actual result will come via signal
