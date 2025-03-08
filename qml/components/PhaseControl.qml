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
    property real defaultAngle1: 30
    property real defaultAmplitude1: 100
    property int minWidth: 110
    
    signal amplitudeChanged(real value)
    signal amplitudeChanged1(real value)
    signal angleChanged(real value)
    signal angleChanged1(real value)

    function resetPhase() {
        amplitudeSpinBox.value = defaultAmplitude
        angleSpinBox.value = defaultAngle
        amplitudeSpinBox1.value = defaultAmplitude1
        angleSpinBox1.value = defaultAngle1
    }

    spacing: 8

    Label {
        text: "Phase " + phase
        font.pixelSize: 16
        font.weight: Font.Medium
        color: phaseColor
    }

    RowLayout {
        spacing: 8

        ColumnLayout {
            spacing: 12
            Label { 
                text: "Amplitude"
                Layout.minimumWidth: minWidth
            }
            
            SpinBox {
                id: amplitudeSpinBox
                Layout.minimumWidth: minWidth
                from: 0
                to: 1000
                value: phase === "A" ? sineModel.rmsA : phase === "B" ? sineModel.rmsB : phase === "C" ? sineModel.rmsC : defaultAmplitude
                editable: true
                stepSize: 1
                
                onValueModified: {
                    amplitudeChanged(value * Math.SQRT2)
                }
            }
        }
        ColumnLayout {
            spacing: 12
            Label { 
                text: "Angle" 
                Layout.minimumWidth: minWidth
            }
            
            SpinBox {
                id: angleSpinBox
                // Layout.fillWidth: true
                Layout.minimumWidth: minWidth
                from: -360
                to: 360
                value: phase === "A" ? sineModel.phaseAngleA : phase === "B" ? sineModel.phaseAngleB : phase === "C" ? sineModel.phaseAngleC : defaultAngle
                editable: true
                stepSize: 1

                property int decimals: 1

                onValueChanged: function() {
                    if (phase === "A") {
                        sineModel.setPhaseAngleA(angleSpinBox.value)
                    } else if (phase === "B") {
                        sineModel.setPhaseAngleB(angleSpinBox.value)
                    } else if (phase === "C") {
                        sineModel.setPhaseAngleC(angleSpinBox.value)
                    }
                }
            }
        }
        ColumnLayout {
            spacing: 12
            Label { 
                text: "Magnitude" 
                Layout.minimumWidth: minWidth
            }
            
            SpinBox {
                id: amplitudeSpinBox1
                Layout.minimumWidth: minWidth
                from: 0
                to: 1000
                value: phase === "A" ? sineModel.currentA : phase === "B" ? sineModel.currentB : phase === "C" ? sineModel.currentC : defaultAmplitude1
                editable: true
                stepSize: 1
                
                onValueModified: {
                    amplitudeChanged1(value * Math.SQRT2)
                }
            }
        }
        ColumnLayout {
            spacing: 12
            Label { 
                text: "Angle" 
                Layout.minimumWidth: minWidth
            }
            
            SpinBox {
                id: angleSpinBox1
                // Layout.fillWidth: true
                Layout.minimumWidth: minWidth
                from: -360
                to: 360
                value: phase === "A" ? sineModel.currentAngleA : phase === "B" ? sineModel.currentAngleB : phase === "C" ? sineModel.currentAngleC : defaultAngle1
                editable: true
                stepSize: 1
                
                onValueModified: {
                    angleChanged1(value)
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 2
        color: phaseColor
        opacity: 0.3
    }
}
