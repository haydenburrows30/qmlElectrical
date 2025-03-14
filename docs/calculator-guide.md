# Calculator Guide

## Implementation Overview
```python
class BaseCalculator:
    def __init__(self):
        self._results = {}
        self._validation_rules = {}
        self._error_handlers = {}
        
    async def calculate(self, params):
        if self.validate(params):
            return await self._run_calculation(params)
        return None
```

## Calculator Architecture
- Async calculation pipeline
- Built-in validation
- Error handling
- Progress tracking
- Result caching

## Available Calculators

### Power System Analysis
1. **Transmission Line Calculator**
   - Line parameters (R, L, C)
   - ABCD parameters
   - SIL calculations
   - Visual line profiles

2. **Protection Relay Calculator**
   - Trip curve plotting
   - Multiple curve types
   - Discrimination analysis
   - Visual coordination

3. **Voltage Drop Calculator**
   - Cable selection
   - Load diversity
   - ADMD calculations
   - Visual results

### Equipment Sizing
1. **Battery Calculator**
   - Implementation: BatteryCalculator
   - Methods:
     ```python
     def size_battery(self, load_kw, duration_hrs)
     def calculate_temperature_effect(self, capacity, temp)
     def estimate_lifecycle(self, cycles, depth)
     ```
   - Usage examples
   - Common configurations

2. **Motor Starting Calculator**
   - Implementation: MotorStartingCalculator  
   - Methods:
     ```python
     def calculate_starting_current(self, method, power)
     def analyze_voltage_drop(self, cable_length, size)
     def estimate_temperature_rise(self, duration)
     ```
   - Starting method comparisons
   - Protection coordination

3. **Transformer Calculator**
   - Rating calculations
   - Efficiency analysis
   - Temperature rise
   - Visual power flow

### Installation Design
1. **Cable Ampacity Calculator**
   - Installation methods
   - Temperature correction
   - Grouping factors
   - Visual cross-sections

2. **Earthing Calculator**
   - Grid resistance
   - Touch/step voltage
   - Visual grid layout
   - Soil effects

3. **Power Factor Correction**
   - Capacitor sizing
   - Resonance check
   - Visual power triangle
   - Economic analysis

## Common Features
- Dark/light theme support
- Export functionality
- Real-time calculations
- Visual feedback
- Detailed results

## Integration Guide

### Creating Custom Calculators
```python
class CustomCalculator(BaseCalculator):
    def __init__(self):
        super().__init__()
        self.register_validation("voltage", self._validate_voltage)
        
    def _validate_voltage(self, value):
        return 0 < value < 1000000
        
    async def _run_calculation(self, params):
        # Custom calculation logic
        return results
```

### Calculator Registration
```python
# In calculator factory
def register_calculator(self, name, calculator_class):
    self._calculators[name] = calculator_class
```

## Best Practices
- Input validation implementation
- Error handling patterns
- Async calculation methods
- Progress reporting
- Result caching strategies

## Testing Approach
- Unit test structure
- Integration testing
- Performance testing
- Edge case handling

## Performance Optimization
- Caching strategies
- Batch calculations
- Memory management
- Thread utilization
