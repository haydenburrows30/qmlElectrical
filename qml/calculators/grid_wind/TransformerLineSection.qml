import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"

Item {
    id: transformerLineSection

    // Properties passed from parent
    property var calculator
    property bool calculatorReady
    property var safeValueFunction

    property var relayCtRatioText: ({ text: "300/5" })
    property var relayTimeDialText: ({ text: "0.30" })
    property var relayCurveTypeText: ({ text: "Very Inverse" })

    signal calculate()

    // Move function to component level
    function updateDisplayValues() {
        if (!calculatorReady) return

        // Update transformer/line values
        transformerZOhmsText.text = safeValueFunction(calculator.transformerZOhms, 0).toFixed(3)
        transformerROhmsText.text = safeValueFunction(calculator.transformerROhms, 0).toFixed(3)
        transformerXOhmsText.text = safeValueFunction(calculator.transformerXOhms, 0).toFixed(3)
        lineTotalZText.text = safeValueFunction(calculator.lineTotalZ, 0).toFixed(3)
        voltageDropText.text = safeValueFunction(calculator.voltageDrop, 0.01).toFixed(2)
        faultCurrentLVText.text = safeValueFunction(calculator.faultCurrentLV, 0).toFixed(2)
        faultCurrentHVText.text = safeValueFunction(calculator.faultCurrentHV, 0).toFixed(2)
        groundFaultCurrentText.text = safeValueFunction(calculator.groundFaultCurrent, 0).toFixed(4)

        // Update protection settings
        relayPickupCurrentText.text = safeValueFunction(calculator.relayPickupCurrent, 0).toFixed(2)
        relayTimeDialText.text = safeValueFunction(calculator.relayTimeDial, 0).toFixed(2)
        relayCtRatioText.text = calculator.relayCtRatio
        relayCurveTypeText.text = calculator.relayCurveType

        // Update regulator values
        regulatedVoltageText.text = safeValueFunction(calculator.regulatedVoltage, 0).toFixed(2)
        regulatorTapPositionText.text = safeValueFunction(calculator.regulatorTapPosition, 0).toString()
    }

    // Add function to component level
    function getCurveInfoText(curveType) {
        switch(curveType) {
            case "Standard Inverse":
                return "IEC Standard Inverse: t = TDS * 0.14 / ((I/Is)^0.02 - 1)\nGood for general distribution networks."
            case "Very Inverse":
                return "IEC Very Inverse: t = TDS * 13.5 / ((I/Is) - 1)\nGood for feeder protection and transformer protection."
            case "Extremely Inverse":
                return "IEC Extremely Inverse: t = TDS * 80 / ((I/Is)^2 - 1)\nGood for transformer and motor protection."
            case "Long-Time Inverse":
                return "Long-Time Inverse: t = TDS * 120 / ((I/Is) - 1)\nGood for high inrush applications."
            case "Definite Time":
                return "Definite Time: t = TDS regardless of current magnitude\nGood for backup protection schemes."
            default:
                return "No information available for this curve type."
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
                anchors.centerIn: parent

                ColumnLayout {
                    Layout.maximumWidth: 400
                    Layout.minimumWidth: 400
                    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

                    // Transformer parameters section
                    WaveCard {
                        title: "Transformer Parameters"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 260

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            Label { text: "Transformer Rating (kVA):" }
                            SpinBoxRound {
                                id: transformerRatingSpinBox
                                from: 100
                                to: 5000
                                value: calculatorReady && calculator ? safeValueFunction(calculator.transformerRating, 1000) : 1000
                                stepSize: 50
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: if (calculatorReady) calculator.setTransformerRating(value)
                            }

                            Label { text: "Transformer LV (V):" }
                            SpinBoxRound {
                                id: lvVoltageSpinBox
                                from: 100
                                to: 5000
                                value: calculatorReady && calculator ? safeValueFunction(calculator.lvVoltage, 400) : 400
                                stepSize: 10
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: if (calculatorReady) calculator.setLVTXRating(value)
                            }

                            Label { text: "Transformer HV (V):" }
                            SpinBoxRound {
                                id: hvVoltageSpinBox
                                from: 100
                                to: 33000
                                value: calculatorReady && calculator ? safeValueFunction(calculator.hvVoltage, 11000) : 11000
                                stepSize: 100
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: if (calculatorReady) calculator.setHVTXRating(value)
                            }

                            Label { text: "Transformer Impedance (%):" }
                            SpinBoxRound {
                                id: transformerImpedanceSpinBox
                                from: 1
                                to: 100
                                value: calculatorReady ? calculator.transformerImpedance * 10 : 45
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

                                validator: RegularExpressionValidator {
                                    regularExpression: /[0-9]*\.?[0-9]*/
                                }

                                onValueModified: if (calculatorReady) calculator.setTransformerImpedance(realValue)
                            }

                            Label { text: "Transformer X/R Ratio:" }
                            SpinBoxRound {
                                id: transformerXRRatioSpinBox
                                from: 30
                                to: 150
                                value: calculatorReady ? calculator.transformerXRRatio * 10 : 80
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

                                onValueModified: if (calculatorReady) calculator.setTransformerXRRatio(realValue)

                                validator: RegularExpressionValidator {
                                    regularExpression: /[0-9]*\.?[0-9]*/
                                }   
                            }
                        }
                    }

                    // Line parameters section
                    WaveCard {
                        title: "Line Parameters"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            Label { text: "Line Length (km):" }
                            SpinBoxRound {
                                id: lineLengthSpinBox
                                from: 1
                                to: 1000
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

                                validator: RegularExpressionValidator {
                                    regularExpression: /[0-9]*\.?[0-9]*/
                                }
                            }

                            Label { text: "Line Resistance (Ohm/km):" }
                            SpinBoxRound {
                                id: lineRSpinBox
                                from: 1
                                to: 1000
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

                                validator: RegularExpressionValidator {
                                    regularExpression: /[0-9]*\.?[0-9]*/
                                }
                            }

                            Label { text: "Line Reactance (Ohm/km):" }
                            SpinBoxRound {
                                id: lineXSpinBox
                                from: 1
                                to: 1000
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

                                validator: RegularExpressionValidator {
                                    regularExpression: /[0-9]*\.?[0-9]*/
                                }
                            }
                        }
                    }

                    // Load parameters updated by wind turbine output or manually
                    WaveCard {
                        title: "Load Parameters"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140

                        GridLayout {
                            anchors.fill: parent
                            uniformCellWidths: true
                            columns: 2

                            Label { text: "Load Value (MVA):" ; Layout.fillWidth: true }

                            // 0-10MVA range 0.1MVA steps
                            SpinBoxRound {
                                id: loadMVASpinBox
                                from: 1
                                to: 1000
                                value: calculatorReady ? calculator.loadMVA * 100 : 50
                                stepSize: 5
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 100
                                
                                textFromValue: function(value) {
                                    return (value / 100).toFixed(2);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 100);
                                }
                                
                                onValueModified: {
                                    if (calculatorReady) {
                                        calculator.setLoadMVA(realValue)
                                        calculator.refreshCalculations()
                                    }
                                }

                                validator: RegularExpressionValidator {
                                    regularExpression: /[0-9]*\.?[0-9]*/
                                }
                            }

                            Label { text: "Power Factor:" ; Layout.fillWidth: true}
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
                                        calculator.setLoadPowerFactorMaintainPower(realValue);

                                        // Force UI update immediately
                                        transformerLineSection.updateDisplayValues();
                                    }
                                }

                                validator: RegularExpressionValidator {
                                regularExpression: /[0-9]*\.?[0-9]*/
                            }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.minimumWidth: 400
                    Layout.maximumWidth: 400
                    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

                    // System results section
                    WaveCard {
                        title: "Electrical System Results"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 430

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

                            Label { text: "Ground Fault Current (kA):" }
                            TextFieldBlue {
                                id: groundFaultCurrentText
                                text: calculatorReady ? safeValueFunction(calculator.groundFaultCurrent, 0).toFixed(4) : "0.0000"
                            }

                            Label { text: "Unregulated Voltage (kV):" }
                            TextFieldBlue {
                                text: calculatorReady ? 
                                    safeValueFunction(calculator.unregulatedVoltage, 0).toFixed(2) : 
                                    "0.00"
                            }

                            RowLayout {
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignRight
                                Layout.fillWidth: true

                                StyledButton {
                                    id: calculateButton
                                    ToolTip.text: "Recalculate parameters"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500

                                    text: "Recalculate"
                                    icon.source: "../../../icons/rounded/calculate.svg"

                                    onClicked: {
                                        if (calculatorReady) {
                                            calculate() // Emit the calculate signal
                                            calculator.refreshCalculations()
                                        }
                                    }
                                }

                                StyledButton {
                                    text: "Export"
                                    icon.source: "../../../icons/rounded/download.svg"

                                    ToolTip.text: "Export report to PDF"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500

                                    onClicked: {
                                        // Use null to let FileSaver handle file dialog
                                        exportReportWithLoading()
                                    }
                                }
                            }
                        }
                    }

                    // Cable selection guide
                    WaveCard {
                        title: "Cable Selection for Wind Turbine Connection"
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
                }

                ColumnLayout {
                    Layout.minimumWidth: 400
                    Layout.maximumWidth: 400
                    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

                    // Transformer protection section
                    WaveCard {
                        id: transformerProtectionCard
                        title: "Transformer Protection Settings"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 310

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            Label { text: "Relay Pickup Current (A):" }
                            TextFieldBlue {
                                id: relayPickupCurrentText
                                text: calculatorReady ? safeValueFunction(calculator.relayPickupCurrent, 0).toFixed(2) : "0.00"
                                Layout.fillWidth: true
                            }

                            Label { text: "CT Ratio:" }
                            TextFieldBlue {
                                id: relayCtRatioText
                                text: calculator ? calculator.relayCtRatio : "300/5"
                            }
                            
                            Label { text: "Relay Curve Type:" }
                            TextFieldBlue {
                                id: curveTypeCombo
                                Layout.fillWidth: true
                                text: calculator ? calculator.relayCurveType : "Very Inverse"
                                
                                // Custom popup that shows curve characteristics
                                Popup {
                                    id: curveInfoPopup
                                    width: 300
                                    height: 200
                                    x: parent.width
                                    y: 0
                                    
                                    ColumnLayout {
                                        anchors.fill: parent
                                        
                                        Label {
                                            id: curveInfoTitle
                                            text: "Curve Characteristics"
                                            font.bold: true
                                        }
                                        
                                        Label {
                                            id: curveInfoText
                                            text: getCurveInfoText(curveTypeCombo.currentText)
                                            wrapMode: Text.Wrap
                                            Layout.fillWidth: true
                                        }
                                        
                                        Button {
                                            text: "Close"
                                            Layout.alignment: Qt.AlignRight
                                            onClicked: curveInfoPopup.close()
                                        }
                                    }
                                }
                                
                                // Show curve info when right-clicked
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    onClicked: {
                                        if (mouse.button === Qt.RightButton) {
                                            curveInfoPopup.open()
                                        }
                                    }
                                }
                            }

                            Label { text: "Time Dial Setting:" }
                            SpinBoxRound {
                                id: timeDialSpinBox
                                from: 1
                                to: 10
                                value: calculatorReady ? safeValueFunction(calculator.relayTimeDial, 0.3) * 10 : 3
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
                                
                                onValueModified: {
                                    if (calculatorReady) {
                                        // This would need a method to update the time dial in calculator
                                        relayTimeDialText.text = realValue.toFixed(2)
                                    }
                                }
                            }
                            
                            Label { text: "Instantaneous Pickup:" }
                            SpinBoxRound {
                                id: instantaneousPickupSpinBox
                                from: 2
                                to: 15
                                value: 8 
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                property real multiplier: value
                                
                                textFromValue: function(value) {
                                    return value.toString() + "× FLC";
                                }
                                
                                valueFromText: function(text) {
                                    return parseInt(text);
                                }
                            }

                            StyledButton {
                                text: "Expert Settings"
                                icon.source: "../../../icons/rounded/settings.svg"
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignRight

                                ToolTip.text: "Show expert protection settings and calculations"
                                ToolTip.visible: hovered
                                ToolTip.delay: 500
                                
                                onClicked: {
                                    // Force calculator to use current MVA and power factor
                                    if (calculatorReady) {
                                        try {
                                            // Update power factor first
                                            if (typeof calculator.setLoadPowerFactor === 'function') {
                                                calculator.setLoadPowerFactor(loadPowerFactorSpinBox.realValue);
                                            }
                                            
                                            // Use direct property assignment for loadMVA - more reliable
                                            calculator.loadMVA = parseFloat(loadMVASpinBox.realValue);
                                            
                                            // Try refreshing calculations - handle gracefully if not available
                                            if (typeof calculator.refreshCalculations === 'function') {
                                                calculator.refreshCalculations();
                                            } else {
                                                console.warn("refreshCalculations method not available");
                                                // Fall back to calculate signal
                                                calculate();
                                            }
                                        } catch (e) {
                                            console.error("Error updating values:", e);
                                        }
                                    }
                                    expertProtectionPopup.open();
                                }
                            }
                        }
                    }

                    // Voltage Regulator parameters
                    WaveCard {
                        id: regulatorCard
                        title: "Voltage Regulator"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 430

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            // Enable/disable regulator
                            Label { text: "Enable Voltage Regulator:" }
                            Switch {
                                id: regulatorEnabledSwitch
                                checked: calculatorReady && calculator ? safeValueFunction(calculator.voltageRegulatorEnabled, true) : true
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
                                text: "Delta"  // Using a fixed string prevents the undefined error
                                enabled: regulatorEnabledSwitch.checked
                            }

                            // Capacity per phase
                            Label { text: "Capacity per Phase (kVA):" }
                            TextFieldBlue {
                                id: regulatorCapacityText
                                text: "185"  // Using a fixed string prevents the undefined error
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
                                    safeValueFunction(calculator.unregulatedVoltage, 0).toFixed(2) : 
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
                                text: calculatorReady ? 
                                    ((2 * calculator.voltageRegulatorRange) / calculator.voltageRegulatorSteps).toFixed(3) :
                                    "0.625"
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

    MessagePopup {
        id: messagePopup
    }

    // Add function to handle export with loading indicator
    function exportReportWithLoading() {
        if (!calculatorReady) return;
        
        // Show loading indicator if available
        if (typeof loadingIndicator !== 'undefined' && loadingIndicator !== null) {
            loadingIndicator.show();
        }
        
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
        };
        
        // Use null to trigger FileSaver
        calculator.exportTransformerReport(data, null);
    }

    Connections {
        target: calculator
        enabled: calculatorReady
        
        // Signal handlers based on exact signal names from Python
        function onTransformerChanged() {
            transformerLineSection.updateDisplayValues()
        }
        
        function onLineChanged() {
            transformerLineSection.updateDisplayValues()
        }
        
        function onLoadChanged() {
            transformerLineSection.updateDisplayValues()
        }
        
        function onVoltageRegulatorChanged() {
            transformerLineSection.updateDisplayValues()
        }
        
        function onCalculationCompleted() {
            transformerLineSection.updateDisplayValues()
        }
        
        function onCalculationsComplete() {
            transformerLineSection.updateDisplayValues()
        }

        function onPdfExportStatusChanged(success, message) {
            // Hide loading indicator if available
            if (typeof loadingIndicator !== 'undefined' && loadingIndicator !== null) {
                loadingIndicator.hide();
            }
            
            if (success) {
                messagePopup.showSuccess(message);
            } else {
                messagePopup.showError(message);
            }
        }
    }

    // Add the ExpertProtectionPopup at the bottom of the component
    ExpertProtectionPopup {
        id: expertProtectionPopup
        calculator: transformerLineSection.calculator
        safeValueFunction: transformerLineSection.safeValueFunction
    }
}