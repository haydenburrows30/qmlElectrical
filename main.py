# Standard library imports
import os
import sys
import logging
import asyncio
import traceback
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
from docs.container import Container
from services.implementations import DefaultLogger, QmlEngineWrapper, ModelFactory
from services.qml_types import register_qml_types
from services.loading_manager import LoadingManager
from services.worker_pool import WorkerPool

from utils.config import app_config
from utils.qml_debug import register_debug_helper
from utils.logger import QLogManager
from utils.system_resources import SystemResources
from utils.cache_manager import CacheManager

from models.calculators.CalculatorFactory import ConcreteCalculatorFactory

import data.rc_resources as rc_resources
from data.menu_items import MenuItems

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
        # NOTE: For better Windows performance, the critical parts of this application
        # could be reimplemented in C++. The QML frontend would remain identical, but
        # backend operations would gain significant performance improvements, especially:
        # - Data processing (5-10x faster)
        # - Model updates (3-8x faster)
        # - Rendering pipeline optimizations through native Qt C++ integration
        
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

    def _initialize_engine(self):
        """Initialize the QML engine."""
        # Add system resources monitor to root context
        self.system_resources = SystemResources()
        self.qml_engine.engine.rootContext().setContextProperty("systemInfo", self.system_resources)

    def setup(self):
        """Configure application components and initialize subsystems."""
        self._setup_logging()
        self.setup_app()
        
        # Initialize the preloading manager
        from utils.preload_manager import PreloadManager
        self.preload_manager = PreloadManager()
        self.qml_engine.engine.rootContext().setContextProperty("preloadManager", self.preload_manager)
        
        # Run initial async setup
        self.loop.run_until_complete(self._setup_async())
        self.register_qml_types()
        
        # Initialize lightweight performance monitoring
        from utils.lightweight_performance import LightweightPerformanceMonitor
        self.performance_monitor = LightweightPerformanceMonitor()
        self.qml_engine.engine.rootContext().setContextProperty("perfMonitor", self.performance_monitor)
        
        # Load main QML file
        self.load_qml()
        
        # Set application version and title for splash screen
        self.qml_engine.engine.rootContext().setContextProperty("appVersion", self.config.version)
        self.qml_engine.engine.rootContext().setContextProperty("applicationTitle", self.config.app_name)
        
        # Start preloading QML components after the main UI is loaded
        # This ensures the splash screen is shown while components are loaded
        qml_dir = os.path.join(CURRENT_DIR, "qml")
        
        # Find and preload only existing directories - safely preload what we can find
        for subdir in ['pages', 'components', 'calculators']:
            full_path = os.path.join(qml_dir, subdir)
            if os.path.exists(full_path) and os.path.isdir(full_path):
                # print(f"Adding directory for preloading: {full_path}")
                self.preload_manager.add_directory(full_path)
                
                # Handle nested directories
                for root, dirs, files in os.walk(full_path):
                    for dir_name in dirs:
                        nested_dir = os.path.join(root, dir_name)
                        # print(f"Adding nested directory: {nested_dir}")
                        self.preload_manager.add_directory(nested_dir)
        
        # Skip menu-based calculator loading since we're directly loading all QML files
        
        # Start preloading
        self.preload_manager.start_preloading(self.qml_engine.engine)
    
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
    """Configure Windows-specific settings for optimal performance"""
    import sys
    if sys.platform == "win32":
        # Import Qt first to avoid the UnboundLocalError
        from PySide6.QtCore import Qt, QCoreApplication
        from PySide6.QtQuick import QSGRendererInterface
        from PySide6.QtGui import QGuiApplication
        
        # Set high DPI settings
        QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
            Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
        )
        
        # Performance optimization: Use threaded render loop for complex UIs
        # or basic render loop for simpler UIs (less CPU overhead)
        if not os.environ.get("QSG_RENDER_LOOP"):
            try:
                # Check if we have complex UI with many elements
                qml_dir = os.path.join(CURRENT_DIR, "qml")
                main_qml = os.path.join(qml_dir, "main.qml")
                complex_ui = False
                
                # Simple heuristic: check file size of main.qml
                if os.path.exists(main_qml) and os.path.getsize(main_qml) > 50000:
                    complex_ui = True
                
                if complex_ui:
                    # Threaded renderer for complex UIs
                    os.environ["QSG_RENDER_LOOP"] = "threaded"
                else:
                    # Basic renderer for simpler UIs (faster startup)
                    os.environ["QSG_RENDER_LOOP"] = "basic"
            except:
                # Default to basic if we can't determine
                os.environ["QSG_RENDER_LOOP"] = "basic"
        
        # QML caching for better performance
        if "QT_QPA_DISABLE_DISK_CACHE" not in os.environ:
            # Use the user's AppData folder for the cache to ensure write permissions
            try:
                # Get user-specific application data directory
                from pathlib import Path
                app_name = QApplication.applicationName() or "QmlTableView"
                
                if hasattr(sys, 'frozen'):  # Running as packaged executable
                    # Use user's AppData folder for packaged apps
                    import tempfile
                    cache_dir = os.path.join(tempfile.gettempdir(), app_name, "QmlCache")
                else:
                    # Use local cache directory in development
                    cache_dir = os.path.join(CURRENT_DIR, "cache")
                
                os.makedirs(cache_dir, exist_ok=True)
                os.environ["QML_DISK_CACHE_PATH"] = cache_dir
                
                # Set cache limits for better performance
                os.environ["QML_DISK_CACHE_MAX_SIZE"] = "512"  # 512MB disk cache
            except Exception as e:
                print(f"Warning: Could not set up QML disk cache: {e}")
        
        # Choose best renderer based on performance tests
        renderer = detect_best_renderer()
        
        # Apply the selected renderer
        if renderer == "software":
            # Software rendering (most compatible)
            os.environ["QT_OPENGL"] = "software"
            QGuiApplication.setAttribute(Qt.AA_UseSoftwareOpenGL)
        elif renderer == "angle":
            # ANGLE renderer (best for most Windows systems)
            os.environ["QT_OPENGL"] = "angle"
            QGuiApplication.setAttribute(Qt.AA_UseOpenGLES)  # Add this to ensure ANGLE is properly used
            # Optimize ANGLE for performance over compatibility
            os.environ["QT_ANGLE_PLATFORM"] = "d3d11"  # Use Direct3D 11 backend for ANGLE
            # Additional ANGLE performance tweaks
            os.environ["QT_ANGLE_D3D11_FEATURES"] = "allowEs3OnFl10_0"  # Allow ES3 features when possible
        elif renderer == "desktop":
            # Native OpenGL (sometimes fastest)
            os.environ["QT_OPENGL"] = "desktop"
            QGuiApplication.setAttribute(Qt.AA_UseDesktopOpenGL)
            # Additional OpenGL performance settings for Windows
            os.environ["QSG_RENDER_LOOP"] = "basic"  # Use basic render loop with desktop OpenGL (more stable)
            # Disable all MSAA on Windows - often causes performance issues
            os.environ["QSG_SAMPLES"] = "0"
        
        # Additional Windows-specific performance tweaks
        # Disable expensive per-frame buffer swaps (Windows-specific)
        os.environ["QSG_RENDERER_BUFFER_SWAP"] = "minimal"  # Reduce buffer swapping overhead
        
        # Batch render geometry for better performance
        os.environ["QSG_BATCHING"] = "1"
        
        # Improved memory management for Windows
        os.environ["QSG_TRANSIENT_IMAGES"] = "1"  # Better memory usage
        os.environ["QV4_MM_MAX_CHUNK_SIZE"] = "256"  # Smaller JS memory chunks (better on Windows)
        
        # Windows process priority boost for better responsiveness
        try:
            import ctypes
            process_handle = ctypes.windll.kernel32.GetCurrentProcess()
            ctypes.windll.kernel32.SetPriorityClass(process_handle, 0x00008000)  # ABOVE_NORMAL_PRIORITY_CLASS
        except:
            pass  # Ignore if it fails

