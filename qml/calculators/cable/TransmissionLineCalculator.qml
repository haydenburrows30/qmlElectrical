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

    PopUpText {
        id: conductanceInfoPopup
        parentCard: parametersCard
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
    }

    PopUpText {
        id: resultsInfoPopup
        parentCard: resultsCard
        popupText: "Transmission Line Parameters Explained:\n\n" +
                   "• Characteristic Impedance (Z₀): Depends on R, L, G, C per unit length, but NOT on line length\n" +
                   "• ABCD Parameters: DO depend on line length, frequency, and other parameters\n" +
                   "• Surge Impedance Loading (SIL): The power delivered when terminated with Z₀\n\n" +
                   "Changing line length affects:\n" +
                   "• ABCD parameters\n" +
                   "• Total line impedance\n" +
                   "• Receiving end voltage and current\n\n" +
                   "But does NOT affect characteristic impedance Z₀."
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        Flickable {
            id: flickableMain
            contentWidth: parent.width
            contentHeight: mainLayout.height + 20
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            ColumnLayout {
                id: mainLayout
                // width: flickableMain.width - 20
                anchors.centerIn: parent

                // Header with title and help button
                RowLayout {
                    id: topHeader
                    Layout.fillWidth: true
                    Layout.bottomMargin: 5
                    Layout.leftMargin: 5

                    Label {
                        text: "Transmission Line Calculator"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    StyledButton {
                        ToolTip.text: "Export report to PDF"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        Layout.alignment: Qt.AlignRight
                        icon.source: "../../../icons/rounded/download.svg"

                        onClicked: {
                            if (calculator) {
                                calculator.exportReport()
                            }
                        }
                    }

                    StyledButton {
                        id: helpButton
                        visible: false
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Information"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: popUpText.open()
                    }
                }

                RowLayout {
                    id: resultsRow
                    Layout.minimumWidth: 650

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

                            GridLayout {
                                columns: 2
                                anchors.fill: parent

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
                                            onClicked: conductanceInfoPopup.open()
                                            
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
                    }

                    ColumnLayout {
                        Layout.maximumWidth: 400
                        Layout.preferredWidth: 400
                        Layout.alignment: Qt.AlignTop

                        // Results
                        WaveCard {
                            id: resultsCard
                            title: "Results"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 220
                            showSettings: true

                            GridLayout {
                                columns: 2

                                Label { 
                                    text: "Characteristic Impedance (Z₀):"
                                    Layout.minimumWidth: 200
                                    Layout.alignment: Qt.AlignLeft
                                }

                                TextFieldBlue { 
                                    id: impedanceField
                                    text: calculator.zMagnitude.toFixed(2) + " Ω ∠" + 
                                        calculator.zAngle.toFixed(1) + "°"
                                    Layout.minimumWidth: 120
                                    Layout.alignment: Qt.AlignRight
                                    verticalAlignment: TextInput.AlignBottom
                                    bottomPadding: 1
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

                                Label { text: "Attenuation Constant (α):" }
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

                                Label { text: "Phase Constant (β):" }
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
                                
                                Label { text: "Surge Impedance Loading (SIL):" }
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
                                    verticalAlignment: TextInput.AlignBottom
                                    bottomPadding: 1
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
                                    verticalAlignment: TextInput.AlignBottom
                                    bottomPadding: 1
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
                                    verticalAlignment: TextInput.AlignBottom
                                    bottomPadding: 1
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
                                    verticalAlignment: TextInput.AlignBottom
                                    bottomPadding: 1
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
                }

                // Visualization
                ColumnLayout {
                    Layout.minimumHeight: 400
                    Layout.maximumWidth: resultsRow.width

                    WaveCard {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        title: "Line Parameters Visualization"

                        TransmissionLineViz {
                            anchors.fill: parent
                            anchors.margins: 0

                            length: parseFloat(lengthInput.text || "100")
                            characteristicImpedance: calculator.characteristicImpedance
                            attenuationConstant: calculator.attenuationConstant
                            phaseConstant: calculator.phaseConstant

                            calculator: transmissionCard.calculator

                            darkMode: Universal.theme === Universal.Dark
                            textColor: transmissionCard.textColor
                        }
                    }
                }
            }
        }
    }

    MessagePopup {
        id: messagePopup
        anchors.centerIn: parent
    }

    Connections {
        target: calculator
        
        function onExportComplete(success, message) {
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
    }
}
