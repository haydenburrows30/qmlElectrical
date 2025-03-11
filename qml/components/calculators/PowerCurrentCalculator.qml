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

    info: ""
    righticon: "Info"
    
    // Create a local instance of the calculator
    property PowerCalculator calculator: PowerCalculator {}

    ColumnLayout {
        RowLayout {
            spacing: 10
            Label {
                text: "Phase:"
                Layout.preferredWidth: 80
            }
            ComboBox {
                id: phaseSelector
                model: ["Single Phase", "Three Phase"]
                onCurrentTextChanged: {
                    if (calculator) {
                        // Use setPhase() method instead of property assignment
                        calculator.setPhase(currentText)
                    }
                }
                currentIndex: 1
                Layout.preferredWidth: 150
                Layout.alignment: Qt.AlignRight
            }
        }

        RowLayout {
            spacing: 10
            Label {
                text: "kVA:"
                Layout.preferredWidth: 80
            }
            TextField {
                id: kvaInput
                Layout.preferredWidth: 150
                Layout.alignment: Qt.AlignRight
                placeholderText: "Enter kVA"
                onTextChanged: {
                    if (text && calculator) {
                        // Use setKva() method instead of property assignment
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
            TextField {
                id: voltageInput
                placeholderText: "Enter Voltage"
                onTextChanged: {
                    if (text && calculator) {
                        // Use setVoltage() method instead of property assignment
                        calculator.setVoltage(parseFloat(text))
                    }
                }
                Layout.preferredWidth: 150
                Layout.alignment: Qt.AlignRight
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
                id: currentOutput
                text: calculator && !isNaN(calculator.current) ? 
                      calculator.current.toFixed(2) + "A" : "0.00A"
                Layout.preferredWidth: 150
                Layout.alignment: Qt.AlignRight
            }
        }
    }
}
