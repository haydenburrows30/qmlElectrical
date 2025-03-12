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

    ColumnLayout {
        anchors.fill: parent

        ColumnLayout {
            Layout.minimumWidth: 300
            Layout.alignment: Qt.AlignHCenter
            
            RowLayout {
                spacing: 10
                Label {
                    text: "Voltage (kV):"
                    Layout.preferredWidth: 80
                }
                TextField {
                    id: voltage_input
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Voltage"
                    onTextChanged: calculator.voltage = parseFloat(text)
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
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
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
                TextField {
                    id: frequencyInput
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Frequency"
                    onTextChanged: calculator.frequency = parseFloat(text)
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
                    Layout.preferredWidth: 150
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
                Text {
                    id: chargingCurrentOutput
                    text: calculator && !isNaN(calculator.chargingCurrent) ? 
                          calculator.chargingCurrent.toFixed(2) + "A" : "0.00A"
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                    color: Universal.foreground  // Use theme foreground color
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
                voltage: parseFloat(voltage_input.text || "0") 
                capacitance: parseFloat(capacitanceInput.text || "0")
                frequency: parseFloat(frequencyInput.text || "50")
                length: parseFloat(lengthInput.text || "1")
                current: calculator ? calculator.chargingCurrent : 0.0
            }
        }
    }
}
