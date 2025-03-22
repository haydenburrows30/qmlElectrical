import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import "../visualizers/"
import InstrumentTransformer 1.0

Item {
    id: instrumentTransformerCard
    // title: 'Instrument Transformer Calculator'

    property InstrumentTransformerCalculator calculator: InstrumentTransformerCalculator {}
    property color textColor: Universal.foreground

    Popup {
        id: tipsPopup
        width: 500
        height: 400
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: results.open

        onAboutToHide: {
            results.open = false
        }
        Text {
            anchors.fill: parent
            text: {"<h3>Instrument Transformer Calculator</h3><br>" +
                    "This calculator estimates the performance of current and voltage transformers based on various parameters.<br><br>" +
                    "<b>Current Transformer:</b> The type, ratio, burden, power factor, temperature, and accuracy class.<br>" +
                    "<b>Voltage Transformer:</b> The ratio, burden, rated voltage factor, and burden status.<br><br>" +
                    "The calculator provides the knee point voltage, maximum fault current, minimum CT burden, error margin, temperature effect, VT rated voltage, VT impedance, and burden utilization.<br><br>" +
                    "The visualization shows the transformer connections and the current and voltage waveforms.<br><br>" +
                    "Developed by <b>Wave</b>."
            }
            wrapMode: Text.WordWrap
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Left side inputs and results
        ColumnLayout {
            id: leftColumn
            Layout.maximumWidth: 400
            Layout.minimumWidth: 320
            Layout.fillHeight: true
            spacing: 10

            // CT Section
            WaveCard {
                title: "Current Transformer"
                Layout.fillWidth: true
                Layout.fillHeight: true
                id: results
                showSettings: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

                    Label { text: "CT Type:" }
                    ComboBox {
                        id: ctType
                        model: ["Measurement", "Protection", "Combined"]
                        onCurrentTextChanged: calculator.currentCtType = currentText.toLowerCase()
                        Layout.fillWidth: true
                    }

                    Label { text: "CT Ratio:" }
                    ComboBox {
                        id: ctRatio
                        model: calculator.standardCtRatios
                        onCurrentTextChanged: if (currentText) calculator.setCtRatio(currentText)
                        Layout.fillWidth: true
                    }

                    Label { text: "Burden (VA):" }
                    TextField {
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
                    SpinBox {
                        id: powerFactor
                        from: 50
                        to: 100
                        value: 80
                        stepSize: 5
                        onValueChanged: calculator.powerFactor = value / 100
                        Layout.fillWidth: true
                        textFromValue: function(value) { return value + "%" }
                    }

                    Label { text: "Temperature (°C):" }
                    TextField {
                        id: temperature
                        text: "25.0"
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
                        Layout.fillWidth: true
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                    }

                    Label { text: "Accuracy Class:" }
                    ComboBox {
                        id: accuracyClass
                        model: calculator.availableAccuracyClasses
                        onCurrentTextChanged: if (currentText) calculator.accuracyClass = currentText
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        Layout.margins: 10
                        height: 1
                        color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
                    }

                    Label { 
                        text: "Voltage Transformer"
                        font.bold: true
                        Layout.columnSpan: 2
                        font.pixelSize: 16
                        }

                    Label { text: "VT Ratio:" }
                    ComboBox {
                        id: vtRatio
                        model: calculator.standardVtRatios
                        onCurrentTextChanged: if (currentText) calculator.setVtRatio(currentText)
                        Layout.fillWidth: true
                    }

                    Label { text: "VT Burden (VA):" }
                    TextField {
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
                    ComboBox {
                        id: ratedVoltageFactor
                        model: ["continuous", "30s", "ground_fault"]
                        onCurrentTextChanged: calculator.ratedVoltageFactor = currentText
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        Layout.margins: 10
                        height: 1
                        color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
                    }

                    Label { 
                        text: "Results"
                        font.bold: true
                        Layout.columnSpan: 2
                        font.pixelSize: 16
                        }

                    Label { text: "CT Knee Point:" }
                    Label { 
                        text: isFinite(calculator.kneePointVoltage) ? calculator.kneePointVoltage.toFixed(1) + " V" : "0.0 V"
                        font.bold: true
                        color: Universal.foreground
                    }

                    Label { text: "Maximum Fault Current:" }
                    Label { 
                        text: isFinite(calculator.maxFaultCurrent) ? calculator.maxFaultCurrent.toFixed(1) + " A" : "0.0 A"
                        font.bold: true
                        color: Universal.foreground
                    }

                    Label { text: "Minimum CT Burden:" }
                    Label { 
                        text: isFinite(calculator.minAccuracyBurden) ? calculator.minAccuracyBurden.toFixed(2) + " Ω" : "0.0 Ω"
                        font.bold: true
                        color: Universal.foreground
                    }

                    Label { text: "Error Margin:" }
                    Label { 
                        text: isFinite(calculator.errorMargin) ? calculator.errorMargin.toFixed(2) + "%" : "0.0%"
                        font.bold: true
                        color: calculator.errorMargin > parseFloat(accuracyClass.currentText) ? "red" : Universal.foreground
                    }

                    Label { text: "Temperature Effect:" }
                    Label { 
                        text: isFinite(calculator.temperatureEffect) ? calculator.temperatureEffect.toFixed(2) + "%" : "0.0%"
                        font.bold: true
                        color: Universal.foreground
                    }

                    Label { text: "VT Rated Voltage:" }
                    Label { 
                        text: isFinite(calculator.vtRatedVoltage) ? calculator.vtRatedVoltage.toFixed(1) + " V" : "0.0 V"
                        font.bold: true
                        color: Universal.foreground
                    }

                    Label { text: "VT Impedance:" }
                    Label { 
                        text: isFinite(calculator.vtImpedance) ? calculator.vtImpedance.toFixed(1) + " Ω" : "0.0 Ω"
                        font.bold: true
                        color: Universal.foreground
                    }

                    Label { text: "VT Burden Status:" }
                    Label { 
                        text: calculator.vtBurdenStatus
                        font.bold: true
                        color: calculator.vtBurdenWithinRange ? "green" : "red"
                    }

                    Label { text: "Burden Utilization:" }
                    Label { 
                        text: isFinite(calculator.vtBurdenUtilization) ? 
                              calculator.vtBurdenUtilization.toFixed(1) + "%" : "0.0%"
                        font.bold: true
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

            TransformerVisualization {
                id: transformerViz
                anchors.fill: parent
                
                // Pass CT data
                ctRatio: ctRatio.currentText || "100/5"
                ctBurden: ctBurden.value || 15
                ctKneePoint: calculator ? calculator.kneePointVoltage : 0
                ctMaxFault: calculator ? calculator.maxFaultCurrent : 0
                
                // Pass VT data
                vtRatio: vtRatio.currentText || "11000/110"
                
                // Theme properties
                darkMode: Universal.theme === Universal.Dark
                textColor: instrumentTransformerCard.textColor
            }
        }
    }
}
