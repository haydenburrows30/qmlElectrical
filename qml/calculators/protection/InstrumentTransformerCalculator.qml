import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import InstrumentTransformer 1.0

Item {
    id: instrumentTransformerCard

    property InstrumentTransformerCalculator calculator: InstrumentTransformerCalculator {}
    property color textColor: Universal.foreground

    PopUpText {
        id: popUpText
        parentCard: topHeader
        popupText: "<h3>Instrument Transformer Calculator</h3><br>" +
                    "This calculator estimates the performance of current and voltage transformers based on various parameters.<br><br>" +
                    "<b>Current Transformer:</b> The type, ratio, burden, power factor, temperature, and accuracy class.<br>" +
                    "<b>Voltage Transformer:</b> The ratio, burden, rated voltage factor, and burden status.<br><br>" +
                    "The calculator provides the knee point voltage, maximum fault current, minimum CT burden, error margin, temperature effect, VT rated voltage, VT impedance, and burden utilization.<br><br>" +
                    "The visualization shows the transformer connections and the current and voltage waveforms.<br><br>" +
                    "Developed by <b>Wave</b>."
        widthFactor: 0.5
        heightFactor: 0.5
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
                icon.source: "../../../icons/rounded/check.svg"
                text: "OK"
                Layout.alignment: Qt.AlignRight
                onClicked: errorPopup.close()
            }
        }
    }

    Connections {
        target: calculator
        
        function onValidationError(message) {
            errorPopup.errorMessage = message
            errorPopup.open()
        }
        
        function onResetCompleted() {
            // Update UI elements after reset
            ctBurden.text = calculator.burden.toFixed(1)
            temperature.text = calculator.temperature.toFixed(1)
            vtBurden.text = calculator.vtBurden.toFixed(1)
            
            // Update comboboxes - find the correct indices
            let ctTypeIndex = ctType.find(calculator.currentCtType.charAt(0).toUpperCase() + calculator.currentCtType.slice(1))
            if (ctTypeIndex !== -1) ctType.currentIndex = ctTypeIndex
            
            let accClassIndex = accuracyClass.find(calculator.accuracyClass)
            if (accClassIndex !== -1) accuracyClass.currentIndex = accClassIndex
            
            let vtRatioIndex = vtRatio.find(calculator.primaryVoltage + "/" + calculator.secondaryVoltage)
            if (vtRatioIndex !== -1) vtRatio.currentIndex = vtRatioIndex
            
            let ratedVoltageFactorIndex = ratedVoltageFactor.find(calculator.ratedVoltageFactor)
            if (ratedVoltageFactorIndex !== -1) ratedVoltageFactor.currentIndex = ratedVoltageFactorIndex
        }
        
        function onPdfExportStatusChanged(success, message) {
            if (success) {
                errorPopup.errorMessage = "Success: " + message
                errorPopup.open()
            } else {
                errorPopup.errorMessage = "Error: " + message
                errorPopup.open()
            }
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        Flickable {
            id: flickableMain
            contentHeight: mainLayout.height + 20
            contentWidth: parent.width
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            ColumnLayout {
                id: mainLayout
                width: flickableMain.width - 20

                // Header with title and help button
                RowLayout {
                    id: topHeader
                    Layout.fillWidth: true
                    Layout.bottomMargin: 5
                    Layout.leftMargin: 5

                    Label {
                        text: "Instrument Transformer Calculator"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    StyledButton {
                        ToolTip.text: "Export to PDF"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        Layout.alignment: Qt.AlignRight
                        icon.source: "../../../icons/rounded/download.svg"
                        
                        onClicked: {
                            calculator.exportToPdf()
                        }
                    }

                    StyledButton {
                        ToolTip.text: "Reset to default values"
                        Layout.alignment: Qt.AlignRight
                        Layout.columnSpan: 2
                        icon.source: "../../../icons/rounded/restart_alt.svg"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500

                        onClicked: {
                            calculator.resetToDefaults()
                        }
                    }

                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Information"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: popUpText.open()
                    }
                }

                RowLayout {
                    // Left side inputs and results
                    ColumnLayout {
                        id: leftColumn
                        Layout.minimumWidth: 380
                        Layout.maximumWidth: 380
                        Layout.alignment: Qt.AlignTop

                        // CT Section
                        WaveCard {
                            id: results
                            title: "Current Transformer"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 340

                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                uniformCellWidths: true

                                Label { text: "CT Type:"}
                                ComboBoxRound {
                                    id: ctType
                                    model: ["Measurement", "Protection", "Combined"]
                                    onCurrentTextChanged: calculator.currentCtType = currentText.toLowerCase()
                                    Layout.fillWidth: true
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
                                    ToolTip.text: "Enter burden between 3.0 and 100.0 VA"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
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
                                        ToolTip.text: "Enter in format: primary/secondary"
                                        ToolTip.visible: hovered
                                        ToolTip.delay: 500
                                    }

                                    StyledButton {
                                        Layout.alignment: Qt.AlignRight
                                        ToolTip.text: "Add Custom Ratio"
                                        ToolTip.visible: hovered
                                        ToolTip.delay: 500
                                        icon.source: "../../../icons/rounded/add.svg"

                                        onClicked: {
                                            if (customRatio.acceptableInput) {
                                                calculator.setCtRatio(customRatio.text)
                                                let found = false
                                                for (let i = 0; i < ctRatio.model.length; i++) {
                                                    if (ctRatio.model[i] === customRatio.text) {
                                                        ctRatio.currentIndex = i
                                                        found = true
                                                        break
                                                    }
                                                }
                                                if (!found) {
                                                    ctRatio.model.push(customRatio.text)
                                                    ctRatio.currentIndex = ctRatio.model.length - 1
                                                }
                                            } else {
                                                errorPopup.errorMessage = "Invalid ratio format. Use format: primary/secondary (e.g., 150/5)"
                                                errorPopup.open()
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
                                anchors.fill: parent
                                uniformCellWidths: true

                                Label { text: "VT Ratio:" ; Layout.fillWidth: true}
                                ComboBoxRound {
                                    id: vtRatio
                                    model: calculator.standardVtRatios
                                    onCurrentTextChanged: if (currentText) calculator.setVtRatio(currentText)
                                    Layout.fillWidth: true
                                }

                                Label { text: "VT Burden (VA):" ; Layout.fillWidth: true}
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
                                    ToolTip.text: "Enter burden between 25.0 and 2000.0 VA"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
                                }

                                Label { text: "Rated Voltage Factor:" ; Layout.fillWidth: true}
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
                            Layout.minimumHeight: 550
                            title: "Results"

                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                uniformCellWidths: true

                                Label { text: "CT Knee Point:"}
                                TextFieldBlue { 
                                    text: isFinite(calculator.kneePointVoltage) ? calculator.kneePointVoltage.toFixed(1) + " V" : "0.0 V"
                                    ToolTip.text: "Voltage at which the CT begins to saturate"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
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

                                Label { text: "CT Saturation Status:" }
                                TextFieldBlue {
                                    text: calculator.saturationStatus
                                    color: {
                                        if (calculator.saturationStatus.includes("Linear")) return "green"
                                        if (calculator.saturationStatus.includes("Slightly")) return "lightgreen"
                                        if (calculator.saturationStatus.includes("Moderately")) return "orange"
                                        return "red"
                                    }
                                }

                                // Additional section for recommendations (if they exist)
                                Label { 
                                    text: "Recommendations:" 
                                    visible: calculator.accuracyRecommendation !== "No issues detected. Operation within specifications."
                                }
                                TextFieldBlue { 
                                    text: calculator.accuracyRecommendation
                                    visible: calculator.accuracyRecommendation !== "No issues detected. Operation within specifications."
                                    wrapMode: Text.WordWrap
                                    Layout.minimumHeight: 60
                                    Layout.fillWidth: true
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
}