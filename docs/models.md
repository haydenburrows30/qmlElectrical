# Models Documentation

## ThreePhaseSineWaveModel
Core model for three-phase calculations:

### Features
- Vectorized calculations using NumPy
- Caching system for performance
- Real-time waveform generation
- RMS and peak value calculations

### Properties
- Frequency: Base frequency (default 50Hz)
- Amplitude: Peak voltage for each phase
- Phase angles: Relative phase shifts
- Time period: 1 second display window

### Optimizations
- Cached calculations
- Vectorized operations
- Downsampling for large datasets
- Memory efficient updates

## Calculator System

### Base Calculator
Abstract base class combining QObject and ABC:
- Defines common calculator interface
- Provides metaclass handling
- Enforces implementation of key methods

### Calculator Factory
Factory pattern implementation:
- Dynamic calculator registration
- Type-safe calculator creation
- Default calculator registration
