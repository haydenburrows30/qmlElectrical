import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"

import Transformer 1.0

Item {
    id: transformerCard

    property TransformerCalculator calculator: TransformerCalculator {}
    property color textColor: Universal.foreground

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 15

        // Left side - Inputs and results
        ColumnLayout {
            Layout.maximumWidth: 300
            spacing: 10
            Layout.alignment: Qt.AlignTop

            // Primary Side
            WaveCard {
                title: "Primary Side"
                Layout.minimumHeight: 150
                Layout.fillWidth: true

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
            WaveCard {
                title: "Secondary Side"
                Layout.minimumHeight: 120
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Label { text: "Voltage (V):" }
                    TextField {
                        id: secondaryVoltage
                        placeholderText: "Enter voltage"
                        onTextChanged: if(text) calculator.secondaryVoltage = parseFloat(text)
                        Layout.minimumWidth: 150
                    }

                    Label { text: "Current (A):" }
                    Text {
                        id: secondaryCurrent
                        text: calculator.secondaryCurrent.toFixed(2)
                        color: Universal.foreground
                        Layout.minimumWidth: 150
                    }
                }
            }

            // Results
            WaveCard {
                title: "Results"
                Layout.minimumHeight: 130
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 5


                    Label { 
                        text: "Turns Ratio: " + calculator.turnsRatio.toFixed(2)
                        visible: calculator.turnsRatio > 0
                        color: Universal.foreground
                    }
                    Label { 
                        text: "Power Rating: " + calculator.powerRating.toFixed(2) + " VA"
                        visible: calculator.powerRating > 0
                        color: Universal.foreground
                    }
                    Label { 
                        text: "Efficiency: " + calculator.efficiency.toFixed(2) + "%"
                        color: Universal.foreground
                    }
                }
            }
        }

        // Right side - Visualization
        WaveCard {
            title: "Transformer Visualization"
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            PowerTransformerVisualization {
                anchors.fill: parent
                anchors.margins: 5
                
                primaryVoltage: parseFloat(primaryVoltage.text || "0")
                primaryCurrent: parseFloat(primaryCurrent.text || "0")
                secondaryVoltage: parseFloat(secondaryVoltage.text || "0")
                secondaryCurrent: calculator ? calculator.secondaryCurrent : 0
                powerRating: calculator ? calculator.powerRating : 0
                turnsRatio: calculator ? calculator.turnsRatio : 1
                efficiency: calculator ? calculator.efficiency : 0
                
                darkMode: Universal.theme === Universal.Dark
                textColor: transformerCard.textColor
            }
        }
    }
}
