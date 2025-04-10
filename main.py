# Standard library imports
import os
import sys
import logging
import asyncio
from typing import Optional

# Qt imports
from PySide6.QtWidgets import QApplication
from PySide6.QtGui import QIcon
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtQml import qmlRegisterType

# Application imports
from services.interfaces import (
    ICalculatorFactory, 
    IModelFactory,
    IQmlEngine,
    ILogger
)
from services.container import Container
from services.implementations import DefaultLogger, QmlEngineWrapper, ModelFactory
from services.qml_types import register_qml_types
from services.loading_manager import LoadingManager
from services.worker_pool import WorkerPool

from utils.config import app_config
from utils.qml_debug import register_debug_helper
from utils.logger import QLogManager

from models.calculators.CalculatorFactory import ConcreteCalculatorFactory

import data.rc_resources as rc_resources

CURRENT_DIR = os.path.dirname(os.path.realpath(__file__))

class ResourceManager:
    """Manages application resources and caching."""
    def __init__(self):
        self._cache = {}
    
    def get_resource(self, key: str):
        if key not in self._cache:
            # Load resource
            pass
        return self._cache.get(key)

class Application:
    """Main application class implementing dependency injection and component management.
    
    This class serves as the primary application controller, managing:
    - Dependency injection
    - Model initialization
    - QML registration
    - Application lifecycle
    """
    
    def __init__(self, container: Optional[Container] = None):
        """Initialize application with dependency container and configuration."""
        # Load config first
        self.config = app_config
        self.container = container or Container()

        self.app = QApplication(sys.argv)

        self.logger = self.container.resolve(ILogger)
        self.calculator_factory = self.container.resolve(ICalculatorFactory)
        self.qml_engine = self.container.resolve(IQmlEngine)
        self.model_factory = self.container.resolve(IModelFactory)

        self.qml_engine.initialize(self.app)
        
        # Add debug helper
        self.debug_helper = register_debug_helper(self.qml_engine.engine)
        
        self.qml_engine.engine.addImportPath(os.path.dirname(CURRENT_DIR))
        self.qml_engine.engine.addImportPath(CURRENT_DIR)

        components_path = os.path.join(CURRENT_DIR, "qml", "components")
        self.qml_engine.engine.addImportPath(os.path.dirname(components_path))

        self.qml_engine.engine.clearComponentCache()

        self.loading_manager = LoadingManager()
        self.qml_engine.engine.rootContext().setContextProperty("loadingManager", self.loading_manager)

        self.worker_pool = WorkerPool()
        self._resource_cache = {}

        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)

        self.resource_manager = ResourceManager()
        self._setup_logging()

        self.setup()
        
    async def load_models_async(self):
        """Load models asynchronously."""
        self.loading_manager._loading = True
        self.loading_manager.statusChanged.emit("Loading core models...")
        
        async def load_model(name, progress):
            model = await self.loading_manager.run_in_thread(
                self.model_factory.create_model, name
            )
            self.loading_manager.update_task("models", progress)
            return model
        
        self.loading_manager._loading = False
        self.loading_manager.loadingChanged.emit()

    async def _setup_async(self):
        """Run all async initialization tasks."""
        await asyncio.gather(
            self.load_models_async()
        )

    def setup_app(self):
        """Configure application using loaded config."""
        QQuickStyle.setStyle(self.config.style)
        QApplication.setApplicationName(self.config.app_name)
        QApplication.setOrganizationName(self.config.org_name)
        QApplication.setWindowIcon(QIcon(self.config.icon_path))
        QIcon.setThemeName("gallery")

    def load_models(self):
        """Initialize and configure application models using factories."""

        # Defer calculator creation until needed
        self._calculators = {}
    
    def get_calculator(self, name):
        """Lazy load calculators only when requested."""
        if name not in self._calculators:
            self._calculators[name] = self.calculator_factory.create_calculator(name)
        return self._calculators[name]

    def _setup_logging(self):
        """Configure application logging."""
        self.logger.setup(level=logging.INFO)

    def register_qml_types(self):
        """Register QML types using external registration function."""
        qml_types = register_qml_types(self.qml_engine.engine, CURRENT_DIR)
        for type_info in qml_types:
            self.qml_engine.register_type(*type_info)
        
        # Register the QLogManager type with QML
        QML_IMPORT_NAME = "Logger"
        QML_IMPORT_MAJOR_VERSION = 1
        # Use the imported qmlRegisterType function instead of trying to call it as a method
        qmlRegisterType(QLogManager, QML_IMPORT_NAME, 
                        QML_IMPORT_MAJOR_VERSION, 0, "LogManager")

    def load_qml(self):
        self.qml_engine.load_qml(os.path.join(CURRENT_DIR, "qml", "main.qml"))

        # Add platform helper registration
        from utils.platform_helper import PlatformHelper
        self.qml_engine.engine.rootContext().setContextProperty("PlatformHelper", PlatformHelper())
        
        # Create and expose log manager to QML
        self.log_manager = QLogManager()
        self.qml_engine.engine.rootContext().setContextProperty("logManager", self.log_manager)

    def setup(self):
        """Configure application components and initialize subsystems."""
        self._setup_logging()
        self.setup_app()
        self.loop.run_until_complete(self._setup_async())
        self.register_qml_types()
        self.load_qml()
    
    def run(self):
        """Run the application."""
        try:
            sys.exit(self.app.exec())
        finally:
            # Clean up resources when application exits
            if hasattr(self, 'log_manager') and hasattr(self.log_manager, '_async_handler'):
                # Stop the async log handler to allow thread to exit
                self.log_manager._async_handler.stop()
            
            self.loop.close()
            self.worker_pool.shutdown()

def setup_container() -> Container:
    """Create and configure the dependency injection container.

    Returns:
        Container: Configured dependency injection container
    """
    container = Container()
    
    # Register services
    container.register(ILogger, DefaultLogger)
    container.register(ICalculatorFactory, ConcreteCalculatorFactory)
    container.register(IQmlEngine, QmlEngineWrapper)
    container.register(IModelFactory, ModelFactory)
    
    return container

# Add Windows-specific code
def setup_windows_specifics():
    """Configure Windows-specific settings"""
    import sys
    if sys.platform == "win32":
        # Use software OpenGL on Windows by default (can be overridden with command-line args)
        from PySide6.QtQuick import QSGRendererInterface
        from PySide6.QtGui import QGuiApplication
        
        # Set default render loop (better performance on Windows)
        QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
            Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
        )
        
        # Allow environment variables to override these settings
        if not os.environ.get("QT_OPENGL"):
            os.environ["QT_OPENGL"] = "software"
        
        # Disable file system watcher to avoid potential performance issues
        os.environ["QT_QPA_DISABLE_DISK_CACHE"] = "1"
        
        # Set the software backend for compatibility
        from PySide6.QtCore import Qt
        QGuiApplication.setAttribute(Qt.AA_UseSoftwareOpenGL)

def main():
    # Setup Windows-specific configuration
    setup_windows_specifics()
    
    container = setup_container()
    app = Application(container)
    app.run()

if __name__ == "__main__":
    main()
