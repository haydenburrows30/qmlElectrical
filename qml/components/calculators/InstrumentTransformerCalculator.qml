import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import InstrumentTransformer 1.0

WaveCard {
    id: instrumentTransformerCard
    title: 'Instrument Transformer Calculator'

    property InstrumentTransformerCalculator calculator: InstrumentTransformerCalculator {}

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        // CT Section
        GroupBox {
            title: "Current Transformer"
            Layout.fillWidth: true

            GridLayout {
                columns: 2
                rowSpacing: 10
                columnSpacing: 15

                Label { text: "CT Ratio:" }
                ComboBox {
                    id: ctRatio
                    model: calculator.standardCtRatios
                    onCurrentTextChanged: if (currentText) calculator.setCtRatio(currentText)
                    Layout.fillWidth: true
                }

                Label { text: "Burden (VA):" }
                SpinBox {
                    id: ctBurden
                    from: 3  // Changed to integer
                    to: 30
                    value: 15
                    stepSize: 3  // Changed to integer
                    onValueChanged: calculator.burden = value
                    Layout.fillWidth: true
                }

                Label { text: "Accuracy Class:" }
                ComboBox {
                    id: accuracyClass
                    model: ["0.1", "0.2", "0.5", "1.0"]
                    onCurrentTextChanged: if (currentText) calculator.accuracyClass = currentText
                    Layout.fillWidth: true
                }
            }
        }

        // VT Section
        GroupBox {
            title: "Voltage Transformer"
            Layout.fillWidth: true

            GridLayout {
                columns: 2
                rowSpacing: 10
                columnSpacing: 15

                Label { text: "VT Ratio:" }
                ComboBox {
                    id: vtRatio
                    model: calculator.standardVtRatios
                    onCurrentTextChanged: if (currentText) calculator.setVtRatio(currentText)
                    Layout.fillWidth: true
                }
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

                Label { text: "CT Knee Point:" }
                Label { 
                    text: isFinite(calculator.kneePointVoltage) ? calculator.kneePointVoltage.toFixed(1) + " V" : "0.0 V"
                    font.bold: true 
                }

                Label { text: "Maximum Fault Current:" }
                Label { 
                    text: isFinite(calculator.maxFaultCurrent) ? calculator.maxFaultCurrent.toFixed(1) + " A" : "0.0 A"
                    font.bold: true 
                }

                Label { text: "Minimum CT Burden:" }
                Label { 
                    text: isFinite(calculator.minAccuracyBurden) ? calculator.minAccuracyBurden.toFixed(2) + " Ω" : "0.0 Ω"
                    font.bold: true 
                }
            }
        }
    }
}
