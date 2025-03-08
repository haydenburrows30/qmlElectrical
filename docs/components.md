# Application Components Documentation

## Overview
The application consists of multiple QML components and Python backend models organized into a modular structure.

## Core Components

### User Interface Components
- `WaveCard` - Base container component with title and optional info icon
- `WaveControls` - Controls for three-phase wave parameters
- `WaveChart` - Real-time waveform visualization
- `PhaseTable` - Displays three-phase measurements
- `PowerTriangle` - Power triangle visualization
- `PhasorDiagram` - Interactive phasor diagram
- `SavedResults` - Display saved calculation results

### Pages
- `Home` - Main navigation dashboard
- `VoltageDrop` - LV voltage drop calculator
- `VoltageDropMV` - MV voltage drop calculator  
- `Calculator` - General electrical calculations
- `ThreePhase` - Three-phase wave simulator
- `Phasor` - RLC and phasor analysis
- `RealTime` - Real-time data visualization

## Application Structure
```
qmltest/
├── qml/
│   ├── pages/           # Main page components
│   └── components/      # Reusable UI components
├── models/             # Python backend models
│   ├── calculator/     # Calculation modules
│   └── visualization/  # Data visualization 
└── docs/              # Documentation
```

## Common Operations

### Component Integration
1. Create component QML file in components/
2. Add component to qmldir module
3. Import in pages using:
```qml
import components 1.0
```

### Data Exchange
Models expose properties to QML:
```python
@Property(float, notify=dataChanged)
def value(self):
    return self._value
```

### Page Navigation
```qml
stackView.push("pages/NewPage.qml")
```

## Best Practices

1. Use WaveCard for consistent container styling
2. Follow naming conventions:
   - Components: PascalCase
   - Properties: camelCase
   - IDs: camelCase
   
3. Error Handling
   - Validate user input
   - Provide feedback through tooltips
   - Handle edge cases gracefully

4. Performance
   - Use clip: true on scrollable areas
   - Avoid binding loops
   - Batch updates when possible

## Testing
### Component Testing
```qml
import QtTest 1.0
TestCase {
    name: "ComponentTests"
    
    WaveCard {
        id: testCard
    }
    
    function test_example() {
        compare(testCard.title, "")
        testCard.title = "Test"
        compare(testCard.title, "Test")
    }
}
```

### Integration Testing
- Use QtTest for QML component testing
- Implement Python unit tests for backend logic
- Test data flow between QML and Python

## Component Details

### WaveCard
- Properties:
  - title: string
  - showInfo: bool
  - info: string
  - Layout properties

### WaveControls  
- Features:
  - Frequency control
  - Amplitude adjustment
  - Phase angle settings
  - Auto-scale option

### Signals & Slots
Example connection:
```qml
WaveControls {
    onValueChanged: waveChart.updateDisplay()
}
```

## Error Handling
1. Input Validation
```qml
TextField {
    validator: DoubleValidator {
        bottom: 0.0
        top: 1000.0
        decimals: 2
    }
}
```

2. Error Messages
```qml
ToolTip {
    visible: parent.error
    text: parent.errorMessage
}
```
