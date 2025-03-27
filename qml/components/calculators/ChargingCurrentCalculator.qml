import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import "../visualizers/"
import "../style"
import "../backgrounds"

import Charging 1.0  // Import the Charging namespace for our calculator

Item {
    id: charging_current
    property ChargingCalculator calculator: ChargingCalculator {}
    
    property color textColor: Universal.foreground

    TextEdit {
        id: clipboardHelper
        visible: false
    }

    Popup {
        id: tipsPopup
        width: 600
        height: 400
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: results.open

        onAboutToHide: {
            results.open = false
        }
        Text {
            anchors.fill: parent
            text: {"<h3>Charging Current Calculator</h3><br>" +
                    "This calculator estimates the charging current for a cable based on various parameters.<br><br>" +
                    "<b>Voltage:</b> The voltage level of the cable in kV.<br>" +
                    "<b>Cable Type:</b> The type of cable insulation.<br>" +
                    "<b>Capacitance:</b> The capacitance of the cable in μF/km.<br>" +
                    "<b>Frequency:</b> The frequency of the power system in Hz.<br>" +
                    "<b>Length:</b> The length of the cable in km.<br><br>" +
                    "The calculator provides the charging current in amperes based on the selected parameters.<br><br>" +
                    "The visualization shows the charging current distribution along the cable.<br><br>" +
                    "Developed by <b>Wave</b>."
            }
            wrapMode: Text.WordWrap
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: Style.spacing
        anchors.margins: 10

        WaveCard {
            title: "System Parameters"
            Layout.minimumWidth: 330
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumHeight: 300

            id: results
            showSettings: true

            ColumnLayout {
            
                RowLayout {
                    spacing: Style.spacing

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
                    spacing: Style.spacing
                    Label {
                        text: "Cable Type:"
                        Layout.preferredWidth: 80
                    }
                    ComboBox {
                        id: cablePresets
                        model: ["Custom", "XLPE 1C", "XLPE 3C", "Paper 1C", "Paper 3C"]
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
                    spacing: Style.spacing
                    Label {
                        text: "uF/km (1ph):"
                        Layout.preferredWidth: 80
                    }
                    TextField {
                        id: capacitanceInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        enabled: cablePresets.currentText === "Custom"
                        opacity: enabled ? 1.0 : 0.5
                        placeholderText: "Enter Capacitance"
                        onTextChanged: calculator.capacitance = parseFloat(text)
                    }
                }

                RowLayout {
                    spacing: Style.spacing
                    Label {
                        text: "Freq (Hz):"
                        Layout.preferredWidth: 80
                    }
                    ComboBox {
                        id: freqPresets
                        model: ["50 Hz", "60 Hz"]
                        Layout.fillWidth: true
                        onCurrentTextChanged: {
                            calculator.frequency = parseFloat(currentText.replace(" Hz", ""))
                        }
                    }
                }

                RowLayout {
                    spacing: Style.spacing
                    Label {
                        text: "Length (km):"
                        Layout.preferredWidth: 80
                    }
                    TextField {
                        id: lengthInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        placeholderText: "Enter Length"
                        onTextChanged: calculator.length = parseFloat(text)
                    }
                }

                RowLayout {
                    spacing: Style.spacing
                    Layout.topMargin: 5
                    Label {
                        text: "Current:"
                        Layout.preferredWidth: 80
                    }
                    Rectangle {
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
        }

        WaveCard {
            title: "Visualization"
            Layout.fillWidth: true
            Layout.minimumHeight: 300
            Layout.minimumWidth: 300
            
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
