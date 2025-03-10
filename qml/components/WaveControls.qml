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

WaveCard {
    id: root
    title: "Wave Controls"
    showInfo: false
    property var model
    property var phaseControls: []
    
    signal requestAutoScale()  // Add new signal

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
                    if (!sineModel) return;
                    sineModel.setFrequency(freqSlider.value)
                }

                background: Rectangle {
                    x: parent.leftPadding
                    y: parent.topPadding + parent.availableHeight / 2 - height / 2
                    width: parent.availableWidth
                    height: 4
                    radius: 2
                    color: sideBar.toggle1 ? "#404040" : "#e0e0e0"

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
                color: sideBar.toggle1 ? "#b0b0b0" : "#606060"
            }

            Button {
                Layout.alignment: Qt.AlignRight
                icon.name: "Reset"
                
                onClicked: {
                    sineModel.reset()  // This will reset all values including power
                    freqSlider.value = 50
                    for (let control of phaseControls) {
                        control.resetPhase()
                    }
                    requestAutoScale()  // Emit signal when reset is clicked
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
                
                onAmplitudeChanged: function(value) {
                    if (phase === "A") sineModel.setAmplitudeA(value)
                    else if (phase === "B") sineModel.setAmplitudeB(value)
                    else sineModel.setAmplitudeC(value)
                }
                onAngleChanged: function(value) {
                    if (phase === "A") sineModel.setPhaseAngleA(value)
                    else if (phase === "B") sineModel.setPhaseAngleB(value)
                    else sineModel.setPhaseAngleC(value)
                }
                onAmplitudeChanged1: function(value) {
                    // Update to directly use the value without dividing by 10
                    if (phase === "A") sineModel.setCurrentA(value)
                    else if (phase === "B") sineModel.setCurrentB(value)
                    else sineModel.setCurrentC(value)
                }
                onAngleChanged1: function(value) {
                    if (phase === "A") sineModel.setCurrentAngleA(value)
                    else if (phase === "B") sineModel.setCurrentAngleB(value)
                    else sineModel.setCurrentAngleC(value)
                }
            }
        }
    }
}