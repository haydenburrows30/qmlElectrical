import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"
import "../visualizers/"
import "../style"
import "../popups"

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

    TransmissionPopUp {
        id: tipsPopup
    }

    PopUpText {
        parentCard: results
        popupText: "A = Open circuit voltage ratio\nB = Transfer impedance\n" +
                                      "C = Transfer admittance\nD = Short circuit current ratio"
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
                    Layout.maximumWidth: 370

                    // Basic Line Parameters
                    WaveCard {
                        id: parametersCard
                        title: "Line Parameters"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 320
                        showSettings: true

                        ColumnLayout {

                            GridLayout {
                                columns: 2
                                Layout.fillWidth: true

                                Label { 
                                    text: "Length (km):"
                                    Layout.minimumWidth: 200
                                    Layout.alignment: Qt.AlignRight
                                }
                                TextFieldRound {
                                    id: lengthInput
                                    text: "100"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setLength(parseFloat(text))
                                    Layout.minimumWidth: 120
                                    Layout.alignment: Qt.AlignRight
                                }

                                Label { text: "Resistance (Ω/km):" }
                                TextFieldRound {
                                    id: resistanceInput
                                    text: "0.1"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setResistance(parseFloat(text))
                                    Layout.fillWidth: true
                                }

                                Label { text: "Inductance (mH/km):" }
                                TextFieldRound {
                                    id: inductanceInput
                                    text: "1.0"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setInductance(parseFloat(text))
                                    Layout.fillWidth: true
                                }

                                Label { text: "Capacitance (µF/km):" }
                                TextFieldRound {
                                    id: capacitanceInput
                                    text: "0.01"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setCapacitance(parseFloat(text))
                                    Layout.fillWidth: true
                                }

                                Label { text: "Conductance (S/km):" }
                                TextFieldRound {
                                    id: conductanceInput
                                    text: "0"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setConductance(parseFloat(text))
                                    Layout.fillWidth: true
                                }

                                Label { text: "Frequency (Hz):" }
                                TextFieldRound {
                                    id: frequencyInput
                                    text: "50"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setFrequency(parseFloat(text))
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Nominal Voltage (kV):" }
                                TextFieldRound {
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
                        Layout.minimumHeight: 250
                        Layout.minimumWidth: 300

                        GridLayout {
                            columns: 2

                            Label { 
                                text: "Bundle Configuration:" 
                                Layout.minimumWidth: 200
                            }
                            SpinBox {
                                id: subConductors
                                from: 1
                                to: 4
                                value: 2
                                onValueChanged: calculator.setSubConductors(value)
                                Layout.minimumWidth: 120
                                Layout.fillWidth: true
                            }

                            Label { text: "Bundle Spacing (m):" }
                            TextFieldRound {
                                id: bundleSpacing
                                text: "0.4"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(text && acceptableInput) calculator.setBundleSpacing(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label { text: "Conductor GMR (m):" }
                            TextFieldRound {
                                id: conductorGMR
                                text: "0.0078"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(text && acceptableInput) calculator.setConductorGMR(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label { text: "Conductor Temperature (°C):" }
                            TextFieldRound {
                                id: conductorTemp
                                text: "75"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(text && acceptableInput) calculator.setConductorTemperature(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label { text: "Earth Resistivity (Ω⋅m):" }
                            TextFieldRound {
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
                        Layout.minimumHeight: 220

                        GridLayout {
                            columns: 2

                            Label { 
                                text: "Characteristic Impedance:"
                                Layout.minimumWidth: 200
                                Layout.alignment: Qt.AlignRight
                            }

                            TextFieldBlue { 
                                text: calculator.zMagnitude.toFixed(2) + " Ω ∠" + 
                                    calculator.zAngle.toFixed(1) + "°"
                                Layout.minimumWidth: 120
                                Layout.alignment: Qt.AlignRight
                            }

                            Label { text: "Attenuation Constant:" }
                            TextFieldBlue { text: calculator.attenuationConstant.toFixed(6) + " Np/km"}

                            Label { text: "Phase Constant:" }
                            TextFieldBlue { text: calculator.phaseConstant.toFixed(4) + " rad/km"}
                            
                            Label { text: "Surge Impedance Loading:" }
                            TextFieldBlue { 
                                text: calculator.surgeImpedanceLoading.toFixed(1) + " MW"
                            }
                        }
                    }

                    // ABCD Results
                    WaveCard {
                        id: results
                        title: "ABCD Parameters"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 230

                        showSettings: true
                    
                        GridLayout {
                            columns: 2

                            Label { 
                                text: "A Parameter:" ; 
                                Layout.minimumWidth: 180
                            }

                            TextFieldBlue { 
                                text: calculator.aMagnitude.toFixed(3) + " ∠" + calculator.aAngle.toFixed(1) + "°"
                                Layout.minimumWidth: 150
                                Layout.alignment: Qt.AlignRight
                            }
                            
                            Label { text: "B Parameter:" }
                            TextFieldBlue { 
                                text: calculator.bMagnitude.toFixed(3) + " ∠" + calculator.bAngle.toFixed(1) + "°"
                                Layout.alignment: Qt.AlignRight
                            }
                            
                            Label { text: "C Parameter:" }
                            TextFieldBlue { 
                                text: calculator.cMagnitude.toFixed(6) + " ∠" + calculator.cAngle.toFixed(1) + "°"
                            }
                            
                            Label { text: "D Parameter:" }
                            TextFieldBlue { 
                                text: calculator.dMagnitude.toFixed(3) + " ∠" + calculator.dAngle.toFixed(1) + "°"
                            }
                        }
                    }
                }

                // Right side - Visualization
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
