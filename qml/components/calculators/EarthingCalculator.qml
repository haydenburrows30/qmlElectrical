import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import "../visualizers/"
import "../backgrounds"
import "../style"
import "../backgrounds"

import Earthing 1.0

Item {
    id: earthingCard

    property EarthingCalculator calculator: EarthingCalculator {}
    property color textColor: Universal.foreground

    Popup {
        id: tipsPopup
        width: 700
        height: 500
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: results.open

        onAboutToHide: {
            results.open = false
        }
        Text {
            anchors.fill: parent
            text: {"<h3>Earthing System Calculator</h3><br>" +
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
                    "The calculator provides the grid resistance, ground rise, touch voltage, step voltage, and minimum conductor size for the earthing system.<br><br>" +
                    "The visualization shows the earthing system with the grid and ground rods.<br><br>" +
                    "Developed by <b>Wave</b>."
            }
            wrapMode: Text.WordWrap
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: Style.spacing

        // Left side - inputs and results
        ColumnLayout {
            Layout.maximumWidth: 300
            Layout.alignment: Qt.AlignTop
            spacing: Style.spacing

            // Grid Parameters
            WaveCard {
                title: "Grid Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 220

                id: results
                showSettings: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

                    Label { text: "Soil Resistivity (Ω⋅m):" ; Layout.minimumWidth: 150}
                    TextField {
                        id: soilResistivityInput
                        text: "100"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setSoilResistivity(parseFloat(text))
                        Layout.minimumWidth: 100
                    }

                    Label { text: "Grid Depth (m):" }
                    TextField {
                        id: gridDepthInput
                        text: "0.5"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setGridDepth(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Grid Length (m):" }
                    TextField {
                        id: gridLengthInput
                        text: "20"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setGridLength(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Grid Width (m):" }
                    TextField {
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
                    rowSpacing: 10
                    columnSpacing: 10

                    Label { text: "Rod Length (m):" ; Layout.minimumWidth: 150}
                    TextField {
                        id: rodLengthInput
                        text: "3"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setRodLength(parseFloat(text))
                        Layout.minimumWidth: 100
                    }

                    Label { text: "Number of Rods:" }
                    SpinBox {
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
                    rowSpacing: 10
                    columnSpacing: 10

                    Label { text: "Fault Current (A):" ;Layout.minimumWidth: 150}
                    TextField {
                        id: faultCurrentInput
                        text: "10000"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setFaultCurrent(parseFloat(text))
                        Layout.minimumWidth: 100
                    }

                    Label { text: "Fault Duration (s):" }
                    TextField {
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
                    TextField{ 
                        text: calculator.gridResistance.toFixed(3) + " Ω"
                        Layout.minimumWidth: 100
                        readOnly: true
                        background: ProtectionRectangle {}
                    }

                    Label { text: "Ground Rise:" }
                    TextField { 
                        text: calculator.voltageRise.toFixed(1) + " V"
                        Layout.fillWidth: true
                        readOnly: true
                        background: ProtectionRectangle {}
                    }

                    Label { text: "Touch Voltage:" }
                    TextField { 
                        text: calculator.touchVoltage.toFixed(1) + " V"
                        color: Universal.theme === Universal.Dark ? "#FF8080" : "red"
                        Layout.fillWidth: true
                        readOnly: true
                        background: ProtectionRectangle {}
                    }

                    Label { text: "Step Voltage:" }
                    TextField { 
                        text: calculator.stepVoltage.toFixed(1) + " V"
                        color: Universal.theme === Universal.Dark ? "#FF8080" : "red"
                        Layout.fillWidth: true
                        readOnly: true
                        background: ProtectionRectangle {}
                    }

                    Label { text: "Min. Conductor Size:" }
                    TextField { 
                        text: calculator.conductorSize.toFixed(1) + " mm²"
                        Layout.fillWidth: true
                        readOnly: true
                        background: ProtectionRectangle {}
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
