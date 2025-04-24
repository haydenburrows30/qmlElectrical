import os
import json
import pandas as pd
from pathlib import Path
from PySide6.QtCore import QObject, Signal, Slot, Property, QThread, QCoreApplication

from services.logger_config import configure_logger

# Setup component-specific logger
logger = configure_logger("qmltest", component="file_saver")

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
    
    def _emit_failure_with_path(self, filepath, message=None):
        """Emit failure with standardized message including file path."""
        if message:
            failure_message = f"{message}: {filepath}"
        else:
            failure_message = f"Error saving file: {filepath}"
        
        logger.info(failure_message)
        
        # Fix: Change True to False for failure status
        self.saveStatusChanged.emit(False, failure_message)
        
        # Also log to console for debugging
        print(f"FAILURE: {failure_message}")
    
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
    
    @Slot('QObject', str, result=bool)
    def save_plot(self, calculator, default_filename="vr32_cl7_plot"):
        """
        Save plot from a calculator object that has a generate_plot_for_file_saver method.
        
        Args:
            calculator: An object with a generate_plot_for_file_saver method
            default_filename: Default filename without extension
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            # Check if the calculator has the required method
            if not hasattr(calculator, 'generate_plot_for_file_saver'):
                error_msg = "Calculator does not have a generate_plot_for_file_saver method"
                logger.error(error_msg)
                self.saveStatusChanged.emit(False, error_msg)
                return False
                
            # Get a filepath from user
            filepath = self.get_save_filepath("png", default_filename)
            if not filepath:
                self.saveStatusChanged.emit(False, "Plot save canceled")
                return False
                
            # Generate the plot using the calculator's method
            result_path = calculator.generate_plot_for_file_saver(filepath)
            
            if result_path:
                # Use standardized success message
                self._emit_success_with_path(result_path, "Plot saved")
                return True
            else:
                error_msg = "Failed to generate plot"
                logger.error(error_msg)
                self.saveStatusChanged.emit(False, error_msg)
                return False
                
        except Exception as e:
            error_msg = f"Error saving plot: {e}"
            logger.error(error_msg)
            self.saveStatusChanged.emit(False, error_msg)
            return False

    @Slot(str, result='QVariant')
    def load_json(self, filepath):
        """
        Load JSON data from a file.
        
        Args:
            filepath: Path to the JSON file (can be a URL from QML FileDialog)
            
        Returns:
            The parsed JSON data or None if loading failed
        """
        try:
            # Clean the filepath (handle file:/// URLs)
            clean_path = self.clean_filepath(filepath)
            
            if not clean_path:
                error_msg = "No filepath provided"
                logger.error(error_msg)
                self.saveStatusChanged.emit(False, error_msg)
                return None
                
            if not os.path.exists(clean_path):
                error_msg = f"File does not exist: {clean_path}"
                logger.error(error_msg)
                self.saveStatusChanged.emit(False, error_msg)
                return None
            
            with open(clean_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            logger.info(f"Successfully loaded JSON from: {clean_path}")
            self.saveStatusChanged.emit(True, f"JSON loaded from: {clean_path}")
            return data
            
        except json.JSONDecodeError as e:
            error_msg = f"Invalid JSON file: {e}"
            logger.error(error_msg)
            self.saveStatusChanged.emit(False, error_msg)
            return None
            
        except Exception as e:
            error_msg = f"Error loading JSON file: {e}"
            logger.error(error_msg)
            self.saveStatusChanged.emit(False, error_msg)
            return None

    @Slot(str, result='QVariant')
    def load_json_with_dialog(self, default_filename=""):
        """
        Show a file open dialog and load the selected JSON file.
        
        Args:
            default_filename: Optional default filename (without extension)
            
        Returns:
            The parsed JSON data or None if loading failed or canceled
        """
        try:
            # Get filepath from dialog
            filepath = self.get_load_filepath("json")
            
            if not filepath:
                logger.info("JSON file selection canceled by user")
                self.saveStatusChanged.emit(False, "JSON loading canceled")
                return None
                
            # Now load the JSON file
            return self.load_json(filepath)
            
        except Exception as e:
            error_msg = f"Error loading JSON file with dialog: {e}"
            logger.error(error_msg)
            self.saveStatusChanged.emit(False, error_msg)
            return None

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
    
    @Slot(str, result=str)
    def clean_filepath(self, filepath):
        """
        Clean up file paths from different sources (QML, file dialogs, etc.)
        Handles platform-specific issues and file:/// URLs
        
        Args:
            filepath (str): The filepath to clean
            
        Returns:
            str: Cleaned filepath
        """
        try:
            import platform
            import os
            
            if not filepath:
                return ""
                
            # Clean up filepath - handle QML URL format
            clean_path = filepath.strip()
            
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
            
            logger.debug(f"Cleaned filepath: {filepath} -> {clean_path}")
            return clean_path
            
        except Exception as e:
            logger.error(f"Error cleaning filepath: {e}")
            return filepath
    
    @Slot(str, str, result=str)
    def ensure_file_extension(self, filepath, extension):
        """
        Ensure filepath has the correct extension
        
        Args:
            filepath (str): The filepath to check
            extension (str): The extension to ensure (without dot)
            
        Returns:
            str: Filepath with correct extension
        """
        try:
            if not filepath:
                return ""
                
            # Remove any leading dot from extension
            if extension.startswith('.'):
                extension = extension[1:]
                
            # Ensure filepath has the correct extension
            if not filepath.lower().endswith(f".{extension.lower()}"):
                filepath += f".{extension}"
            
            return filepath
            
        except Exception as e:
            logger.error(f"Error ensuring file extension: {e}")
            return filepath
