import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import Motor 1.0

WaveCard {
    id: motorCard
    title: 'Motor Calculator'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 300

    property MotorCalculator calculator: MotorCalculator {}

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Input Section
        GridLayout {
            columns: 2
            rowSpacing: 10
            columnSpacing: 15

            Label { text: "Motor Power (kW):" }
            TextField {
                id: motorPower
                placeholderText: "Enter power"
                onTextChanged: if(text) calculator.motorPower = parseFloat(text)
                Layout.fillWidth: true
                validator: DoubleValidator { bottom: 0 }
            }

            Label { text: "Supply Voltage (V):" }
            TextField {
                id: voltage
                text: "400"
                onTextChanged: if(text) calculator.voltage = parseFloat(text)
                Layout.fillWidth: true
                validator: DoubleValidator { bottom: 0 }
            }

            Label { text: "Efficiency:" }
            TextField {
                id: efficiency
                text: "0.85"
                onTextChanged: if(text) calculator.efficiency = parseFloat(text)
                Layout.fillWidth: true
                validator: DoubleValidator { bottom: 0; top: 1.0 }
            }

            Label { text: "Power Factor:" }
            TextField {
                id: powerFactor
                text: "0.8"
                onTextChanged: if(text) calculator.powerFactor = parseFloat(text)
                Layout.fillWidth: true
                validator: DoubleValidator { bottom: 0; top: 1.0 }
            }

            Label { text: "Starting Method:" }
            ComboBox {
                id: startingMethod
                model: ["DOL", "Star-Delta", "Soft Starter", "VFD"]
                onCurrentTextChanged: calculator.startingMethod = currentText
                Layout.fillWidth: true
            }
        }

        // Results Section
        GroupBox {
            title: "Results"
            Layout.fillWidth: true

            GridLayout {
                columns: 2
                rowSpacing: 5
                columnSpacing: 10

                Label { text: "Starting Current:" }
                Label { 
                    text: calculator.startingCurrent.toFixed(1) + " A"
                    font.bold: true 
                }

                Label { text: "Starting Torque:" }
                Label { 
                    text: calculator.startingTorque.toFixed(1) + " Nm"
                    font.bold: true 
                }
            }
        }
    }
}
