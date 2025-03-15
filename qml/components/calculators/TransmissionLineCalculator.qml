import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"   
import Transmission 1.0

Item {
    id: transmissionCard

    property TransmissionLineCalculator calculator: TransmissionLineCalculator {}
    property color textColor: Universal.foreground
    property int colWidth: 195

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Left side - inputs and results
        ColumnLayout {
            Layout.maximumWidth: 350
            Layout.alignment: Qt.AlignTop
            spacing: 10

            // Line Parameters
            WaveCard {
                title: "Line Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 300

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

                    Label { 
                        text: "Length (km):"
                        Layout.minimumWidth: colWidth
                        }
                    TextField {
                        id: lengthInput
                        text: "100"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setLength(parseFloat(text))
                        Layout.minimumWidth: 100
                    }

                    Label { text: "Resistance (Ω/km):" }
                    TextField {
                        id: resistanceInput
                        text: "0.1"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setResistance(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Inductance (mH/km):" }
                    TextField {
                        id: inductanceInput
                        text: "1.0"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setInductance(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Capacitance (µF/km):" }
                    TextField {
                        id: capacitanceInput
                        text: "0.01"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setCapacitance(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Conductance (S/km):" }
                    TextField {
                        id: conductanceInput
                        text: "0"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setConductance(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Frequency (Hz):" }
                    TextField {
                        id: frequencyInput
                        text: "50"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setFrequency(parseFloat(text))
                        Layout.fillWidth: true
                    }
                }
            }

            WaveCard {
                title: "Advanced Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 210
                Layout.minimumWidth: 300

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

                    Label { 
                        text: "Bundle Configuration:" 
                        Layout.minimumWidth: colWidth
                        }
                    SpinBox {
                        id: subConductors
                        from: 1
                        to: 4
                        value: 2
                        onValueChanged: calculator.setSubConductors(value)
                        Layout.minimumWidth: 100
                        Layout.fillWidth: true
                    }

                    Label { text: "Bundle Spacing (m):" }
                    TextField {
                        id: bundleSpacing
                        text: "0.4"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setBundleSpacing(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Conductor Temperature (°C):" }
                    TextField {
                        id: conductorTemp
                        text: "75"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setConductorTemperature(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Earth Resistivity (Ω⋅m):" }
                    TextField {
                        id: earthResistivity
                        text: "100"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.setEarthResistivity(parseFloat(text))
                        Layout.fillWidth: true
                    }
                }
            }

            // Results
            WaveCard {
                title: "Results"
                Layout.fillWidth: true
                Layout.minimumHeight: 150

                GridLayout {
                    columns: 2
                    rowSpacing: 15
                    columnSpacing: 10

                    Label { text: "Characteristic Impedance:" }
                    Label { 
                        text: calculator.zMagnitude.toFixed(2) + " Ω ∠" + 
                              calculator.zAngle.toFixed(1) + "°"
                        font.bold: true
                    }

                    Label { text: "Attenuation Constant:" }
                    Label { text: calculator.attenuationConstant.toFixed(4) + " Np/km" ; font.bold: true}

                    Label { text: "Phase Constant:" }
                    Label { text: calculator.phaseConstant.toFixed(4) + " rad/km" ; font.bold: true}
                }
            }

            WaveCard {
                title: "ABCD Results"
                Layout.fillWidth: true
                Layout.minimumHeight: 370
            
                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

                    Label { text: "A:" }
                    Label { 
                        text: calculator.aMagnitude.toFixed(3) + " ∠" + calculator.aAngle.toFixed(1) + "°" 
                        font.bold: true
                        }
                    Label { text: "B:"}
                    Label { 
                        text: calculator.bMagnitude.toFixed(3) + " ∠" + calculator.bAngle.toFixed(1) + "°" ; font.bold: true
                        }
                    Label { text: "C:"}
                    Label { 
                        text: calculator.cMagnitude.toFixed(3) + " ∠" + calculator.cAngle.toFixed(1) + "°" ; font.bold: true
                        }
                    Label { text: "D:"}
                    Label { 
                        text: calculator.dMagnitude.toFixed(3) + " ∠" + calculator.dAngle.toFixed(1) + "°" ; font.bold: true
                        }

                    Label { text: "SIL:"}
                    Label { 
                        text: calculator.surgeImpedanceLoading.toFixed(1) + " MW"
                        color: Universal.foreground
                        font.bold: true
                    }
                }
            }
        }

        // Right side - Visualization
        WaveCard {
            Layout.fillHeight: true
            Layout.fillWidth: true
            title: "Visualization"

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
