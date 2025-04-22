from PySide6.QtCore import (
    QObject, Property, Signal, Slot, QPointF, QTimer,
    QThread, QMetaObject, Qt, Q_ARG
)
from PySide6.QtWidgets import QApplication
import numpy as np
import math
import csv
import os
from datetime import datetime
import time
from utils.logger_config import configure_logger
from utils.file_saver import FileSaver  # Add import for FileSaver

from utils.calculation_cache import CalculationCache, generate_cache_key
from utils.worker_pool import WorkerPoolManager, ManagedWorker

# Setup component-specific logger
logger = configure_logger("qmltest", component="harmonic_analysis")

class CalculationWorker(ManagedWorker):
    """Worker class to run calculations in a separate thread"""
    
    def __init__(self, calculator, params=None):
        super().__init__(self._do_calculation)
        self.calculator = calculator
        self.params = params or {}
        
    def _do_calculation(self):
        """Execute the calculation in a separate thread"""
        try:
            # Check which calculation to run based on parameters
            if 'resolution' in self.params:
                # Resolution calculation
                points = self.params['resolution']
                
                # Check cache first
                cache_key = generate_cache_key({"type": "resolution", "points": points})
                cached_result = CalculationCache.get_instance().get(cache_key)
                
                if cached_result:
                    # Use cached result
                    logger.debug(f"Cache hit for resolution calculation with {points} points")
                    self.calculator._waveform = cached_result['waveform']
                    self.calculator._fundamental_wave = cached_result['fundamental']
                    self.calculator._waveform_points = cached_result['waveform_points']
                    self.calculator._fundamental_points = cached_result['fundamental_points']
                    
                    # Signal that calculation is complete
                    self.calculator._pending_signals = {"waveformChanged"}
                    self.calculator._emit_pending = True
                else:
                    # Calculate and cache
                    logger.debug(f"Cache miss for resolution calculation with {points} points")
                    result = self.calculator.calculateWithResolution(points)
                    if result:
                        self.calculator._waveform = result['waveform']
                        self.calculator._fundamental_wave = result['fundamental']
                        self.calculator._waveform_points = result['waveform_points']
                        self.calculator._fundamental_points = result['fundamental_points']
                        
                        # Cache the result
                        CalculationCache.get_instance().put(cache_key, result)
                        
                        # Signal that calculation is complete
                        self.calculator._pending_signals = {"waveformChanged"}
                        self.calculator._emit_pending = True
            else:
                # Full calculation based on current harmonics
                cache_key = self.calculator._get_cache_key()
                
                # Check cache to avoid duplicate work
                cached_result = CalculationCache.get_instance().get(cache_key)
                if cached_result:
                    logger.debug("Cache hit for full harmonic calculation")
                    # Load values from cache
                    self.calculator._thd = cached_result['thd']
                    self.calculator._cf = cached_result['cf']
                    self.calculator._ff = cached_result['ff']
                    self.calculator._waveform = cached_result['waveform']
                    self.calculator._fundamental_wave = cached_result['fundamental_wave']
                    self.calculator._individual_distortion = cached_result['individual_distortion']
                    self.calculator._harmonic_phases = cached_result['harmonic_phases']
                    self.calculator._waveform_points = cached_result['waveform_points']
                    self.calculator._fundamental_points = cached_result['fundamental_points']
                    
                    # For cache hits, immediately update status
                    QMetaObject.invokeMethod(self.calculator, "_update_calculation_status",
                                           Qt.ConnectionType.QueuedConnection,
                                           Q_ARG(bool, False),
                                           Q_ARG(float, 1.0))
                else:
                    logger.debug("Cache miss for full harmonic calculation")
                    # Perform full calculation
                    self.calculator._calculate_full()
                
                # Signal that calculation is complete
                self.calculator._pending_signals = {"harmonicsChanged", "waveformChanged", 
                                                  "crestFactorChanged", "formFactorChanged",
                                                  "calculationsComplete"}
                self.calculator._emit_pending = True

            # Use QMetaObject::invokeMethod to safely signal back to main thread
            QMetaObject.invokeMethod(self.calculator, "checkPendingUpdates", 
                                   Qt.ConnectionType.QueuedConnection)
        except Exception as e:
            logger.error(f"Error in calculation worker: {e}")
            logger.exception(e)
            # Always ensure we reset calculation status on error
            QMetaObject.invokeMethod(self.calculator, "_update_calculation_status",
                                   Qt.ConnectionType.QueuedConnection,
                                   Q_ARG(bool, False),
                                   Q_ARG(float, 0.0))

