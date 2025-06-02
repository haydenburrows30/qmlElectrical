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

    // Component.onCompleted: {
    //     // Initialize fields directly without using timers
    //     initializeFields()
    // }

    function initializeFields() {
        // Set input fields from calculator model with null safety
        if (calculator) {
            lengthInput.text = calculator.length !== undefined ? calculator.length.toString() : "100"
            resistanceInput.text = calculator.resistance !== undefined ? calculator.resistance.toString() : "0.1"
            inductanceInput.text = calculator.inductance !== undefined ? calculator.inductance.toString() : "1.0"
            capacitanceInput.text = calculator.capacitance !== undefined ? calculator.capacitance.toString() : "0.01"
            conductanceInput.text = calculator.conductance !== undefined ? calculator.conductance.toString() : "0.00001"
            frequencyInput.text = calculator.frequency !== undefined ? calculator.frequency.toString() : "50"
            
            // Advanced parameters
            if (subConductors && calculator.subConductors !== undefined)
                subConductors.value = calculator.subConductors
            
            bundleSpacing.text = calculator.bundleSpacing !== undefined ? calculator.bundleSpacing.toString() : "0.4"
            conductorTemp.text = calculator.conductorTemperature !== undefined ? calculator.conductorTemperature.toString() : "75"
            earthResistivity.text = calculator.earthResistivity !== undefined ? calculator.earthResistivity.toString() : "100"
            
            // Additional parameters
            conductorGMR.text = calculator.conductorGMR !== undefined ? calculator.conductorGMR.toString() : "0.0078"
            nominalVoltage.text = calculator.nominalVoltage !== undefined ? calculator.nominalVoltage.toString() : "400"
            
            // Add conductor spacing initialization
            conductorSpacing.text = calculator.conductorSpacing !== undefined ? calculator.conductorSpacing.toString() : "0.3"
            nominalMvaInput.text = calculator.nominalMVA !== undefined ? calculator.nominalMVA.toString() : "100"
            powerFactorInput.text = calculator.powerFactor !== undefined ? calculator.powerFactor.toString() : "0.9"
        } else {
            // Fallback default values if calculator isn't available
            lengthInput.text = "100"
            resistanceInput.text = "0.1"
            inductanceInput.text = "1.0"
            capacitanceInput.text = "0.01"
            conductanceInput.text = "0.00001"
            frequencyInput.text = "50"
            
            if (subConductors) subConductors.value = 2
            bundleSpacing.text = "0.4"
            conductorTemp.text = "75"
            earthResistivity.text = "100"
            conductorGMR.text = "0.0078"
            nominalVoltage.text = "400"
            
            // Add conductor spacing fallback
            conductorSpacing.text = "0.3"  // Default 300mm (0.3m) reference spacing
            nominalMvaInput.text = "100"
            powerFactorInput.text = "0.9"
        }
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

    PopUpText {
        id: bundleInfoPopup
        parentCard: resultsCard
        popupText: "Bundle Configuration Effects:\n\n" +
                   "• More conductors per bundle = lower Z₀ and higher SIL\n" +
                   "• Wider bundle spacing = higher effective GMR and lower inductance\n" +
                   "• Bundle configuration mainly affects the inductive reactance\n" +
                   "• Typical improvements from bundling:\n" +
                   "  - 2 conductors: ~20-25% lower Z₀ than single conductor\n" +
                   "  - 3 conductors: ~30-35% lower Z₀ than single conductor\n" +
                   "  - 4 conductors: ~35-40% lower Z₀ than single conductor\n\n" +
                   "Example: 400kV lines commonly use 2-4 conductors with 0.4-0.6m spacing"
    }

    PopUpText {
        id: spacingInfoPopup
        parentCard: parametersCard
        popupText: "Conductor Spacing vs Bundle Spacing:\n\n" +
                   "• Conductor Spacing: Distance between phase conductors (typically 0.3-10m)\n" +
                   "• Bundle Spacing: Distance between subconductors within a single phase bundle (typically 0.3-0.6m)\n\n" +
                   "Manufacturer datasheets typically specify R and X values at a standard reference spacing of 1 foot (0.3m) or 1 meter.\n\n" +
                   "Increasing phase-to-phase spacing increases inductance and reactance."
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
                            Layout.minimumHeight: 400

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
                                    // Direct connection without timer
                                    onTextChanged: {
                                        if(text && acceptableInput) {
                                            console.log("Setting length to: " + parseFloat(text))
                                            calculator.setLength(parseFloat(text))
                                        }
                                    }
                                    Layout.minimumWidth: 120
                                    Layout.alignment: Qt.AlignRight
                                }

                                Label { text: "Resistance (Ω/km):" }
                                TextFieldRound {
                                    id: resistanceInput
                                    text: "0.1"
                                    validator: DoubleValidator { bottom: 0 }
                                    // Direct connection without timer
                                    onTextChanged: {
                                        if(text && acceptableInput) {
                                            console.log("QML sending resistance: " + parseFloat(text))
                                            calculator.setResistance(parseFloat(text))
                                        }
                                    }
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
                                    // Direct connection - make sure it properly updates the SIL
                                    onTextChanged: {
                                        if(text && acceptableInput) {
                                            console.log("Setting nominal voltage to: " + parseFloat(text))
                                            calculator.setNominalVoltage(parseFloat(text))
                                        }
                                    }
                                    Layout.fillWidth: true
                                    // Add tooltip to explain voltage effect on SIL
                                    hoverEnabled: true
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Nominal voltage directly affects Surge Impedance Loading (SIL = kV²/Z₀)"
                                }

                                Label { text: "Nominal MVA:" }
                                TextFieldRound {
                                    id: nominalMvaInput
                                    text: "100"
                                    validator: DoubleValidator { bottom: 0 }
                                    onTextChanged: {
                                        if(text && acceptableInput) {
                                            calculator.setNominalMVA(parseFloat(text))
                                        }
                                    }
                                    Layout.fillWidth: true
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Nominal MVA of the line/load"
                                }

                                Label { text: "Power Factor:" }
                                TextFieldRound {
                                    id: powerFactorInput
                                    text: "0.9"
                                    validator: DoubleValidator { bottom: -1.0; top: 1.0 }
                                    onTextChanged: {
                                        if(text && acceptableInput) {
                                            calculator.setPowerFactor(parseFloat(text))
                                        }
                                    }
                                    Layout.fillWidth: true
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Load power factor (e.g., 0.9 lagging, -0.9 leading)"
                                }
                            }
                        }

                        // Advanced Parameters
                        WaveCard {
                            title: "Advanced Parameters"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 350
                            Layout.minimumWidth: 300

                            GridLayout {
                                columns: 2

                                // Add conductor spacing field (before bundle configuration)
                                Label {
                                    text: "Conductor Spacing (m):" 
                                    Layout.minimumWidth: 200
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: spacingInfoPopup.open()
                                    }
                                }
                                TextFieldRound {
                                    id: conductorSpacing
                                    text: "0.3"
                                    validator: DoubleValidator { bottom: 0.1; top: 15.0 }
                                    onTextChanged: {
                                        if(text && acceptableInput) {
                                            console.log("QML sending conductor spacing: " + parseFloat(text))
                                            calculator.setConductorSpacing(parseFloat(text))
                                            // Force an immediate UI update
                                            updateResultsDisplay()
                                        }
                                    }
                                    Layout.fillWidth: true
                                    // Add tooltip to explain the parameter
                                    hoverEnabled: true
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Distance between phase conductors (reference: 0.3m/1ft)\nTypical values: 69kV=2-3m, 138kV=3-4.5m, 345kV=7-9m, 765kV=12-15m"
                                }

                                Label { 
                                    text: "Bundle Configuration:" 
                                    Layout.minimumWidth: 200
                                }
                                SpinBoxRound {
                                    id: subConductors
                                    from: 1
                                    to: 4
                                    value: 2
                                    // Direct connection without timer
                                    onValueChanged: {
                                        calculator.setSubConductors(value)
                                        // Enable/disable bundle spacing based on subconductors
                                        bundleSpacing.enabled = value > 1
                                        bundleSpacingLabel.opacity = value > 1 ? 1.0 : 0.5
                                        
                                        if (value === 1 && bundleSpacing.enabled !== false) {
                                            // Add hint when switching to single conductor
                                            messagePopup.showInfo("Bundle spacing has no effect with a single conductor")
                                        }
                                    }
                                    Layout.minimumWidth: 120
                                    Layout.fillWidth: true
                                    
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Select number of subconductors per phase (1-4)"
                                }

                                Label { 
                                    id: bundleSpacingLabel
                                    text: "Bundle Spacing (m):" 
                                    opacity: subConductors.value > 1 ? 1.0 : 0.5
                                }
                                TextFieldRound {
                                    id: bundleSpacing
                                    text: "0.4"
                                    enabled: subConductors.value > 1  // Disable when only 1 conductor
                                    validator: DoubleValidator { bottom: 0.001 }  // Prevent zero or negative values
                                    // Enhanced handling for bundle spacing changes
                                    onTextChanged: {
                                        if(text && acceptableInput && enabled) {
                                            console.log("QML sending bundle spacing: " + parseFloat(text))
                                            calculator.setBundleSpacing(parseFloat(text))
                                            
                                            // Force immediate UI update for better feedback
                                            updateResultsDisplay()
                                            
                                            // Add slight delay and update again to ensure changes are visible
                                            refreshTimer.start()
                                        }
                                    }
                                    Layout.fillWidth: true
                                    
                                    // Add tooltip to help guide typical values
                                    hoverEnabled: true
                                    ToolTip.visible: hovered
                                    ToolTip.text: subConductors.value > 1 ? 
                                        "Larger spacing reduces inductance and Z₀. Try values between 0.2-0.8m to see effects." : 
                                        "Bundle spacing only applies when using multiple conductors"
                                }

                                Label { 
                                    text: "Conductor GMR (m):"
                                    Layout.minimumWidth: 200
                                }
                                TextFieldRound {
                                    id: conductorGMR
                                    text: "0.0078"
                                    validator: DoubleValidator { bottom: 0.0001 }  // Prevent zero or very small values
                                    // Enhanced change handling - force immediate update
                                    onTextChanged: {
                                        if(text && acceptableInput) {
                                            console.log("QML sending conductor GMR: " + parseFloat(text))
                                            calculator.setConductorGMR(parseFloat(text))
                                            // Force an immediate UI update
                                            updateResultsDisplay()
                                        }
                                    }
                                    Layout.fillWidth: true
                                    // Add tooltip to explain GMR effect
                                    hoverEnabled: true
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Larger GMR reduces inductance and Z₀. Typical values: ACSR Drake = 0.0103m, Bluebird = 0.0122m"
                                }

                                // Add GMR test values
                                CheckBox {
                                    id: useCalculatedInductanceCheckbox
                                    text: "Use GMR for inductance"
                                    checked: true  // Default to true to make GMR changes visible
                                    Layout.columnSpan: 2
                                    Layout.alignment: Qt.AlignHCenter
                                    onCheckedChanged: {
                                        calculator.setUseCalculatedInductance(checked)
                                        
                                        // When we change this setting, disable/enable the inductance field
                                        inductanceInput.enabled = !checked
                                        
                                        // Update the UI immediately
                                        updateResultsDisplay()
                                    }
                                }

                                Label { text: "Conductor Temperature (°C):" }
                                TextFieldRound {
                                    id: conductorTemp
                                    text: "75"
                                    validator: DoubleValidator { bottom: 0 }
                                    // Direct connection without timer
                                    onTextChanged: {
                                        if(text && acceptableInput) {
                                            console.log("QML sending conductor temperature: " + parseFloat(text))
                                            calculator.setConductorTemperature(parseFloat(text))
                                        }
                                    }
                                    Layout.fillWidth: true
                                }

                                Label { text: "Earth Resistivity (Ω⋅m):" }
                                TextFieldRound {
                                    id: earthResistivity
                                    text: "100"
                                    validator: DoubleValidator { 
                                        bottom: 1.0  // Minimum realistic value
                                        top: 10000.0 // Maximum realistic value
                                    }
                                    // Enhanced error handling for earth resistivity changes
                                    onTextChanged: {
                                        if(text && acceptableInput) {
                                            // Add delay to prevent rapid changes that could cause issues
                                            earthResistivityTimer.stop()
                                            earthResistivityTimer.start()
                                        }
                                    }
                                    Layout.fillWidth: true
                                    // Add tooltip to help guide typical values
                                    hoverEnabled: true
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Typical values: wet soil=10-100, dry soil=100-500, rock=500-10000 Ω⋅m"
                                }

                                // Add information about bundle configuration effects
                                StyledButton {
                                    id: bundleInfoButton
                                    text: "Bundle Effects"
                                    ToolTip.text: "View the effects of bundle configuration"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
                                    Layout.columnSpan: 2
                                    Layout.alignment: Qt.AlignHCenter
                                    
                                    onClicked: bundleInfoPopup.open()
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
                            Layout.minimumHeight: 320
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
                                    // Add tooltip to explain formula
                                    hoverEnabled: true
                                    ToolTip.visible: hovered
                                    ToolTip.text: "SIL = kV²/Z₀. Increasing voltage or decreasing Z₀ raises SIL."
                                }
                                
                                // Add Series Reactance display
                                Label { 
                                    text: "Series Reactance (X):"
                                    Layout.minimumWidth: 200
                                    Layout.alignment: Qt.AlignLeft
                                }
                                TextFieldBlue { 
                                    id: reactanceField
                                    text: calculator.reactancePerKm.toFixed(4) + " Ω/km"
                                    Layout.minimumWidth: 120
                                    Layout.alignment: Qt.AlignRight
                                    verticalAlignment: TextInput.AlignBottom
                                    bottomPadding: 1
                                    
                                    // Add connections to update on reactance change
                                    Connections {
                                        target: calculator
                                        function onReactanceCalculated() {
                                            reactanceField.text = calculator.reactancePerKm.toFixed(4) + " Ω/km"
                                        }
                                    }
                                    
                                    // Add tooltip explaining the reactance
                                    hoverEnabled: true
                                    ToolTip.visible: hovered
                                    ToolTip.text: "Inductive reactance (X = 2πfL). Reference values are often specified at 1-foot (0.3m) spacing."
                                }

                                Label { text: "Receiving End Voltage:" }
                                TextFieldBlue {
                                    id: receivingVoltageField
                                    text: calculator.receivingEndVoltageKv.toFixed(2) + " kV"
                                    Connections {
                                        target: calculator
                                        function onVoltageDropCalculated() {
                                            receivingVoltageField.text = calculator.receivingEndVoltageKv.toFixed(2) + " kV"
                                        }
                                    }
                                }

                                Label { text: "Voltage Drop (%):" }
                                TextFieldBlue {
                                    id: voltageDropField
                                    text: calculator.voltageDropPercent.toFixed(2) + " %"
                                    Connections {
                                        target: calculator
                                        function onVoltageDropCalculated() {
                                            voltageDropField.text = calculator.voltageDropPercent.toFixed(2) + " %"
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
                // ColumnLayout {
                //     Layout.minimumHeight: 400
                //     Layout.maximumWidth: resultsRow.width

                //     WaveCard {
                //         Layout.fillHeight: true
                //         Layout.fillWidth: true
                //         title: "Line Parameters Visualization"

                //         TransmissionLineViz {
                //             anchors.fill: parent
                //             anchors.margins: 0

                //             // Use calculator.length directly instead of lengthInput.text
                //             length: calculator.length
                //             characteristicImpedance: calculator.characteristicImpedance
                //             attenuationConstant: calculator.attenuationConstant
                //             phaseConstant: calculator.phaseConstant

                //             calculator: transmissionCard.calculator

                //             darkMode: Universal.theme === Universal.Dark
                //             textColor: transmissionCard.textColor
                //         }
                //     }
                // }
            }
        }
    }

    MessagePopup {
        id: messagePopup
        anchors.centerIn: parent
    }

    // Add a debug/refresh button to help troubleshoot parameter updates
    RowLayout {
        id: debugRow
        Layout.fillWidth: true
        Layout.topMargin: 5
        Layout.bottomMargin: 10
        
        Item { Layout.fillWidth: true }
        
        StyledButton {
            text: "Refresh Results"
            ToolTip.text: "Force refresh of all calculation results"
            ToolTip.visible: hovered
            ToolTip.delay: 500
            
            onClicked: {
                // Force UI update by manually triggering calculator
                calculator.calculate()
                updateResultsDisplay()
            }
        }
    }
    
    // Replace the refresh timer with a direct function to update the UI
    function updateResultsDisplay() {
        // Force update all result fields
        if (calculator) {
            impedanceField.text = calculator.zMagnitude.toFixed(2) + " Ω ∠" + 
                            calculator.zAngle.toFixed(1) + "°"
            attenuationField.text = calculator.attenuationConstant.toFixed(6) + " Np/km"
            phaseField.text = calculator.phaseConstant.toFixed(4) + " rad/km"
            silField.text = calculator.surgeImpedanceLoading.toFixed(1) + " MW"
            aParameterField.text = calculator.aMagnitude.toFixed(3) + " ∠" + calculator.aAngle.toFixed(1) + "°"
            bParameterField.text = calculator.bMagnitude.toFixed(3) + " ∠" + calculator.bAngle.toFixed(1) + "°"
            cParameterField.text = calculator.cMagnitude.toFixed(6) + " ∠" + calculator.cAngle.toFixed(1) + "°"
            dParameterField.text = calculator.dMagnitude.toFixed(3) + " ∠" + calculator.dAngle.toFixed(1) + "°"
            
            receivingVoltageField.text = calculator.receivingEndVoltageKv.toFixed(2) + " kV"
            voltageDropField.text = calculator.voltageDropPercent.toFixed(2) + " %"

            // Fix reactance update by using the value from the signal instead of property access
            try {
                // Use a global variable to store the latest reactance value
                if (transmissionCard.lastReactanceValue !== undefined) {
                    reactanceField.text = transmissionCard.lastReactanceValue.toFixed(4) + " Ω/km";
                } else {
                    // Force calculation to get initial value
                    calculator.calculate();
                }
            } catch (e) {
                console.error("Error updating reactance: " + e);
                reactanceField.text = "0.0000 Ω/km";  // Fallback with zeros
            }
            
            // Also update visualization if present
            let viz = transmissionCard.children.find(child => child instanceof TransmissionLineViz)
            if (viz) {
                viz.characteristicImpedance = calculator.characteristicImpedance
                viz.attenuationConstant = calculator.attenuationConstant
                viz.phaseConstant = calculator.phaseConstant
                viz.length = calculator.length
            }
        }
    }

    // Add a property to store the latest reactance value
    property double lastReactanceValue: 0.0

    Connections {
        target: calculator
        
        function onExportComplete(success, message) {
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
        
        // Connect all result update signals to the same function
        function onResultsCalculated() { updateResultsDisplay() }
        function onBundleConfigChanged() { updateResultsDisplay() }
        function onTemperatureChanged() { updateResultsDisplay() }
        function onEarthResistivityChanged() { updateResultsDisplay() }
        function onResistanceChanged() { updateResultsDisplay() }
        function onNominalVoltageChanged() { updateResultsDisplay() }
        function onSilCalculated() { updateResultsDisplay() }
        function onLengthChanged() { updateResultsDisplay() }
        // Add reactance update to the signals
        function onReactanceCalculated(value) { 
            console.log("Reactance calculated signal received: " + value);
            // Store the value in our item property for later use
            transmissionCard.lastReactanceValue = value;
            reactanceField.text = value.toFixed(4) + " Ω/km";
        }
        function onVoltageDropCalculated() { updateResultsDisplay() }
    }

    // Force initial calculation to make sure we have reactance
    Component.onCompleted: {
        initializeFields();
        
        // Force calculation once loaded
        if (calculator) {
            calculator.calculate();
        }
    }

    // Add a delayed refresh timer to handle bundle spacing changes properly
    Timer {
        id: refreshTimer
        interval: 300
        running: false
        repeat: false
        onTriggered: {
            calculator.calculate()
            updateResultsDisplay()
        }
    }

    // Add a delayed timer specifically for earth resistivity changes to prevent rapid changes
    Timer {
        id: earthResistivityTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            try {
                var value = parseFloat(earthResistivity.text)
                if (!isNaN(value) && isFinite(value) && value > 0) {
                    console.log("QML sending earth resistivity: " + value)
                    calculator.setEarthResistivity(value)
                    updateResultsDisplay()
                }
            } catch (e) {
                console.error("Error processing earth resistivity: " + e)
            }
        }
    }
}
