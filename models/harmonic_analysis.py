from PySide6.QtCore import QObject, Property, Signal, Slot, QPointF, QTimer
import numpy as np
import math
import csv
import os
from datetime import datetime
import json
import time

# Import the profiling decorator
from utils.profiling import profile, PerformanceProfiler

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

    def __init__(self, parent=None):
        super().__init__(parent)
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
        self._calculation_cache = {}
        self._max_cache_size = 20  # Limit cache size
        self._cache_hits = 0
        self._cache_misses = 0
        
        # Add signal emission timer
        self._update_timer = QTimer(self)
        self._update_timer.setSingleShot(True)
        self._update_timer.setInterval(10)  # 10ms delay
        self._update_timer.timeout.connect(self._emitSignals)
        
        # Flag to track pending updates
        self._update_pending = False
        
        # Add pending signals tracking
        self._pending_signals = set()
        
        self._calculate()
        
        # Profiling support
        self._profiling_enabled = False

    @Slot(bool)
    def enableProfiling(self, enabled):
        """Enable or disable performance profiling"""
        self._profiling_enabled = enabled
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
        """Print profiling summary to console"""
        PerformanceProfiler.get_instance().print_summary()
    
    @Property(bool, notify=profilingChanged)
    def profilingEnabled(self):
        """Get profiling enabled state"""
        return self._profiling_enabled

    @profile
    def _get_cache_key(self):
        """Generate a unique key for the current harmonics configuration
        
        Returns a tuple that uniquely identifies the current calculation state
        """
        # Use a tuple of sorted items for consistent key generation
        sorted_harmonics = sorted(self._harmonics_dict.items())
        return tuple((order, float(magnitude), float(phase)) for order, (magnitude, phase) in sorted_harmonics)
        
    @profile
    def _calculate(self):
        try:
            # Check cache first
            cache_key = self._get_cache_key()
            if (cache_key in self._calculation_cache):
                # Cache hit - use stored results
                self._cache_hits += 1
                cached_result = self._calculation_cache[cache_key]
                
                # Load all values from cache
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
                return
            
            # Cache miss - perform full calculation
            self._cache_misses += 1
            
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
                (harmonics[order-1] / self._fundamental * 100.0) 
                for order in display_orders
            ]
            
            # Store phases for display harmonics
            self._harmonic_phases = [
                phases[order-1] for order in display_orders
            ]
            
            # Generate waveform with validation
            # Reduce default resolution for better performance
            t = np.linspace(0, 2*np.pi, 250)  # Reduced from 500 to 250 points
            wave = np.zeros_like(t)  # Pre-allocate array
            
            # Handle potential NaN/Inf in calculation
            try:
                # Vectorized calculation of fundamental waveform - more efficient
                phase_rad_fundamental = np.radians(self._safe_value(phases[0], 0.0))
                fundamental_wave = self._fundamental * np.sin(t + phase_rad_fundamental)
                
                # Replace any NaN or Inf values with zeros
                np.nan_to_num(fundamental_wave, copy=False)
                self._fundamental_wave = fundamental_wave.tolist()
                
                # Pre-calculate all harmonic components at once for better performance
                for i, (amplitude, phase_deg) in enumerate(zip(harmonics, phases)):
                    if amplitude > 0 and self._is_valid_number(amplitude) and self._is_valid_number(phase_deg):
                        harmonic_order = i + 1
                        phase_rad = np.radians(phase_deg)
                        # Use np.add with out parameter to avoid creating new arrays
                        harmonic_wave = amplitude * np.sin(harmonic_order * t + phase_rad)
                        np.nan_to_num(harmonic_wave, copy=False)  # Replace NaN/Inf with zeros
                        np.add(wave, harmonic_wave, out=wave)
                
                # Replace any NaN or Inf values
                np.nan_to_num(wave, copy=False)
                self._waveform = wave.tolist()
                
                # Vectorized calculation of crest factor and form factor - more efficient
                if wave.size:
                    # Use pre-calculated numpy functions for better performance
                    wave_abs = np.abs(wave)
                    peak = np.max(wave_abs)
                    rms_squared = np.mean(np.square(wave))
                    
                    # Prevent division by zero or invalid values
                    if rms_squared > 0 and np.isfinite(rms_squared):
                        rms = np.sqrt(rms_squared)
                        self._cf = self._safe_value(peak / rms, 1.414)  # Default to sine wave value
                        
                        # Calculate form factor efficiently
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
                self._waveform = [0.0] * 500
                self._fundamental_wave = [0.0] * 500
                self._cf = 1.414
                self._ff = 1.11
            
            # Generate QPointF ready data for more efficient plotting
            # Reuse t for point generation to avoid recalculating
            self._waveform_points = self._generate_points_array(t, wave)
            self._fundamental_points = self._generate_points_array(t, fundamental_wave)
            
            # Store in cache
            if len(self._calculation_cache) >= self._max_cache_size:
                # Remove oldest item when cache is full (simple FIFO strategy)
                oldest_key = next(iter(self._calculation_cache))
                self._calculation_cache.pop(oldest_key)
            
            # Store all results in cache
            self._calculation_cache[cache_key] = {
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
            
            # Mark which signals need emission based on what actually changed
            self._pending_signals = {"harmonicsChanged", "waveformChanged", 
                                     "crestFactorChanged", "formFactorChanged",
                                     "calculationsComplete"}
                                     
            # Add a slight delay before updating to avoid overwhelming the UI thread
            self._update_timer.setInterval(20)  # Increase delay to 20ms
            self.batchUpdate()
            
        except Exception as e:
            print(f"Calculation error: {e}")
            import traceback
            traceback.print_exc()  # Print full stack trace for debugging
    
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
    def batchUpdate(self):
        """Emit all signals at once to reduce update frequency with a small delay"""
        # Default to emitting all signals if no specific signals are pending
        if not self._pending_signals:
            self._pending_signals = {"harmonicsChanged", "waveformChanged", 
                                     "crestFactorChanged", "formFactorChanged",
                                     "calculationsComplete"}
        
        self._update_pending = True
        if not self._update_timer.isActive():
            self._update_timer.start()
            
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
                    
            # Throttle update frequency during intensive operations
            import psutil
            if self._profiling_enabled:
                cpu_load = psutil.cpu_percent(interval=0.05)
                if cpu_load > 80:
                    # Reduce update frequency during high CPU load
                    time.sleep(0.05)  # Brief pause to allow UI to remain responsive
        except (ImportError, Exception):
            pass
            
        # Reset state
        self._update_pending = False
        self._pending_signals.clear()

    # Properties and setters...
    @Property(float, notify=fundamentalChanged)
    def fundamental(self):
        return self._fundamental
    
    @fundamental.setter
    def fundamental(self, value):
        if value >= 0:
            self._fundamental = value
            self.fundamentalChanged.emit()
            self._calculate()

    @Property(list, notify=calculationsComplete)
    def harmonics(self):
        return self._harmonics
    
    @Property(float, notify=calculationsComplete)
    def thd(self):
        return self._thd

    @Property(float, notify=crestFactorChanged)
    def crestFactor(self):
        """Get Crest Factor."""
        return self._cf

    @Property(float, notify=formFactorChanged)
    def formFactor(self):
        """Get Form Factor."""
        return self._ff

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

    @Slot()
    def resetHarmonics(self):
        """Reset harmonics to default values (pure fundamental)."""
        self._harmonics_dict = {1: (100.0, 0.0)}  # Only fundamental at 100%
        self._calculate()

    @Slot()
    def exportData(self):
        """Export harmonic data to CSV file."""
        try:
            # Create directory if it doesn't exist
            export_dir = os.path.expanduser("~/Documents/harmonics_export")
            os.makedirs(export_dir, exist_ok=True)
            
            # Generate filename with timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{export_dir}/harmonics_data_{timestamp}.csv"
            
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

    @Slot(float)
    def setFundamental(self, value):
        self.fundamental = value

    @Slot(int, float)
    def setHarmonic(self, index, amplitude):
        """Set the amplitude of a specific harmonic"""
        if 0 <= index < len(self._harmonics):
            self._harmonics[index] = amplitude
            self.harmonicsChanged.emit()
            self._calculate()

    @profile
    @Slot(int, float, float)
    def setHarmonic(self, order, magnitude, angle=0):
        """Set magnitude and angle for a harmonic order."""
        if order > 0 and order <= len(self._harmonics):
            # Validate inputs before storing them
            safe_magnitude = self._safe_value(magnitude, 0.0)
            safe_angle = self._safe_value(angle, 0.0)
            
            self._harmonics_dict[order] = (safe_magnitude, safe_angle)
            self._calculate()

    @Slot(list)
    def setAllHarmonics(self, harmonics):
        """Set all harmonic amplitudes at once"""
        if len(harmonics) <= len(self._harmonics):
            self._harmonics = harmonics + [0.0] * (len(self._harmonics) - len(harmonics))
            self.harmonicsChanged.emit()
            self._calculate()

    @Slot('QVariant', list)
    def fillSeries(self, series, points):
        """Efficiently fill a QXYSeries with points using replace method"""
        if series and points:
            try:
                series.replace(points)
                return True
            except Exception as e:
                print(f"Error filling series: {e}")
                return False
        return False

    @Slot('QVariant')
    def fillWaveformSeries(self, series):
        """Efficiently fill a waveform series with calculated points"""
        return self.fillSeries(series, self._waveform_points)
        
    @Slot('QVariant')
    def fillFundamentalSeries(self, series):
        """Efficiently fill a fundamental series with calculated points"""
        return self.fillSeries(series, self._fundamental_points)

    @Slot(int)
    def prepareSpectrumPoint(self, index):
        """Get a QPointF for a spectrum point (for phase angle series)"""
        if 0 <= index < len(self._harmonic_phases):
            return QPointF(index + 0.5, self._harmonic_phases[index])
        return QPointF(0, 0)

    @profile
    @Slot(int)
    def calculateWithResolution(self, points=500):
        """Calculate waveform with adaptive resolution
        
        Args:
            points: Number of points to generate for the waveform
        """
        try:
            # Get current harmonic configuration
            harmonics = [0.0] * 15
            phases = [0.0] * 15
            
            for order, (magnitude, phase) in self._harmonics_dict.items():
                if 1 <= order < len(harmonics):
                    harmonics[order-1] = magnitude
                    phases[order-1] = phase
            
            # Generate waveform with optimized NumPy operations at specified resolution
            t = np.linspace(0, 2*np.pi, points)
            wave = np.zeros_like(t)
            
            # Vectorized calculation of fundamental waveform
            phase_rad_fundamental = np.radians(phases[0])
            fundamental_wave = self._fundamental * np.sin(t + phase_rad_fundamental)
            
            # Pre-calculate all harmonic components at once for better performance
            for i, (amplitude, phase_deg) in enumerate(zip(harmonics, phases)):
                if amplitude > 0:
                    harmonic_order = i + 1
                    phase_rad = np.radians(phase_deg)
                    np.add(wave, amplitude * np.sin(harmonic_order * t + phase_rad), out=wave)
            
            # Generate QPointF ready data for efficient plotting
            waveform_points = self._generate_points_array(t, wave)
            fundamental_points = self._generate_points_array(t, fundamental_wave)
            
            return {
                'waveform': wave.tolist(),
                'fundamental': fundamental_wave.tolist(),
                'waveform_points': waveform_points,
                'fundamental_points': fundamental_points
            }
        except Exception as e:
            print(f"Resolution calculation error: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    @profile
    @Slot(int)
    def updateResolution(self, points=500):
        """Update waveform with specified resolution"""
        # More aggressive throttling for better performance
        # Dynamic resolution based on device capability
        try:
            # Check system load to determine optimal resolution
            import psutil
            cpu_load = psutil.cpu_percent(interval=0.1)
            
            # Adjust points based on system load
            if cpu_load > 70:  # High load
                points = min(points, 100)  # Force low resolution on high CPU load
            elif cpu_load > 40:  # Medium load
                points = min(points, 250)  # Medium resolution
        except ImportError:
            # If psutil isn't available, use provided points
            pass
            
        # Upper limit to prevent lag on any system
        adjusted_points = min(points, 500)
        
        result = self.calculateWithResolution(adjusted_points)
        if result:
            self._waveform = result['waveform']
            self._fundamental_wave = result['fundamental']
            self._waveform_points = result['waveform_points']
            self._fundamental_points = result['fundamental_points']
            
            # Only emit waveform changed since other properties didn't change
            self._pending_signals = {"waveformChanged"}
            self.batchUpdate()
        return True

    @Slot()
    def clearCache(self):
        """Clear the calculation cache"""
        self._calculation_cache.clear()
        self._cache_hits = 0
        self._cache_misses = 0
        return True
    
    @Slot()
    def getCacheStats(self):
        """Get cache performance statistics"""
        total = self._cache_hits + self._cache_misses
        hit_rate = self._cache_hits / total if total > 0 else 0
        return {
            "hits": self._cache_hits,
            "misses": self._cache_misses,
            "total": total,
            "hit_rate": hit_rate * 100.0,
            "cache_size": len(self._calculation_cache),
            "max_size": self._max_cache_size
        }

    @Slot()
    def getProfiler(self):
        """Get reference to the profiler for QML to use"""
        return PerformanceProfiler.get_instance()
    
    @Slot(bool)
    def setDetailedLogging(self, enabled):
        """Enable/disable detailed performance logging"""
        profiler = PerformanceProfiler.get_instance()
        profiler.detailed_logging = enabled
        
    @Slot()
    def recordFrameTime(self):
        """Record frame time for profiling from QML"""
        if self._profiling_enabled:
            try:
                PerformanceProfiler.get_instance().record_frame()
            except Exception as e:
                print(f"Error recording frame time: {e}")
