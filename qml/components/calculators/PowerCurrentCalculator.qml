import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../"
import "../style"
import "../popups"
import "../style"
import "../buttons"
import "../../../scripts/MaterialDesignRegular.js" as MD

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

    FontLoader {
        id: iconFont
        source: "../../../icons/MaterialIcons-Regular.ttf"
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

    RowLayout {
        anchors.centerIn: parent

        WaveCard {
            id: results
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumHeight: 300
            Layout.minimumWidth: 400
            title: "Transformer Calculator"

            showSettings: true
         
            GridLayout {
                anchors.centerIn: parent
                Layout.maximumWidth: 300
                columns: 3

                Label {
                    text: "Phase:"
                    Layout.preferredWidth: 80
                }

                ComboBox {
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

                ComboBox {
                    id: kvaPresets
                    model: ["Custom", "15 kVA", "30 kVA", "50 kVA", "75 kVA", "100 kVA", "200 kVA", "300 kVA", "500 kVA", "750 kVA", "1000 kVA", "1500 kVA"] 
                    Layout.preferredWidth: 120
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

                Label {
                    text: "Voltage:"
                    Layout.preferredWidth: 80
                }

                ComboBox {
                    id: voltagePresets
                    model: ["Custom", "230V", "400V", "415V", "11000V"]
                    Layout.preferredWidth: 120
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
                    Layout.fillWidth: true
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
                        text: "Copy  " + MD.icons["copy_all"]
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
            title: "Current-> Power Calculator"

            showSettings: true
         
            GridLayout {
                anchors.centerIn: parent
                Layout.maximumWidth: 400
                columns: 3

                Label {
                    text: "Phase Type:"
                    Layout.preferredWidth: 80
                }
                ComboBox {
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
                    Layout.preferredWidth: 100
                }

                TextField {
                    id: currentInput
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    placeholderText: "Enter current"
                    validator: DoubleValidator {
                        bottom: 0
                        decimals: 2
                    }
                    color: acceptableInput ? "black" : "red"
                    onTextChanged: {
                        if (acceptableInput && calculator1) {
                            calculator1.setCurrent(parseFloat(text))
                        }
                    }
                }

                Label {
                    text: "Power Factor:"
                    Layout.preferredWidth: 100
                }
                
                ComboBox {
                    id: pfPresets
                    model: ["Custom", "0.8", "0.85", "0.9", "0.95", "1.0"]
                    Layout.preferredWidth: 120
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
                    Layout.preferredWidth: 80
                    enabled: pfPresets.currentText === "Custom"
                    opacity: enabled ? 1.0 : 0.5
                    placeholderText: "0.8-1.0"
                    validator: DoubleValidator {
                        bottom: 0
                        top: 1
                        decimals: 2
                    }
                    text: "0.8"  
                    color: acceptableInput ? "black" : "red"
                    onTextChanged: {
                        if (acceptableInput && calculator1) {
                            calculator1.setPowerFactor(parseFloat(text))
                        }
                    }
                }

                RowLayout {
                    Layout.columnSpan: 3
                    
                    Label {
                        text: "Power (kW):"
                        Layout.preferredWidth: 100
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
                        text: "Copy  " + MD.icons["copy_all"]
                        ToolTip.text: "Copy to clipboard"
                        ToolTip.visible: hovered
                        onClicked: {
                            if (calculator1 && !isNaN(calculator1.kw)) {
                                clipboardHelper.text = kwOutput.text
                                clipboardHelper.selectAll()
                                clipboardHelper.copy()
                            }
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
                             (!pfInput.acceptableInput && pfInput.text !== "")
                    text: "Please enter valid numbers"
                    Layout.columnSpan: 3
                }
            }
        }
    }
}