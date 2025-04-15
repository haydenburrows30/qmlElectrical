"""Windows-specific utilities for application rendering and performance."""
import os
import sys
import subprocess
import re
from typing import Literal

# Renderer type definition
RendererType = Literal["software", "angle", "desktop"]

def setup_windows_specifics():
    """Configure Windows-specific settings for optimal performance."""
    if sys.platform != "win32":
        return
    
    try:
        # Import Qt modules inside function to avoid import issues on non-Windows platforms
        from PySide6.QtCore import Qt, QCoreApplication
        from PySide6.QtQuick import QSGRendererInterface
        from PySide6.QtGui import QGuiApplication
        from PySide6.QtWidgets import QApplication
        
        # Set high DPI settings
        QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
            Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
        )
        
        # Detect renderer and current directory
        current_dir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
        
        # Performance optimization: Determine render loop type
        if not os.environ.get("QSG_RENDER_LOOP"):
            try:
                # Check if we have complex UI with many elements
                qml_dir = os.path.join(current_dir, "qml")
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
        
        # Set up QML disk cache - now use the cross-platform utility
        from utils.cache_utils import setup_qml_cache
        setup_qml_cache(current_dir, QApplication.applicationName())
        
        # Apply renderer settings
        renderer = detect_best_renderer()
        apply_renderer_settings(renderer)
        
        # Apply additional performance tweaks
        apply_performance_tweaks()
    
    except Exception as e:
        print(f"Warning: Windows-specific setup error: {e}")

def detect_best_renderer() -> RendererType:
    """Detect the best available renderer on Windows for performance.
    
    This function tests different rendering backends and selects the one
    with the best performance-stability tradeoff.
    
    Returns:
        str: Renderer type - 'software', 'angle', or 'desktop'
    """
    if sys.platform != "win32":
        return "desktop"
    
    # First check for environment variable overrides
    if "QT_OPENGL" in os.environ:
        return os.environ["QT_OPENGL"]  # type: ignore
    
    try:
        # More thorough GPU detection on Windows
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

def apply_renderer_settings(renderer: RendererType):
    """Apply renderer-specific settings."""
    try:
        from PySide6.QtCore import Qt
        from PySide6.QtGui import QGuiApplication
        
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
    except Exception as e:
        print(f"Warning: Failed to apply renderer settings: {e}")

def apply_performance_tweaks():
    """Apply additional Windows-specific performance tweaks."""
    try:
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
    except Exception as e:
        print(f"Warning: Failed to apply performance tweaks: {e}")

def detect_gpu_type() -> str:
    """Detect GPU type for optimal rendering settings.
    
    Returns:
        str: GPU type - 'nvidia', 'amd', 'intel', or 'unknown'
    """
    gpu_type = "unknown"
    
    try:
        if sys.platform == "win32":
            gpu_info = subprocess.check_output("wmic path win32_VideoController get name", shell=True).decode().lower()
            if any(gpu in gpu_info for gpu in ["nvidia", "geforce", "quadro"]):
                gpu_type = "nvidia"
            elif any(gpu in gpu_info for gpu in ["amd", "radeon"]):
                gpu_type = "amd"
            elif "intel" in gpu_info:
                gpu_type = "intel"
    except:
        pass
        
    return gpu_type

def set_gpu_attributes():
    """Set GPU-specific Qt attributes."""
    try:
        from PySide6.QtCore import Qt, QCoreApplication
        
        # Detect GPU type
        gpu_type = detect_gpu_type()
            
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
    except Exception as e:
        print(f"Warning: Failed to set GPU attributes: {e}")
