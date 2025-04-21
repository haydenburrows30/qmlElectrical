"""
Centralized logging configuration for the application.
"""
import os
import logging
import logging.handlers
from datetime import datetime
from pathlib import Path
import threading

# Maximum log file size (10 MB)
MAX_LOG_SIZE = 10 * 1024 * 1024
# Number of backup log files to keep
BACKUP_COUNT = 5

# Global configuration options
ROOT_CAPTURE_ENABLED = False  # Set to False to prevent double logging
DEBUG_LOGGING = os.environ.get("QMLTEST_DEBUG_LOGGING", "0") == "1"

# Cache the log directory
_LOG_DIR = None
_LOG_DIR_LOCK = threading.Lock()

def get_log_dir():
    """Get the log directory path."""
    global _LOG_DIR
    
    if _LOG_DIR is None:
        with _LOG_DIR_LOCK:
            if _LOG_DIR is None:  # Double-check to prevent race conditions
                base_dir = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
                _LOG_DIR = base_dir / 'logs'
                _LOG_DIR.mkdir(exist_ok=True)
    
    return _LOG_DIR

# Cache log file path
_LOG_FILE = None
_LOG_FILE_LOCK = threading.Lock()

def get_log_file():
    """Get the log file path."""
    global _LOG_FILE
    
    if _LOG_FILE is None:
        with _LOG_FILE_LOCK:
            if _LOG_FILE is None:  # Double-check to prevent race conditions
                log_dir = get_log_dir()
                date_key = datetime.now().strftime('%Y%m%d')
                _LOG_FILE = log_dir / f"app_{date_key}.log"
    
    return _LOG_FILE

# Cache loggers to avoid duplicating setup
_LOGGERS = {}
_LOGGERS_LOCK = threading.Lock()

# Single shared handler for all loggers
_SHARED_HANDLER = None
_HANDLER_LOCK = threading.Lock()

def configure_logger(name="qmltest", level=logging.INFO, component=None):
    """Configure a logger with standard settings."""
    global _SHARED_HANDLER
    
    # Create a unique logger name if component is specified
    logger_name = f"{name}.{component}" if component else name
    
    # Use cached logger if available
    with _LOGGERS_LOCK:
        if logger_name in _LOGGERS:
            return _LOGGERS[logger_name]
    
    logger = logging.getLogger(logger_name)
    
    # Only configure if this logger hasn't been set up already
    if not logger.handlers:
        logger.setLevel(level)
        
        # Use a shared file handler for all loggers
        with _HANDLER_LOCK:
            if _SHARED_HANDLER is None:
                # Create formatter
                file_formatter = logging.Formatter(
                    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
                )
                
                # Create the shared file handler
                log_file = get_log_file()
                _SHARED_HANDLER = logging.handlers.RotatingFileHandler(
                    log_file, 
                    maxBytes=MAX_LOG_SIZE, 
                    backupCount=BACKUP_COUNT
                )
                _SHARED_HANDLER.setFormatter(file_formatter)
                _SHARED_HANDLER.setLevel(logging.INFO)
            
            # Add the shared handler to this logger
            logger.addHandler(_SHARED_HANDLER)
            
            # Add console handler for warnings and errors
            console_handler = logging.StreamHandler()
            console_formatter = logging.Formatter('%(levelname)s: %(message)s')
            console_handler.setFormatter(console_formatter)
            console_handler.setLevel(logging.WARNING)
            logger.addHandler(console_handler)
        
        # IMPORTANT: Disable propagation to the root logger to avoid duplicate logs
        # This is the key setting that prevents duplicates:
        logger.propagate = ROOT_CAPTURE_ENABLED  # Set to False
        
        # Print debug info if enabled
        if DEBUG_LOGGING:
            print(f"Configured logger: {logger_name}, propagate={logger.propagate}")
        
        # Cache the configured logger
        with _LOGGERS_LOCK:
            _LOGGERS[logger_name] = logger
    
    return logger

# Configure root logger to have a higher threshold to reduce noise
def configure_root_logger():
    """Configure the root logger with minimal handlers to prevent duplicates."""
    root_logger = logging.getLogger()
    
    # Only set up once
    if not root_logger.handlers:
        # Set a higher threshold for the root logger
        root_logger.setLevel(logging.WARNING)
        
        if DEBUG_LOGGING:
            # Add a minimal console handler for debugging
            handler = logging.StreamHandler()
            handler.setFormatter(logging.Formatter('ROOT: %(levelname)s - %(name)s - %(message)s'))
            handler.setLevel(logging.DEBUG)
            root_logger.addHandler(handler)
            print("Root logger configured with DEBUG handler")

# Configure the root logger immediately
configure_root_logger()

# Create root application logger
root_logger = configure_logger()