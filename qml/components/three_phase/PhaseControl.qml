import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts

import "../"

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
        if (phase === "A") {
            sineModel.setAmplitudeA(325.27)  // 230V RMS
            sineModel.setPhaseAngleA(0)
            sineModel.setCurrentA(100)
            sineModel.setCurrentAngleA(0)
        } else if (phase === "B") {
            sineModel.setAmplitudeB(325.27)
            sineModel.setPhaseAngleB(-120)
            sineModel.setCurrentB(100)
            sineModel.setCurrentAngleB(-120)
        } else {
            sineModel.setAmplitudeC(325.27)
            sineModel.setPhaseAngleC(120)
            sineModel.setCurrentC(100)
            sineModel.setCurrentAngleC(120)
        }
    }

    Connections {
        target: sineModel
        function onDataChanged() {
            if (phase === "A") {
                amplitudeSpinBox.value = sineModel.rmsA
                angleSpinBox.value = sineModel.phaseAngleA
                amplitudeSpinBox1.value = sineModel.currentA
                angleSpinBox1.value = sineModel.currentAngleA
            } else if (phase === "B") {
                amplitudeSpinBox.value = sineModel.rmsB
                angleSpinBox.value = sineModel.phaseAngleB
                amplitudeSpinBox1.value = sineModel.currentB
                angleSpinBox1.value = sineModel.currentAngleB
            } else {
                amplitudeSpinBox.value = sineModel.rmsC
                angleSpinBox.value = sineModel.phaseAngleC
                amplitudeSpinBox1.value = sineModel.currentC
                angleSpinBox1.value = sineModel.currentAngleC
            }
        }
    }

    Label {
        text: "Phase " + phase
        font.pixelSize: 16
        font.weight: Font.Medium
        color: phaseColor
    }

    RowLayout {

        ColumnLayout {
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
            Label { 
                text: "Angle" 
                Layout.minimumWidth: minWidth
            }
            
            SpinBox {
                id: angleSpinBox
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
            Label { 
                text: "Magnitude" 
                Layout.minimumWidth: minWidth
            }
            
            SpinBox {
                id: amplitudeSpinBox1
                Layout.minimumWidth: minWidth
                from: 0
                to: 1000
                value: phase === "A" ? sineModel.currentA : 
                       phase === "B" ? sineModel.currentB : 
                       phase === "C" ? sineModel.currentC : defaultAmplitude1
                editable: true
                stepSize: 1
                
                onValueModified: {
                    amplitudeChanged1(value)
                }

                textFromValue: function(value, locale) {
                    return Number(value).toLocaleString(locale, 'f', 1)
                }

                valueFromText: function(text, locale) {
                    return Number.fromLocaleString(locale, text)
                }
            }
        }
        ColumnLayout {
            Label { 
                text: "Angle" 
                Layout.minimumWidth: minWidth
            }
            
            SpinBox {
                id: angleSpinBox1
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
