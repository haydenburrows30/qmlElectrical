import os
import sys
import logging

# Add project root to Python path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

# Import the database manager
from services.database_manager import DatabaseManager

# Set up logger
logger = logging.getLogger("qmltest.database.init")

def init_database():
    """Initialize the application database."""
    try:
        # Get database manager instance
        db_path = os.path.join(project_root, 'data', 'application_data.db')
        logger.info(f"Initializing database at {db_path}")
        
        db_manager = DatabaseManager.get_instance(db_path)
        
        # Database will be automatically initialized by the manager if needed
        logger.info("Database initialization complete")
        return True
        
    except Exception as e:
        logger.error(f"Error initializing database: {e}")
        return False

if __name__ == "__main__":
    # Configure basic logging for standalone execution
    logging.basicConfig(level=logging.INFO, 
                        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    
    success = init_database()
    if success:
        print("Successfully initialized database")
    else:
        print("Failed to initialize database")
        sys.exit(1)
