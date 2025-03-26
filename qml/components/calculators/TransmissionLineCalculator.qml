import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import "../visualizers/"
import "../style"
import "../backgrounds"

import Transmission 1.0

Item {
    id: transmissionCard

    property TransmissionLineCalculator calculator: TransmissionLineCalculator {}
    property color textColor: Universal.foreground
    property int colWidth: 195

    // Initialize inputs when component is loaded
    Component.onCompleted: {
        initializeFields()
    }
    
    function initializeFields() {
        // Set input fields from calculator model
        lengthInput.text = calculator.length.toString()
        resistanceInput.text = calculator.resistance.toString()
        inductanceInput.text = calculator.inductance.toString()
        capacitanceInput.text = calculator.capacitance.toString()
        conductanceInput.text = calculator.conductance.toString()
        frequencyInput.text = calculator.frequency.toString()
        
        // Advanced parameters
        subConductors.value = calculator.subConductors
        bundleSpacing.text = calculator.bundleSpacing.toString()
        conductorTemp.text = calculator.conductorTemperature.toString()
        earthResistivity.text = calculator.earthResistivity.toString()
        
        // Additional parameters
        conductorGMR.text = calculator.conductorGMR.toString()
        nominalVoltage.text = calculator.nominalVoltage.toString()
    }

    Popup {
        id: tipsPopup
        width: parent.width * 0.8
        height: parent.height * 0.8
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: results.open

        onAboutToHide: {
            results.open = false
        }
        ScrollView {
            width: parent.width
            height: parent.height
            
            Text {
                anchors.fill: parent
                text: {"Transmission Line Calculator\n\n" +
                    "This calculator is used to calculate the characteristic impedance, attenuation constant, phase constant, and ABCD parameters of a transmission line.\n\n" +
                    "The following parameters are required:\n" +
                    "1. Length (km): The length of the transmission line in kilometers.\n" +
                    "2. Resistance (Ω/km): The resistance of the transmission line in ohms per kilometer.\n" +
                    "3. Inductance (mH/km): The inductance of the transmission line in millihenries per kilometer.\n" +
                    "4. Capacitance (µF/km): The capacitance of the transmission line in microfarads per kilometer.\n" +
                    "5. Conductance (S/km): The conductance of the transmission line in siemens per kilometer.\n" +
                    "6. Frequency (Hz): The frequency of the transmission line in hertz.\n" +
                    "7. Bundle Configuration: The number of sub-conductors in the transmission line bundle.\n" +
                    "8. Bundle Spacing (m): The spacing between the sub-conductors in the transmission line bundle in meters.\n" +
                    "9. Conductor Temperature (°C): The temperature of the transmission line conductor in degrees Celsius.\n" +
                    "10. Earth Resistivity (Ω⋅m): The resistivity of the earth in ohm-meters.\n\n" +
                    "The following results are calculated:\n" +
                    "1. Characteristic Impedance: The characteristic impedance of the transmission line.\n" +
                    "2. Attenuation Constant: The attenuation constant of the transmission line in nepers per kilometer.\n" +
                    "3. Phase Constant: The phase constant of the transmission line in radians per kilometer.\n" +
                    "4. ABCD Parameters: The ABCD parameters of the transmission line.\n" +
                    "5. Surge Impedance Loading: The surge impedance loading of the transmission line in megawatts.\n\n" +
                    "The visualization on the right side shows the transmission line parameters graphically.\n\n" +
                    "The calculator uses the following formulas:\n" +
                    "1. Characteristic Impedance: Zc = sqrt((R + jωL) / (G + jωC))\n" +
                    "2. Attenuation Constant: α = sqrt((R + jωL)(G + jωC))\n" +
                    "3. Phase Constant: β = sqrt((R + jωL)(G + jωC))\n" +
                    "4. ABCD Parameters: A = cosh(γl), B = Zc * sinh(γl), C = (1 / Zc) * sinh(γl), D = cosh(γl)\n" +
                    "5. Surge Impedance Loading: SIL = sqrt((R + jωL) / (G + jωC))\n\n" +
                    "Where:\n" +
                    "Zc = Characteristic Impedance α = Attenuation Constant\n" +
                    "β = Phase Constant\n" +
                    "γ = sqrt((R + jωL)(G + jωC))\n" +
                    "l = Length of the transmission line\n" +
                    "R = Resistance\n" +
                    "L = Inductance\n" +
                    "G = Conductance\n" +
                    "C = Capacitance\n" +
                    "ω = 2πf\n" +
                    "f = Frequency\n" +
                    "SIL = Surge Impedance Loading\n\n" +
                    "The calculator is based on the transmission line theory and is used in electrical engineering to analyze the behavior of transmission lines.\n\n" +
                    "For more information, refer to the IEEE Standard 141-1993 (Red Book) and the IEEE Standard 242-2001 (Gold Book)."}
                wrapMode: Text.WordWrap
            }
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            RowLayout {
                id: mainLayout
                width: scrollView.width

                ColumnLayout {
                    Layout.maximumWidth: 350
                    Layout.alignment: Qt.AlignTop
                    spacing: Style.spacing

                    // Basic Line Parameters
                    WaveCard {
                        id: results
                        title: "Line Parameters"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 380
                        showSettings: true

                        ColumnLayout {
                            spacing: 5
                            anchors.fill: parent
                            anchors.margins: 5

                            GridLayout {
                                columns: 2
                                rowSpacing: 10
                                columnSpacing: 15
                                Layout.fillWidth: true

                                Label { 
                                    text: "Length (km):"
                                    Layout.minimumWidth: colWidth
                                }
                                TextField {
                                    id: lengthInput
                                    text: "100"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setLength(parseFloat(text))
                                    Layout.minimumWidth: 100
                                }

                                Label { text: "Resistance (Ω/km):" }
                                TextField {
                                    id: resistanceInput
                                    text: "0.1"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setResistance(parseFloat(text))
                                    Layout.fillWidth: true
                                }

                                Label { text: "Inductance (mH/km):" }
                                TextField {
                                    id: inductanceInput
                                    text: "1.0"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setInductance(parseFloat(text))
                                    Layout.fillWidth: true
                                }

                                Label { text: "Capacitance (µF/km):" }
                                TextField {
                                    id: capacitanceInput
                                    text: "0.01"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setCapacitance(parseFloat(text))
                                    Layout.fillWidth: true
                                }

                                Label { text: "Conductance (S/km):" }
                                TextField {
                                    id: conductanceInput
                                    text: "0"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setConductance(parseFloat(text))
                                    Layout.fillWidth: true
                                }

                                Label { text: "Frequency (Hz):" }
                                TextField {
                                    id: frequencyInput
                                    text: "50"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setFrequency(parseFloat(text))
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Nominal Voltage (kV):" }
                                TextField {
                                    id: nominalVoltage
                                    text: "400"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setNominalVoltage(parseFloat(text))
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    // Advanced Parameters
                    WaveCard {
                        title: "Advanced Parameters"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 280
                        Layout.minimumWidth: 300

                        GridLayout {
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 15
                            anchors.fill: parent
                            anchors.margins: 5

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
                                onTextChanged: if(text && acceptableInput) calculator.setBundleSpacing(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label { text: "Conductor GMR (m):" }
                            TextField {
                                id: conductorGMR
                                text: "0.0078"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(text && acceptableInput) calculator.setConductorGMR(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label { text: "Conductor Temperature (°C):" }
                            TextField {
                                id: conductorTemp
                                text: "75"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(text && acceptableInput) calculator.setConductorTemperature(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label { text: "Earth Resistivity (Ω⋅m):" }
                            TextField {
                                id: earthResistivity
                                text: "100"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(text && acceptableInput) calculator.setEarthResistivity(parseFloat(text))
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Results
                    WaveCard {
                        title: "Results"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 200

                        GridLayout {
                            columns: 2
                            rowSpacing: 15
                            columnSpacing: 10
                            anchors.fill: parent
                            anchors.margins: 5

                            Label { text: "Characteristic Impedance:" }
                            Label { 
                                text: calculator.zMagnitude.toFixed(2) + " Ω ∠" + 
                                    calculator.zAngle.toFixed(1) + "°"
                                font.bold: true
                            }

                            Label { text: "Attenuation Constant:" }
                            Label { text: calculator.attenuationConstant.toFixed(6) + " Np/km" ; font.bold: true}

                            Label { text: "Phase Constant:" }
                            Label { text: calculator.phaseConstant.toFixed(4) + " rad/km" ; font.bold: true}
                            
                            Label { text: "Surge Impedance Loading:" }
                            Label { 
                                text: calculator.surgeImpedanceLoading.toFixed(1) + " MW"
                                color: Universal.accent
                                font.bold: true
                            }
                        }
                    }

                    // ABCD Results
                    WaveCard {
                        title: "ABCD Parameters"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 350
                    
                        GridLayout {
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 15
                            anchors.fill: parent
                            anchors.margins: 5

                            Label { text: "A Parameter:" }
                            Label { 
                                text: calculator.aMagnitude.toFixed(3) + " ∠" + calculator.aAngle.toFixed(1) + "°" 
                                font.bold: true
                            }
                            
                            Label { text: "B Parameter:" }
                            Label { 
                                text: calculator.bMagnitude.toFixed(3) + " ∠" + calculator.bAngle.toFixed(1) + "°"
                                font.bold: true
                            }
                            
                            Label { text: "C Parameter:" }
                            Label { 
                                text: calculator.cMagnitude.toFixed(6) + " ∠" + calculator.cAngle.toFixed(1) + "°"
                                font.bold: true
                            }
                            
                            Label { text: "D Parameter:" }
                            Label { 
                                text: calculator.dMagnitude.toFixed(3) + " ∠" + calculator.dAngle.toFixed(1) + "°"
                                font.bold: true
                            }
                            
                            // Info about ABCD parameters
                            Rectangle {
                                color: "transparent"
                                height: 1
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                            }
                            
                            Label {
                                text: "ABCD Parameter Interpretation:"
                                font.bold: true
                                Layout.columnSpan: 2
                            }
                            
                            TextArea {
                                text: "A = Open circuit voltage ratio\nB = Transfer impedance\n" +
                                      "C = Transfer admittance\nD = Short circuit current ratio"
                                readOnly: true
                                background: null
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Right side - Visualization
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    
                    WaveCard {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        title: "Line Parameters Visualization"

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
        }
    }
}
