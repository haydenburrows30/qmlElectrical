import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal // Add missing import for Slider and CheckBox

import "../buttons"
import "../style"

ColumnLayout {
    anchors.fill: parent
    
    PhaseVector {
        id: phaseVector
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
    
    // Controls for Phasor Diagram
    GridLayout {
        Layout.fillWidth: true
        columns: 4
        
        columnSpacing: 20
        
        Text { 
            text: "Frequency (Hz):" 
        }
        Slider {
            id: freqSlider
            from: 10
            to: 100
            value: 50
            onValueChanged: phaseVector.frequency = value
        }
        Text {
            text: freqSlider.value.toFixed(1)
        }
        StyledButton {
            text: phaseVector.isAnimating ? "Stop Animation" : "Start Animation"
            onClicked: phaseVector.isAnimating = !phaseVector.isAnimating
        }
        
        Text { 
            text: "Circuit Type:" 
        }
        ComboBoxRound {
            model: ["Series", "Parallel"]
            onCurrentIndexChanged: phaseVector.circuitType = currentIndex
        }
        
        CheckBox {
            text: "Show Components"
            checked: true
            onCheckedChanged: phaseVector.showComponents = checked
            Layout.columnSpan: 2
        }
    }
}