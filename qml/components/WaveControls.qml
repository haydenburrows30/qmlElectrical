import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    property var model
    
    GroupBox {
        title: "Wave Controls"
        Layout.fillWidth: true
        
        GridLayout {
            columns: 4
            rowSpacing: 10
            columnSpacing: 10
            
            Label { text: "Frequency (Hz)" }
            SpinBox {
                value: 50
                from: 1
                to: 400
                onValueChanged: model.setFrequency(value)
            }
            
            Label { text: "Amplitude A (V)" }
            SpinBox {
                value: 230
                from: 0
                to: 1000
                onValueChanged: model.setAmplitudeA(value * Math.SQRT2)
            }
            
            Label { text: "Phase A (°)" }
            SpinBox {
                value: 0
                from: -360
                to: 360
                onValueChanged: model.setPhaseAngleA(value)
            }
            
            // Similar controls for phases B and C
            Label { text: "Amplitude B (V)" }
            SpinBox {
                value: 230
                from: 0
                to: 1000
                onValueChanged: model.setAmplitudeB(value * Math.SQRT2)
            }
            
            Label { text: "Phase B (°)" }
            SpinBox {
                value: 120
                from: -360
                to: 360
                onValueChanged: model.setPhaseAngleB(value)
            }
            
            Label { text: "Amplitude C (V)" }
            SpinBox {
                value: 230
                from: 0
                to: 1000
                onValueChanged: model.setAmplitudeC(value * Math.SQRT2)
            }
            
            Label { text: "Phase C (°)" }
            SpinBox {
                value: 240
                from: -360
                to: 360
                onValueChanged: model.setPhaseAngleC(value)
            }
        }
    }
}
