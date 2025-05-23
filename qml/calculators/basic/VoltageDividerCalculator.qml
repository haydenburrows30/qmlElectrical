import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import VoltDivider 1.0

Item {
    id: root

    property VoltageDividerCalculator calculator: VoltageDividerCalculator {}
    property bool calculatorReady: calculator !== null

    // Simplified safeValue function
    function safeValue(value, defaultVal) {
        return (value === undefined || value === null || isNaN(value) || !isFinite(value)) ? defaultVal : value;
    }
    
    // calculateVoltageDivider can be much simpler since Python does all calculations
    function calculateVoltageDivider() {
        if (!calculatorReady) return;
        calculator.setInputVoltage(parseFloat(vinField.text));
        calculator.setR1(parseFloat(r1Field.text));
        calculator.setR2(parseFloat(r2Field.text));
    }
    
    function updateCircuitVisualization() {
        // Trigger canvas redraw
        circuitCanvas.requestPaint();
    }

    PopUpText {
        id: popUpText
        parentCard: topHeader
        popupText: "<h3>Voltage Divider Equation:</h3><br>" +
                    "<b>Vout</b> = Vin × (R2 / (R1 + R2))<br><br>" +
                    "<b>Applications:</b><br>" +
                    "• Level shifting for ADC inputs<br>" +
                        "• Reference voltage generation<br>" +
                        "• Biasing circuits<br>" +
                        "• Attenuators<br>" +
                        "• Potential dividers for measurement<br><br>" +
                        "<b>Note:</b> For high impedance loads, the output voltage closely follows the theoretical value. " +
                        "For low impedance loads, loading effects must be considered."
    }

    ColumnLayout {
        anchors.centerIn: parent

        // Header with title and help button
        RowLayout {
            id: topHeader
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 5

            Label {
                text: "Voltage Divider Calculator"
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
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
            id: header
            
            WaveCard {
                id: results
                title: "Input Parameters"
                Layout.preferredWidth: 300
                Layout.minimumHeight: 230

                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    
                    Label { text: "Input Voltage (V):" }
                    TextFieldRound {
                        id: vinField
                        placeholderText: "e.g., 12"
                        text: "12"
                        validator: DoubleValidator {
                            bottom: 0
                            notation: DoubleValidator.StandardNotation
                        }
                        Layout.fillWidth: true
                        onEditingFinished: calculateVoltageDivider()
                    }
                    
                    Label { text: "Resistor R1 (Ω):" }
                    TextFieldRound {
                        id: r1Field
                        placeholderText: "e.g., 10000"
                        text: "10000"
                        validator: DoubleValidator {
                            bottom: 0.001
                            notation: DoubleValidator.StandardNotation
                        }
                        Layout.fillWidth: true
                        onEditingFinished: calculateVoltageDivider()
                    }
                    
                    Label { text: "Resistor R2 (Ω):" }
                    TextFieldRound {
                        id: r2Field
                        placeholderText: "e.g., 10000"
                        text: "10000"
                        validator: DoubleValidator {
                            bottom: 0.001
                            notation: DoubleValidator.StandardNotation
                        }
                        Layout.fillWidth: true
                        onEditingFinished: calculateVoltageDivider()
                    }
                    
                    Item { Layout.columnSpan: 2; Layout.preferredHeight: 10 }
                    
                    StyledButton {
                        text: "Calculate"
                        Layout.columnSpan: 2
                        Layout.alignment: Qt.AlignRight
                        onClicked: calculateVoltageDivider()
                        icon.source: "../../../icons/rounded/calculate.svg"
                    }

                    Label { Layout.fillHeight: true }
                }
            }
            
            // Results
            WaveCard {
                title: "Results"
                Layout.preferredWidth: 300
                Layout.minimumHeight: 230
                
                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    Label { text: "Output Voltage (V):" }

                    TextFieldBlue {
                        id: voutField
                        text: calculatorReady ? calculator.outputVoltage.toFixed(3) : "0.000"
                    }
                    
                    Label { text: "Current (mA):" }
                    TextFieldBlue {
                        id: currentField
                        text: calculatorReady ? (calculator.current * 1000).toFixed(3) : "0.000"
                    }
                    
                    Label { text: "Power in R1 (mW):" }
                    TextFieldBlue {
                        id: powerR1Field
                        text: calculatorReady ? (calculator.powerR1 * 1000).toFixed(3) : "0.000"
                        Layout.fillWidth: true
                    }
                    
                    Label { text: "Power in R2 (mW):" }
                    TextFieldBlue {
                        id: powerR2Field
                        text: calculatorReady ? (calculator.powerR2 * 1000).toFixed(3) : "0.000"
                    }
                }
            }
        }
        
        // Circuit visualization
        WaveCard {
            title: "Circuit Visualization"
            Layout.minimumHeight: 300
            Layout.minimumWidth: header.width
            
            CircuitVisualizer {
                id: circuitCanvas
                anchors.fill: parent
                
                // Pass values from calculator to the visualizer
                inputVoltage: vinField.text
                resistorR1: r1Field.text 
                resistorR2: r2Field.text
                outputVoltage: voutField.text
                currentValue: calculatorReady ? (calculator.current * 1000).toFixed(3) : "0.000"
            }
        }
    }
    
    Component.onCompleted: {
        // Calculate initial values
        calculateVoltageDivider()
    }
    
    Connections {
        target: calculator
        function onCalculationCompleted() {
            updateCircuitVisualization()
        }
    }
}
