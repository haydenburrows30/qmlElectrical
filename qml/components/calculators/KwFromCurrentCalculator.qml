import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import KwFromCurrent 1.0

Item {
    id: kw_calculator
    
    // You'll need to register this calculator type in your main.py or similar
    property KwFromCurrentCalculator calculator: KwFromCurrentCalculator {}

    TextEdit {
        id: clipboardHelper
        visible: false
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10
        anchors.margins: 10

        WaveCard {
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumHeight: 300
            Layout.minimumWidth: 400
            title: "Power from Current Calculator"
         
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 15
                Layout.maximumWidth: 300

                Text {
                    text: "Single Phase: 230V | Three Phase: 415V"
                    font.italic: true
                    color: "gray"
                    Layout.alignment: Qt.AlignHCenter
                }

                RowLayout {
                    spacing: 10
                    Label {
                        text: "Phase Type:"
                        Layout.preferredWidth: 100
                    }
                    ComboBox {
                        id: phaseSelector
                        model: ["Single Phase", "Three Phase"]
                        Layout.fillWidth: true
                        onCurrentTextChanged: {
                            if (calculator) {
                                calculator.setPhase(currentText)
                            }
                        }
                        currentIndex: 1
                        Layout.alignment: Qt.AlignRight
                    }
                }

                RowLayout {
                    spacing: 10
                    Label {
                        text: "Current (A):"
                        Layout.preferredWidth: 100
                    }
                    TextField {
                        id: currentInput
                        Layout.fillWidth: true
                        placeholderText: "Enter current"
                        validator: DoubleValidator {
                            bottom: 0
                            decimals: 2
                        }
                        color: acceptableInput ? "black" : "red"
                        onTextChanged: {
                            if (acceptableInput && calculator) {
                                calculator.setCurrent(parseFloat(text))
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 10
                    Label {
                        text: "Power Factor:"
                        Layout.preferredWidth: 100
                    }
                    
                    ComboBox {
                        id: pfPresets
                        model: ["Custom", "0.8", "0.85", "0.9", "0.95", "1.0"]
                        Layout.preferredWidth: 80
                        onCurrentTextChanged: {
                            if (currentText !== "Custom") {
                                pfInput.text = currentText
                                pfInput.enabled = false
                            } else {
                                pfInput.enabled = true
                            }
                        }
                        currentIndex: 1  // Default to 0.8
                    }
                    
                    TextField {
                        id: pfInput
                        Layout.fillWidth: true
                        enabled: pfPresets.currentText === "Custom"
                        opacity: enabled ? 1.0 : 0.5
                        placeholderText: "0.8-1.0"
                        validator: DoubleValidator {
                            bottom: 0
                            top: 1
                            decimals: 2
                        }
                        text: "0.8"  // Default value
                        color: acceptableInput ? "black" : "red"
                        onTextChanged: {
                            if (acceptableInput && calculator) {
                                calculator.setPowerFactor(parseFloat(text))
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 10
                    Layout.topMargin: 15
                    
                    Label {
                        text: "Power (kW):"
                        Layout.preferredWidth: 100
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: "#f0f0f0"
                        radius: 4

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4

                            Text {
                                id: kwOutput
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                font.bold: true
                                text: {
                                    if (!calculator || isNaN(calculator.kw)) return "0.00 kW"
                                    return calculator.kw.toFixed(2) + " kW"
                                }
                            }

                            Button {
                                Layout.preferredWidth: 50
                                Layout.preferredHeight: 22
                                text: "Copy"
                                font.pointSize: 8
                                ToolTip.text: "Copy to clipboard"
                                ToolTip.visible: hovered
                                onClicked: {
                                    if (calculator && !isNaN(calculator.kw)) {
                                        clipboardHelper.text = kwOutput.text
                                        clipboardHelper.selectAll()
                                        clipboardHelper.copy()
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    text: phaseSelector.currentText === "Single Phase" ? 
                          "Formula: P = V × I × PF / 1000" : 
                          "Formula: P = √3 × V × I × PF / 1000"
                    font.italic: true
                    color: "gray"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    id: errorMessage
                    color: "red"
                    visible: (!currentInput.acceptableInput && currentInput.text !== "") ||
                             (!pfInput.acceptableInput && pfInput.text !== "")
                    text: "Please enter valid numbers"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
