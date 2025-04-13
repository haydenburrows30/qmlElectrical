import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal


import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

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
    
    // Add info popup for conductance impact with improved visibility
    PopUpText {
        id: conductanceInfoPopup
        parentCard: parametersCard
        visible: false  // Start hidden
        popupText: "Higher conductance decreases the characteristic impedance magnitude and " +
                   "affects its phase angle. This represents leakage current through insulation.\n\n" +
                   "Formula: Z₀ = √(Z/Y) where Y = G + jωC\n" +
                   "• Higher G (conductance) increases losses\n" +
                   "• Higher G decreases surge impedance loading\n" +
                   "• Typical transmission lines have very low conductance\n\n" +
                   "Typical values:\n" +
                   "• 0.00001 S/km (dry weather, good insulation)\n" +
                   "• 0.001 S/km (wet weather, light pollution)\n" +
                   "• 0.01 S/km (heavy pollution, salt spray areas)"
        
        function show() {
            visible = true;
        }
    }

    // Add info popup for parameter explanations
    PopUpText {
        id: resultsInfoPopup
        parentCard: parametersCard
        visible: false  // Start hidden
        popupText: "Transmission Line Parameters Explained:\n\n" +
                   "• Characteristic Impedance (Z₀): Depends on R, L, G, C per unit length, but NOT on line length\n" +
                   "• ABCD Parameters: DO depend on line length, frequency, and other parameters\n" +
                   "• Surge Impedance Loading (SIL): The power delivered when terminated with Z₀\n\n" +
                   "Changing line length affects:\n" +
                   "• ABCD parameters\n" +
                   "• Total line impedance\n" +
                   "• Receiving end voltage and current\n\n" +
                   "But does NOT affect characteristic impedance Z₀."
        
        function show() {
            visible = true;
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
                    Layout.maximumWidth: 370
                    Layout.preferredWidth: 370

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

                                // Conductance label with info button
                                RowLayout {
                                    Layout.minimumWidth: 200
                                    
                                    Label { 
                                        text: "Conductance (S/km):"
                                        Layout.fillWidth: true
                                    }
                                    
                                    Rectangle {
                                        width: 16
                                        height: 16
                                        radius: width/2
                                        color: Universal.accent
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "i"
                                            color: "white"
                                            font.bold: true
                                            font.pixelSize: 12
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: conductanceInfoPopup.show()
                                            
                                            ToolTip {
                                                visible: parent.containsMouse
                                                text: "Click for info about conductance"
                                            }
                                        }
                                    }
                                }
                                
                                TextFieldRound {
                                    id: conductanceInput
                                    text: "0.00001"  // Typical value for dry conditions
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: if(text && acceptableInput) calculator.setConductance(parseFloat(text))
                                    Layout.fillWidth: true
                                    hoverEnabled: true
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Typical values: 0.00001-0.0001 S/km (dry conditions), 0.001-0.01 S/km (wet conditions)"
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
                            SpinBoxRound {
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
                        showSettings: true
                        
                        // Add info button to results card
                        RowLayout {
                            id: resultInfoButton
                            x: parent.width - width - 10
                            y: 5
                            width: 30
                            height: 20
                            
                            Rectangle {
                                width: 20
                                height: 20
                                radius: width/2
                                color: Universal.accent
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "?"
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 12
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: resultsInfoPopup.show()
                                    
                                    ToolTip {
                                        visible: parent.containsMouse
                                        text: "Click for explanation of parameter relationships"
                                    }
                                }
                            }
                        }

                        GridLayout {
                            columns: 2

                            Label { 
                                text: "Characteristic Impedance:"
                                Layout.minimumWidth: 200
                                Layout.alignment: Qt.AlignRight
                            }

                            TextFieldBlue { 
                                id: impedanceField
                                text: calculator.zMagnitude.toFixed(2) + " Ω ∠" + 
                                    calculator.zAngle.toFixed(1) + "°"
                                Layout.minimumWidth: 120
                                Layout.alignment: Qt.AlignRight
                                Connections {
                                    target: calculator
                                    function onResultsCalculated() {
                                        impedanceField.text = calculator.zMagnitude.toFixed(2) + " Ω ∠" + 
                                                           calculator.zAngle.toFixed(1) + "°"
                                    }
                                }
                                ToolTip.visible: hovered
                                ToolTip.text: "Characteristic impedance is independent of line length. It only depends on the line's per-unit-length parameters."
                                hoverEnabled: true
                            }

                            Label { text: "Attenuation Constant:" }
                            TextFieldBlue { 
                                id: attenuationField
                                text: calculator.attenuationConstant.toFixed(6) + " Np/km"
                                Connections {
                                    target: calculator
                                    function onResultsCalculated() {
                                        attenuationField.text = calculator.attenuationConstant.toFixed(6) + " Np/km"
                                    }
                                }
                            }

                            Label { text: "Phase Constant:" }
                            TextFieldBlue { 
                                id: phaseField
                                text: calculator.phaseConstant.toFixed(4) + " rad/km"
                                Connections {
                                    target: calculator
                                    function onResultsCalculated() {
                                        phaseField.text = calculator.phaseConstant.toFixed(4) + " rad/km"
                                    }
                                }
                            }
                            
                            Label { text: "Surge Impedance Loading:" }
                            TextFieldBlue { 
                                id: silField
                                text: calculator.surgeImpedanceLoading.toFixed(1) + " MW"
                                Connections {
                                    target: calculator
                                    function onResultsCalculated() {
                                        silField.text = calculator.surgeImpedanceLoading.toFixed(1) + " MW"
                                    }
                                    function onSilCalculated() {
                                        silField.text = calculator.surgeImpedanceLoading.toFixed(1) + " MW"
                                    }
                                }
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
                                text: "A Parameter:"
                                Layout.minimumWidth: 180
                            }
                            TextFieldBlue { 
                                id: aParameterField
                                text: calculator.aMagnitude.toFixed(3) + " ∠" + calculator.aAngle.toFixed(1) + "°"
                                Layout.minimumWidth: 150
                                Layout.alignment: Qt.AlignRight
                                Connections {
                                    target: calculator
                                    function onResultsCalculated() {
                                        aParameterField.text = calculator.aMagnitude.toFixed(3) + " ∠" + 
                                                              calculator.aAngle.toFixed(1) + "°"
                                    }
                                }
                            }

                            Label { text: "B Parameter:" }
                            TextFieldBlue { 
                                id: bParameterField
                                text: calculator.bMagnitude.toFixed(3) + " ∠" + calculator.bAngle.toFixed(1) + "°"
                                Layout.alignment: Qt.AlignRight
                                Connections {
                                    target: calculator
                                    function onResultsCalculated() {
                                        bParameterField.text = calculator.bMagnitude.toFixed(3) + " ∠" + 
                                                              calculator.bAngle.toFixed(1) + "°"
                                    }
                                }
                            }

                            Label { text: "C Parameter:" }
                            TextFieldBlue { 
                                id: cParameterField
                                text: calculator.cMagnitude.toFixed(6) + " ∠" + calculator.cAngle.toFixed(1) + "°"
                                Connections {
                                    target: calculator
                                    function onResultsCalculated() {
                                        cParameterField.text = calculator.cMagnitude.toFixed(6) + " ∠" + 
                                                              calculator.cAngle.toFixed(1) + "°"
                                    }
                                }
                            }

                            Label { text: "D Parameter:" }
                            TextFieldBlue { 
                                id: dParameterField
                                text: calculator.dMagnitude.toFixed(3) + " ∠" + calculator.dAngle.toFixed(1) + "°"
                                Connections {
                                    target: calculator
                                    function onResultsCalculated() {
                                        dParameterField.text = calculator.dMagnitude.toFixed(3) + " ∠" + 
                                                              calculator.dAngle.toFixed(1) + "°"
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Right side - Visualization - Fix layout issues
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    WaveCard {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        title: "Line Parameters Visualization"
                        
                        // This ensures a minimum size for the visualization to render properly
                        Layout.minimumWidth: 300
                        Layout.minimumHeight: 400

                        TransmissionLineViz {
                            anchors.fill: parent
                            anchors.margins: 5
                            
                            // Pass all required properties correctly
                            length: parseFloat(lengthInput.text || "100")
                            characteristicImpedance: calculator.characteristicImpedance
                            attenuationConstant: calculator.attenuationConstant
                            phaseConstant: calculator.phaseConstant
                            
                            // Make sure calculator is passed to the visualization
                            calculator: transmissionCard.calculator
                            
                            darkMode: Universal.theme === Universal.Dark
                            textColor: transmissionCard.textColor
                            
                            // Add debug output
                            Component.onCompleted: {
                                console.log("TransmissionLineViz initialized")
                                console.log("Size:", width, "x", height)
                                console.log("Calculator reference:", calculator ? "valid" : "null")
                            }
                        }
                    }
                }
            }
        }
    }
}
