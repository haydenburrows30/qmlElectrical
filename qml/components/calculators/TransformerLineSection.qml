import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore

import "../"
import "../buttons"
import "../popups"
import "../style"

Item {
    id: transformerLineSection

    // Properties passed from parent
    property var calculator
    property bool calculatorReady
    property real totalGeneratedPower
    property var safeValueFunction

    signal calculate()

    // Move function to component level
    function updateDisplayValues() {
        if (!calculatorReady) return

        loadMVAField.text = calculator.loadMVA.toFixed(3);

        // Update transformer/line values
        transformerZOhmsText.text = safeValueFunction(calculator.transformerZOhms, 0).toFixed(3)
        transformerROhmsText.text = safeValueFunction(calculator.transformerROhms, 0).toFixed(3)
        transformerXOhmsText.text = safeValueFunction(calculator.transformerXOhms, 0).toFixed(3)
        lineTotalZText.text = safeValueFunction(calculator.lineTotalZ, 0).toFixed(3)
        voltageDropText.text = safeValueFunction(calculator.voltageDrop, 0.01).toFixed(2)
        faultCurrentLVText.text = safeValueFunction(calculator.faultCurrentLV, 0).toFixed(2)
        faultCurrentHVText.text = safeValueFunction(calculator.faultCurrentHV, 0).toFixed(2)

        // Update protection settings
        relayPickupCurrentText.text = safeValueFunction(calculator.relayPickupCurrent, 0).toFixed(2)
        relayTimeDialText.text = safeValueFunction(calculator.relayTimeDial, 0).toFixed(2)
        relayCtRatioText.text = calculator.relayCtRatio
        relayCurveTypeText.text = calculator.relayCurveType

        // Update regulator values
        regulatedVoltageText.text = safeValueFunction(calculator.regulatedVoltage, 0).toFixed(2)
        regulatorTapPositionText.text = safeValueFunction(calculator.regulatorTapPosition, 0).toString()
    }

    // Enhanced safeValueFunction implementation directly in the component
    function safeValueFunction(value, defaultVal) {
        // Enhanced safe value function that handles null, undefined, NaN
        if (value === undefined || value === null || isNaN(value) || !isFinite(value)) {
            return defaultVal;
        }
        return value;
    }

    onTotalGeneratedPowerChanged: {
        if (calculatorReady) {
            calculator.setLoadMVA(totalGeneratedPower / 1000000)
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height + 40
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            RowLayout {
                id: mainLayout
                width: scrollView.width

                ColumnLayout {

                    Layout.maximumWidth: 400
                    Layout.minimumWidth: 400
                    Layout.alignment: Qt.AlignTop

                    // Transformer parameters section
                    WaveCard {
                        title: "Transformer Parameters (400V to 11kV)"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            Label { text: "Transformer Rating (kVA):" }
                            SpinBoxRound {
                                id: transformerRatingSpinBox
                                from: 100
                                to: 5000
                                value: calculatorReady ? calculator.transformerRating : 1000
                                stepSize: 50
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: if (calculatorReady) calculator.setTransformerRating(value)
                            }

                            Label { text: "Transformer Impedance (%):" }
                            SpinBoxRound {
                                id: transformerImpedanceSpinBox
                                from: 30
                                to: 100
                                value: calculatorReady ? calculator.transformerImpedance * 10 : 60
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 10.0

                                textFromValue: function(value) {
                                    return (value / 10.0).toFixed(1);
                                }

                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }

                                onValueModified: if (calculatorReady) calculator.setTransformerImpedance(realValue)
                            }

                            Label { text: "Transformer X/R Ratio:" }
                            SpinBoxRound {
                                id: transformerXRRatioSpinBox
                                from: 30
                                to: 150
                                value: calculatorReady ? calculator.transformerXRRatio * 10 : 80
                                stepSize: 5
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 10.0

                                textFromValue: function(value) {
                                    return (value / 10.0).toFixed(1);
                                }

                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }

                                onValueModified: if (calculatorReady) calculator.setTransformerXRRatio(realValue)
                            }
                        }
                    }

                    // Line parameters section
                    WaveCard {
                        title: "Line Parameters (5km Cable)"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            Label { text: "Line Length (km):" }
                            SpinBoxRound {
                                id: lineLengthSpinBox
                                from: 1
                                to: 50
                                value: calculatorReady ? calculator.lineLength * 10 : 50
                                stepSize: 5
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 10.0

                                textFromValue: function(value) {
                                    return (value / 10.0).toFixed(1);
                                }

                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }

                                onValueModified: if (calculatorReady) calculator.setLineLength(realValue)
                            }

                            Label { text: "Line Resistance (Ohm/km):" }
                            SpinBoxRound {
                                id: lineRSpinBox
                                from: 1
                                to: 100
                                value: calculatorReady ? calculator.lineR * 100 : 25
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 100.0

                                textFromValue: function(value) {
                                    return (value / 100.0).toFixed(2);
                                }

                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 100);
                                }

                                onValueModified: if (calculatorReady) calculator.setLineR(realValue)
                            }

                            Label { text: "Line Reactance (Ohm/km):" }
                            SpinBoxRound {
                                id: lineXSpinBox
                                from: 1
                                to: 100
                                value: calculatorReady ? calculator.lineX * 100 : 20
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 100.0

                                textFromValue: function(value) {
                                    return (value / 100.0).toFixed(2);
                                }

                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 100);
                                }

                                onValueModified: if (calculatorReady) calculator.setLineX(realValue)
                            }
                        }
                    }

                    // Load parameters updated by wind turbine output
                    WaveCard {
                        title: "Load Parameters (From Wind Turbine Output)"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            Label { text: "Wind Turbine Output (MW):" }
                            TextFieldBlue {
                                text: (totalGeneratedPower / 1000).toFixed(3)
                            }

                            Label { text: "Load (MVA):" }
                            TextFieldBlue {
                                id: loadMVAField
                                text: { calculator.loadMVA.toFixed(3) }
                            }

                            Label { text: "Power Factor:" }
                            SpinBoxRound {
                                id: loadPowerFactorSpinBox
                                from: 70
                                to: 100
                                value: calculatorReady ? calculator.loadPowerFactor * 100 : 95
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 100.0

                                textFromValue: function(value) {
                                    return (value / 100.0).toFixed(2);
                                }

                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 100);
                                }

                                onValueModified: {
                                    if (calculatorReady) {
                                        console.log("Setting power factor to:", realValue);
                                        calculator.setLoadPowerFactorMaintainPower(realValue);

                                        // Update MVA field after power factor change
                                        loadMVAField.text = calculator.loadMVA.toFixed(3);

                                        // Force UI update immediately
                                        transformerLineSection.updateDisplayValues();
                                    }
                                }
                            }

                        }
                    }

                    // Voltage Regulator parameters
                    WaveCard {
                        id: regulatorCard
                        title: "Voltage Regulator"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 450

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            // Enable/disable regulator
                            Label { text: "Enable Voltage Regulator:" }
                            Switch {
                                id: regulatorEnabledSwitch
                                checked: calculatorReady ? calculator.voltageRegulatorEnabled : true
                                onToggled: if (calculatorReady) calculator.setVoltageRegulatorEnabled(checked)
                            }

                            // Regulator type - specific to Eaton
                            Label { text: "Regulator Type:" }
                            TextFieldBlue {
                                id: regulatorTypeText
                                text: "Eaton Single-Phase"
                                enabled: regulatorEnabledSwitch.checked
                            }

                            // Regulator model - specific to VR-32
                            Label { text: "Regulator Model:" }
                            TextFieldRound {
                                id: regulatorModelText
                                text: "Cooper VR-32"
                                readOnly: true
                                Layout.fillWidth: true
                                enabled: regulatorEnabledSwitch.checked
                                background: Rectangle {
                                    color: window.modeToggled ? "black":"#f0f0f0"
                                    border.color: "#c0c0c0"
                                    radius: 2
                                }
                            }

                            // Connection type - delta
                            Label { text: "Connection Type:" }
                            TextFieldBlue {
                                id: regulatorConnectionText
                                text: "Delta"
                                enabled: regulatorEnabledSwitch.checked
                            }

                            // Capacity per phase
                            Label { text: "Capacity per Phase (kVA):" }
                            TextFieldBlue {
                                id: regulatorCapacityText
                                text: "185"
                                enabled: regulatorEnabledSwitch.checked
                            }

                            // Target voltage setting
                            Label { text: "Target Voltage (kV):" }
                            SpinBoxRound {
                                id: regulatorTargetSpinBox
                                from: 100
                                to: 120
                                value: calculatorReady ? calculator.voltageRegulatorTarget * 10 : 110
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                enabled: regulatorEnabledSwitch.checked
                                property real realValue: value / 10.0

                                textFromValue: function(value) {
                                    return (value / 10.0).toFixed(1);
                                }

                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }

                                onValueModified: if (calculatorReady) calculator.setVoltageRegulatorTarget(realValue)
                            }

                            // Bandwidth
                            Label { text: "Bandwidth (%):" }
                            SpinBoxRound {
                                id: regulatorBandwidthSpinBox
                                from: 10
                                to: 50
                                value: calculatorReady ? calculator.voltageRegulatorBandwidth * 10 : 20
                                stepSize: 5
                                editable: true
                                Layout.fillWidth: true
                                enabled: regulatorEnabledSwitch.checked
                                property real realValue: value / 10.0

                                textFromValue: function(value) {
                                    return (value / 10.0).toFixed(1);
                                }

                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }

                                onValueModified: if (calculatorReady) calculator.setVoltageRegulatorBandwidth(realValue)
                            }

                            // Regulator range
                            Label { text: "Range (±%):" }
                            SpinBoxRound {
                                id: regulatorRangeSpinBox
                                from: 50
                                to: 150
                                value: calculatorReady ? calculator.voltageRegulatorRange * 10 : 100
                                stepSize: 5
                                editable: true
                                Layout.fillWidth: true
                                enabled: regulatorEnabledSwitch.checked
                                property real realValue: value / 10.0

                                textFromValue: function(value) {
                                    return (value / 10.0).toFixed(1);
                                }

                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }

                                onValueModified: if (calculatorReady) calculator.setVoltageRegulatorRange(realValue)
                            }

                            // Number of steps
                            Label { text: "Number of Steps:" }
                            TextFieldBlue {
                                id: regulatorStepsText
                                text: "32"
                                enabled: regulatorEnabledSwitch.checked
                            }
                        }
                    }
                }
                
                ColumnLayout {
                    Layout.minimumWidth: 400
                    Layout.maximumWidth: 400
                    Layout.alignment: Qt.AlignTop

                    // System results section
                    WaveCard {
                        title: "Electrical System Results"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 450

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            Label { text: "Transformer Z (Ohms):" }
                            TextFieldBlue {
                                id: transformerZOhmsText
                                text: calculatorReady ? safeValueFunction(calculator.transformerZOhms, 0).toFixed(3) : "0.000"
                            }

                            Label { text: "Transformer R (Ohms):" }
                            TextFieldBlue {
                                id: transformerROhmsText
                                text: calculatorReady ? safeValueFunction(calculator.transformerROhms, 0).toFixed(3) : "0.000"
                            }

                            Label { text: "Transformer X (Ohms):" }
                            TextFieldBlue {
                                id: transformerXOhmsText
                                text: calculatorReady ? safeValueFunction(calculator.transformerXOhms, 0).toFixed(3) : "0.000"
                            }

                            Label { text: "Line Total Z (Ohms):" }
                            TextFieldBlue {
                                id: lineTotalZText
                                text: calculatorReady ? safeValueFunction(calculator.lineTotalZ, 0).toFixed(3) : "0.000"
                            }

                            Label { text: "Natural Voltage Drop (%):" }
                            TextFieldBlue {
                                id: voltageDropText
                                text: calculatorReady ? safeValueFunction(calculator.voltageDrop, 0.01).toFixed(2) : "0.00"
                            }

                            Label { text: "Fault Current at LV Side (kA):" }
                            TextFieldBlue {
                                id: faultCurrentLVText
                                text: calculatorReady ? safeValueFunction(calculator.faultCurrentLV, 0).toFixed(2) : "0.00"
                            }

                            Label { text: "Fault Current at HV Side (kA):" }
                            TextFieldBlue {
                                id: faultCurrentHVText
                                text: calculatorReady ? safeValueFunction(calculator.faultCurrentHV, 0).toFixed(2) : "0.00"
                            }

                            Label { text: "Unregulated Voltage (kV):" }
                            TextFieldBlue {
                                text: calculatorReady ? 
                                    safeValueFunction(calculator.unregulatedVoltage, 0).toFixed(2) : 
                                    "0.00"
                            }

                            StyledButton {
                                id: exportButton
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignRight
                                text: "Export"
                                icon.source: "../../../icons/rounded/download.svg"

                                onClicked: {
                                    saveDialog.open()
                                }
                            }
                        }
                    }

                    // Transformer protection section
                    WaveCard {
                        id: transformerProtectionCard
                        title: "Transformer Protection Settings"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 280

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            Label { text: "Relay Pickup Current (A):" }
                            TextFieldBlue {
                                id: relayPickupCurrentText
                                text: calculatorReady ? safeValueFunction(calculator.relayPickupCurrent, 0).toFixed(2) : "0.00"
                            }

                            Label { text: "CT Ratio:" }
                            TextFieldBlue {
                                id: relayCtRatioText
                                text: calculatorReady ? calculator.relayCtRatio : "300/1"
                            }

                            Label { text: "Relay Curve Type:" }
                            TextFieldBlue {
                                id: relayCurveTypeText
                                text: calculatorReady ? calculator.relayCurveType : "Very Inverse"
                            }

                            Label { text: "Time Dial Setting:" }
                            TextFieldBlue {
                                id: relayTimeDialText
                                text: calculatorReady ? safeValueFunction(calculator.relayTimeDial, 0).toFixed(2) : "0.30"
                            }

                            StyledButton {
                                text: "Expert Settings"
                                icon.source: "../../../icons/rounded/settings.svg"
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignRight
                                onClicked: {
                                    // Force calculator to use current MVA and power factor
                                    if (calculatorReady) {
                                        // Update values just to be sure
                                        calculator.setLoadMVA(parseFloat(loadMVAField.text));
                                        calculator.setLoadPowerFactor(loadPowerFactorSpinBox.realValue);
                                        calculator.refreshCalculations();
                                    }
                                    expertProtectionPopup.open();
                                }
                            }
                        }
                    }

                    // Enhanced ExpertProtectionPopup with proper value passing
                    ExpertProtectionPopup {
                        id: expertProtectionPopup
                        calculator: transformerLineSection.calculator
                        safeValueFunction: function(value, defaultVal) {
                            // Enhanced safe value function that handles null, undefined, NaN
                            if (value === undefined || value === null || isNaN(value) || !isFinite(value)) {
                                return defaultVal;
                            }
                            return value;
                        }
                        x: Math.round((parent.width - width) / 2)
                        y: Math.round((parent.height - height) / 2)
                    }
                }

                ColumnLayout {
                    Layout.minimumWidth: 400
                    Layout.maximumWidth: 400
                    Layout.alignment: Qt.AlignTop

                    // Cable selection guide
                    WaveCard {
                        title: "Cable Selection Guide for Wind Turbine Connection"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        Layout.alignment: Qt.AlignTop

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            Label { text: "Recommended HV Cable Size:" }
                            TextFieldBlue {
                                text: calculatorReady ? calculator.recommendedHVCable : "25 mm²"
                            }

                            Label { text: "Recommended LV Cable Size:" }
                            TextFieldBlue {
                                text: calculatorReady ? calculator.recommendedLVCable : "25 mm²"
                            }
                        }
                    }
                    // Regulator results
                    WaveCard {
                        title: "Voltage Regulation Results"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 280
                        visible: regulatorEnabledSwitch.checked
                        Layout.alignment: Qt.AlignTop

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            Label { text: "Unregulated Voltage (kV):" }
                            TextFieldBlue {
                                text: calculatorReady ? 
                                    ((11 * (1 - safeValueFunction(calculator.voltageDrop, 0) / 100))).toFixed(2) : 
                                    "0.00"
                            }

                            Label { text: "Regulated Voltage (kV):" }
                            TextFieldBlue {
                                id: regulatedVoltageText
                                text: calculatorReady ? safeValueFunction(calculator.regulatedVoltage, 0).toFixed(2) : "0.00"
                            }

                            Label { text: "Tap Position:" }
                            TextFieldBlue {
                                id: regulatorTapPositionText
                                text: calculatorReady ? safeValueFunction(calculator.regulatorTapPosition, 0).toString() : "0"
                            }

                            Label { text: "Step Size (%):" }
                            TextFieldBlue {
                                text: (calculator.voltageRegulatorRange / 16).toFixed(3)
                            }

                            Label { text: "Total 3-Phase Capacity (kVA):" }
                            TextFieldBlue {
                                text: calculatorReady ? safeValueFunction(calculator.regulatorThreePhaseCapacity, 0).toFixed(0) : "555"
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: updateTimer
        interval: 250
        repeat: true
        running: calculatorReady
        onTriggered: {
            if(calculatorReady) {
                transformerLineSection.updateDisplayValues()
            }
        }
    }

    FileDialog {
        id: saveDialog
        title: "Save PDF Report"
        nameFilters: ["PDF files (*.pdf)"]
        fileMode: FileDialog.SaveFile
        currentFolder: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]

        onAccepted: {
            if (calculatorReady) {
                let data = {
                    "transformer_rating": calculator.transformerRating,
                    "transformer_impedance": calculator.transformerImpedance,
                    "transformer_xr_ratio": calculator.transformerXRRatio,
                    "transformer_z": calculator.transformerZOhms,
                    "transformer_r": calculator.transformerROhms,
                    "transformer_x": calculator.transformerXOhms,
                    "ground_fault_current": calculator.groundFaultCurrent,
                    "ct_ratio": calculator.relayCtRatio,
                    "relay_pickup_current": calculator.relayPickupCurrent,
                    "relay_curve_type": calculator.relayCurveType,
                    "time_dial": calculator.relayTimeDial
                }
            }

            let filePath = saveDialog.selectedFile.toString();
                
            // Remove the "file://" prefix properly based on platform
            if (filePath.startsWith("file:///") && Qt.platform.os === "windows") {
                // On Windows, file:///C:/path becomes C:/path
                filePath = filePath.substring(8);
            } else if (filePath.startsWith("file:///")) {
                // On Unix-like systems, file:///path becomes /path
                filePath = filePath.substring(7); 
            } else if (filePath.startsWith("file://")) {
                // Alternative format
                filePath = filePath.substring(5);
            }

            calculator.exportTransformerReport(data, filePath)
        }
    }

    Connections {
        target: calculator
        function loadChanged() {
            if (calculatorReady) {
                transformerLineSection.updateDisplayValues()
            }
        }
    }
}