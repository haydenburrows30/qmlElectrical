import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"

import Transformer 1.0

WaveCard {
    id: transformerCard
    title: 'Transformer Calculator'

    property TransformerCalculator calculator: TransformerCalculator {}

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        // Primary Side
        GroupBox {
            title: "Primary Side"

            GridLayout {
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                Label { text: "Voltage (V):" }
                TextField {
                    id: primaryVoltage
                    Layout.minimumWidth: 150
                    placeholderText: "Enter voltage"
                    onTextChanged: calculator.primaryVoltage = parseFloat(text)
                }

                Label { text: "Current (A):" }
                TextField {
                    id: primaryCurrent
                    Layout.minimumWidth: 150
                    placeholderText: "Enter current"
                    onTextChanged: calculator.primaryCurrent = parseFloat(text)

                }
            }
        }

        // Secondary Side
        GroupBox {
            title: "Secondary Side"

            GridLayout {
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                Label { text: "Voltage (V):" }
                TextField {
                    id: secondaryVoltage
                    placeholderText: "Enter voltage"
                    onTextChanged: if(text) calculator.secondaryVoltage = parseFloat(text)  // Fix: Use correct property
                    Layout.minimumWidth: 150
                }

                Label { text: "Current (A):" }
                Text {
                    id: secondaryCurrent
                    Layout.minimumWidth: 150
                    text: calculator.secondaryCurrent.toFixed(2)
                }
            }
        }

        // Results
        GroupBox {
            title: "Results"
            Layout.fillWidth: true
            

            ColumnLayout {
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
