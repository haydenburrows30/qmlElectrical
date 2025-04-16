import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../components"
import "../../components/visualizers/"
import "../../components/style"
import "../../components/popups"
import "../../components/buttons"

import BaseImpedanceCalculator 1.0

Item {
    id: baseImpedanceCalculator

    property BaseImpedanceCalculator calculator: BaseImpedanceCalculator {}
    property color textColor: Universal.foreground

    PopUpText {
        id: popUpText
        parentCard: topHeader
        popupText: "<h3>Base Impedance Calculator</h3><br>" +
                "The base impedance (Zb) is a reference value used in per-unit system calculations for power systems. <br>" + 
                "It is calculated using the formula: Zb = (kV)²/MVA where kV is the base voltage in kilovolts and MVA is the base power in megavolt-amperes. <br>" + 
                "Base impedance is useful for normalizing system values and simplifying power system calculations."
        widthFactor: 0.4
        heightFactor: 0.4
    }

    ColumnLayout {
        anchors.centerIn: parent

        // Header with title and help button
        RowLayout {
            id: topHeader
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 5

            Label {
                text: "Base Impedance Calculator"
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            StyledButton {
                id: helpButton
                icon.source: "../../../icons/rounded/info.svg"
                ToolTip.text: "Help"
                onClicked: popUpText.open()
            }
        }

        WaveCard {
            Layout.preferredHeight: 250
            Layout.preferredWidth: 400
            Layout.alignment: Qt.AlignCenter
            titleVisible: false
        
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 20

                Label {
                    text: "Calculate Base Impedance (Zb)"
                    font.pixelSize: 16
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: "Formula: Zb = (kV)² / MVA"
                    font.italic: true
                    Layout.alignment: Qt.AlignHCenter
                }

                GridLayout {
                    columns: 2
                    Layout.fillWidth: true
                    columnSpacing: 10
                    rowSpacing: 15
                    uniformCellWidths: true

                    Label {
                        text: "System Voltage (kV):"
                        Layout.fillWidth: true
                    }
                    TextFieldRound {
                        id: voltageInput
                        placeholderText: "Enter voltage in kV"
                        text: "11.0"
                        onTextChanged: {
                            if (text && calculator) {
                                calculator.voltageKv = parseFloat(text)
                            }
                        }
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "System Power (MVA):"
                        Layout.fillWidth: true
                    }
                    TextFieldRound {
                        id: powerInput
                        placeholderText: "Enter power in MVA"
                        text: "100.0"
                        onTextChanged: {
                            if (text && calculator) {
                                calculator.powerMva = parseFloat(text)
                            }
                        }
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "Base Impedance (Zb):"
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    TextFieldBlue {
                        id: resultField
                        text: calculator && !isNaN(calculator.baseImpedance) ? 
                              calculator.baseImpedance.toFixed(3) + " Ω" : "1.210 Ω"
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true
                    }
                }

                Label {
                    text: "Base impedance is used as a reference value in per-unit system calculations"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}