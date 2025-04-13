import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import PFCorrection 1.0

Item {
    id: pfCorrectionCard

    property PowerFactorCorrectionCalculator calculator: PowerFactorCorrectionCalculator {}
    property color textColor: Universal.foreground

    PopUpText {
        id: popUpText
        parentCard: topHeader
        popupText: "<h3>Power Factor Correction</h3><br>" +
                "Power factor correction is a technique used to improve the power factor of a power system by adding capacitors to the system. This helps to reduce the reactive power drawn from the grid, which in turn reduces the losses in the system and improves the efficiency of the system.<br><br>" +
                "The power factor is the ratio of the real power (kW) to the apparent power (kVA) in the system. A power factor of 1 indicates that all the power is being used effectively, while a power factor of 0 indicates that all the power is being wasted. Power factor correction is used to bring the power factor closer to 1, which reduces the reactive power and improves the efficiency of the system.<br><br>" +
                "The power factor correction calculator helps you calculate the required capacitor size and capacitance needed to improve the power factor of a system. Simply enter the active power (kW), current power factor, and target power factor, and the calculator will provide you with the required capacitor size and capacitance needed to achieve the target power factor.<br><br>" +
                "The calculator also provides you with the annual savings that can be achieved by improving the power factor of the system. Power factor correction can help reduce the losses in the system, improve the efficiency of the system, and save you money on your electricity bills."
        widthFactor: 0.5
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
                text: "Power Factor Correction"
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

        RowLayout {

            // Input Section
            ColumnLayout {
                id: inputColumn
                Layout.minimumWidth: 370

                WaveCard {
                    id: results
                    title: "System Parameters"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 170

                    GridLayout {
                        columns: 2

                        Label { text: "Active Power (kW):" ; Layout.minimumWidth: 170}
                        TextFieldRound {
                            id: activePowerInput
                            placeholderText: "Enter power"
                            onTextChanged: if(text) calculator.activePower = parseFloat(text)
                            Layout.minimumWidth: 150
                        }

                        Label { text: "Current PF:" }
                        TextFieldRound {
                            id: currentPFInput
                            placeholderText: "Enter current PF"
                            onTextChanged: if(text) calculator.currentPF = parseFloat(text)
                            Layout.fillWidth: true
                        }

                        Label { text: "Target PF:" }
                        TextFieldRound {
                            id: targetPFInput
                            placeholderText: "Enter target PF"
                            text: "0.95"
                            onTextChanged: if(text) calculator.targetPF = parseFloat(text)
                            Layout.fillWidth: true
                        }
                    }
                }

                // Results Section
                WaveCard {
                    title: "Results"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 170

                    GridLayout {
                        columns: 2

                        Label { text: "Required Capacitor:" ; Layout.minimumWidth: 170}
                        TextFieldBlue { 
                            text: calculator.capacitorSize.toFixed(2) + " kVAR"
                            Layout.minimumWidth: 150

                        }

                        Label { text: "Capacitance Required:" }
                        TextFieldBlue { 
                            text: calculator.capacitance.toFixed(2) + " μF"
                        }

                        Label { text: "Annual Savings:" }
                        TextFieldBlue { 
                            text: "$" + calculator.annualSavings.toFixed(2)
                            color: Universal.theme === Universal.Dark ? "#90EE90" : "green"
                        }
                    }
                }
            }

            // Power Triangle Visualization
            
            PowerFactorViz  {
                id: powerTriangle

                activePower: calculator.activePower
                currentPF: calculator.currentPF

                Layout.minimumWidth: inputColumn.height
                Layout.minimumHeight: inputColumn.height
            }
        }
    }
}
