# QML Components API Documentation

## WaveControls
Component for controlling three-phase waveform parameters.

### Properties
- `model: ThreePhaseSineWaveModel` - Model instance for wave control

### Methods
None (purely declarative component)

### Example Usage
```qml
WaveControls {
    model: sineModel
    Layout.fillWidth: true
}
```

## WaveChart
Real-time visualization of three-phase waveforms.

### Properties
- `model: ThreePhaseSineWaveModel` - Data model for waveforms
- `title: string` - Chart title
- `antialiasing: bool` - Enable/disable antialiasing
- `legend.visible: bool` - Show/hide legend

### Example Usage
```qml
WaveChart {
    model: sineModel
    Layout.fillWidth: true
    Layout.fillHeight: true
}
```

### Customization
```qml
WaveChart {
    model: sineModel
    ValueAxis {
        id: axisY
        min: -400
        max: 400
        titleText: "Custom Y Axis"
    }
}
```

## Measurements
Display component for electrical measurements.

### Properties
- `model: ThreePhaseSineWaveModel` - Model containing measurement data

### Available Measurements
- RMS Values (Phase A, B, C)
- Peak Values (Phase A, B, C)
- Line-to-Line RMS (A-B, B-C, C-A)

### Example Usage
```qml
Measurements {
    model: sineModel
    Layout.fillWidth: true
}
```

## Custom Controls

### FrequencySlider
Slider for frequency adjustment.

```qml
Slider {
    from: 1
    to: 400
    value: 50
    onValueChanged: model.setFrequency(value)
}
```

### AmplitudeControl
Control for voltage amplitude.

```qml
SpinBox {
    from: 0
    to: 1000
    value: 230
    onValueChanged: model.setAmplitudeA(value * Math.SQRT2)
}
```

### PhaseAngleAdjuster
Control for phase angle adjustment.

```qml
SpinBox {
    from: -360
    to: 360
    onValueChanged: model.setPhaseAngleA(value)
}
```

## Voltage Drop Calculator

### Properties
- `model: VoltageDrop` - Voltage drop calculator model

### Input Controls
```qml
// System Configuration
ComboBox {
    model: voltageDrop.voltageOptions  // ["230V", "415V"]
}

CheckBox {
    text: "ADMD (neutral)"
    enabled: voltage === "415V"
    onCheckedChanged: voltageDrop.setADMDEnabled(checked)
}

// Load Configuration
TextField {
    placeholderText: "Enter kVA"
    onTextChanged: {
        let kva = parseFloat(text) || 0
        voltageDrop.calculateTotalLoad(kva, houses)
    }
}

TextField {
    placeholderText: "Number of houses"
    onTextChanged: {
        let houses = parseInt(text) || 1
        voltageDrop.setNumberOfHouses(houses)
    }
}
```

### Results Display
```qml
Label {
    text: "Total Adjusted Load: " + 
          (kvaPerHouse * houses * 
           voltageDrop.diversityFactor).toFixed(1) + " kVA"
}

Text {
    text: Number(voltageDrop.current).toFixed(1) + " A"
}

Label {
    text: "Voltage Drop: " + 
          voltageDrop.voltageDrop.toFixed(2) + " V"
}
```

### Best Practices
- Use number validation for inputs
- Handle voltage system changes
- Update calculations on diversity changes
- Monitor cable current ratings
- Check voltage drop limits

## SavedResults
Component for displaying voltage drop calculation history.

### Properties
- `resultsManager: ResultsManager` - Required property for results management

### Methods
None (uses ResultsManager methods)

### Example Usage
```qml
SavedResults {
    resultsManager: resultsManager
    Layout.fillWidth: true
    Layout.minimumHeight: 300
}

// Clear all results with confirmation
Dialog {
    title: "Clear All Results"
    standardButtons: Dialog.Yes | Dialog.No
    
    onAccepted: {
        resultsManager.clear_all_results()
        resultsManager.refresh_results()
    }
}
```

## Layout Guidelines

### Grid Layout
```qml
GridLayout {
    columns: 4
    rowSpacing: 10
    columnSpacing: 10
    
    // Controls
    Label { text: "Frequency (Hz)" }
    FrequencySlider { /* ... */ }
    
    Label { text: "Amplitude (V)" }
    AmplitudeControl { /* ... */ }
}
```

### Column Layout
```qml
ColumnLayout {
    spacing: 10
    
    WaveControls { /* ... */ }
    WaveChart { /* ... */ }
    Measurements { /* ... */ }
}
```

## Best Practices

### Performance
- Use `Layout.fillWidth: true` for responsive design
- Enable antialiasing only when needed
- Use proper anchoring for stable layouts

### Error Handling
```qml
ErrorBoundary {
    anchors.fill: parent
    
    WaveChart {
        model: sineModel
        onError: parent.catchError(error)
    }
}
```

### Responsive Design
```qml
WaveChart {
    Layout.preferredHeight: Math.min(parent.width * 0.6, 400)
    Layout.maximumHeight: 600
}
```

## Model Integration

### Connecting Signals
```qml
Connections {
    target: model
    function onDataChanged() {
        // Handle data updates
    }
}
```

### Property Binding
```qml
Label {
    text: "RMS Value: " + model.rmsA.toFixed(1) + " V"
    color: model.rmsA > 230 ? "red" : "black"
}
```

## Styling

### Theme Support
```qml
WaveChart {
    theme: ChartView.ChartThemeDark
    backgroundColor: "#1e1e1e"
}
```

### Custom Colors
```qml
LineSeries {
    name: "Phase A"
    color: "#FF0000"
    width: 2
}
```

## Data Flow
1. User interaction → Controls
2. Controls → Model updates
3. Model → Signal emission
4. Signal → Chart/Display updates

## Common Patterns

### Model Updates
```qml
Button {
    text: "Reset"
    onClicked: {
        model.reset()
        // Additional UI updates if needed
    }
}
```

### Dynamic Updates
```qml
Timer {
    interval: 16 // ~60 FPS
    running: true
    repeat: true
    onTriggered: {
        // Periodic updates
    }
}
```
