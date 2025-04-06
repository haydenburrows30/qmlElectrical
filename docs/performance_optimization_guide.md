# Harmonics Analyzer Performance Optimization Guide

This document contains recommendations to improve the performance of the Harmonics Analyzer without modifying the existing code directly.

## Calculator Optimizations

### Memoization for Repeated Calculations

Add this to `HarmonicAnalysisCalculator` class to cache previous calculations:

```python
# Add to __init__ method
self._calculation_cache = {}
self._max_cache_size = 50  # Limit cache size

# Define a method to generate cache keys
def _get_cache_key(self):
    """Generate a unique key for the current harmonics configuration"""
    return frozenset(self._harmonics_dict.items())

# Update the _calculate method to use caching
def _calculate(self):
    try:
        # Check cache first
        cache_key = self._get_cache_key()
        if cache_key in self._calculation_cache:
            cached_result = self._calculation_cache[cache_key]
            self._thd = cached_result['thd']
            self._cf = cached_result['cf']
            self._ff = cached_result['ff']
            self._waveform = cached_result['waveform']
            self._fundamental_wave = cached_result['fundamental_wave']
            self._individual_distortion = cached_result['individual_distortion']
            self._harmonic_phases = cached_result['harmonic_phases']
            self._waveform_points = cached_result['waveform_points']
            self._fundamental_points = cached_result['fundamental_points']
            
            self.batchUpdate()
            return
            
        # ... existing calculation code ...
        
        # Store in cache
        if len(self._calculation_cache) >= self._max_cache_size:
            # Remove oldest item if cache is full
            self._calculation_cache.pop(next(iter(self._calculation_cache)))
            
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
    # ... existing error handling ...
```

### Optimize NumPy Operations

Replace this part of the `_calculate` method:

```python
# Generate waveform more efficiently
t = np.linspace(0, 2*np.pi, 500)
wave = np.zeros_like(t)  # Pre-allocate array

# Vectorize fundamental calculation
phase_rad = np.radians(phases[0])
self._fundamental_wave = (self._fundamental * np.sin(t + phase_rad)).tolist()

# Vectorize harmonic calculation with pre-allocated arrays
for i, (amplitude, phase_deg) in enumerate(zip(harmonics, phases)):
    if amplitude > 0:
        # No need to create new arrays in this loop
        harmonic_order = i + 1
        phase_rad = np.radians(phase_deg)
        np.add(wave, amplitude * np.sin(harmonic_order * t + phase_rad), out=wave)

self._waveform = wave.tolist()
```

### Limit Waveform Resolution Based on View

```python
def calculate_with_resolution(self, points=500):
    """Calculate waveform with adaptive resolution"""
    # Scale the number of points based on what's actually needed
    t = np.linspace(0, 2*np.pi, points)
    # ... rest of calculation ...
```

## Visualization Optimizations

### Enable Hardware Acceleration for Charts

Add these properties to both ChartView elements:

```qml
renderTarget: ChartView.OpenGLRenderTarget
renderStrategy: ChartView.HardwareAcceleration
```

### Throttle Input Changes

Replace the TextField's `onTextChanged` handler with a throttled version:

```qml
TextFieldRound {
    id: magnitudeField
    placeholderText: modelData === 1 ? "100%" : "0%"
    enabled: modelData !== 1
    validator: DoubleValidator { bottom: 0; top: 100 }
    
    // Add throttling to avoid excessive updates
    property bool updatePending: false
    onTextChanged: {
        if(text && !updatePending) {
            updatePending = true
            updateTimer.start()
        }
    }
    
    Timer {
        id: updateTimer
        interval: 300 // 300ms throttle
        onTriggered: {
            if (magnitudeField.text) {
                calculator.setHarmonic(
                    modelData, 
                    parseFloat(magnitudeField.text), 
                    phaseField.text ? parseFloat(phaseField.text) : 0
                )
            }
            magnitudeField.updatePending = false
        }
    }
}
```

### Optimize Series Data Updates

Enhance the `SeriesHelper` class with these methods:

```python
def optimize_points(self, x_values, y_values, max_points=500):
    """Reduce data points while preserving key features"""
    if len(x_values) <= max_points:
        return x_values, y_values
    
    # Downsample data using strides
    stride = len(x_values) // max_points
    return x_values[::stride], y_values[::stride]

def fill_series_optimized(self, series, x_values, y_values, max_points=500):
    """Fill a series with optimized point count"""
    x_opt, y_opt = self.optimize_points(x_values, y_values, max_points)
    self.fillSeriesFromArrays(series, x_opt, y_opt)
```

## Low-Hanging Optimizations

### Batch UI Updates

In the calculator's `batchUpdate` method, add a small delay to group signals:

```python
def batchUpdate(self):
    """Emit all signals at once to reduce update frequency"""
    # Delay signal emissions slightly to batch them
    QTimer.singleShot(0, self._emitSignals)

def _emitSignals(self):
    self.harmonicsChanged.emit()
    self.waveformChanged.emit()
    self.crestFactorChanged.emit()
    self.formFactorChanged.emit()
    self.calculationsComplete.emit()
```

### Reduce Data Transfer

Instead of sending the full array of waveform points to QML, implement a method that returns only the changed data:

```python
@Property(list)
def waveformDelta(self):
    """Get only the changed points since last update"""
    if not hasattr(self, '_last_waveform'):
        self._last_waveform = self._waveform
        return self._waveform
    
    delta = []
    for i, (old, new) in enumerate(zip(self._last_waveform, self._waveform)):
        if old != new:
            delta.append((i, new))
    
    self._last_waveform = self._waveform
    return delta
```

### Add Profiling Support

Add this utility to identify performance bottlenecks:

```python
import time
import functools

def profile(func):
    """Decorator for profiling methods"""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        print(f"{func.__name__} took {(end-start)*1000:.2f}ms to run")
        return result
    return wrapper

# Usage example:
# @profile
# def _calculate(self):
#     ...
```

## Testing the Optimizations

To test these optimizations safely:

1. Implement one optimization at a time
2. Measure performance before and after each change
3. Verify that functionality remains intact
4. Monitor memory usage and CPU consumption

## Implementation Priority

1. Enable hardware acceleration in ChartView
2. Add throttling to text input handlers
3. Implement memoization in the calculator
4. Optimize NumPy operations
5. Add optimized point reduction


Calculation Optimizations
Memoization for Repeated Calculations

Cache results of expensive calculations that get called with the same parameters
Store previously calculated waveforms and reuse them when harmonic parameters haven't changed
Reduce Numpy/Math Overhead

Pre-allocate arrays and avoid recreating them repeatedly
Use vectorized operations (np.sin over arrays instead of loops)
Consider using NumPy's out parameter to avoid creating new arrays
Defer Calculations

Calculate only what's needed at each step (lazy evaluation)
Implement throttling to avoid recalculating too frequently during user input
Parallel Processing

Use multi-threading for intensive calculations
Consider using NumPy's parallel processing capabilities
Visualization Optimizations
Reduce Data Points

Downsample waveforms when not zoomed in (adaptive level of detail)
Generate fewer data points for simpler harmonics combinations
Efficient Series Updates

Use QtCharts batch operations (replace() instead of multiple append())
Only update charts when data has significantly changed
Hardware Acceleration

Enable OpenGL rendering for QML charts
Use QSGNode for custom rendering if needed
Optimize UI Updates

Reduce binding loops and property evaluations
Use Component.onCompleted to defer non-critical initializations
Batch multiple property changes together
Memory Management

Explicitly clean up unused resources
Monitor and limit memory usage for large datasets