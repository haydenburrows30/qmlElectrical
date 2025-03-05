# Application Architecture

## Overview
The application follows a clean architecture pattern with dependency injection, factory patterns, and clear separation of concerns.

## Core Components

### Dependency Injection
- Container-based DI system
- Services are registered and resolved at runtime
- Supports singleton and transient lifecycles

### Service Interfaces
- `ICalculatorFactory`: Creates calculator instances
- `IModelFactory`: Creates model instansces
- `IQmlEngine`: Handles QML engine operations
- `ILogger`: Manages application logging

### Factories
- Calculator Factory: Manages calculator instantiation
- Model Factory: Creates and manages model instances

### Models
- ThreePhaseSineWaveModel: Generates three-phase waveforms
- Various calculators (Power, Fault Current, Charging)

## QML Components

### Three Phase Visualization
- WaveControls: User input for wave parameters
- WaveChart: Real-time waveform display
- Measurements: Shows calculated values

## Directory Structure
```
/qmltest/
├── docs/
├── models/
│   ├── calculators/
│   │   ├── BaseCalculator.py
│   │   └── CalculatorFactory.py
│   ├── Calculator.py
│   └── ThreePhase.py
├── qml/
│   ├── components/
│   │   ├── WaveControls.qml
│   │   ├── WaveChart.qml
│   │   └── Measurements.qml
│   └── ThreePhase.qml
└── services/
    ├── interfaces.py
    ├── implementations.py
    └── container.py
```
