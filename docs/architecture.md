# Application Architecture

## Overview
The application uses a modular architecture with QML for UI and Python for backend calculations.

## Core Components

### UI Layer (QML)
- Pages: Main application views
- Components: Reusable UI elements
- Models: Data models exposed to QML

### Business Layer (Python)
- Calculators: Electrical calculations
- Models: Data management
- Services: Application services

## Directory Structure
```
/qmltest/
├── qml/
│   ├── pages/
│   │   ├── Home.qml
│   │   ├── VoltageDrop.qml
│   │   ├── Calculator.qml
│   │   ├── ThreePhase.qml
│   │   ├── RLC.qml
│   │   └── RealTime.qml
│   ├── components/
│   │   ├── WaveCard.qml
│   │   ├── WaveControls.qml
│   │   ├── WaveChart.qml
│   │   ├── PhaseTable.qml
│   │   ├── PowerTriangle.qml
│   │   ├── PhasorDiagram.qml
│   │   └── SavedResults.qml
│   └── main.qml
├── models/
│   ├── calculator/
│   │   ├── voltage_drop.py
│   │   └── three_phase.py
│   └── visualization/
│       └── wave_generator.py
└── resources/
    ├── icons/
    └── images/
```

## Key Features
- Three-phase visualization
- Voltage drop calculations
- Power calculations
- Real-time data display
- Dark/light theme support

## Data Flow
1. User input via QML
2. Data passed to Python models
3. Calculations performed
4. Results updated in UI
5. Optional persistence to storage

## Design Patterns
- MVVM architecture
- Factory pattern for calculators
- Observer pattern for updates
- Strategy pattern for calculations

## Future Considerations
- Component testing
- Performance optimization
- Additional calculators
- Mobile support

## Technical Details

### Dependencies
- Qt 6.2+
- Python 3.8+
- PySide6
- NumPy/SciPy for calculations

### Build System
```bash
cmake_minimum_required(VERSION 3.16)
project(QmlElectrical VERSION 1.0)
set(CMAKE_CXX_STANDARD 17)
```

### Performance Optimization
1. Data Models
- Use QAbstractListModel for large datasets
- Implement data pagination
- Lazy loading for complex calculations

2. Resource Management
- Bundle resources using Qt Resource System
- Implement image caching
- Optimize SVG assets

## Deployment

### Desktop
1. Build Requirements:
- Qt development tools
- Python development environment
- Build tools (CMake, ninja)

2. Distribution:
- Create standalone executable
- Bundle Python interpreter
- Include required DLLs/shared libraries

### Configuration
```ini
[Controls]
Style=Material

[Material]
Theme=Dark
Accent=Teal
Primary=BlueGrey
```

## Security Considerations
1. Input Sanitization
2. File Access Controls
3. Error Logging

## Monitoring
1. Performance Metrics
2. Error Tracking
3. Usage Analytics
