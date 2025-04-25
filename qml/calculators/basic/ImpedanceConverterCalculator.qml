import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../components"
import "../../components/visualizers/"
import "../../components/style"
import "../../components/popups"
import "../../components/buttons"

import PerUnitImpedance 1.0
import BaseImpedanceCalculator 1.0

Item {
    id: perUnitImpedanceCalculator

    property BaseImpedanceCalculator baseCalculator: BaseImpedanceCalculator {}
    property PerUnitImpedanceCalculator unitCalculator: PerUnitImpedanceCalculator {}
    property color textColor: Universal.foreground

    PopUpText {
        id: popUpText
        parentCard: topHeader
        popupText: "<h3>Per-Unit Impedance Calculator</h3><br>" +
                "This calculator converts per-unit impedance from one system base to another using the formula: <br>" + 
                "<center><b>Z<sub>p.u.2</sub> = Z<sub>p.u.1</sub> × (MVA<sub>b2</sub>/MVA<sub>b1</sub>) × (kV<sub>b1</sub>/kV<sub>b2</sub>)²</b></center><br>" + 
                "Where:<br>" +
                "Z<sub>p.u.1</sub> = Per-unit impedance on base 1<br>" +
                "Z<sub>p.u.2</sub> = Per-unit impedance on base 2<br>" +
                "MVA<sub>b1</sub> = Base MVA for system 1<br>" +
                "MVA<sub>b2</sub> = Base MVA for system 2<br>" +
                "kV<sub>b1</sub> = Base voltage for system 1<br>" +
                "kV<sub>b2</sub> = Base voltage for system 2<br>" +
                "<h3>Base Impedance Calculator</h3><br>" +
                "The base impedance (Zb) is a reference value used in per-unit system calculations for power systems. <br><br>" + 
                "It is calculated using the formula: Zb = (kV)²/MVA <br><br>" +
                "kV is the base voltage. <br>" +
                "MVA is the base power <br><br>" + 
                "Base impedance is useful for normalizing system values and simplifying power system calculations."
        widthFactor: 0.6
        heightFactor: 0.6
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
                text: "Impedance Converter"
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            StyledButton {
                id: helpButton
                icon.source: "../../../icons/rounded/info.svg"
                ToolTip.text: "Information"
                ToolTip.visible: hovered
                ToolTip.delay: 500
                onClicked: popUpText.open()
            }
        }

        RowLayout {

            WaveCard {
                Layout.preferredHeight: 500
                Layout.preferredWidth: 450
                Layout.alignment: Qt.AlignCenter

                title: "Convert Per-Unit Impedance Between System Bases"

                titleVisible: true
            
                ColumnLayout {
                    anchors.fill: parent

                    Label {
                        text: "Z₍ₚ.ᵤ.₂₎ = Z₍ₚ.ᵤ.₁₎ × (MVA₍ᵦ₂₎/MVA₍ᵦ₁₎) × (kV₍ᵦ₁₎/kV₍ᵦ₂₎)²"
                        font.italic: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Section 1: Base System 1 Parameters
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: Universal.accent
                        radius: 5
                        
                        Label {
                            text: "System 1 Base"
                            font.bold: true
                            anchors.centerIn: parent
                            color: "white"
                        }
                    }

                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true
                        columnSpacing: 10
                        rowSpacing: 10

                        Label {
                            text: "Impedance (Z₁, p.u.):"
                            Layout.preferredWidth: 180
                        }
                        TextFieldRound {
                            id: zPu1Input
                            placeholderText: "Per-unit impedance"
                            text: "0.1"
                            onTextChanged: {
                                if (text && unitCalculator) {
                                    unitCalculator.zPu1 = parseFloat(text)
                                }
                            }
                            Layout.preferredWidth: 200
                            Layout.alignment: Qt.AlignLeft
                        }

                        Label {
                            text: "Base MVA (MVA₁):"
                            Layout.preferredWidth: 180
                        }
                        TextFieldRound {
                            id: mvaB1Input
                            placeholderText: "Base MVA"
                            text: "100.0"
                            onTextChanged: {
                                if (text && unitCalculator) {
                                    unitCalculator.mvaB1 = parseFloat(text)
                                }
                            }
                            Layout.preferredWidth: 200
                            Layout.alignment: Qt.AlignLeft
                        }

                        Label {
                            text: "Base Voltage (kV₁):"
                            Layout.preferredWidth: 180
                        }
                        TextFieldRound {
                            id: kvB1Input
                            placeholderText: "Base kV"
                            text: "11.0"
                            onTextChanged: {
                                if (text && unitCalculator) {
                                    unitCalculator.kvB1 = parseFloat(text)
                                }
                            }
                            Layout.preferredWidth: 200
                            Layout.alignment: Qt.AlignLeft
                        }
                    }

                    // Section 2: Base System 2 Parameters
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        color: Universal.accent
                        radius: 5
                        
                        Label {
                            text: "System 2 Base"
                            font.bold: true
                            anchors.centerIn: parent
                            color: "white"
                        }
                    }

                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true
                        columnSpacing: 10
                        rowSpacing: 10

                        Label {
                            text: "Base MVA (MVA₂):"
                            Layout.preferredWidth: 180
                        }
                        TextFieldRound {
                            id: mvaB2Input
                            placeholderText: "Base MVA"
                            text: "500.0"
                            onTextChanged: {
                                if (text && unitCalculator) {
                                    unitCalculator.mvaB2 = parseFloat(text)
                                }
                            }
                            Layout.preferredWidth: 200
                            Layout.alignment: Qt.AlignLeft
                        }

                        Label {
                            text: "Base Voltage (kV₂):"
                            Layout.preferredWidth: 180
                        }
                        TextFieldRound {
                            id: kvB2Input
                            placeholderText: "Base kV"
                            text: "22.0"
                            onTextChanged: {
                                if (text && unitCalculator) {
                                    unitCalculator.kvB2 = parseFloat(text)
                                }
                            }
                            Layout.preferredWidth: 200
                            Layout.alignment: Qt.AlignLeft
                        }

                        // Result section
                        Label {
                            text: "Converted Impedance (Z₂, p.u.):"
                            font.bold: true
                            Layout.preferredWidth: 180
                            Layout.columnSpan: 2
                        }
                        TextFieldBlue {
                            id: zPu2Result
                            text: unitCalculator && !isNaN(unitCalculator.zPu2) ? 
                                unitCalculator.zPu2.toFixed(4) + " p.u." : "0.0125 p.u."
                            Layout.preferredWidth: 200
                            Layout.columnSpan: 2
                            Layout.alignment: Qt.AlignLeft
                        }
                    }
                }
            }

            WaveCard {
                Layout.preferredHeight: 260
                Layout.preferredWidth: 400
                Layout.alignment: Qt.AlignTop
                titleVisible: true

                title: "Calculate Base Impedance (Zb)"

                ColumnLayout {
                    anchors.fill: parent

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
                                if (text && baseCalculator) {
                                    baseCalculator.voltageKv = parseFloat(text)
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
                                if (text && baseCalculator) {
                                    baseCalculator.powerMva = parseFloat(text)
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
                            text: baseCalculator && !isNaN(baseCalculator.baseImpedance) ? 
                                baseCalculator.baseImpedance.toFixed(3) + " Ω" : "1.210 Ω"
                            Layout.alignment: Qt.AlignLeft
                            Layout.fillWidth: true
                        }

                        Label {
                            text: "Base impedance is used as a reference value in per-unit system calculations"
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignHCenter
                            wrapMode: Text.WordWrap
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}