class HarmonicAnalysisCalculator(QObject):
    """Calculator for harmonic analysis and THD calculation"""

    fundamentalChanged = Signal()
    harmonicsChanged = Signal()
    calculationsComplete = Signal()
    thdChanged = Signal()
    crestFactorChanged = Signal()
    formFactorChanged = Signal()
    waveformChanged = Signal()
    calculationStatusChanged = Signal()
    calculationProgressChanged = Signal(float)
    exportDataToFolderCompleted = Signal(bool, str)  # New signal for export completion

    def __init__(self, parent=None):
        """Initialize the calculator."""
        super().__init__(parent)
        
        # Add these lines for cache statistics
        self._cache_hits = 0
        self._cache_misses = 0
        self._cache_lookups = 0
        
        self._fundamental = 100.0  # Fundamental amplitude
        self._fundamentalMagnitude = 100.0
        self._fundamentalAngle = 0.0
        self._harmonics = [0.0] * 15  # Up to 15th harmonic
        self._harmonics_dict = {1: (100.0, 0.0)}  # Dict to store harmonic orders and their values
        self._thd = 0.0
        self._cf = 0.0
        self._ff = 1.11  # Form factor (default sine wave value)
        self._individual_distortion = [100.0, 0.0, 0.0, 0.0, 0.0, 0.0]  # For display harmonics [1,3,5,7,11,13]
        self._harmonic_phases = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]  # Phases for display harmonics
        self._waveform_points = []
        self._waveform = []
        self._fundamental_wave = []  # Store fundamental waveform
        self._fundamental_points = []  # Initialize fundamental points array
        self._spectrum_points = []
        self._spectrum = []
        self._resolution = 250  # Default resolution
        
        # Add calculation cache for memoization
        self._calculation_cache = CalculationCache.get_instance()
        
        # Add signal emission timer
        self._update_timer = QTimer(self)
        self._update_timer.setSingleShot(True)
        self._update_timer.setInterval(10)  # 10ms delay
        self._update_timer.timeout.connect(self._emitSignals)
        
        # Flag to track pending updates
        self._update_pending = False
        
        # Add pending signals tracking
        self._pending_signals = set()
        
        # Ensure all variables are initialized
        # Initialize calculation status tracking BEFORE calling any methods that use it
        self._calculation_in_progress = False
        self._calculation_progress = 0.0
        self._cancel_requested = False
        
        # Add thread pool for background calculations
        self._thread_pool = WorkerPoolManager.get_instance()
        logger.info(f"Using {self._thread_pool.maxThreadCount()} threads for calculations")
        
        # Flag to track if updates are needed
        self._emit_pending = False
        
        # Add a fast memory cache for very common calculations
        self._memory_cache = {}  # Simple in-memory cache for ultra-fast lookups
        self._memory_cache_hits = 0
        
        # Add debouncing for rapid user input
        self._last_calculation_time = 0
        self._debounce_interval = 100  # ms
        
        # Now we can safely call methods that depend on these attributes
        self._calculate()
        
    @Property(bool, notify=calculationStatusChanged)
    def calculationInProgress(self):
        """Indicates if a calculation is currently in progress"""
        try:
            return self._calculation_in_progress
        except AttributeError:
            # Ensure the attribute exists even if not properly initialized
            self._calculation_in_progress = False
            return False
    
    @Property(float, notify=calculationProgressChanged)
    def calculationProgress(self):
        """Current calculation progress (0.0 to 1.0)"""
        try:
            return self._calculation_progress
        except AttributeError:
            # Ensure the attribute exists even if not properly initialized
            self._calculation_progress = 0.0
            return 0.0
        
    @Slot(bool, float)
    def _update_calculation_status(self, in_progress, progress=0.0):
        """Update calculation status and emit signals if changed"""
        status_changed = (self._calculation_in_progress != in_progress)
        self._calculation_in_progress = in_progress
        
        # Only emit progress signal if significant change
        if abs(self._calculation_progress - progress) > 0.01:
            self._calculation_progress = progress
            self.calculationProgressChanged.emit(progress)
        
        if status_changed:
            self.calculationStatusChanged.emit()
    
    def _emitSignals(self):
        """Actually emit the signals after the delay"""
        if not self._update_pending:
            return
        
        # Only emit signals that are actually needed
        # This prevents unnecessary UI updates
        pending = self._pending_signals
        
        try:
            # Instead of emitting individual signals, use a single combined signal
            # for efficiency. This avoids multiple updates to the UI in rapid succession
            if len(pending) > 1:
                # If multiple signals are pending, just emit calculationsComplete
                # which the QML can use as a trigger for a complete refresh
                self.calculationsComplete.emit()
            else:
                # If only one signal is pending, emit just that one
                if "waveformChanged" in pending:
                    self.waveformChanged.emit()
                elif "harmonicsChanged" in pending:
                    self.harmonicsChanged.emit()
                elif "crestFactorChanged" in pending:
                    self.crestFactorChanged.emit()
                elif "formFactorChanged" in pending:
                    self.formFactorChanged.emit()
                elif "calculationsComplete" in pending:
                    self.calculationsComplete.emit()
                    self.harmonicsChanged.emit()
            
            try:
                import psutil
                cpu_load = psutil.cpu_percent(interval=0.05)
                if cpu_load > 80:
                    # Reduce update frequency during high CPU load
                    time.sleep(0.05)  # Brief pause to allow UI to remain responsive
            except (ImportError, Exception):
                pass
        except Exception as e:
            logger.error(f"Error emitting signals: {e}")
            
        # Reset state
        self._update_pending = False
        self._pending_signals.clear()
    
    def _calculate(self):
        """Start calculation in a worker thread"""
        # Set calculation status to in-progress
        self._cancel_requested = False
        self._update_calculation_status(True, 0.0)
        
        logger.info("Starting harmonic analysis calculation")
        
        # Create a worker and start it in the thread pool
        worker = CalculationWorker(self)
        self._thread_pool.start(worker)
        return True
    
    def _get_cache_key(self):
        """Generate a unique key for the current harmonics configuration
        
        Returns a string that uniquely identifies the current calculation state
        """
        # Use a tuple of sorted items for consistent key generation
        sorted_harmonics = sorted(self._harmonics_dict.items())
        return generate_cache_key({
            'harmonics': [(order, float(magnitude), float(phase)) for order, (magnitude, phase) in sorted_harmonics],
            'fundamental': float(self._fundamental)
        })
    
    def _calculate_full(self):
        """Perform full harmonic analysis calculation"""
        try:
            # Update progress
            self._update_calculation_status(True, 0.1)
            
            # Check cancellation
            if self._cancel_requested:
                logger.info("Harmonic calculation cancelled by user")
                self._update_calculation_status(False)
                return
            
            # Try memory cache first (faster than disk cache)
            sorted_harmonics = sorted(self._harmonics_dict.items())
            memory_key = str(sorted_harmonics) + str(self._fundamental)
            if memory_key in self._memory_cache:
                logger.debug("Memory cache hit for harmonic calculation")
                self._memory_cache_hits += 1
                result = self._memory_cache[memory_key]
                # Use memory cached result
                self._thd = result['thd']
                self._cf = result['cf']
                self._ff = result['ff']
                self._waveform = result['waveform']
                self._fundamental_wave = result['fundamental_wave']
                self._individual_distortion = result['individual_distortion']
                self._harmonic_phases = result['harmonic_phases']
                self._waveform_points = result['waveform_points']
                self._fundamental_points = result['fundamental_points']
                
                # Mark which signals need emission
                self._pending_signals = {"harmonicsChanged", "waveformChanged", 
                                        "crestFactorChanged", "formFactorChanged",
                                        "calculationsComplete"}
                
                # Emit signals once cached data is loaded
                self.batchUpdate()
                
                # Update status before returning
                self._update_calculation_status(False)
                return
            
            # Check disk cache
            cache_key = self._get_cache_key()
            self._cache_lookups += 1
            cached_result = self._calculation_cache.get(cache_key)
            if cached_result:
                # Cache hit - use stored results
                logger.debug("Disk cache hit for harmonic calculation")
                self._cache_hits += 1
                self._thd = cached_result['thd']
                self._cf = cached_result['cf']
                self._ff = cached_result['ff']
                self._waveform = cached_result['waveform']
                self._fundamental_wave = cached_result['fundamental_wave']
                self._individual_distortion = cached_result['individual_distortion']
                self._harmonic_phases = cached_result['harmonic_phases']
                self._waveform_points = cached_result['waveform_points']
                self._fundamental_points = cached_result['fundamental_points']
                
                # Mark which signals need emission
                self._pending_signals = {"harmonicsChanged", "waveformChanged", 
                                        "crestFactorChanged", "formFactorChanged",
                                        "calculationsComplete"}
                
                # Emit signals once cached data is loaded
                self.batchUpdate()
                
                # Update status before returning
                self._update_calculation_status(False)
                return
                
            # Cache miss - perform full calculation
            logger.debug("Cache miss - performing full harmonic calculation")
            self._cache_misses += 1
            
            # Log calculation parameters
            logger.info("\n=== Starting Harmonic Analysis ===")
            logger.info(f"Fundamental: {self._fundamental:.1f}")
            
            # Log active harmonics
            active_harmonics = {order: (mag, phase) for order, (mag, phase) in self._harmonics_dict.items() if mag > 0}
            logger.info(f"Active harmonics: {active_harmonics}")
                
            # Update progress
            self._update_calculation_status(True, 0.2)
            
            # Check cancellation
            if self._cancel_requested:
                logger.info("Calculation cancelled during harmonic analysis")
                self._update_calculation_status(False)
                return
            
            # Update harmonics array from dictionary input
            harmonics = [0.0] * 15  # Reset array
            phases = [0.0] * 15     # Reset phases array
            
            # Map harmonic orders to correct indices
            for order, (magnitude, phase) in self._harmonics_dict.items():
                if 1 <= order < len(harmonics):
                    # Validate input values to prevent NaN/Inf
                    if self._is_valid_number(magnitude) and self._is_valid_number(phase):
                        harmonics[order-1] = float(magnitude)
                        phases[order-1] = float(phase)
                    else:
                        logger.warning(f"Invalid values for harmonic {order}: magnitude={magnitude}, phase={phase}")
                        harmonics[order-1] = 0.0
                        phases[order-1] = 0.0
                    
            self._harmonics = harmonics
            
            # Calculate THD using only actual harmonics (excluding fundamental)
            if self._fundamental > 0:
                # Vectorized sum of squares with validation
                harmonics_array = np.array(harmonics[1:])
                harmonics_sum = np.sum(harmonics_array * harmonics_array)
                self._thd = math.sqrt(harmonics_sum) / self._fundamental * 100.0
                # Validate THD
                self._thd = self._safe_value(self._thd, 0.0)
                
            # Calculate individual distortion for display harmonics [1,3,5,7,11,13]
            display_orders = [1, 3, 5, 7, 11, 13]
            self._individual_distortion = [
                self._safe_value(harmonics[order-1] / self._fundamental * 100.0, 0.0) 
                for order in display_orders
            ]
            
            # Store phases for display harmonics
            self._harmonic_phases = [
                self._safe_value(phases[order-1], 0.0) 
                for order in display_orders
            ]

            # Log calculated values
            logger.info(f"THD: {self._thd:.2f}%")
            logger.info(f"Individual Distortion: {self._individual_distortion}")
            logger.info(f"Harmonic Phases: {self._harmonic_phases}")

            numpoints = self._resolution  # Use stored resolution
            
            # Cache key for resolution calculations
            resolution_cache_key = generate_cache_key({"type": "resolution", "points": numpoints})
            cached_resolution = self._calculation_cache.get(resolution_cache_key)
            
            if cached_resolution:
                # Use cached time values
                t = np.array(cached_resolution.get('time_values', []))
            else:
                # Generate new time values and cache them
                t = np.linspace(0, 2*np.pi, numpoints)
                self._calculation_cache.put(resolution_cache_key, {'time_values': t.tolist()})
            
            wave = np.zeros_like(t)  # Pre-allocate array
            
            # Calculate all harmonics at once for orders where magnitude > 0
            try:
                # First calculate the fundamental
                phase_rad_fundamental = np.radians(self._safe_value(phases[0], 0.0))
                fundamental_wave = self._fundamental * np.sin(t + phase_rad_fundamental)
                np.nan_to_num(fundamental_wave, copy=False)
                self._fundamental_wave = fundamental_wave.tolist()
                
                # Add fundamental to wave
                wave += fundamental_wave
                
                # Only process harmonics with amplitude > 0 to save computation
                for i, (amplitude, phase_deg) in enumerate(zip(harmonics[1:], phases[1:])):  # Skip fundamental
                    if amplitude > 0 and self._is_valid_number(amplitude) and self._is_valid_number(phase_deg):
                        harmonic_order = i + 2  # +2 because we start from 2nd harmonic (index+2)
                        phase_rad = np.radians(phase_deg)
                        # Add directly to wave instead of creating temporary arrays
                        wave += amplitude * np.sin(harmonic_order * t + phase_rad)
                
                # Replace any NaN or Inf values in the final waveform
                np.nan_to_num(wave, copy=False)
                self._waveform = wave.tolist()
                
                if wave.size:
                    wave_sq = np.square(wave)
                    wave_abs = np.abs(wave)
                    
                    # Calculate RMS once and reuse
                    rms_squared = np.mean(wave_sq)
                    
                    if rms_squared > 0 and np.isfinite(rms_squared):
                        rms = np.sqrt(rms_squared)
                        peak = np.max(wave_abs)
                        average_rectified = np.mean(wave_abs)
                        
                        # Calculate factors
                        if average_rectified > 0:
                            self._cf = self._safe_value(peak / rms, 1.414)
                            self._ff = self._safe_value(rms / average_rectified, 1.11)
                        else:
                            self._cf = 1.414
                            self._ff = 1.11
                    else:
                        self._cf = 1.414
                        self._ff = 1.11
            except Exception as inner_e:
                logger.error(f"Error in waveform calculation: {inner_e}")
                logger.exception(inner_e)
                # Reset to safe defaults
                self._waveform = [0.0] * 250
                self._fundamental_wave = [0.0] * 250
                self._cf = 1.414
                self._ff = 1.11

            # Only generate these arrays when actually needed by the UI
            self._waveform_points = self._generate_points_array(t, wave)
            self._fundamental_points = self._generate_points_array(t, fundamental_wave)
            
            # Log waveform generation
            logger.info(f"Generated waveform with {len(self._waveform)} points")
            logger.info(f"Crest Factor: {self._cf:.3f}")
            logger.info(f"Form Factor: {self._ff:.3f}")
            
            # Store in memory cache
            result = {
                'thd': self._thd,
                'cf': self._cf,
                'ff': self._ff,
                'waveform': self._waveform,
                'fundamental_wave': self._fundamental_wave,
                'individual_distortion': self._individual_distortion,
                'harmonic_phases': self._harmonic_phases,
                'waveform_points': self._waveform_points,
                'fundamental_points': self._fundamental_points
            }
            self._memory_cache[memory_key] = result
            
            # Limit memory cache size
            if len(self._memory_cache) > 20:
                # Remove oldest entries (first 5)
                for key in list(self._memory_cache.keys())[:5]:
                    del self._memory_cache[key]
            
            # Also store in disk cache
            self._calculation_cache.put(cache_key, result)
            
            # Limit cache size to prevent memory growth
            if hasattr(self._calculation_cache, 'trim') and self._cache_lookups > 1000:
                self._calculation_cache.trim(max_size=50)  # Keep only 50 most recent entries
                self._cache_lookups = 0
            
            # Mark which signals need emission
            self._pending_signals = {"harmonicsChanged", "waveformChanged", 
                                   "crestFactorChanged", "formFactorChanged",
                                   "calculationsComplete"}
            
            # Reset calculation status
            self._update_calculation_status(False, 1.0)
            
            # Trigger batch update
            self.batchUpdate()
            
            logger.info("=== Harmonic Analysis Complete ===\n")
            
        except Exception as e:
            logger.error(f"Harmonic calculation error: {e}")
            logger.exception(e)
            # Reset calculation status on error
            self._update_calculation_status(False)
    
    @Slot(int)
    def updateResolution(self, points):
        """Update the resolution used for waveform calculations"""
        if self._is_valid_number(points) and 50 <= points <= 1000:
            # Store new resolution for future calculations
            self._resolution = points
            
            # Start a calculation with the new resolution
            worker = CalculationWorker(self, {'resolution': points})
            self._thread_pool.start(worker)
            return True
        return False
    
    @Slot(int)
    def calculateWithResolution(self, points):
        """Calculate waveform with specified resolution"""
        if not self._is_valid_number(points) or points < 50:
            points = 250  # Default to safe value
            
        t = np.linspace(0, 2*np.pi, points)
        result = {}
        
        try:
            # Get data from harmonics_dict
            harmonics = [0.0] * 15
            phases = [0.0] * 15
            
            for order, (magnitude, phase) in self._harmonics_dict.items():
                if 1 <= order <= len(harmonics):
                    harmonics[order-1] = magnitude
                    phases[order-1] = phase
            
            # Calculate fundamental wave
            phase_rad_fundamental = np.radians(phases[0])
            fundamental = self._fundamental * np.sin(t + phase_rad_fundamental)
            
            # Calculate combined waveform
            wave = np.copy(fundamental)  # Start with fundamental
            
            # Add harmonics
            for i, (amplitude, phase_deg) in enumerate(zip(harmonics[1:], phases[1:])):
                if amplitude > 0:
                    harmonic_order = i + 2  # +2 because we start from 2nd harmonic
                    phase_rad = np.radians(phase_deg)
                    wave += amplitude * np.sin(harmonic_order * t + phase_rad)
            
            # Generate point arrays for plotting
            result['waveform'] = wave.tolist()
            result['fundamental'] = fundamental.tolist()
            result['waveform_points'] = self._generate_points_array(t, wave)
            result['fundamental_points'] = self._generate_points_array(t, fundamental)
            
            return result
        except Exception as e:
            logger.error(f"Error in resolution calculation: {e}")
            logger.exception(e)
            return None
    
    def _is_valid_number(self, value):
        """Check if a value is a valid finite number."""
        try:
            float_val = float(value)
            return np.isfinite(float_val)
        except (ValueError, TypeError):
            return False
    
    def _safe_value(self, value, default=0.0):
        """Return a safe numeric value, replacing NaN/Inf with default."""
        if self._is_valid_number(value):
            return float(value)
        return default
    
    def _generate_points_array(self, x_values, y_values):
        """Convert numpy arrays to a list of QPointF for efficient plotting"""
        # Optimize creation of points by avoiding unnecessary array conversion
        if isinstance(y_values, list):
            y_values = np.array(y_values)
        
        # Avoid recalculating if x_values are already in degrees
        if np.max(x_values) > 10:  # If already in degrees (larger than ~6.28)
            x_degrees = x_values
        else:
            # Map x values from radians to degrees for display
            x_degrees = np.degrees(x_values)
        
        # Create list of QPointF objects efficiently using list comprehension
        return [QPointF(float(x), float(y)) for x, y in zip(x_degrees, y_values)]
    
    def batchUpdate(self):
        """Emit all signals at once to reduce update frequency with a small delay"""
        # Default to emitting all signals if no specific signals are pending
        if not self._pending_signals:
            self._pending_signals = {"harmonicsChanged", "waveformChanged", 
                                   "crestFactorChanged", "formFactorChanged",
                                   "calculationsComplete"}
        
        self._update_pending = True
        
        # Only start timer from main thread
        if QThread.currentThread() == QApplication.instance().thread():
            if not self._update_timer.isActive():
                self._update_timer.start()
        else:
            # If called from worker thread, set flag for main thread to handle
            self._emit_pending = True
            QMetaObject.invokeMethod(self, "checkPendingUpdates", 
                                   Qt.ConnectionType.QueuedConnection)
    
    @Slot()
    def checkPendingUpdates(self):
        """Check and process any pending updates (called from main thread)"""
        if self._emit_pending:
            self._emit_pending = False
            self.batchUpdate()
    
    @Property(float, notify=thdChanged)
    def thd(self):
        """Get current THD (Total Harmonic Distortion) value."""
        return self._thd

    @Slot(str, result=bool)
    def exportDataToCSV(self, filePath=None):
        """Export harmonic data to CSV file.
        
        If filePath is None, a file dialog will be shown.
        """
        try:
            # If no filePath provided, use the file saver to get one
            file_saver = FileSaver()
            if not filePath:
                filePath = file_saver.get_save_filepath("csv", "harmonics_data")
                if not filePath:
                    self.exportDataToFolderCompleted.emit(False, "CSV export canceled")
                    return False
            
            # Prepare data in the format expected by save_csv
            csv_data = []
            
            # Add header row
            csv_data.append(['Harmonic Order', 'Magnitude (%)', 'Phase (degrees)'])
            
            # Add harmonic data rows
            display_orders = [1, 3, 5, 7, 11, 13]
            for i, order in enumerate(display_orders):
                csv_data.append([
                    order, 
                    self._individual_distortion[i], 
                    self._harmonic_phases[i]
                ])
            
            # Add blank row between data sections
            csv_data.append([])
            
            # Add analysis results header
            csv_data.append(['Analysis Results', ''])
            
            # Add results rows
            csv_data.append(['THD', f"{self._thd:.2f}%"])
            csv_data.append(['Crest Factor', f"{self._cf:.2f}"])
            csv_data.append(['Form Factor', f"{self._ff:.2f}"])
            
            # Call save_csv with the prepared data
            result = file_saver.save_csv(filePath, csv_data)
            
            # Let file_saver handle the success message for consistency
            if result:
                # Success message will be handled by FileSaver's signal
                return True
            else:
                self.exportDataToFolderCompleted.emit(False, f"Error saving to {filePath}")
                return False
                
        except Exception as e:
            error_message = f"Error exporting harmonic data: {str(e)}"
            logger.error(error_message)
            logger.exception(e)
            self.exportDataToFolderCompleted.emit(False, error_message)
            return False

    @Slot()
    def resetHarmonics(self):
        """Reset harmonics to default values (pure fundamental)."""
        # Reset harmonics dictionary to only include fundamental
        self._harmonics_dict = {1: (100.0, 0.0)}  # Only fundamental at 100%
        
        # Reset harmonics array
        self._harmonics = [0.0] * len(self._harmonics)
        self._harmonics[0] = 100.0  # Set fundamental to 100%
        
        # Reset phases
        self._harmonic_phases = [0.0] * len(self._harmonic_phases)
        
        # Reset individual distortion values
        self._individual_distortion = [100.0] + [0.0] * (len(self._individual_distortion) - 1)
        
        # Signal that harmonics have changed
        self.harmonicsChanged.emit()
        
        # Recalculate with new harmonics
        self._calculate()
        
        return True

    @Slot(int, float, float)
    def setHarmonic(self, order, magnitude, angle=0):
        """Set magnitude and angle for a harmonic order."""
        if order > 0 and order <= len(self._harmonics):
            # Validate inputs before storing them
            safe_magnitude = self._safe_value(magnitude, 0.0)
            safe_angle = self._safe_value(angle, 0.0)
            
            # Update the harmonics dictionary
            self._harmonics_dict[order] = (safe_magnitude, safe_angle)
            
            # Debounce calculations during rapid changes
            current_time = time.time() * 1000  # Convert to ms
            if current_time - self._last_calculation_time > self._debounce_interval:
                self._last_calculation_time = current_time
                self._calculate()
            else:
                # Delay calculation using timer
                QTimer.singleShot(self._debounce_interval, self._calculate)
            
            return True
        return False
    
    @Slot(int, float)
    def setHarmonicAmplitude(self, order, amplitude):
        """Set the amplitude of a specific harmonic (maintains angle)"""
        if order > 0 and order <= len(self._harmonics):
            # Get current phase or default to 0
            _, angle = self._harmonics_dict.get(order, (0.0, 0.0))
            # Call the full setter
            return self.setHarmonic(order, amplitude, angle)
        return False
    
    @Slot(int, float)
    def setHarmonicPhase(self, order, angle):
        """Set the phase of a specific harmonic (maintains amplitude)"""
        if order > 0 and order <= len(self._harmonics):
            # Get current magnitude or default to 0
            magnitude, _ = self._harmonics_dict.get(order, (0.0, 0.0))
            # Call the full setter
            return self.setHarmonic(order, magnitude, angle)
        return False
    
    @Slot(float)
    def setFundamental(self, value):
        """Set the fundamental amplitude."""
        if value >= 0:
            self._fundamental = value
            self.fundamentalChanged.emit()
            self._calculate()
            return True
        return False
    
    @Slot(list)
    def setAllHarmonics(self, harmonics):
        """Set all harmonic amplitudes at once."""
        if len(harmonics) <= len(self._harmonics):
            # Update harmonics dictionary - keep phases the same
            for i, amplitude in enumerate(harmonics):
                order = i + 1
                _, angle = self._harmonics_dict.get(order, (0.0, 0.0))
                self._harmonics_dict[order] = (amplitude, angle)
            
            self.harmonicsChanged.emit()
            self._calculate()
            return True
        return False
    
    @Property(list, notify=calculationsComplete)
    def individualDistortion(self):
        return self._individual_distortion
    
    @Property(list, notify=calculationsComplete)
    def harmonicPhases(self):
        """Get phase angles for display harmonics."""
        return self._harmonic_phases
    
    @Property(list, notify=calculationsComplete)
    def waveformPoints(self):
        return self._waveform_points
    
    @Property(list)
    def waveform(self):
        """Get time-domain waveform points."""
        return self._waveform
        
    @Property(list)
    def fundamentalWaveform(self):
        """Get fundamental component waveform."""
        return self._fundamental_wave
    
    @Property(list)
    def spectrum(self):
        """Get frequency spectrum points."""
        return self._spectrum
    
    @Property(list)
    def fundamentalPoints(self):
        """Get fundamental waveform points as QPointF objects for efficient plotting"""
        return self._fundamental_points