def detect_best_renderer():
    """Detect the best available renderer on Windows for performance
    
    This function tests different rendering backends and selects the one
    with the best performance-stability tradeoff.
    """
    import sys
    if sys.platform != "win32":
        return "desktop"
    
    # First check for environment variable overrides
    if "QT_OPENGL" in os.environ:
        return os.environ["QT_OPENGL"]
    
    try:
        # More thorough GPU detection on Windows
        import subprocess
        import re
        
        # Get both GPU info and Windows version
        gpu_info = subprocess.check_output("wmic path win32_VideoController get name", shell=True).decode().lower()
        windows_ver = subprocess.check_output("ver", shell=True).decode().strip()
        
        # Determine Windows 10/11 version
        is_win11 = "windows 11" in windows_ver.lower() or "10.0.2" in windows_ver
        is_win10 = "windows 10" in windows_ver.lower() or "10.0.1" in windows_ver
        
        # Check for integrated vs. dedicated GPU
        is_integrated = "intel" in gpu_info or "uhd" in gpu_info or "hd graphics" in gpu_info
        is_nvidia = any(gpu in gpu_info for gpu in ["nvidia", "geforce", "quadro", "rtx", "gtx"])
        is_amd = any(gpu in gpu_info for gpu in ["amd", "radeon", "firepro", "rx"])
        
        # Get system memory - lower memory systems need more conservative rendering
        try:
            mem_info = subprocess.check_output("wmic ComputerSystem get TotalPhysicalMemory", shell=True).decode()
            total_mem_gb = int(re.search(r"\d+", mem_info).group()) / (1024**3)
            low_memory = total_mem_gb < 8
        except:
            low_memory = False
            
        # Logic for renderer selection based on collected data
        if is_integrated:
            if is_win11 or is_win10:
                # For newer Windows + integrated GPU, ANGLE provides best compatibility
                return "angle"
            else:
                # For older Windows + integrated GPU, software is safest
                return "software"
        elif is_nvidia:
            # NVIDIA GPUs generally work well with desktop OpenGL on Windows 10/11
            if is_win11 or is_win10:
                return "desktop"
            else:
                return "angle"  # Older Windows + NVIDIA is safer with ANGLE
        elif is_amd:
            # AMD GPUs can be problematic with desktop OpenGL
            return "angle"
        else:
            # Unknown GPU configuration - use ANGLE for better compatibility
            return "angle"
            
    except Exception as e:
        print(f"Warning: GPU detection failed ({e}), defaulting to ANGLE renderer")
        return "angle"  # ANGLE is the safest fallback

