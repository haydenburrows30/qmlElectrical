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
    property var model
    title: "Wave Controls"
    showInfo: false

    GridLayout {
        anchors.fill: parent
        anchors.margins: 10
        columns: 3
        rowSpacing: 10
        columnSpacing: 10

        ColumnLayout {
            Layout.columnSpan: 3
            spacing: 8

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
                        if (!model) return;
                        model.setFrequency(freqSlider.value)
                    }

                    background: Rectangle {
                        x: parent.leftPadding
                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        width: parent.availableWidth
                        height: 4
                        radius: 2
                        color: toolBar.toggle ? "#404040" : "#e0e0e0"

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
                    color: toolBar.toggle ? "#b0b0b0" : "#606060"
                }

                Button {
                    Layout.alignment: Qt.AlignRight
                    icon.name: "Reset"
                    
                    onClicked: {
                        model.reset()
                        freqSlider.value = 50
                        phaseRepeater.itemAt(0).resetPhase()
                        phaseRepeater.itemAt(1).resetPhase()
                        phaseRepeater.itemAt(2).resetPhase()
                    }
                }
            }
        }

        // Phase Controls
        Repeater {
            id: phaseRepeater
            model: [
                {phase: "A", defaultAngle: 0},
                {phase: "B", defaultAngle: 120},
                {phase: "C", defaultAngle: 240}
            ]
            
            delegate: PhaseControl {
                Layout.columnSpan: 1
                phase: modelData.phase
                defaultAngle: modelData.defaultAngle
                defaultAmplitude: 230
                
                onAmplitudeChanged: function(value) {
                    if (phase === "A") root.model.setAmplitudeA(value)
                    else if (phase === "B") root.model.setAmplitudeB(value)
                    else root.model.setAmplitudeC(value)
                }
                onAngleChanged: function(value) {
                    if (phase === "A") root.model.setPhaseAngleA(value)
                    else if (phase === "B") root.model.setPhaseAngleB(value)
                    else root.model.setPhaseAngleC(value)
                }
            }
        }
    }
}
