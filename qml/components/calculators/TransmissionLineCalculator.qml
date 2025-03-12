import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"   
import Transmission 1.0

WaveCard {
    id: transmissionCard
    title: 'Transmission Line Calculator'

    property TransmissionLineCalculator calculator: TransmissionLineCalculator {}
    property color textColor: Universal.foreground

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 15

        // Left side - inputs and results
        ColumnLayout {
            Layout.preferredWidth: 350
            spacing: 10

            // Line Parameters
            GroupBox {
                title: "Line Parameters"

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

                    Label { text: "Length (km):" }
                    TextField {
                        id: lengthInput
                        text: "100"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setLength(parseFloat(text))
                    }

                    Label { text: "Resistance (Ω/km):" }
                    TextField {
                        id: resistanceInput
                        text: "0.1"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setResistance(parseFloat(text))
                    }

                    Label { text: "Inductance (mH/km):" }
                    TextField {
                        id: inductanceInput
                        text: "1.0"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setInductance(parseFloat(text))
                    }

                    Label { text: "Capacitance (µF/km):" }
                    TextField {
                        id: capacitanceInput
                        text: "0.01"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setCapacitance(parseFloat(text))
                    }

                    Label { text: "Conductance (S/km):" }
                    TextField {
                        id: conductanceInput
                        text: "0"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setConductance(parseFloat(text))
                    }

                    Label { text: "Frequency (Hz):" }
                    TextField {
                        id: frequencyInput
                        text: "50"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setFrequency(parseFloat(text))
                    }
                }
            }

            GroupBox {
                title: "Advanced Parameters"

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

                    Label { text: "Bundle Configuration:" }
                    SpinBox {
                        id: subConductors
                        from: 1
                        to: 4
                        value: 2
                        onValueChanged: calculator.setSubConductors(value)
                    }

                    Label { text: "Bundle Spacing (m):" }
                    TextField {
                        id: bundleSpacing
                        text: "0.4"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setBundleSpacing(parseFloat(text))
                    }

                    Label { text: "Conductor Temperature (°C):" }
                    TextField {
                        id: conductorTemp
                        text: "75"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setConductorTemperature(parseFloat(text))
                    }

                    Label { text: "Earth Resistivity (Ω⋅m):" }
                    TextField {
                        id: earthResistivity
                        text: "100"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setEarthResistivity(parseFloat(text))
                    }
                }
            }

            // Results
            GroupBox {
                title: "Results"

                GridLayout {
                    columns: 2
                    rowSpacing: 5
                    columnSpacing: 10

                    Label { text: "Characteristic Impedance:" }
                    Label { 
                        text: calculator.zMagnitude.toFixed(2) + " Ω ∠" + 
                              calculator.zAngle.toFixed(1) + "°"
                    }

                    Label { text: "Attenuation Constant:" }
                    Label { text: calculator.attenuationConstant.toFixed(4) + " Np/km" }

                    Label { text: "Phase Constant:" }
                    Label { text: calculator.phaseConstant.toFixed(4) + " rad/km" }

                    Label { text: "ABCD Parameters:" }
                    GridLayout {
                        columns: 2
                        Layout.columnSpan: 2

                        Label { text: "A = " + calculator.aMagnitude.toFixed(3) + " ∠" + calculator.aAngle.toFixed(1) + "°" }
                        Label { text: "B = " + calculator.bMagnitude.toFixed(3) + " ∠" + calculator.bAngle.toFixed(1) + "°" }
                        Label { text: "C = " + calculator.cMagnitude.toFixed(3) + " ∠" + calculator.cAngle.toFixed(1) + "°" }
                        Label { text: "D = " + calculator.dMagnitude.toFixed(3) + " ∠" + calculator.dAngle.toFixed(1) + "°" }
                    }

                    Label { text: "SIL:" }
                    Label { 
                        text: calculator.surgeImpedanceLoading.toFixed(1) + " MW"
                        color: Universal.foreground
                    }
                }
            }
        }

        // Right side - Visualization
        Rectangle {
            
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: Universal.background
            border.color: Universal.foreground
            border.width: 1

            TransmissionLineViz {
                anchors.fill: parent
                anchors.margins: 5
                
                length: parseFloat(lengthInput.text || "100")
                characteristicImpedance: calculator.characteristicImpedance
                attenuationConstant: calculator.attenuationConstant
                phaseConstant: calculator.phaseConstant
                
                darkMode: Universal.theme === Universal.Dark
                textColor: transmissionCard.textColor
            }
        }
    }
}
