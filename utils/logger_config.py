"""
Centralized logging configuration for the application.
"""
import os
import logging
import logging.handlers
from datetime import datetime
from pathlib import Path

# Maximum log file size (10 MB)
MAX_LOG_SIZE = 10 * 1024 * 1024
# Number of backup log files to keep
BACKUP_COUNT = 5

def get_log_dir():
    """Get the log directory path."""
    base_dir = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    log_dir = base_dir / 'logs'
    log_dir.mkdir(exist_ok=True)
    return log_dir

def get_log_file(name=None):
    """Get the log file path with optional component name."""
    log_dir = get_log_dir()
    if name:
        # Create component-specific log file
        return log_dir / f"{name}_{datetime.now().strftime('%Y%m%d')}.log"
    else:
        # Create main application log file
        return log_dir / f"app_{datetime.now().strftime('%Y%m%d')}.log"

def configure_logger(name="qmltest", level=logging.INFO, component=None):
    """Configure a logger with standard settings.
    
    Args:
        name: Base logger name (default: "qmltest")
        level: Logging level (default: INFO)
        component: Optional component name for specialized loggers
    
    Returns:
        Logger instance
    """
    # Create a unique logger name if component is specified
    logger_name = f"{name}.{component}" if component else name
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
    
    return logger

# Create root application logger
root_logger = configure_logger()