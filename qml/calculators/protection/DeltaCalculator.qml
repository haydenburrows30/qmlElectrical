import QtQuick
import QtQuick.Controls
import QtQuick.Layouts


import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import DeltaTransformer 1.0

Item {

    property DeltaTransformerCalculator calculator: DeltaTransformerCalculator {}

    PopUpText {
        id: popUpText
        parentCard: topHeader
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

    ColumnLayout {
        id: mainLayout
        anchors.centerIn: parent

        // Header with title and help button
        RowLayout {
            id: topHeader
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 5

            Label {
                text: "Open Delta Calculator"
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }


            StyledButton {
                text: "Reference Guide"
                icon.source: "../../../icons/rounded/folder.svg"
                onClicked: {
                    Qt.openUrlExternally("file://" + calculator.getPdfPath())
                }
            }

            StyledButton {
                id: helpButton
                icon.source: "../../../icons/rounded/info.svg"
                ToolTip.text: "Help"
                onClicked: popUpText.open()
            }
        }

        RowLayout {
            id: inputLayout
            Layout.minimumWidth: 800

            WaveCard {
                id: results
                Layout.fillWidth: true
                Layout.minimumHeight: 450
                titleVisible: false

                RowLayout {
                    anchors.fill: parent

                    GridLayout {
                        columns: 2
                        uniformCellWidths: true
                        Layout.minimumWidth: 350
                        Layout.leftMargin: 10

                        Label { text: "Primary Voltage (V):" ; Layout.alignment: Qt.AlignRight }

                        TextFieldRound {
                            id: primaryVoltage
                            validator: DoubleValidator { bottom: 0 }
                            Layout.fillWidth: true
                            placeholderText: "11000"

                            ToolTip.text: "Enter primary side line-to-line voltage"
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                        }

                        Label { text: "Secondary Voltage (V):" ; Layout.alignment: Qt.AlignRight }

                        TextFieldRound {
                            id: secondaryVoltage
                            validator: DoubleValidator { bottom: 0 }
                            Layout.fillWidth: true
                            placeholderText: "110"

                            ToolTip.text: "Phase voltage will be V/3 = 36.67V for 110V input"
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                        }

                        Label { text: "Power Rating (VA):" ; Layout.alignment: Qt.AlignRight }

                        TextFieldRound {
                            id: powerRating
                            validator: DoubleValidator { bottom: 0 }
                            Layout.fillWidth: true
                            placeholderText: "150"

                            ToolTip.text: "Enter voltage transformer secondary nameplate VA rating. Power will be derated to 86.6% for open delta."
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                        }

                        StyledButton {
                            text: "Calculate"
                            Layout.columnSpan: 2
                            Layout.alignment: Qt.AlignRight

                            icon.source: "../../../icons/rounded/calculate.svg"

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

                        Label {
                            id: phaseVoltageText
                            text: "Phase Voltage:"
                            Layout.alignment: Qt.AlignRight
                        }

                        TextFieldBlue {
                            text: secondaryVoltage.text ? 
                                `${(parseFloat(secondaryVoltage.text)/3).toFixed(2)}V` : ""
                        }

                        Label {
                            id: resultText
                            text: "Resistor:"
                            Layout.alignment: Qt.AlignRight
                        }

                        TextFieldBlue {
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            text: calculator.resistor.toFixed(2) + " ohm"
                        }

                        Label {
                            id: wattageText
                            Layout.alignment: Qt.AlignRight
                            text: "Resistor power rating:"
                        }

                        TextFieldBlue {
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            text: calculator.wattage.toFixed(2) + " W"
                        }

                        Label {
                            text: "Note: Calculations based on phase voltage (V/3)\n" +
                                "• Open delta connection factor applied\n" +
                                "• Fault conditions (1.5x)\n" +
                                "• Continuous operation (2.0x)"
                            color: "#666666"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            Layout.topMargin: 10
                            Layout.leftMargin: 10
                            Layout.columnSpan: 2
                        }

                        Rectangle {
                            id: validationIndicator
                            Layout.minimumHeight: 10
                            Layout.fillWidth: true
                            Layout.topMargin: 10
                            Layout.alignment: Qt.AlignHCenter
                            Layout.columnSpan: 2
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

                    Image {
                        Layout.maximumHeight: 400
                        source: "../../../assets/open_delta.png"
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }
        }
    }
}
