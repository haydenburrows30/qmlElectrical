import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts

import "../../"
import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"

ColumnLayout {
    id: control
    property string phase: "A"
    property color phaseColor: phase === "A" ? "#f44336" : phase === "B" ? "#4caf50" : "#2196f3"
    property real defaultAngle: 0
    property real defaultAmplitude: 230
    property real defaultAngle1: 30
    property real defaultAmplitude1: 100
    property int minWidth: 110
    property var calculator
    
    signal amplitudeChanged(real value)
    signal amplitudeChanged1(real value)
    signal angleChanged(real value)
    signal angleChanged1(real value)

    function resetPhase() {
        if (phase === "A") {
            calculator.setAmplitudeA(325.27)  // 230V RMS
            calculator.setPhaseAngleA(0)
            calculator.setCurrentA(100)
            calculator.setCurrentAngleA(0)
        } else if (phase === "B") {
            calculator.setAmplitudeB(325.27)
            calculator.setPhaseAngleB(-120)
            calculator.setCurrentB(100)
            calculator.setCurrentAngleB(-120)
        } else {
            calculator.setAmplitudeC(325.27)
            calculator.setPhaseAngleC(120)
            calculator.setCurrentC(100)
            calculator.setCurrentAngleC(120)
        }
    }

    Connections {
        target: calculator
        function onDataChanged() {
            if (phase === "A") {
                amplitudeSpinBox.value = calculator.rmsA
                angleSpinBox.value = calculator.phaseAngleA
                amplitudeSpinBox1.value = calculator.currentA
                angleSpinBox1.value = calculator.currentAngleA
            } else if (phase === "B") {
                amplitudeSpinBox.value = calculator.rmsB
                angleSpinBox.value = calculator.phaseAngleB
                amplitudeSpinBox1.value = calculator.currentB
                angleSpinBox1.value = calculator.currentAngleB
            } else {
                amplitudeSpinBox.value = calculator.rmsC
                angleSpinBox.value = calculator.phaseAngleC
                amplitudeSpinBox1.value = calculator.currentC
                angleSpinBox1.value = calculator.currentAngleC
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
            
            SpinBoxRound {
                id: amplitudeSpinBox
                Layout.minimumWidth: minWidth
                from: 0
                to: 1000
                value: phase === "A" ? calculator.rmsA : phase === "B" ? calculator.rmsB : phase === "C" ? calculator.rmsC : defaultAmplitude
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
            
            SpinBoxRound {
                id: angleSpinBox
                Layout.minimumWidth: minWidth
                from: -360
                to: 360
                value: phase === "A" ? calculator.phaseAngleA : phase === "B" ? calculator.phaseAngleB : phase === "C" ? calculator.phaseAngleC : defaultAngle
                editable: true
                stepSize: 1

                property int decimals: 1

                onValueChanged: function() {
                    if (phase === "A") {
                        calculator.setPhaseAngleA(angleSpinBox.value)
                    } else if (phase === "B") {
                        calculator.setPhaseAngleB(angleSpinBox.value)
                    } else if (phase === "C") {
                        calculator.setPhaseAngleC(angleSpinBox.value)
                    }
                }
            }
        }
        ColumnLayout {
            Label { 
                text: "Magnitude" 
                Layout.minimumWidth: minWidth
            }
            
            SpinBoxRound {
                id: amplitudeSpinBox1
                Layout.minimumWidth: minWidth
                from: 0
                to: 1000
                value: phase === "A" ? calculator.currentA : 
                       phase === "B" ? calculator.currentB : 
                       phase === "C" ? calculator.currentC : defaultAmplitude1
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
            
            SpinBoxRound {
                id: angleSpinBox1
                Layout.minimumWidth: minWidth
                from: -360
                to: 360
                value: phase === "A" ? calculator.currentAngleA : phase === "B" ? calculator.currentAngleB : phase === "C" ? calculator.currentAngleC : defaultAngle1
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
        Layout.topMargin: 10
        Layout.bottomMargin: 10
        height: 2
        color: phaseColor
        opacity: 0.3
    }
}
