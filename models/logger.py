import logging
import os
from datetime import datetime

def setup_logger(name="qmltest", level=logging.INFO):
    """Configure application-wide logging system.
    
    Args:
        name: Logger name
        level: Logging level (default: INFO)
    
    Returns:
        Logger instance
    """
    # Create logs directory if it doesn't exist
    log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')
    os.makedirs(log_dir, exist_ok=True)
    
    # Set up log file with timestamp
    log_file = os.path.join(log_dir, f'app_{datetime.now().strftime("%Y%m%d")}.log')
    
    # Configure logger
    logger = logging.getLogger(name)
    logger.setLevel(level)
    
    # Add file handler if not already added
    if not logger.handlers:
        file_handler = logging.FileHandler(log_file)
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
        
        # Also add console handler for development
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)
    
    return logger
