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

# Import the profiling decorator
from utils.profiling import profile, PerformanceProfiler
from utils.calculation_cache import CalculationCache, generate_cache_key
from utils.worker_pool import WorkerPoolManager, ManagedWorker

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
                    self.calculator._waveform = cached_result['waveform']
                    self.calculator._fundamental_wave = cached_result['fundamental']
                    self.calculator._waveform_points = cached_result['waveform_points']
                    self.calculator._fundamental_points = cached_result['fundamental_points']
                    
                    # Signal that calculation is complete
                    self.calculator._pending_signals = {"waveformChanged"}
                    self.calculator._emit_pending = True
                else:
                    # Calculate and cache
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
            print(f"Error in calculation worker: {e}")
            # Always ensure we reset calculation status on error
            QMetaObject.invokeMethod(self.calculator, "_update_calculation_status",
                                   Qt.ConnectionType.QueuedConnection,
                                   Q_ARG(bool, False),
                                   Q_ARG(float, 0.0))
            import traceback
            traceback.print_exc()

class HarmonicAnalysisCalculator(QObject):
    """Calculator for harmonic analysis and THD calculation"""

    fundamentalChanged = Signal()
    harmonicsChanged = Signal()
    calculationsComplete = Signal()
    thdChanged = Signal()
    crestFactorChanged = Signal()
    formFactorChanged = Signal()
    waveformChanged = Signal()
    profilingChanged = Signal()  # Add new signal for profiling state
    calculationStatusChanged = Signal()
    calculationProgressChanged = Signal(float)

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
        self._spectrum_points = []
        self._spectrum = []
        
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
        
        # Initialize profiling support
        self._profiling_enabled = False
        
        # Add thread pool for background calculations
        self._thread_pool = WorkerPoolManager.get_instance()
        print(f"Using {self._thread_pool.maxThreadCount()} threads for calculations")
        
        # Flag to track if updates are needed
        self._emit_pending = False
        
        # Now we can safely call methods that depend on these attributes
        self._calculate()
        
    @Slot(bool)
    def enableProfiling(self, enabled):
        """Enable/disable performance profiling"""
        self._profiling_enabled = enabled  # Make sure we update the attribute
        profiler = PerformanceProfiler.get_instance()
        if enabled:
            profiler.enable()
        else:
            profiler.disable()
        self.profilingChanged.emit()
            
    @Slot()
    def clearProfilingData(self):
        """Clear all profiling data"""
        PerformanceProfiler.get_instance().clear()
            
    @Slot()
    def printProfilingSummary(self):
        """Print profiling summary to console with error handling"""
        try:
            PerformanceProfiler.get_instance().print_summary()
        except Exception as e:
            print(f"Error printing profiling summary: {e}")
            print("Some performance data might not be available.")
    
    @Property(bool, notify=profilingChanged)
    def profilingEnabled(self):
        """Get profiling enabled state"""
        return self._profiling_enabled

    @profilingEnabled.setter
    def profilingEnabled(self, enabled):
        """Set profiling enabled state"""
        if self._profiling_enabled != enabled:
            self._profiling_enabled = enabled
            profiler = PerformanceProfiler.get_instance()
            if enabled:
                profiler.enable()
            else:
                profiler.disable()
            self.profilingChanged.emit()
        
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
        
    @Slot()
    def cancelCalculation(self):
        """Request cancellation of any in-progress calculation"""
        self._cancel_requested = True
        print("Calculation cancellation requested")
        
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
    
    @profile
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
            
            # Throttle update frequency during intensive operations
            try:
                import psutil
                if self._profiling_enabled:
                    cpu_load = psutil.cpu_percent(interval=0.05)
                    if cpu_load > 80:
                        # Reduce update frequency during high CPU load
                        time.sleep(0.05)  # Brief pause to allow UI to remain responsive
            except (ImportError, Exception):
                pass
        except Exception as e:
            print(f"Error emitting signals: {e}")
            
        # Reset state
        self._update_pending = False
        self._pending_signals.clear()
    
    @profile
    def _calculate(self):
        """Start calculation in a worker thread"""
        # Set calculation status to in-progress
        self._cancel_requested = False
        self._update_calculation_status(True, 0.0)
        
        # Create a worker and start it in the thread pool
        worker = CalculationWorker(self)
        self._thread_pool.start(worker)
        return True
    
    @profile
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
    
    @profile
    def _calculate_full(self):
        """Perform full harmonic analysis calculation"""
        try:
            # Update progress
            self._update_calculation_status(True, 0.1)
            
            # Check cancellation
            if self._cancel_requested:
                self._update_calculation_status(False)
                return
            
            # Check cache first
            cache_key = self._get_cache_key()
            self._cache_lookups += 1
            cached_result = self._calculation_cache.get(cache_key)
            if cached_result:
                # Cache hit - use stored results
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
            self._cache_misses += 1
                
            # Update progress
            self._update_calculation_status(True, 0.2)
            
            # Check cancellation
            if self._cancel_requested:
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
                        print(f"Warning: Invalid values for harmonic {order}: magnitude={magnitude}, phase={phase}")
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
            
            # Generate waveform with validation
            # Reduced default resolution for better performance
            t = np.linspace(0, 2*np.pi, 250)  # Reduced from 500 to 250 points
            wave = np.zeros_like(t)  # Pre-allocate array
            
            # Calculate waveform with safe handling of potential NaN/Inf
            try:
                # Vectorized calculation of fundamental waveform
                phase_rad_fundamental = np.radians(self._safe_value(phases[0], 0.0))
                fundamental_wave = self._fundamental * np.sin(t + phase_rad_fundamental)
                
                # Replace any NaN or Inf values with zeros
                np.nan_to_num(fundamental_wave, copy=False)
                self._fundamental_wave = fundamental_wave.tolist()
                
                # Calculate harmonics and add to waveform
                for i, (amplitude, phase_deg) in enumerate(zip(harmonics, phases)):
                    if amplitude > 0 and self._is_valid_number(amplitude) and self._is_valid_number(phase_deg):
                        harmonic_order = i + 1
                        phase_rad = np.radians(phase_deg)
                        harmonic_wave = amplitude * np.sin(harmonic_order * t + phase_rad)
                        np.nan_to_num(harmonic_wave, copy=False)  # Replace NaN/Inf with zeros
                        np.add(wave, harmonic_wave, out=wave)
                
                # Replace any NaN or Inf values in the final waveform
                np.nan_to_num(wave, copy=False)
                self._waveform = wave.tolist()
                
                # Calculate crest factor and form factor
                if wave.size:
                    wave_abs = np.abs(wave)
                    peak = np.max(wave_abs)
                    rms_squared = np.mean(np.square(wave))
                    
                    if rms_squared > 0 and np.isfinite(rms_squared):
                        rms = np.sqrt(rms_squared)
                        self._cf = self._safe_value(peak / rms, 1.414)  # Default to sine wave value
                        
                        # Calculate form factor
                        average_rectified = np.mean(wave_abs)
                        if average_rectified > 0 and np.isfinite(average_rectified):
                            self._ff = self._safe_value(rms / average_rectified, 1.11)  # Default to sine wave value
                        else:
                            self._ff = 1.11  # Default sine wave value
                    else:
                        self._cf = 1.414  # Default sine wave value
                        self._ff = 1.11   # Default sine wave value
            except Exception as inner_e:
                print(f"Error in waveform calculation: {inner_e}")
                # Reset to safe defaults
                self._waveform = [0.0] * 250
                self._fundamental_wave = [0.0] * 250
                self._cf = 1.414
                self._ff = 1.11
            
            # Generate QPointF ready data for more efficient plotting
            self._waveform_points = self._generate_points_array(t, wave)
            self._fundamental_points = self._generate_points_array(t, fundamental_wave)
            
            # Store in cache
            self._calculation_cache.put(cache_key, {
                'thd': self._thd,
                'cf': self._cf,
                'ff': self._ff,
                'waveform': self._waveform,
                'fundamental_wave': self._fundamental_wave,
                'individual_distortion': self._individual_distortion,
                'harmonic_phases': self._harmonic_phases,
                'waveform_points': self._waveform_points,
                'fundamental_points': self._fundamental_points
            })
            
            # Mark which signals need emission
            self._pending_signals = {"harmonicsChanged", "waveformChanged", 
                                   "crestFactorChanged", "formFactorChanged",
                                   "calculationsComplete"}
            
            # Reset calculation status
            self._update_calculation_status(False, 1.0)
            
            # Trigger batch update
            self.batchUpdate()
            
        except Exception as e:
            print(f"Calculation error: {e}")
            import traceback
            traceback.print_exc()
            # Reset calculation status on error
            self._update_calculation_status(False)
    
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
    
    @profile
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
    
    @profile
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

    @Slot(result=bool)
    def exportData(self):
        """Export harmonic data to CSV file."""
        try:
            # Create directory if it doesn't exist
            export_dir = os.path.expanduser("~/Documents/harmonics_export")
            os.makedirs(export_dir, exist_ok=True)
            
            # Generate filename with timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{export_dir}/harmonics_data_{timestamp}.csv"
            
            # Create directory if it doesn't exist
            with open(filename, 'w', newline='') as csvfile:
                writer = csv.writer(csvfile)
                writer.writerow(['Harmonic Order', 'Magnitude (%)', 'Phase (degrees)'])
                
                # Write data for display harmonics
                display_orders = [1, 3, 5, 7, 11, 13]
                for i, order in enumerate(display_orders):
                    writer.writerow([order, 
                                     self._individual_distortion[i], 
                                     self._harmonic_phases[i]])
                
                # Add additional results
                writer.writerow([])
                writer.writerow(['Analysis Results', ''])
                writer.writerow(['THD', f"{self._thd:.2f}%"])
                writer.writerow(['Crest Factor', f"{self._cf:.2f}"])
                writer.writerow(['Form Factor', f"{self._ff:.2f}"])
                
            print(f"Data exported to {filename}")
            return True
        except Exception as e:
            print(f"Export error: {e}")
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
            
            # Start calculation
            self._calculate()
            
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