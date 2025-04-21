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

# Cache log file paths to avoid repeated calculations
_LOG_FILES = {}
_LOG_FILES_LOCK = threading.Lock()

def get_log_file(name=None):
    """Get the log file path with optional component name."""
    date_key = datetime.now().strftime('%Y%m%d')
    cache_key = f"{name}_{date_key}" if name else f"app_{date_key}"
    
    with _LOG_FILES_LOCK:
        if cache_key not in _LOG_FILES:
            log_dir = get_log_dir()
            if name:
                # Create component-specific log file
                _LOG_FILES[cache_key] = log_dir / f"{name}_{date_key}.log"
            else:
                # Create main application log file
                _LOG_FILES[cache_key] = log_dir / f"app_{date_key}.log"
    
    return _LOG_FILES[cache_key]

# Cache loggers to avoid duplicating setup
_LOGGERS = {}
_LOGGERS_LOCK = threading.Lock()

def configure_logger(name="qmltest", level=logging.INFO, component=None):
    """Configure a logger with standard settings."""
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
        
        # Main log file (with rotation)
        main_log_file = get_log_file()
        file_handler = logging.handlers.RotatingFileHandler(
            main_log_file, 
            maxBytes=MAX_LOG_SIZE, 
            backupCount=BACKUP_COUNT
        )
        file_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(file_formatter)
        file_handler.setLevel(logging.INFO)
        logger.addHandler(file_handler)
        
        # Component-specific log (if requested)
        if component:
            component_log_file = get_log_file(component)
            component_handler = logging.handlers.RotatingFileHandler(
                component_log_file,
                maxBytes=MAX_LOG_SIZE, 
                backupCount=BACKUP_COUNT
            )
            component_handler.setFormatter(file_formatter)
            component_handler.setLevel(logging.DEBUG)  # Component files get more details
            logger.addHandler(component_handler)
        
        # Console handler for warnings and errors
        console_handler = logging.StreamHandler()
        console_formatter = logging.Formatter('%(levelname)s: %(message)s')
        console_handler.setFormatter(console_formatter)
        console_handler.setLevel(logging.WARNING)
        logger.addHandler(console_handler)
        
        # Cache the configured logger
        with _LOGGERS_LOCK:
            _LOGGERS[logger_name] = logger
    
    return logger

# Create root application logger
root_logger = configure_logger()