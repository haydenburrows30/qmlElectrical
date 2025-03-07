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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 15

        // Voltage Controls
        GroupBox {
            title: "Voltage"
            Layout.fillWidth: true

            GridLayout {
                columns: 4
                columnSpacing: 20
                rowSpacing: 10

                Label { text: "Phase" }
                Label { text: "Amplitude (V)" }
                Label { text: "Frequency (Hz)" }
                Label { text: "Phase Angle (°)" }

                Label { text: "A"; color: "#f44336" }
                SpinBox {
                    from: 0
                    to: 1000
                    value: model.amplitudeA
                    onValueModified: model.setAmplitudeA(value)
                }
                SpinBox {
                    from: 1
                    to: 400
                    value: model.frequency
                    onValueModified: model.setFrequency(value)
                }
                SpinBox {
                    from: -360
                    to: 360
                    value: model.phaseAngleA
                    onValueModified: model.setPhaseAngleA(value)
                }

                Label { text: "B"; color: "#4caf50" }
                SpinBox {
                    from: 0
                    to: 1000
                    value: model.amplitudeB
                    onValueModified: model.setAmplitudeB(value)
                }
                Rectangle { color: "transparent" }
                SpinBox {
                    from: -360
                    to: 360
                    value: model.phaseAngleB
                    onValueModified: model.setPhaseAngleB(value)
                }

                Label { text: "C"; color: "#2196f3" }
                SpinBox {
                    from: 0
                    to: 1000
                    value: model.amplitudeC
                    onValueModified: model.setAmplitudeC(value)
                }
                Rectangle { color: "transparent" }
                SpinBox {
                    from: -360
                    to: 360
                    value: model.phaseAngleC
                    onValueModified: model.setPhaseAngleC(value)
                }
            }
        }

        // Current Controls
        GroupBox {
            title: "Current"
            Layout.fillWidth: true

            GridLayout {
                columns: 3
                columnSpacing: 20
                rowSpacing: 10

                Label { text: "Phase" }
                Label { text: "Magnitude (A)" }
                Label { text: "Angle (°)" }

                Label { text: "A"; color: "#f44336" }
                SpinBox {
                    id: currentSpinA
                    from: 0
                    to: 1000
                    value: (model && model.currentA ? model.currentA * 10 : 10)
                    stepSize: 1
                    editable: true
                    onValueModified: if (model) model.setCurrentA(value / 10)
                    
                    property int decimals: 1
                    validator: DoubleValidator {
                        bottom: Math.min(currentSpinA.from, currentSpinA.to)
                        top: Math.max(currentSpinA.from, currentSpinA.to)
                    }
                    textFromValue: function(value, locale) {
                        return Number(value / 10).toLocaleString(locale, 'f', decimals)
                    }
                    valueFromText: function(text, locale) {
                        return Number.fromLocaleString(locale, text) * 10
                    }
                }
                SpinBox {
                    from: -90
                    to: 90
                    value: model.currentAngleA
                    editable: true
                    onValueModified: model.setCurrentAngleA(value)
                }

                Label { text: "B"; color: "#4caf50" }
                SpinBox {
                    id: currentSpinB
                    from: 0
                    to: 1000
                    value: (model && model.currentB ? model.currentB * 10 : 10)
                    stepSize: 1
                    editable: true
                    onValueModified: if (model) model.setCurrentB(value / 10)
                    property int decimals: 1
                    validator: DoubleValidator {
                        bottom: Math.min(currentSpinB.from, currentSpinB.to)
                        top: Math.max(currentSpinB.from, currentSpinB.to)
                    }
                    textFromValue: function(value, locale) {
                        return Number(value / 10).toLocaleString(locale, 'f', decimals)
                    }
                    valueFromText: function(text, locale) {
                        return Number.fromLocaleString(locale, text) * 10
                    }
                }
                SpinBox {
                    from: -90
                    to: 90
                    value: model.currentAngleB
                    editable: true
                    onValueModified: model.setCurrentAngleB(value)
                }

                Label { text: "C"; color: "#2196f3" }
                SpinBox {
                    id: currentSpinC
                    from: 0
                    to: 1000
                    value: (model && model.currentC ? model.currentC * 10 : 10)
                    stepSize: 1
                    editable: true
                    onValueModified: if (model) model.setCurrentC(value / 10)
                    property int decimals: 1
                    validator: DoubleValidator {
                        bottom: Math.min(currentSpinC.from, currentSpinC.to)
                        top: Math.max(currentSpinC.from, currentSpinC.to)
                    }
                    textFromValue: function(value, locale) {
                        return Number(value / 10).toLocaleString(locale, 'f', decimals)
                    }
                    valueFromText: function(text, locale) {
                        return Number.fromLocaleString(locale, text) * 10
                    }
                }
                SpinBox {
                    from: -90
                    to: 90
                    value: model.currentAngleC
                    editable: true
                    onValueModified: model.setCurrentAngleC(value)
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
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
}