def main():
    # Set Qt attributes before creating QApplication
    try:
        from PySide6.QtCore import Qt, QCoreApplication
        from PySide6.QtGui import QGuiApplication
        import sys
        
        # Initialize our cache manager first, before QApplication is created
        from utils.cache_manager import CacheManager
        cache_manager = CacheManager()
        
        # Parse command line args first to allow rendering and cache overrides
        import argparse
        parser = argparse.ArgumentParser(description='Application launcher')
        parser.add_argument('--renderer', choices=['software', 'angle', 'desktop'], 
                            help='Override renderer selection')
        parser.add_argument('--no-cache', action='store_true', 
                            help='Disable QML disk cache')
        parser.add_argument('--debug', action='store_true',
                            help='Enable additional debug output')
        parser.add_argument('--clear-cache', action='store_true',
                            help='Clear the QML cache before starting')
        
        args, unknown = parser.parse_known_args()
        
        # Handle cache options from command line
        if args.no_cache:
            os.environ["QT_QPA_DISABLE_DISK_CACHE"] = "1"
            print("QML disk cache disabled")
        else:
            # Initialize cache manager
            app_name = "QmlTableView"  # Use app_config.app_name later after it's loaded
            cache_manager.initialize(app_name)
            
            # Clear cache if requested
            if args.clear_cache:
                print("Clearing QML cache...")
                cache_manager.clear_cache()
        
        # Handle rendering options from command line
        if args.renderer:
            os.environ["QT_OPENGL"] = args.renderer
            print(f"Using renderer: {args.renderer}")
        
        if args.debug:
            # Enable Qt debug output
            os.environ["QT_DEBUG_PLUGINS"] = "1"
            os.environ["QT_LOGGING_RULES"] = "qt.qml.connections=true"
            print("Debug mode enabled")
            
        # Detect GPU type for optimal renderer selection
        gpu_type = "unknown"
        try:
            if sys.platform == "win32":
                import subprocess
                gpu_info = subprocess.check_output("wmic path win32_VideoController get name", shell=True).decode().lower()
                if any(gpu in gpu_info for gpu in ["nvidia", "geforce", "quadro"]):
                    gpu_type = "nvidia"
                elif any(gpu in gpu_info for gpu in ["amd", "radeon"]):
                    gpu_type = "amd"
                elif "intel" in gpu_info:
                    gpu_type = "intel"
        except:
            pass
            
        # Set appropriate GL attributes based on GPU
        if gpu_type == "intel":
            # Intel GPUs work best with ANGLE
            QCoreApplication.setAttribute(Qt.AA_UseOpenGLES)
            os.environ["QT_OPENGL"] = "angle"
        elif gpu_type in ["nvidia", "amd"]:
            # NVIDIA and AMD work well with desktop OpenGL
            QCoreApplication.setAttribute(Qt.AA_UseDesktopOpenGL)
            os.environ["QT_OPENGL"] = "desktop"
        else:
            # Unknown or problematic GPUs use software rendering
            QCoreApplication.setAttribute(Qt.AA_UseSoftwareOpenGL)
            os.environ["QT_OPENGL"] = "software"
    except ImportError:
        pass  # Fall back to default if PySide6 not available yet

    try:
        # Setup Windows-specific configuration
        setup_windows_specifics()
        container = setup_container()
        app = Application(container)
        app.run()
        
    except Exception as e:
        print(f"ERROR during startup: {str(e)}", file=sys.stderr)
        print(traceback.format_exc(), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
