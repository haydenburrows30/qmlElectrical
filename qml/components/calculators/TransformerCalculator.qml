import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import Transformer 1.0

WaveCard {
    id: transformerCard
    title: 'Transformer Calculator'
    Layout.fillWidth: true
    Layout.fillHeight: true

    property TransformerCalculator calculator: TransformerCalculator {
        onPrimaryVoltageChanged: secondaryCurrent.text = calculator.secondaryCurrent.toFixed(2)
        onPrimaryCurrentChanged: secondaryCurrent.text = calculator.secondaryCurrent.toFixed(2)
        onSecondaryVoltageChanged: secondaryCurrent.text = calculator.secondaryCurrent.toFixed(2)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Primary Side
        GroupBox {
            title: "Primary Side"
            Layout.fillWidth: true

            GridLayout {
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                Label { text: "Voltage (V):" }
                TextField {
                    id: primaryVoltage
                    placeholderText: "Enter voltage"
                    onTextChanged: if(text) calculator.primaryVoltage = parseFloat(text)
                    Layout.fillWidth: true
                }

                Label { text: "Current (A):" }
                TextField {
                    id: primaryCurrent
                    placeholderText: "Enter current"
                    onTextChanged: if(text) calculator.primaryCurrent = parseFloat(text)
                    Layout.fillWidth: true
                }
            }
        }

        // Secondary Side
        GroupBox {
            title: "Secondary Side"
            Layout.fillWidth: true

            GridLayout {
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                Label { text: "Voltage (V):" }
                TextField {
                    id: secondaryVoltage
                    placeholderText: "Enter voltage"
                    onTextChanged: if(text) calculator.setPrimaryVoltage(parseFloat(text))
                    Layout.fillWidth: true
                }

                Label { text: "Current (A):" }
                Text {
                    id: secondaryCurrent
                    Layout.fillWidth: true
                    text: calculator.secondaryCurrent.toFixed(2)
                }
            }
        }

        // Results
        GroupBox {
            title: "Results"
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Label { 
                    text: "Turns Ratio: " + calculator.turnsRatio.toFixed(2)
                    visible: calculator.turnsRatio > 0
                }
                Label { 
                    text: "Power Rating: " + calculator.powerRating.toFixed(2) + " VA"
                    visible: calculator.powerRating > 0
                }
                Label { 
                    text: "Efficiency: " + calculator.efficiency.toFixed(2) + "%"
                }
            }
        }
    }
}
