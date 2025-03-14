import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import Earthing 1.0

WaveCard {
    id: earthingCard
    title: 'Earthing System Calculator'

    property EarthingCalculator calculator: EarthingCalculator {}
    property color textColor: Universal.foreground

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 15

        // Left side - inputs and results
        ColumnLayout {
            // Layout.preferredWidth: 300
            Layout.alignment: Qt.AlignTop
            spacing: 10

            // Grid Parameters
            GroupBox {
                title: "Grid Parameters"

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
            GroupBox {
                title: "Ground Rods"

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

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
            GroupBox {
                title: "Fault Parameters"

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

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
            GroupBox {
                title: "Results"

                GridLayout {
                    columns: 2
                    rowSpacing: 5
                    columnSpacing: 15

                    Label { text: "Grid Resistance:" ;Layout.minimumWidth: 150}
                    Label { 
                        text: calculator.gridResistance.toFixed(3) + " Ω"
                        color: Universal.foreground
                        Layout.minimumWidth: 100
                    }

                    Label { text: "Ground Rise:" }
                    Label { 
                        text: calculator.voltageRise.toFixed(1) + " V"
                        color: Universal.foreground
                    }

                    Label { text: "Touch Voltage:" }
                    Label { 
                        text: calculator.touchVoltage.toFixed(1) + " V"
                        color: Universal.theme === Universal.Dark ? "#FF8080" : "red"
                    }

                    Label { text: "Step Voltage:" }
                    Label { 
                        text: calculator.stepVoltage.toFixed(1) + " V"
                        color: Universal.theme === Universal.Dark ? "#FF8080" : "red"
                    }

                    Label { text: "Min. Conductor Size:" }
                    Label { 
                        text: calculator.conductorSize.toFixed(1) + " mm²"
                        color: Universal.foreground
                    }
                }
            }
        }

        // Right side - Visualization will be added in EarthingViz.qml
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Universal.background
            border.color: Universal.foreground
            border.width: 1

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
