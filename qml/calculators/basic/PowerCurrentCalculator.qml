import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"

import PCalculator 1.0
import KwFromCurrent 1.0

Item {
    id: power_current
    
    property PowerCalculator calculator: PowerCalculator {}
    property KwFromCurrentCalculator calculator1: KwFromCurrentCalculator {}

    TextEdit {
        id: clipboardHelper
        visible: false
    }

    PopUpText {
        parentCard: results
        popupText: "<h3>Transformer Calculator </h3><br> Helps you calculate the current flowing through a transformer based on the kVA and voltage. The formula used is: <br><br>" +
                   "Single Phase: I = kVA / V <br>" +
                   "Three Phase: I = kVA / (V × √3)"
        widthFactor: 0.3
        heightFactor: 0.3
    }

    PopUpText {
        parentCard: results1
        popupText: "<h3> Current->Power Calculator </h3><br> Calculate the power consumed by a device based on the current and power factor. The formula used is: <br><br>" +
                     "Single Phase: P = V × I × PF / 1000<br>" +
                     "Three Phase: P = √3 × V × I × PF / 1000"
        widthFactor: 0.3
        heightFactor: 0.3
    }

    ColumnLayout {
        anchors.centerIn: parent

        // Header with title and help button
        RowLayout {
            id: topHeader
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 5

            Label {
                text: "Transformer Current & Power Calculator"
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            // StyledButton {
            //     id: helpButton
            //     icon.source: "../../../icons/rounded/info.svg"
            //     ToolTip.text: "Help"
            //     onClicked: popUpText.open()
            // }
        }

        RowLayout {

            WaveCard {
                id: results
                Layout.alignment: Qt.AlignHCenter
                Layout.minimumHeight: 300
                Layout.minimumWidth: 400
                title: "Transformer kVA -> Current"

                showSettings: true
            
                GridLayout {
                    anchors.centerIn: parent
                    Layout.maximumWidth: 300
                    columns: 3

                    Label {
                        text: "Phase:"
                        Layout.preferredWidth: 80
                    }

                    ComboBoxRound {
                        id: phaseSelector
                        model: ["Single Phase", "Three Phase"]
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        onCurrentTextChanged: {
                            if (calculator) {
                                calculator.setPhase(currentText)
                            }
                        }
                        currentIndex: 1
                    }

                    Label {
                        text: "kVA:"
                        Layout.preferredWidth: 80
                    }

                    ComboBoxRound {
                        id: kvaPresets
                        model: ["Custom", "15 kVA", "30 kVA", "50 kVA", "75 kVA", "100 kVA", "200 kVA", "300 kVA", "500 kVA", "750 kVA", "1000 kVA", "1500 kVA"] 
                        Layout.preferredWidth: 120
                        onCurrentTextChanged: {
                            if (currentText !== "Custom") {
                                let kva = parseInt(currentText.replace("V", ""))
                                calculator.setKva(kva)
                                kvaInput.enabled = false
                                kvaInput.text = kva.toString()
                            } else {
                                kvaInput.enabled = true
                            }
                        }
                    }
                    
                    TextFieldRound {
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

                        onTextChanged: {
                            if (acceptableInput && calculator) {
                                calculator.setKva(parseFloat(text))
                            }
                        }
                    }

                    Label {
                        text: "Voltage:"
                        Layout.preferredWidth: 80
                    }

                    ComboBoxRound {
                        id: voltagePresets
                        model: ["Custom", "230V", "400V", "415V", "11000V"]
                        Layout.preferredWidth: 120
                        onCurrentTextChanged: {
                            if (currentText !== "Custom") {
                                let voltage = parseInt(currentText.replace("V", ""))
                                calculator.setVoltage(voltage)
                                voltageInput.enabled = false
                                voltageInput.text = voltage.toString()
                            } else {
                                voltageInput.enabled = true
                            }
                        }
                    }

                    TextFieldRound {
                        id: voltageInput
                        Layout.fillWidth: true
                        enabled: voltagePresets.currentText === "Custom"
                        opacity: enabled ? 1.0 : 0.5
                        placeholderText: "Voltage"
                        validator: DoubleValidator {
                            bottom: 0
                            decimals: 1
                        }

                        onTextChanged: {
                            if (acceptableInput && calculator) {
                                calculator.setVoltage(parseFloat(text))
                            }
                        }
                        ToolTip.text: "Enter voltage in V"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                    }

                    RowLayout {
                        Layout.columnSpan: 3

                        Label {
                            text: "Current:"
                            Layout.preferredWidth: 80
                        }

                        TextFieldBlue {
                            id: currentOutput
                            font.bold: true
                            text: {
                                if (!calculator || isNaN(calculator.current)) return "0.00 A"
                                let current = calculator.current
                                return current >= 2000 ? 
                                    (current/1000).toFixed(2) + " kA" :
                                    current.toFixed(2) + " A"
                            }
                        }

                        StyledButton {
                            Layout.preferredWidth: 80
                            text: "Copy"
                            ToolTip.text: "Copy to clipboard"
                            ToolTip.visible: hovered
                            icon.source: "../../../icons/rounded/copy_all.svg"
                            onClicked: {
                                if (calculator && !isNaN(calculator.current)) {
                                    clipboardHelper.text = currentOutput.text
                                    clipboardHelper.selectAll()
                                    clipboardHelper.copy()
                                }
                            }
                        }
                    }

                    Label {
                        text: "Based on: " + (phaseSelector.currentText === "Three Phase" ? "√3 × V × I" : "V × I")
                        font.italic: true
                        color: "gray"
                        Layout.columnSpan: 3
                        Layout.topMargin: 5
                    }

                    Label {
                        id: errorMessage
                        color: "red"
                        visible: (!kvaInput.acceptableInput && kvaInput.text !== "") ||
                                (!voltageInput.acceptableInput && voltageInput.text !== "")
                        text: "Please enter valid numbers"
                    }
                }
            }

            WaveCard {
                id: results1
                Layout.alignment: Qt.AlignHCenter
                Layout.minimumHeight: 300
                Layout.minimumWidth: 400
                title: "Current -> Power"

                showSettings: true
            
                GridLayout {
                    anchors.centerIn: parent
                    Layout.maximumWidth: 400
                    columns: 3

                    Label {
                        text: "Phase Type:"
                        Layout.preferredWidth: 120
                    }

                    ComboBoxRound {
                        id: phaseSelector1
                        model: ["Single Phase", "Three Phase"]
                        Layout.minimumWidth: 200
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        onCurrentTextChanged: {
                            if (calculator1) {
                                calculator1.setPhase(currentText)
                            }
                        }
                        currentIndex: 1
                        Layout.alignment: Qt.AlignRight
                    }

                    Label {
                        text: "Current (A):"
                        Layout.fillWidth: true
                    }

                    TextFieldRound {
                        id: currentInput
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        placeholderText: "Enter current"
                        validator: DoubleValidator {
                            bottom: 0
                            decimals: 2
                        }
                        onTextChanged: {
                            if (acceptableInput && calculator1) {
                                calculator1.setCurrent(parseFloat(text))
                            }
                        }
                    }

                    Label {
                        text: "Voltage:"
                        Layout.fillWidth: true
                    }

                    ComboBoxRound {
                        id: voltagePresets1
                        model: ["Custom", "230V", "400V", "415V", "11000V"]
                        Layout.fillWidth: true
                        onCurrentTextChanged: {
                            if (currentText !== "Custom") {
                                let voltage = parseInt(currentText.replace("V", ""))
                                calculator1.setVoltage(voltage)
                                voltageInput1.enabled = false
                                voltageInput1.text = voltage.toString()
                            } else {
                                voltageInput1.enabled = true
                            }
                        }
                        currentIndex: 2  // Default to 415V
                    }

                    TextFieldRound {
                        id: voltageInput1
                        Layout.fillWidth: true
                        enabled: voltagePresets1.currentText === "Custom"
                        opacity: enabled ? 1.0 : 0.5
                        placeholderText: "Voltage"
                        validator: DoubleValidator {
                            bottom: 0
                            decimals: 1
                        }

                        onTextChanged: {
                            if (acceptableInput && calculator1 && enabled) {
                                calculator1.setVoltage(parseFloat(text))
                            }
                        }
                    }

                    Label {
                        text: "Power Factor:"
                        Layout.fillWidth: true
                    }
                    
                    ComboBoxRound {
                        id: pfPresets
                        model: ["Custom", "0.8", "0.85", "0.9", "0.95", "1.0"]
                    Layout.fillWidth: true
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
                    
                    TextFieldRound {
                        id: pfInput
                        Layout.fillWidth: true
                        enabled: pfPresets.currentText === "Custom"
                        opacity: enabled ? 1.0 : 0.5
                        placeholderText: "PF"
                        validator: DoubleValidator {
                            bottom: 0.0  // Changed from 1 to 0.0
                            top: 1.0     // Added top limit
                            decimals: 2
                        }
                        // color: acceptableInput ? "black" : "red"
                        onTextChanged: {
                            if (acceptableInput && calculator1) {
                                calculator1.setPowerFactor(parseFloat(text))
                            }
                        }
                    }

                    Label {
                        text: "Power (kW):"
                        Layout.fillWidth: true
                    }

                    TextFieldBlue {
                        id: kwOutput
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        font.bold: true
                        text: {
                            if (!calculator1 || isNaN(calculator1.kw)) return "0.00 kW"
                            return calculator1.kw.toFixed(2) + " kW"
                        }
                    }

                    StyledButton {
                        Layout.preferredWidth: 80
                        text: "Copy"
                        ToolTip.text: "Copy to clipboard"
                        ToolTip.visible: hovered
                        icon.source: "../../../icons/rounded/copy_all.svg"
                        onClicked: {
                            if (calculator1 && !isNaN(calculator1.kw)) {
                                clipboardHelper.text = kwOutput.text
                                clipboardHelper.selectAll()
                                clipboardHelper.copy()
                            }
                        }
                    }

                    Label {
                        text: "Apparent Power:"
                        Layout.preferredWidth: 100
                    }

                    TextFieldBlue {
                        id: kvaOutput
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        font.bold: true
                        text: {
                            if (!calculator1 || isNaN(calculator1.kva)) return "0.00 kVA"
                            return calculator1.kva.toFixed(2) + " kVA"
                        }
                    }

                    StyledButton {
                        Layout.preferredWidth: 80
                        text: "Copy"
                        ToolTip.text: "Copy to clipboard"
                        ToolTip.visible: hovered
                        icon.source: "../../../icons/rounded/copy_all.svg"
                        onClicked: {
                            if (calculator1 && !isNaN(calculator1.kva)) {
                                clipboardHelper.text = kvaOutput.text
                                clipboardHelper.selectAll()
                                clipboardHelper.copy()
                            }
                        }
                    }

                    Label {
                        text: phaseSelector1.currentText === "Single Phase" ? 
                            "Formula: P = V × I × PF / 1000" : 
                            "Formula: P = √3 × V × I × PF / 1000"
                        font.italic: true
                        color: "gray"
                        Layout.columnSpan: 3
                        Layout.topMargin: 5
                    }

                    Label {
                        id: errorMessage1
                        color: "red"
                        visible: (!currentInput.acceptableInput && currentInput.text !== "") ||
                                (!pfInput.acceptableInput && pfInput.text !== "") ||
                                (!voltageInput1.acceptableInput && voltageInput1.text !== "")
                        text: "Please enter valid numbers"
                        Layout.columnSpan: 3
                    }
                }
            }
        }
    }
}