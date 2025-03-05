import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

import "../components"

ColumnLayout {
    id: control
    property string phase: "A"
    property color phaseColor: phase === "A" ? "#f44336" : phase === "B" ? "#4caf50" : "#2196f3"
    property real defaultAngle: 0
    property real defaultAmplitude: 230
    
    signal amplitudeChanged(real value)
    signal angleChanged(real value)

    function resetPhase() {
        amplitudeSpinBox.value = defaultAmplitude
        angleSpinBox.value = defaultAngle
    }

    spacing: 16

    Label {
        text: "Phase " + phase
        font.pixelSize: 16
        font.weight: Font.Medium
        color: phaseColor
    }

    ColumnLayout {
        spacing: 8

        RowLayout {
            spacing: 12
            Label { 
                text: "Amplitude"
                Layout.preferredWidth: 80
            }
            
            SpinBox {
                id: amplitudeSpinBox
                Layout.fillWidth: true
                from: 0
                to: 1000
                value: defaultAmplitude
                editable: true
                stepSize: 1
                
                onValueModified: {
                    amplitudeChanged(value * Math.SQRT2)
                }
            }

            // Label {
            //     text: (amplitudeSpinBox.value * Math.SQRT2).toFixed(0) + " V(peak)"
            //     Layout.preferredWidth: 120
            //     horizontalAlignment: Text.AlignRight
            // }
        }

        RowLayout {
            spacing: 12
            Label { 
                text: "Angle" 
                Layout.preferredWidth: 80
            }
            
            SpinBox {
                id: angleSpinBox
                Layout.fillWidth: true
                from: -360
                to: 360
                value: defaultAngle
                editable: true
                stepSize: 1
                
                onValueModified: {
                    angleChanged(value)
                }
            }

            // Label {
            //     text: angleSpinBox.value + "°"
            //     Layout.preferredWidth: 60
            //     horizontalAlignment: Text.AlignRight
            // }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 2
        color: phaseColor
        opacity: 0.3
    }
}
