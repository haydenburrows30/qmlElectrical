# Standard library imports
import sys
import traceback
import os
from pathlib import Path

# Qt imports
from PySide6.QtWidgets import QApplication
from PySide6.QtGui import QIcon
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtQml import qmlRegisterType, QQmlApplicationEngine

# Application imports
# Core services
from services.qml_types import register_qml_types
from services.loading_manager import LoadingManager
from services.worker_pool import WorkerPool

# Utilities
from services.config import app_config
from utils.qml_debug import register_debug_helper
# Use the new logger directly
from services.logger import QLogManager
from services.platform_helper import PlatformHelper
from services.cache_manager import CacheManager
from services.cache_utils import setup_qml_cache
from utils.windows_utils import setup_windows_specifics, set_gpu_attributes
from utils.preload_manager import PreloadManager
from services.lightweight_performance import LightweightPerformanceMonitor
from services.logger_config import configure_logger
from services.about_program import ConfigBridge
# Import the new FileSaver class
from services.file_saver import FileSaver

# Resources
import data.rc_resources as rc_resources

# Constants
CURRENT_DIR = Path(__file__).parent

# Set up application-wide logger
logger = configure_logger("qmltest", component="main")

class Application:
    """Main application class implementing component management.
    
    This class serves as the primary application controller, managing:
    - QML registration
    - Application lifecycle
    """
    
    def __init__(self):
        """Initialize application with configuration."""
        self.config = app_config
        
        self.app = QApplication(sys.argv)

        # Use the configured logger instead of creating a new one
        self.logger = logger
        
        # Setup QML engine directly
        self.qml_engine = QQmlApplicationEngine()

        self.debug_helper = register_debug_helper(self.qml_engine)

        self.qml_engine.addImportPath(str(CURRENT_DIR.parent))
        self.qml_engine.addImportPath(str(CURRENT_DIR))
        self.qml_engine.addImportPath(str(CURRENT_DIR / "qml" / "components"))
        self.qml_engine.clearComponentCache()

        # Setup core services
        self.loading_manager = LoadingManager()
        self.qml_engine.rootContext().setContextProperty("loadingManager", self.loading_manager)
        self.worker_pool = WorkerPool()

        # Initialize application
        self.setup()

    def setup_app(self):
        """Configure application using loaded config."""
        QQuickStyle.setStyle(self.config.style)
        QApplication.setApplicationName(self.config.app_name)
        QApplication.setOrganizationName(self.config.org_name)
        QApplication.setWindowIcon(QIcon(self.config.icon_path))
        QIcon.setThemeName("gallery")

    def register_qml_types(self):
        """Register QML types using external registration function."""
        qml_types = register_qml_types(self.qml_engine, str(CURRENT_DIR))
        for type_info in qml_types:
            try:
                type_class, uri, major, minor, name = type_info
                qmlRegisterType(type_class, uri, major, minor, name)
            except Exception as e:
                self.logger.warning(f"Could not register type: {e}")
        
        # Register the FileSaver class
        qmlRegisterType(FileSaver, "FileSaverUtils", 1, 0, "FileSaver")

    def load_qml(self):
        """Load main QML file and register context properties."""
        # Create and expose log manager to QML
        self.log_manager = QLogManager()
        self.qml_engine.rootContext().setContextProperty("logManager", self.log_manager)

        # Use ConfigBridge to expose app config to QML instead of direct exposure
        self.config_bridge = ConfigBridge()
        self.qml_engine.rootContext().setContextProperty("appConfig", self.config_bridge)
        
        # PlatformHelper keeps a context property for backward compatibility
        self.qml_engine.rootContext().setContextProperty("PlatformHelper", PlatformHelper())
        
        # Load main QML file
        main_qml = CURRENT_DIR / "qml" / "main.qml"
        self.qml_engine.load(str(main_qml))

    def setup(self):
        """Configure application components and initialize subsystems."""
        self.setup_app()

        self.register_qml_types()

        # Core properties needed for the app
        self.preload_manager = PreloadManager()
        self.qml_engine.rootContext().setContextProperty("preloadManager", self.preload_manager)
        
        self.performance_monitor = LightweightPerformanceMonitor()
        self.qml_engine.rootContext().setContextProperty("perfMonitor", self.performance_monitor)
        
        # Application metadata
        self.qml_engine.rootContext().setContextProperty("appVersion", self.config.version)
        self.qml_engine.rootContext().setContextProperty("applicationTitle", self.config.app_name)

        self.load_qml()
        
        # Start preloading QML components after the main UI is loaded
        self._setup_preloading()
    
    def _setup_preloading(self):
        """Set up preloading of QML components."""
        # Get QML directories from config
        qml_directories = app_config.get_qml_directories()
        
        # Add each directory to preload manager
        for _, dir_path in qml_directories.items():
            self.preload_manager.add_directory(str(dir_path))
        
        # Start preloading
        self.preload_manager.start_preloading(self.qml_engine)
    
    def run(self):
        """Run the application."""
        try:
            sys.exit(self.app.exec())
        finally:
            # Clean up resources when application exits
            if hasattr(self, 'log_manager') and hasattr(self.log_manager, '_async_handler'):
                # Stop the async log handler to allow thread to exit
                self.log_manager._async_handler.stop()
            
            self.worker_pool.shutdown()

def main():
    """Application entry point."""
    try:
        # Enable debug logging if requested via command line
        if "--debug-logging" in sys.argv:
            os.environ["QMLTEST_DEBUG_LOGGING"] = "1"
            print("DEBUG LOGGING ENABLED")
        
        # Log application startup
        logger.info("Application starting...")
        
        # Setup environment from config
        app_config.setup_environment()
        
        # Setup Windows-specific configuration
        setup_windows_specifics()
        
        # Handle cache setup
        if app_config.args.clear_cache:
            cache_manager = CacheManager()
            print("Clearing QML cache...")
            cache_manager.clear_cache()
        
        # Set up QML cache unless disabled
        if not app_config.args.no_cache:
            cache_manager = CacheManager()
            app_name = app_config.app_name
            cache_manager.initialize(app_name)
            setup_qml_cache(str(CURRENT_DIR), app_name)
        
        # Set GPU-specific attributes
        set_gpu_attributes()
        
        # Create and run application as a single step
        Application().run()
        
    except Exception as e:
        logger.critical(f"ERROR during startup: {str(e)}")
        logger.critical(traceback.format_exc())
        sys.exit(1)

if __name__ == "__main__":
    main()