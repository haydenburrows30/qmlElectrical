import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import Charging 1.0  // Import the Charging namespace for our calculator

WaveCard {
    id: charging_current
    title: 'Cable Charging Current'

    // Create a local instance of our calculator
    property ChargingCalculator calculator: ChargingCalculator {}
    
    // Helper property for theme colors
    property color textColor: Universal.foreground

    TextEdit {
        id: clipboardHelper
        visible: false
    }

    ColumnLayout {
        anchors.fill: parent

        ColumnLayout {
            Layout.maximumWidth: 300
            Layout.alignment: Qt.AlignHCenter
            
            RowLayout {
                spacing: 10
                Label {
                    text: "Voltage (kV):"
                    Layout.preferredWidth: 80
                }
                ComboBox {
                    id: voltagePresets
                    model: ["Custom", "11 kV", "22 kV", "33 kV", "66 kV", "220 kV"]
                    Layout.preferredWidth: 100
                    onCurrentTextChanged: {
                        if (currentText !== "Custom") {
                            voltage_input.text = currentText.replace(" kV", "")
                        }
                    }
                }
                TextField {
                    id: voltage_input
                    Layout.preferredWidth: 100
                    Layout.alignment: Qt.AlignRight
                    enabled: voltagePresets.currentText === "Custom"
                    opacity: enabled ? 1.0 : 0.5
                    placeholderText: "Enter kV"
                    validator: DoubleValidator { bottom: 0; decimals: 3 }
                    color: acceptableInput ? Universal.foreground : "red"
                    onTextChanged: if (acceptableInput) calculator.voltage = parseFloat(text)
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Cable Type:"
                    Layout.preferredWidth: 80
                }
                ComboBox {
                    id: cablePresets
                    model: ["Custom", "XLPE 1C", "XLPE 3C", "Paper 1C", "Paper 3C"]
                    // Layout.preferredWidth: 150
                    Layout.fillWidth: true
                    onCurrentTextChanged: {
                        if (currentText !== "Custom") {
                            // Typical values μF/km
                            switch(currentText) {
                                case "XLPE 1C": capacitanceInput.text = "0.23"; break;
                                case "XLPE 3C": capacitanceInput.text = "0.19"; break;
                                case "Paper 1C": capacitanceInput.text = "0.28"; break;
                                case "Paper 3C": capacitanceInput.text = "0.25"; break;
                            }
                        }
                    }
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "uF/km (1ph):"
                    Layout.preferredWidth: 80
                }
                TextField {
                    id: capacitanceInput
                    // Layout.preferredWidth: 150
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    enabled: cablePresets.currentText === "Custom"
                    opacity: enabled ? 1.0 : 0.5
                    placeholderText: "Enter Capacitance"
                    onTextChanged: calculator.capacitance = parseFloat(text)
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Freq (Hz):"
                    Layout.preferredWidth: 80
                }
                ComboBox {
                    id: freqPresets
                    model: ["50 Hz", "60 Hz"]
                    // Layout.preferredWidth: 150
                    Layout.fillWidth: true
                    onCurrentTextChanged: {
                        calculator.frequency = parseFloat(currentText.replace(" Hz", ""))
                    }
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Length (km):"
                    Layout.preferredWidth: 80
                }
                TextField {
                    id: lengthInput
                    // Layout.preferredWidth: 150
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Length"
                    onTextChanged: calculator.length = parseFloat(text)
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
                    // Layout.preferredWidth: 150
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: Universal.background
                    border.color: Universal.foreground
                    border.width: 1
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        Text {
                            id: chargingCurrentOutput
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            color: Universal.foreground
                            font.bold: true
                            text: {
                                if (!calculator || isNaN(calculator.chargingCurrent)) return "0.00 A"
                                let current = calculator.chargingCurrent
                                return current >= 1000 ? 
                                    (current/1000).toFixed(2) + " kA" :
                                    current.toFixed(2) + " A"
                            }
                        }

                        Button {
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 22
                            text: "Copy"
                            font.pointSize: 8
                            onClicked: {
                                clipboardHelper.text = chargingCurrentOutput.text
                                clipboardHelper.selectAll()
                                clipboardHelper.copy()
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 300
            Layout.minimumWidth: 300
            color: Universal.background
            border.color: Universal.foreground
            border.width: 1
            
            ChargingCurrentViz {
                id: chargingCurrentViz
                anchors.fill: parent
                anchors.margins: 2
                voltage: calculator.voltage //parseFloat(voltage_input.text || "0") 
                capacitance: calculator.capacitance //parseFloat(capacitanceInput.text || "0")
                frequency: calculator.frequency
                length: calculator.length //parseFloat(lengthInput.text || "1")
                current: calculator ? calculator.chargingCurrent : 0.0
            }
        }
    }
}
