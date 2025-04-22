import os
import json
import pandas as pd
from pathlib import Path
from PySide6.QtCore import QObject, Signal, Slot, Property, QThread, QCoreApplication

try:
    from utils.logger_config import configure_logger
    # Setup component-specific logger
    logger = configure_logger("qmltest", component="file_saver")
except ImportError:
    import logging
    # Fallback logger if logger_config is not available
    logger = logging.getLogger("file_saver")
    handler = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)

class FileSaver(QObject):
    """
    Utility class for standardized file saving operations across the application.
    
    Features:
    - Default save location to user's documents folder
    - Consistent file dialogs
    - Support for various file formats (CSV, JSON, PDF, PNG)
    - Status feedback signals with file path information
    """
    
    saveStatusChanged = Signal(bool, str)
    # Signal to request dialog operation on main thread
    requestDialogOnMainThread = Signal(str, str, str, bool)
    dialogFinished = Signal(str)
    
    def __init__(self):
        super().__init__()
        self._default_folder = self._get_documents_folder()
        self._dialog_result = ""
        
        # Connect signal for main thread dialog operations
        self.requestDialogOnMainThread.connect(self._show_dialog_on_main_thread)
        
        logger.info(f"FileSaver initialized with default folder: {self._default_folder}")
        
    def _is_main_thread(self):
        """Check if the current thread is the main thread."""
        return QThread.currentThread() == QCoreApplication.instance().thread()
    
    def _get_documents_folder(self):
        """Get the user's documents folder."""
        try:
            # Use standard locations according to the OS
            documents = str(Path.home() / "Documents")
            if os.path.exists(documents):
                return documents
                
            # Fallback for different OS naming
            documents_alt = str(Path.home() / "My Documents")
            if os.path.exists(documents_alt):
                return documents_alt
                
            # Last resort, use home directory
            return str(Path.home())
        except Exception as e:
            logger.error(f"Error determining documents folder: {e}")
            return os.path.expanduser("~")
    
    def _emit_success_with_path(self, filepath, message=None):
        """Emit success with standardized message including file path."""
        if message:
            success_message = f"{message}: {filepath}"
        else:
            success_message = f"File saved to: {filepath}"
        
        logger.info(success_message)
        
        # Directly emit the signal without trying/catching
        # This makes behavior more predictable
        self.saveStatusChanged.emit(True, success_message)
        
        # Also log to console for debugging
        print(f"SUCCESS: {success_message}")
    
    @Slot(str, str, str, bool)
    def _show_dialog_on_main_thread(self, dialog_type, file_extension, default_path, save_mode):
        """Show file dialog on the main thread."""
        from PySide6.QtWidgets import QFileDialog
        
        # Ensure extension doesn't have a dot prefix
        if file_extension.startswith('.'):
            file_extension = file_extension[1:]
            
        # Create filter string
        filter_string = f"{file_extension.upper()} Files (*.{file_extension})"
        
        if save_mode:
            filepath, _ = QFileDialog.getSaveFileName(
                None,  # parent
                "Save File",  # title
                default_path,  # directory
                filter_string  # filter
            )
        else:
            filepath, _ = QFileDialog.getOpenFileName(
                None,  # parent
                "Open File",  # title
                default_path,  # directory
                filter_string  # filter
            )
        
        if filepath:
            # Only add extension if it's not already there and we're in save mode
            if save_mode and not filepath.lower().endswith(f".{file_extension.lower()}"):
                filepath = f"{filepath}.{file_extension}"
            
            logger.info(f"Selected {'save' if save_mode else 'open'} filepath: {filepath}")
        else:
            logger.info(f"File {'save' if save_mode else 'open'} canceled by user")
        
        # Set the result and emit signal
        self._dialog_result = filepath
        self.dialogFinished.emit(filepath)
    
    @Slot(str, str, result=str)
    def get_save_filepath(self, file_extension, default_filename):
        """
        Get a save filepath with the given extension and default filename.
        
        Args:
            file_extension: File extension without dot (e.g., 'csv', 'pdf')
            default_filename: Default filename without extension
            
        Returns:
            Full filepath or empty string if canceled
        """
        try:
            # Ensure extension doesn't have a dot prefix
            if file_extension.startswith('.'):
                file_extension = file_extension[1:]
                
            # Create default path
            default_path = os.path.join(self._default_folder, f"{default_filename}.{file_extension}")
            
            # Check if we're on the main thread
            if self._is_main_thread():
                # Direct dialog call if we're on the main thread
                from PySide6.QtWidgets import QFileDialog
                
                # Create filter string
                filter_string = f"{file_extension.upper()} Files (*.{file_extension})"
                
                filepath, _ = QFileDialog.getSaveFileName(
                    None,  # parent
                    "Save File",  # title
                    default_path,  # directory
                    filter_string  # filter
                )
                
                if filepath and not filepath.lower().endswith(f".{file_extension.lower()}"):
                    filepath = f"{filepath}.{file_extension}"
                    
                return filepath
            else:
                # We're not on the main thread, use the signal-slot mechanism
                logger.info("Not on main thread, requesting dialog on main thread")
                
                # Reset the dialog result
                self._dialog_result = ""
                
                # Request dialog on main thread
                self.requestDialogOnMainThread.emit("save", file_extension, default_path, True)
                
                # Here we would normally wait for the result, but this requires
                # a proper event loop integration. For simplicity, we'll assume
                # the user will handle this appropriately
                logger.warning("Dialog requested from non-main thread - returning empty string")
                logger.warning("Note: Use the dialogFinished signal to get the result asynchronously")
                return ""
                
        except Exception as e:
            logger.error(f"Error getting save filepath: {e}")
            self.saveStatusChanged.emit(False, f"Error selecting file: {e}")
            return ""
    
    @Slot(str, str, str, result=bool)
    def save_text_file(self, filepath, content, default_filename="exported_text"):
        """Save content to a text file."""
        try:
            # If no filepath provided, ask for one
            if not filepath:
                filepath = self.get_save_filepath("txt", default_filename)
                if not filepath:
                    self.saveStatusChanged.emit(False, "Save canceled")
                    return False
            
            # Ensure we don't double-add extension
            if not filepath.lower().endswith(".txt"):
                filepath += ".txt"
                
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            
            # Use standardized success message    
            self._emit_success_with_path(filepath, "Text saved")
            return True
        except Exception as e:
            error_msg = f"Error saving text file: {e}"
            logger.error(error_msg)
            self.saveStatusChanged.emit(False, error_msg)
            return False
            
    @Slot(str, 'QVariant', str, result=bool)
    def save_json(self, filepath, data, default_filename="exported_data"):
        """Save data to a JSON file."""
        try:
            # If no filepath provided, ask for one
            if not filepath:
                filepath = self.get_save_filepath("json", default_filename)
                if not filepath:
                    self.saveStatusChanged.emit(False, "Save canceled")
                    return False
            
            # Ensure we don't double-add extension
            if not filepath.lower().endswith(".json"):
                filepath += ".json"
                
            # Convert QJSValue to Python if needed
            if hasattr(data, 'toVariant'):
                data = data.toVariant()
                
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2)
            
            # Use standardized success message
            self._emit_success_with_path(filepath, "JSON data saved")
            return True
        except Exception as e:
            error_msg = f"Error saving JSON file: {e}"
            logger.error(error_msg)
            self.saveStatusChanged.emit(False, error_msg)
            return False
    
    @Slot(str, 'QVariant', 'QVariant', str, result=bool)
    def save_csv(self, filepath, data, metadata=None, default_filename="exported_data"):
        """
        Save data to a CSV file. Data can be a DataFrame or a dictionary-like structure.
        Optional metadata will be included as header comments.
        """
        try:
            # If no filepath provided, ask for one
            if not filepath:
                filepath = self.get_save_filepath("csv", default_filename)
                if not filepath:
                    self.saveStatusChanged.emit(False, "Save canceled")
                    return False
            
            # Ensure we don't double-add extension
            if not filepath.lower().endswith(".csv"):
                filepath += ".csv"
            
            # Convert data to DataFrame if it's not already
            if not isinstance(data, pd.DataFrame):
                # Handle QJSValue objects
                if hasattr(data, 'toVariant'):
                    data = data.toVariant()
                
                # Convert dictionary-like to DataFrame
                if isinstance(data, dict) and 'data' in data and 'headers' in data:
                    df = pd.DataFrame(data['data'], columns=data['headers'])
                else:
                    # Try to convert directly
                    df = pd.DataFrame(data)
            else:
                df = data
            
            # Create CSV with metadata header if provided
            if metadata:
                # Handle QJSValue objects
                if hasattr(metadata, 'toVariant'):
                    metadata = metadata.toVariant()
                    
                # Write metadata as comments
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write("# Exported Data\n")
                    for key, value in metadata.items():
                        f.write(f"# {key}: {value}\n")
                    
                    # Write DataFrame without index
                    df.to_csv(f, index=False)
            else:
                # Write DataFrame directly
                df.to_csv(filepath, index=False)
            
            # Use standardized success message
            self._emit_success_with_path(filepath, "CSV data saved")
            return True
        except Exception as e:
            error_msg = f"Error saving CSV file: {e}"
            logger.error(error_msg)
            self.saveStatusChanged.emit(False, error_msg)
            return False
    
    @Slot(str, 'QVariant', str, result=bool)
    def save_pdf(self, filepath, data, default_filename="exported_data"):
        """
        Save PDF with the provided generator function.
        
        Args:
            filepath: Target filepath or empty for dialog
            data: PDF content or generator data 
            default_filename: Default filename without extension
        """
        try:
            # If no filepath provided, ask for one
            if not filepath:
                filepath = self.get_save_filepath("pdf", default_filename)
                if not filepath:
                    self.saveStatusChanged.emit(False, "PDF export canceled")
                    return False
                
            # Ensure we're not adding .pdf extension if it's already there
            if not filepath.lower().endswith(".pdf"):
                filepath += ".pdf"
                
            # The actual PDF generation should be handled by the caller
            # This method just provides a consistent interface
            
            # Signal success with file path
            self._emit_success_with_path(filepath, "PDF saved")
            return True
        except Exception as e:
            error_msg = f"Error handling PDF file: {e}"
            logger.error(error_msg)
            self.saveStatusChanged.emit(False, error_msg)
            return False
    
    @Slot(str, result=str)
    def get_load_filepath(self, file_extension):
        """
        Show a file open dialog and return the selected file path.
        
        Args:
            file_extension: File extension without dot (e.g., 'csv', 'pdf')
            
        Returns:
            Full filepath or empty string if canceled
        """
        try:
            # Ensure extension doesn't have a dot prefix
            if file_extension.startswith('.'):
                file_extension = file_extension[1:]
            
            # Check if we're on the main thread
            if self._is_main_thread():
                # Direct dialog call if we're on the main thread
                from PySide6.QtWidgets import QFileDialog
                
                # Create filter string
                filter_string = f"{file_extension.upper()} Files (*.{file_extension})"
                
                filepath, _ = QFileDialog.getOpenFileName(
                    None,  # parent
                    "Open File",  # title
                    self._default_folder,  # directory
                    filter_string  # filter
                )
                
                return filepath
            else:
                # We're not on the main thread, use the signal-slot mechanism
                logger.info("Not on main thread, requesting dialog on main thread")
                
                # Reset the dialog result
                self._dialog_result = ""
                
                # Request dialog on main thread
                self.requestDialogOnMainThread.emit("open", file_extension, self._default_folder, False)
                
                # Here we would normally wait for the result, but this requires
                # a proper event loop integration. For simplicity, we'll assume
                # the user will handle this appropriately
                logger.warning("Dialog requested from non-main thread - returning empty string")
                logger.warning("Note: Use the dialogFinished signal to get the result asynchronously")
                return ""
                
        except Exception as e:
            logger.error(f"Error getting open filepath: {e}")
            self.saveStatusChanged.emit(False, f"Error selecting file: {e}")
            return ""
    
    @Property(str)
    def defaultFolder(self):
        """Get the default save folder path."""
        return self._default_folder
    
    @Slot(str, result=bool)
    def setDefaultFolder(self, folder_path):
        """Set a custom default save folder."""
        if os.path.exists(folder_path) and os.path.isdir(folder_path):
            self._default_folder = folder_path
            logger.info(f"Default save folder changed to: {folder_path}")
            return True
        else:
            logger.warning(f"Invalid folder path: {folder_path}")
            return False
