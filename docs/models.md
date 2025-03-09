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

## VoltageDropCalculator
Cable voltage drop calculator with diversity and ADMD support.

### Features
- Load-based calculations with diversity factors
- ADMD (After Diversity Maximum Demand) support
- Single and three-phase calculations
- Temperature correction
- Installation method factors
- Multiple conductor materials (Cu/Al)
- Core configuration options (1C+E/3C+E)

### Key Properties
- `current`: Calculated current in amperes
- `diversityFactor`: Applied diversity factor
- `admdEnabled`: ADMD calculation state
- `voltageDrop`: Calculated voltage drop in volts

### Calculations
1. Diversity Factor
   - Loaded from CSV data
   - Interpolated for missing values
   - Applied to total load

2. Current Calculation
   - Single phase: I = (kVA × 1000) / V
   - Three phase: I = (kVA × 1000) / (V × √3)
   - Includes diversity adjustments

3. Voltage Drop
   - Uses mV/A/m method
   - Includes temperature correction
   - Installation method factors
   - Material-specific adjustments
   - ADMD factor for neutrals (1.5×)

### CSV Data Format
```csv
size,mv_per_am,max_current
1.5,29,16
2.5,18,25
...etc
```

### Usage Example
```python
calculator = VoltageDropCalculator()
calculator.setTotalKVA(100)  # Set total load
calculator.setNumberOfHouses(20)  # Apply diversity
calculator.setLength(200)  # Set cable length
calculator.setADMDEnabled(True)  # Enable neutral calculations
```

## ResultsManager
Manages saved voltage drop calculation results with table view support.

### Features
- CSV-based storage and retrieval
- Table model for QML display
- Auto-formatting of results
- Persistence between sessions

### Properties
- `tableModel`: QAbstractTableModel for QML TableView
- Supports columns:
  - Date/Time
  - System Voltage
  - Load (kVA)
  - Houses
  - Cable Details
  - Length
  - Current
  - Voltage Drop
  - Drop Percentage

### Methods
```python
refresh_results()  # Reload from CSV
clear_all_results()  # Clear all saved data
removeResult(index)  # Remove single result
```

### Storage Format
```csv
timestamp,voltage_system,kva_per_house,num_houses,diversity_factor,
total_kva,current,cable_size,conductor,core_type,length,
voltage_drop,drop_percent,admd_enabled
```
