import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import PCalculator 1.0  // Import the PowerCalculator

WaveCard {
    id: power_current
    title: 'Power -> Current'
    Layout.minimumHeight: 200
    Layout.minimumWidth: 300
    
    property PowerCalculator calculator: PowerCalculator {}

    TextEdit {
        id: clipboardHelper
        visible: false
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 15
        Layout.maximumWidth: 300

        RowLayout {
            spacing: 10
            Label {
                text: "Phase:"
                Layout.preferredWidth: 80
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
                text: "kVA:"
                Layout.preferredWidth: 80
            }
            ComboBox {
                id: kvaPresets
                model: ["Custom", "15 kVA", "30 kVA", "50 kVA", "75 kVA", "100 kVA", "200 kVA", "300 kVA", "500 kVA", "750 kVA", "1000 kVA", "1500 kVA"] 
                Layout.preferredWidth: 100
                onCurrentTextChanged: {
                    if (currentText !== "Custom") {
                        let kva = parseInt(currentText)
                        kvaInput.text = kva.toString()
                        kvaInput.enabled = false
                    } else {
                        kvaInput.enabled = true
                    }
                }
            }
            TextField {
                id: kvaInput
                Layout.preferredWidth: 100
                Layout.alignment: Qt.AlignRight
                enabled: kvaPresets.currentText === "Custom"
                opacity: enabled ? 1.0 : 0.5
                placeholderText: "Enter kVA"
                validator: DoubleValidator {
                    bottom: 0
                    decimals: 2
                }
                color: acceptableInput ? "black" : "red"
                onTextChanged: {
                    if (acceptableInput && calculator) {
                        calculator.setKva(parseFloat(text))
                    }
                }
            }
        }

        RowLayout {
            spacing: 10
            Label {
                text: "Voltage:"
                Layout.preferredWidth: 80
            }
            ComboBox {
                id: voltagePresets
                model: ["Custom", "230V", "400V", "415V", "11000V"]
                Layout.preferredWidth: 100
                onCurrentTextChanged: {
                    if (currentText !== "Custom") {
                        let voltage = parseInt(currentText.replace("V", ""))
                        calculator.setVoltage(voltage)
                        voltageInput.enabled = false
                    } else {
                        voltageInput.enabled = true
                    }
                }
            }
            TextField {
                id: voltageInput
                Layout.preferredWidth: 100
                enabled: voltagePresets.currentText === "Custom"
                opacity: enabled ? 1.0 : 0.5
                placeholderText: "Voltage"
                validator: DoubleValidator {
                    bottom: 0
                    decimals: 1
                }
                color: acceptableInput ? "black" : "red"
                onTextChanged: {
                    if (acceptableInput && calculator && enabled) {
                        calculator.setVoltage(parseFloat(text))
                    }
                }
            }
        }

        RowLayout {
            spacing: 10
            Layout.topMargin: 5
            
            Label {
                text: "Current:"
                Layout.preferredWidth: 80
            }
            Rectangle {
                Layout.preferredWidth: 150
                Layout.preferredHeight: 30
                Layout.fillWidth: true
                color: "#f0f0f0"
                radius: 4

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    Text {
                        id: currentOutput
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        font.bold: true
                        text: {
                            if (!calculator || isNaN(calculator.current)) return "0.00 A"
                            let current = calculator.current
                            return current >= 2000 ? 
                                (current/1000).toFixed(2) + " kA" :
                                current.toFixed(2) + " A"
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
                            if (calculator && !isNaN(calculator.current)) {
                                clipboardHelper.text = currentOutput.text
                                clipboardHelper.selectAll()
                                clipboardHelper.copy()
                            }
                        }
                    }
                }
            }
        }

        Text {
            text: "Based on: " + (phaseSelector.currentText === "Three Phase" ? "√3 × V × I" : "V × I")
            font.italic: true
            color: "gray"
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            id: errorMessage
            color: "red"
            visible: (!kvaInput.acceptableInput && kvaInput.text !== "") ||
                    (!voltageInput.acceptableInput && voltageInput.text !== "")
            text: "Please enter valid numbers"
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
