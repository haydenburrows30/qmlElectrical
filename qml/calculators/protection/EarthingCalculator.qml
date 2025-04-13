import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal


import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import Earthing 1.0

Item {
    id: earthingCard

    property EarthingCalculator calculator: EarthingCalculator {}
    property color textColor: Universal.foreground

    PopUpText {
        id: popUpText
        parentCard: topHeader
        widthFactor: 0.5
        heightFactor: 0.7
        popupText: "<h3>Earthing System Calculator</h3><br>" +
                "This calculator estimates the grid resistance, ground rise, touch voltage, step voltage, and minimum conductor size for an earthing system.<br><br>" +
                "<b>Grid Parameters:</b><br>" +
                "<b>Soil Resistivity:</b> The resistivity of the soil in Ω⋅m.<br>" +
                "<b>Grid Depth:</b> The depth of the grid in meters.<br>" +
                "<b>Grid Length:</b> The length of the grid in meters.<br>" +
                "<b>Grid Width:</b> The width of the grid in meters.<br><br>" +
                "<b>Rod Parameters:</b><br>" +
                "<b>Rod Length:</b> The length of the ground rods in meters.<br>" +
                "<b>Number of Rods:</b> The number of ground rods.<br><br>" +
                "<b>Fault Parameters:</b><br>" +
                "<b>Fault Current:</b> The fault current in Amperes.<br>" +
                "<b>Fault Duration:</b> The fault duration in seconds.<br><br>" +
                "<b>Standards:</b> Calculations are based on IEEE Standard 80 \"Guide for Safety in AC Substation Grounding\". " +
                "The implementation includes improved grid resistance formulation using the IEEE 80 approach, accurate " +
                "touch and step voltage calculations, and conductor sizing based on thermal capacity.<br><br>" +
                "The calculator provides the grid resistance, ground rise, touch voltage, step voltage, and minimum conductor size for the earthing system.<br><br>" +
                "The visualization shows the earthing system with the grid and ground rods.<br><br>" +
                "Developed by <b>Wave</b>."
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent

        // Header with title and help button
        RowLayout {
            id: topHeader
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 5

            Label {
                text: "Earthing Calculator"
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

            // Left side - inputs and results
            ColumnLayout {
                Layout.maximumWidth: 300
                Layout.alignment: Qt.AlignTop

                // Grid Parameters
                WaveCard {
                    title: "Grid Parameters"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 220

                    GridLayout {
                        columns: 2
                        
                        columnSpacing: 15

                        Label { text: "Soil Resistivity (Ω⋅m):" ; Layout.minimumWidth: 150}
                        TextFieldRound {
                            id: soilResistivityInput
                            text: "100"
                            validator: DoubleValidator { bottom: 0 }
                            onTextChanged: if(text) calculator.setSoilResistivity(parseFloat(text))
                            Layout.minimumWidth: 100
                        }

                        Label { text: "Grid Depth (m):" }
                        TextFieldRound {
                            id: gridDepthInput
                            text: "0.5"
                            validator: DoubleValidator { bottom: 0 }
                            onTextChanged: if(text) calculator.setGridDepth(parseFloat(text))
                            Layout.fillWidth: true
                        }

                        Label { text: "Grid Length (m):" }
                        TextFieldRound {
                            id: gridLengthInput
                            text: "20"
                            validator: DoubleValidator { bottom: 0 }
                            onTextChanged: if(text) calculator.setGridLength(parseFloat(text))
                            Layout.fillWidth: true
                        }

                        Label { text: "Grid Width (m):" }
                        TextFieldRound {
                            id: gridWidthInput
                            text: "20"
                            validator: DoubleValidator { bottom: 0 }
                            onTextChanged: if(text) calculator.setGridWidth(parseFloat(text))
                            Layout.fillWidth: true
                        }
                    }
                }

                // Rod Parameters
                WaveCard {
                    title: "Ground Rods"
                    Layout.minimumHeight: 150
                    Layout.fillWidth: true

                    GridLayout {
                        columns: 2
                        
                        

                        Label { text: "Rod Length (m):" ; Layout.minimumWidth: 150}
                        TextFieldRound {
                            id: rodLengthInput
                            text: "3"
                            validator: DoubleValidator { bottom: 0 }
                            onTextChanged: if(text) calculator.setRodLength(parseFloat(text))
                            Layout.minimumWidth: 100
                        }

                        Label { text: "Number of Rods:" }
                        SpinBoxRound {
                            id: rodCountInput
                            from: 0
                            to: 20
                            value: 4
                            onValueChanged: calculator.setRodCount(value)
                            Layout.fillWidth: true
                        }
                    }
                }

                // Fault Parameters
                WaveCard {
                    title: "Fault Parameters"
                    Layout.minimumHeight: 150
                    Layout.fillWidth: true

                    GridLayout {
                        columns: 2
                        
                        

                        Label { text: "Fault Current (A):" ;Layout.minimumWidth: 150}
                        TextFieldRound {
                            id: faultCurrentInput
                            text: "10000"
                            validator: DoubleValidator { bottom: 0 }
                            onTextChanged: if(text) calculator.setFaultCurrent(parseFloat(text))
                            Layout.minimumWidth: 100
                        }

                        Label { text: "Fault Duration (s):" }
                        TextFieldRound {
                            id: faultDurationInput
                            text: "0.5"
                            validator: DoubleValidator { bottom: 0 }
                            onTextChanged: if(text) calculator.setFaultDuration(parseFloat(text))
                            Layout.fillWidth: true
                        }
                    }
                }

                // Results Section
                WaveCard {
                    title: "Results"
                    Layout.minimumHeight: 250
                    Layout.fillWidth: true

                    GridLayout {
                        columns: 2

                        Label { text: "Grid Resistance:" ; Layout.minimumWidth: 150}
                        TextFieldBlue { 
                            text: calculator.gridResistance.toFixed(3) + " Ω"
                            Layout.minimumWidth: 100
                            ToolTip.text: "Total ground grid resistance"
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                        }

                        Label { text: "Ground Rise:" }
                        TextFieldBlue { 
                            text: calculator.voltageRise.toFixed(1) + " V"
                            ToolTip.text: "Ground potential rise under fault conditions"
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                        }

                        Label { text: "Touch Voltage:" }
                        TextFieldBlue { 
                            text: calculator.touchVoltage.toFixed(1) + " V"
                            color: calculator.touchVoltage > 50 * (1 + 0.116 * parseFloat(soilResistivityInput.text)/1000) ? 
                                (Universal.theme === Universal.Dark ? "#FF8080" : "red") : 
                                (Universal.theme === Universal.Dark ? "#80FF80" : "green")
                            ToolTip.text: "Touch voltage potential (colored red if exceeds safety threshold)"
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                        }

                        Label { text: "Step Voltage:" }
                        TextFieldBlue { 
                            text: calculator.stepVoltage.toFixed(1) + " V"
                            color: calculator.stepVoltage > 50 * (1 + 0.53 * parseFloat(soilResistivityInput.text)/1000) ? 
                                (Universal.theme === Universal.Dark ? "#FF8080" : "red") : 
                                (Universal.theme === Universal.Dark ? "#80FF80" : "green")
                            ToolTip.text: "Step voltage potential (colored red if exceeds safety threshold)"
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                        }

                        Label { text: "Min. Conductor Size:" }
                        TextFieldBlue { 
                            text: calculator.conductorSize.toFixed(1) + " mm²"
                            ToolTip.text: "Minimum conductor cross-sectional area for thermal rating"
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                        }
                    }
                }
            }

            WaveCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                EarthingViz {
                    anchors.fill: parent
                    anchors.margins: 5
                    
                    gridLength: parseFloat(gridLengthInput.text || "20")
                    gridWidth: parseFloat(gridWidthInput.text || "20")
                    rodCount: rodCountInput.value
                    rodLength: parseFloat(rodLengthInput.text || "3")
                    gridResistance: calculator.gridResistance
                    
                    darkMode: Universal.theme === Universal.Dark
                    textColor: earthingCard.textColor
                }
            }
        }
    }
}
