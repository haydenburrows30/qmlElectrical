import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import InstrumentTransformer 1.0

Item {
    id: instrumentTransformerCard
    // title: 'Instrument Transformer Calculator'

    property InstrumentTransformerCalculator calculator: InstrumentTransformerCalculator {}
    property color textColor: Universal.foreground

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Left side inputs and results
        ColumnLayout {
            Layout.maximumWidth: 400
            Layout.minimumWidth: 300
            Layout.alignment: Qt.AlignTop
            spacing: 10

            // CT Section
            WaveCard {
                title: "Current Transformer"
                Layout.fillWidth: true
                Layout.minimumHeight: 200

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
            WaveCard {
                title: "Voltage Transformer"
                Layout.fillWidth: true
                Layout.minimumHeight: 100

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
            WaveCard {
                title: "Results"
                Layout.fillWidth: true
                Layout.minimumHeight: 140

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Label { text: "CT Knee Point:" }
                    Label { 
                        text: isFinite(calculator.kneePointVoltage) ? calculator.kneePointVoltage.toFixed(1) + " V" : "0.0 V"
                        font.bold: true
                        color: Universal.foreground
                    }

                    Label { text: "Maximum Fault Current:" }
                    Label { 
                        text: isFinite(calculator.maxFaultCurrent) ? calculator.maxFaultCurrent.toFixed(1) + " A" : "0.0 A"
                        font.bold: true
                        color: Universal.foreground
                    }

                    Label { text: "Minimum CT Burden:" }
                    Label { 
                        text: isFinite(calculator.minAccuracyBurden) ? calculator.minAccuracyBurden.toFixed(2) + " Ω" : "0.0 Ω"
                        font.bold: true
                        color: Universal.foreground
                    }
                }
            }
        }

        // Right side visualization
        WaveCard {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TransformerVisualization {
                id: transformerViz
                anchors.fill: parent
                anchors.margins: 5
                
                // Pass CT data
                ctRatio: ctRatio.currentText || "100/5"
                ctBurden: ctBurden.value || 15
                ctKneePoint: calculator ? calculator.kneePointVoltage : 0
                ctMaxFault: calculator ? calculator.maxFaultCurrent : 0
                
                // Pass VT data
                vtRatio: vtRatio.currentText || "11000/110"
                
                // Theme properties
                darkMode: Universal.theme === Universal.Dark
                textColor: instrumentTransformerCard.textColor
            }
        }
    }
}
