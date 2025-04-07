import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts

import "../"
import "../buttons"

WaveCard {
    id: root
    title: "Wave Controls"
    property var model
    property var phaseControls: []
    property var calculator
    
    signal requestAutoScale()

    ColumnLayout {
        Label {
            text: "Frequency"
            font.pixelSize: 14
        }
        RowLayout {
            Slider {
                id: freqSlider
                Layout.fillWidth: true
                from: 1
                to: 100
                value: 50
                stepSize: 1
                onValueChanged: function() {
                    if (!calculator) return;
                    calculator.setFrequency(freqSlider.value)
                }

                background: Rectangle {
                    x: parent.leftPadding
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    width: parent.availableWidth
                    height: 4
                    radius: 2
                    color: window.modeToggled ? "#404040" : "#e0e0e0"

                    Rectangle {
                        width: parent.width * parent.visualPosition
                        height: parent.height
                        color: "#2196F3"
                        radius: 2
                    }
                }

                handle: Rectangle {
                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    width: 20
                    height: 20
                    radius: 10
                    color: parent.pressed ? "#1976D2" : "#2196F3"
                    border.color: "#1976D2"

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }
            }

            Label {
                text: freqSlider.value.toFixed(1) + " Hz"
                font.pixelSize: 12
                color: window.modeToggled ? "#b0b0b0" : "#606060"
            }

            StyledButton {
                Layout.alignment: Qt.AlignRight
                icon.source: "../../../icons/svg/restart_alt/baseline.svg"
                
                onClicked: {
                    calculator.reset()  
                    freqSlider.value = 50
                    for (let control of phaseControls) {
                        control.resetPhase()
                    }
                    requestAutoScale()
                }
            }
        }
        
        Repeater {
            id: phaseRepeater
            model: [
                {phase: "A", defaultAngle: 0},
                {phase: "B", defaultAngle: 120},
                {phase: "C", defaultAngle: 240}
            ]
            
            delegate: PhaseControl {
                Layout.columnSpan: 3
                phase: modelData.phase
                defaultAngle: modelData.defaultAngle
                defaultAmplitude: 230
                defaultAmplitude1: 100
                defaultAngle1: 30

                calculator: root.calculator //pass calculator to controls
                
                onAmplitudeChanged: function(value) {
                    if (phase === "A") calculator.setAmplitudeA(value)
                    else if (phase === "B") calculator.setAmplitudeB(value)
                    else calculator.setAmplitudeC(value)
                }
                onAngleChanged: function(value) {
                    if (phase === "A") calculator.setPhaseAngleA(value)
                    else if (phase === "B") calculator.setPhaseAngleB(value)
                    else calculator.setPhaseAngleC(value)
                }
                onAmplitudeChanged1: function(value) {
                    if (phase === "A") calculator.setCurrentA(value)
                    else if (phase === "B") calculator.setCurrentB(value)
                    else calculator.setCurrentC(value)
                }
                onAngleChanged1: function(value) {
                    if (phase === "A") calculator.setCurrentAngleA(value)
                    else if (phase === "B") calculator.setCurrentAngleB(value)
                    else calculator.setCurrentAngleC(value)
                }
            }
        }
    }
}