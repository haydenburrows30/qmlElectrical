import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"
import "../visualizers/"
import "../style"
import "../buttons"
import "../popups"

import InstrumentTransformer 1.0

Item {
    id: instrumentTransformerCard

    property InstrumentTransformerCalculator calculator: InstrumentTransformerCalculator {}
    property color textColor: Universal.foreground

    PopUpText {
        id: tipsPopup
        parentCard: info
        popupText: "<h3>Instrument Transformer Calculator</h3><br>" +
                    "This calculator estimates the performance of current and voltage transformers based on various parameters.<br><br>" +
                    "<b>Current Transformer:</b> The type, ratio, burden, power factor, temperature, and accuracy class.<br>" +
                    "<b>Voltage Transformer:</b> The ratio, burden, rated voltage factor, and burden status.<br><br>" +
                    "The calculator provides the knee point voltage, maximum fault current, minimum CT burden, error margin, temperature effect, VT rated voltage, VT impedance, and burden utilization.<br><br>" +
                    "The visualization shows the transformer connections and the current and voltage waveforms.<br><br>" +
                    "Developed by <b>Wave</b>."
    }

    Popup {
        id: errorPopup
        width: 300
        height: 150
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        property string errorMessage: ""
        
        contentItem: ColumnLayout {
            
            Label {
                text: "Input Error"
                font.bold: true
                font.pixelSize: 16
                Layout.alignment: Qt.AlignHCenter
            }
            
            Label {
                text: errorPopup.errorMessage
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            StyledButton {
                text: "OK"
                Layout.alignment: Qt.AlignRight
                onClicked: errorPopup.close()
            }
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentHeight: mainLayout.height + 10
            contentWidth: parent.width
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            RowLayout {
                id: mainLayout
                width: scrollView.width

                // Left side inputs and results
                ColumnLayout {
                    id: leftColumn
                    Layout.minimumWidth: 380
                    Layout.maximumWidth: 380
                    Layout.alignment: Qt.AlignTop

                    // Controls
                    ButtonCard {
                        Layout.fillWidth: true
                        Layout.minimumHeight: 100

                        RowLayout {
                            anchors.right: parent.right

                            MessageButton {
                                title: "Reset"
                                ToolTip.text: "Reset to default values"
                                buttonIcon: '\uf053'
                                buttonColor: Style.blueGreen
                                Layout.alignment: Qt.AlignRight
                                Layout.columnSpan: 2

                                defaultMessage: ""
                                successMessage: "Parameters reset"
                                errorMessage: "PDF export failed"

                                onButtonClicked: {
                                    startOperation()

                                    calculator.resetToDefaults()

                                    operationSucceeded(2000)
                                }
                            }

                            MessageButton {
                                id: info
                                title: "Info"
                                buttonIcon: '\ue88e'
                                buttonColor: Style.charcoalGrey
                                defaultMessage: ""
                                successMessage: ""
                                errorMessage: ""

                                ToolTip.visible: false

                                onButtonClicked: {

                                    startOperation()
                                    tipsPopup.open()
                                    operationSucceeded(1/100)
                                }
                            }
                        }
                    }

                    // CT Section
                    WaveCard {
                        id: results
                        title: "Current Transformer"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 340
                        
                        showSettings: false

                        GridLayout {
                            columns: 2

                            Label { text: "CT Type:" ; Layout.minimumWidth: 160}
                            ComboBoxRound {
                                id: ctType
                                model: ["Measurement", "Protection", "Combined"]
                                onCurrentTextChanged: calculator.currentCtType = currentText.toLowerCase()
                                Layout.fillWidth: true
                                Layout.minimumWidth: 150
                            }

                            Label { text: "CT Ratio:" }
                            ComboBoxRound {
                                id: ctRatio
                                model: calculator.standardCtRatios
                                onCurrentTextChanged: if (currentText) calculator.setCtRatio(currentText)
                                Layout.fillWidth: true
                            }

                            Label { text: "Burden (VA):" }
                            TextFieldRound {
                                id: ctBurden
                                text: "15.0"
                                validator: DoubleValidator {
                                    bottom: 3.0
                                    top: 100.0
                                    notation: DoubleValidator.StandardNotation
                                    decimals: 1
                                }
                                onTextChanged: {
                                    if (acceptableInput) {
                                        calculator.burden = parseFloat(text)
                                    }
                                }
                                Layout.fillWidth: true
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                            }

                            Label { text: "Power Factor:" }
                            SpinBoxRound {
                                id: powerFactor
                                from: 50
                                to: 100
                                value: 80
                                stepSize: 5
                                onValueChanged: calculator.powerFactor = value / 100
                                Layout.fillWidth: true
                                textFromValue: function(value) { return value + "%" }
                            }

                            Label { text: "Temperature:" }
                            RowLayout {
                                Layout.fillWidth: true
                                
                                TextFieldRound {
                                    id: temperature
                                    text: "25.0"
                                    Layout.fillWidth: true
                                    validator: DoubleValidator {
                                        bottom: -40.0
                                        top: 120.0
                                        notation: DoubleValidator.StandardNotation
                                        decimals: 1
                                    }
                                    onTextChanged: {
                                        if (acceptableInput) {
                                            calculator.temperature = parseFloat(text)
                                        }
                                    }
                                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                                }
                                
                                ComboBoxRound {
                                    id: tempUnit
                                    model: ["°C", "°F"]
                                    currentIndex: 0
                                    onCurrentTextChanged: {
                                        if (currentText === "°F" && acceptableInput) {
                                            // Convert to Celsius for the backend
                                            calculator.temperature = (parseFloat(temperature.text) - 32) * 5/9
                                        } else if (currentText === "°C" && acceptableInput) {
                                            calculator.temperature = parseFloat(temperature.text)
                                        }
                                    }
                                    Layout.preferredWidth: 60
                                }
                            }

                            Label { text: "Accuracy Class:" }
                            ComboBoxRound {
                                id: accuracyClass
                                model: calculator.availableAccuracyClasses
                                onCurrentTextChanged: if (currentText) calculator.accuracyClass = currentText
                                Layout.fillWidth: true
                            }

                            Label { text: "Custom Ratio:" }
                            RowLayout {
                                Layout.fillWidth: true
                                
                                TextFieldRound {
                                    id: customRatio
                                    placeholderText: "e.g., 150/5"
                                    Layout.fillWidth: true
                                    validator: RegularExpressionValidator {
                                        regularExpression: /^\d+\/\d+$/
                                    }
                                }

                                MessageButton {
                                    Layout.alignment: Qt.AlignRight
                                    
                                    ToolTip.text: "Add Relay"
                                    buttonIcon: '\ue145'
                                    buttonColor: Style.blueGreen

                                    textVisible: false

                                    defaultMessage: ""
                                    successMessage: "Custom CT ratio added: " + customRatio.text
                                    errorMessage: "Invalid ratio format. Please use format like '100/5'"
                                    infoMessage: "CT ratio found in list"

                                    onButtonClicked: {

                                        startOperation()

                                        if (customRatio.acceptableInput) {
                                            calculator.setCtRatio(customRatio.text)
                                            let found = false
                                            for (let i = 0; i < ctRatio.model.length; i++) {
                                                if (ctRatio.model[i] === customRatio.text) {
                                                    ctRatio.currentIndex = i
                                                    found = true
                                                    operationInfo(2000)
                                                    break
                                                }
                                            }
                                            if (!found) {
                                                ctRatio.model.push(customRatio.text)
                                                ctRatio.currentIndex = ctRatio.model.length - 1
                                                operationSucceeded(2000)
                                            }
                                        } else {
                                            operationFailed(2000)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // VT Section
                    WaveCard {
                        Layout.fillWidth: true
                        Layout.minimumHeight: 180
                        title: "Voltage Transformer"

                        GridLayout {
                            columns: 2

                            Label { text: "VT Ratio:" ; Layout.minimumWidth: 160}
                            ComboBoxRound {
                                id: vtRatio
                                model: calculator.standardVtRatios
                                onCurrentTextChanged: if (currentText) calculator.setVtRatio(currentText)
                                Layout.fillWidth: true
                                Layout.minimumWidth: 150
                            }

                            Label { text: "VT Burden (VA):" }
                            TextFieldRound {
                                id: vtBurden
                                text: "100.0"
                                validator: DoubleValidator {
                                    bottom: 25.0
                                    top: 2000.0
                                    notation: DoubleValidator.StandardNotation
                                    decimals: 1
                                }
                                onTextChanged: {
                                    if (acceptableInput) {
                                        calculator.vtBurden = parseFloat(text)
                                    }
                                }
                                Layout.fillWidth: true
                            }

                            Label { text: "Rated Voltage Factor:" }
                            ComboBoxRound {
                                id: ratedVoltageFactor
                                model: ["continuous", "30s", "ground_fault"]
                                onCurrentTextChanged: calculator.ratedVoltageFactor = currentText
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Results Section
                    WaveCard {
                        Layout.fillWidth: true
                        Layout.minimumHeight: 430
                        title: "Results"

                        GridLayout {
                            columns: 2

                            Label { text: "CT Knee Point:" ; Layout.minimumWidth: 160}
                            TextFieldBlue { 
                                text: isFinite(calculator.kneePointVoltage) ? calculator.kneePointVoltage.toFixed(1) + " V" : "0.0 V"
                                Layout.minimumWidth: 150
                            }

                            Label { text: "Maximum Fault Current:" }
                            TextFieldBlue { 
                                text: isFinite(calculator.maxFaultCurrent) ? calculator.maxFaultCurrent.toFixed(1) + " A" : "0.0 A"
                            }

                            Label { text: "Minimum CT Burden:" }
                            TextFieldBlue { 
                                text: isFinite(calculator.minAccuracyBurden) ? calculator.minAccuracyBurden.toFixed(2) + " Ω" : "0.0 Ω"
                            }

                            Label { text: "Error Margin:" }
                            TextFieldBlue { 
                                text: isFinite(calculator.errorMargin) ? calculator.errorMargin.toFixed(2) + "%" : "0.0%"
                                color: calculator.errorMargin > parseFloat(accuracyClass.currentText) ? "red" : Universal.foreground
                            }

                            Label { text: "Temperature Effect:" }
                            TextFieldBlue { 
                                text: isFinite(calculator.temperatureEffect) ? calculator.temperatureEffect.toFixed(2) + "%" : "0.0%"
                            }

                            Label { text: "VT Rated Voltage:" }
                            TextFieldBlue { 
                                text: isFinite(calculator.vtRatedVoltage) ? calculator.vtRatedVoltage.toFixed(1) + " V" : "0.0 V"
                            }

                            Label { text: "VT Impedance:" }
                            TextFieldBlue { 
                                text: isFinite(calculator.vtImpedance) ? calculator.vtImpedance.toFixed(1) + " Ω" : "0.0 Ω"
                            }

                            Label { text: "VT Burden Status:" }
                            TextFieldBlue { 
                                text: calculator.vtBurdenStatus
                                color: calculator.vtBurdenWithinRange ? "green" : "red"
                                Layout.minimumHeight: 60
                                Layout.minimumWidth: 150
                                wrapMode: Text.WordWrap
                            }

                            Label { text: "Burden Utilization:" }
                            TextFieldBlue {
                                text: isFinite(calculator.vtBurdenUtilization) ? 
                                        calculator.vtBurdenUtilization.toFixed(1) + "%" : "0.0%"
                                color: {
                                    if (calculator.vtBurdenUtilization < 50) return "green"
                                    if (calculator.vtBurdenUtilization < 80) return "orange"
                                    return "red"
                                }
                            }
                        }
                    }
                }

                // Right side visualization
                WaveCard {
                    Layout.minimumHeight: 600
                    Layout.minimumWidth: 600
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    InstrumentTransformerVisualization {
                        id: transformerViz
                        anchors.fill: parent
                        
                        // CT properties
                        ctRatio: ctRatio.currentText || "100/5"
                        ctBurden: parseFloat(ctBurden.text) || 15
                        ctKneePoint: calculator.kneePointVoltage || 0
                        ctMaxFault: calculator.maxFaultCurrent || 0
                        ctErrorMargin: calculator.errorMargin || 0
                        ctAccuracyClass: accuracyClass.currentText || "0.5"
                        ctPowerFactor: powerFactor.value / 100 || 0.8
                        
                        // VT properties
                        vtRatio: vtRatio.currentText || "11000/110"
                        vtBurden: parseFloat(vtBurden.text) || 100
                        vtUtilization: calculator.vtBurdenUtilization || 0
                        vtImpedance: calculator.vtImpedance || 0
                        
                        // Theme properties
                        darkMode: Universal.theme === Universal.Dark
                        textColor: instrumentTransformerCard.textColor
                    }
                }
            }
        }
    }
}