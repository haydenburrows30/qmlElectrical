# Component Reference

## Core System Components

### Calculators
- **Base Calculator**
  - Abstract calculator interface
  - Common calculation methods
  - Event system
  - Result validation

- **Power System Calculators**
  - Voltage drop analysis
  - Fault calculations  
  - Protection coordination
  - Power factor correction

- **Equipment Calculators**
  - Motor starting analysis
  - Transformer sizing
  - Battery systems
  - Cable ampacity

### Infrastructure
- **Worker Pool**: Multi-threaded calculation engine
- **Loading Manager**: Async resource loading
- **Results Manager**: Calculation history and export
- **Model Factory**: Component instantiation

## UI Components

### Export Components
- **ExportFileDialog**: Generic file export dialog
  - Supports multiple export formats (PDF, CSV, PNG)
  - Scale options for image exports
  - Default directory handling
  - File type filtering

- **ExportFormatMenu**: Context menu for export options
  - CSV export for tables
  - PDF export for detailed reports
  - PNG export for charts
  - Configurable export handlers

### Visualization Components
- **CableAmpacityViz**: Cable ampacity visualization
  - Cross-section view 
  - Installation method representation
  - Temperature and grouping effects
  - Theme-aware rendering

- **PowerTransformerViz**: Transformer visualization
  - Power flow representation
  - Efficiency indication
  - Temperature monitoring
  - Rating indicators

- **EarthingViz**: Earthing system visualization
  - Grid layout representation
  - Rod placement visualization
  - Soil layers indication
  - Dimension annotations

### Calculator Components
- **TransmissionLineCalculator**: Advanced transmission line calculations
  - ABCD parameters
  - Line constants
  - Surge impedance loading
  - Visual results

- **BatteryCalculator**: Battery sizing tool
  - Load-based calculations
  - Temperature effects
  - Charging profiles
  - Visual state indication

- **MotorStartingCalculator**: Motor analysis
  - Starting current profiles
  - Temperature rise
  - Visual torque curves
  - Method comparisons

### UI Components
- **VoltageDropDetails**: Detailed calculation view
  - Complete system parameters
  - Visual results indicators
  - Theme-aware styling
  - PDF export capability

- **ComparisonTable**: Cable comparison grid
  - Color-coded status cells
  - Export functionality
  - Sortable columns
  - Context menu actions

## Theme Integration
All components support light/dark themes via:
- Universal.foreground/background colors
- Theme-aware visualization
- Consistent contrast ratios
- Automatic adaptation

## Installation & Setup
- Package dependencies
- Build requirements 
- Configuration options
- Extension points

## Development
- Component creation guide
- Calculator integration
- Theme customization
- Testing guidelines
