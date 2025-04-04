import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../"
import "../style"
import "../popups"
import "../buttons"

import DeltaTransformer 1.0


Item {

    property DeltaTransformerCalculator calculator: DeltaTransformerCalculator {}

    PopUpText {
        parentCard: results
        popupText: "<h3>Open Delta Transformer Calculator</h3><br>" +
                "This calculator estimates the resistor required for an open delta transformer.<br><br>" +
                "<b>Primary Voltage:</b> The primary side line-to-line voltage.<br>" +
                "<b>Secondary Voltage:</b> The secondary side line-to-line voltage.<br>" +
                "<b>Power Rating:</b> The secondary side VA rating.<br><br>" +
                "The phase voltage is calculated as V/3.<br>" +
                "The resistor is calculated based on the phase voltage.<br>" +
                "The power rating is derated to 86.6% for open delta.<br><br>" +
                "Click the 'Open Reference Guide' button to view the reference guide.<br>" +
                "Click the 'Calculate' button to calculate the resistor.<br>" +
                "The results will be displayed below the input fields.<br>" +
                "The validation indicator will change color based on the input validity.<br>"
    }

    RowLayout {
        anchors.centerIn: parent
        

        ColumnLayout {
            id: inputLayout
            Layout.minimumWidth: 400
            

            WaveCard {
                id: results
                Layout.fillWidth: true
                Layout.minimumHeight: 600
                showSettings: true

                ColumnLayout {
                    
                    anchors.fill: parent
                    

                    Label {
                        text: "Open Delta Transformer Calculator"
                        font.bold: true
                        font.pixelSize: 18
                    }

                    GridLayout {
                        columns: 2
                        
                        

                        Label { text: "Primary Voltage (V):" }
                        TextField {
                            id: primaryVoltage
                            validator: DoubleValidator { bottom: 0 }
                            Layout.fillWidth: true
                        }

                        ToolTip {
                            parent: primaryVoltage
                            visible: primaryVoltage.hovered 
                            text: "Enter primary side line-to-line voltage"
                            delay: 1000
                        }

                        Label { text: "Secondary Voltage (V):" }
                        TextField {
                            id: secondaryVoltage
                            validator: DoubleValidator { bottom: 0 }
                            Layout.fillWidth: true
                            placeholderText: "Usually 110V phase-to-phase"
                        }

                        Label {
                            text: "(Phase voltage will be V/3 = 36.67V for 110V input)"
                            font.italic: true
                            font.pixelSize: 12
                            color: "#666666"
                            Layout.columnSpan: 2
                        }

                        Label { text: "Power Rating (VA):" }
                        TextField {
                            id: powerRating
                            validator: DoubleValidator { bottom: 0 }
                            Layout.fillWidth: true
                        }

                        ToolTip {
                            parent: powerRating
                            visible: powerRating.hovered
                            text: "Enter voltage transformer secondary nameplate VA rating"
                            delay: 1000
                        }

                        Label { 
                            text: "(Note: Power will be derated to 86.6% for open delta)" 
                            font.italic: true
                            font.pixelSize: 12
                            color: "#666666"
                            Layout.columnSpan: 2
                        }
                    }

                    StyledButton {
                        text: "Open Reference Guide"
                        Layout.fillWidth: true
                        onClicked: {
                            Qt.openUrlExternally("file://" + calculator.getPdfPath())
                        }
                    }

                    StyledButton {
                        text: "Calculate"
                        Layout.fillWidth: true
                        onClicked: {
                            if (primaryVoltage.text && secondaryVoltage.text && powerRating.text) {
                                calculator.calculateResistor(
                                    parseFloat(primaryVoltage.text),
                                    parseFloat(secondaryVoltage.text),
                                    parseFloat(powerRating.text)
                                )
                            }
                        }
                    }

                    GroupBox {
                        title: "Results"
                        Layout.fillWidth: true
                        Layout.topMargin: 10

                        ColumnLayout {
                            width: parent.width
                            

                            Label {
                                id: phaseVoltageText
                                text: secondaryVoltage.text ? 
                                    `Phase Voltage: ${(parseFloat(secondaryVoltage.text)/3).toFixed(2)}V` : ""
                                font.pixelSize: 14
                                visible: secondaryVoltage.text !== ""
                            }

                            Label {
                                id: resultText
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                text: "Resistor: " + calculator.resistor.toFixed(2) + " ohm"
                            }

                            Label {
                                id: wattageText
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                text: "Resistor power rating: " + calculator.wattage.toFixed(2) + " W"
                            }

                            Label {
                                text: "Note: Calculations based on phase voltage (V/3)\n" +
                                    "• Open delta connection factor applied\n" +
                                    "• Fault conditions (1.5x)\n" +
                                    "• Continuous operation (2.0x)"
                                font.pixelSize: 12
                                color: "#666666"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.topMargin: 10
                            }
                        }
                    }

                    Rectangle {
                        id: validationIndicator
                        Layout.minimumHeight: 10
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        Layout.alignment: Qt.AlignHCenter
                        radius: 5
                        color: {
                            if (!primaryVoltage.text || !secondaryVoltage.text || !powerRating.text)
                                return "#666666"
                            if (primaryVoltage.acceptableInput && secondaryVoltage.acceptableInput && 
                                powerRating.acceptableInput)
                                return "#00ff00"
                            return "#ff0000"
                        }
                    }
                }
            }
        }

        Image {
            source: "../../../assets/open_delta.png"
            Layout.preferredWidth: 400
            Layout.maximumHeight: inputLayout.height
            fillMode: Image.PreserveAspectFit
        }
    }
}
