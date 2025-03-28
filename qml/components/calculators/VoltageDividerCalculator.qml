import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../"
import "../visualizers/"
import "../style"
import "../backgrounds"
import "../popups"

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

    Popup {
        id: tipsPopup
        width: 600
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
        VoltageDividerPopup {}
    }

    ColumnLayout {
        anchors.centerIn: parent
        anchors.margins: Style.spacing
        spacing: Style.spacing
        
        RowLayout {
            id: header
            // Input parameters
            WaveCard {
                id: results
                title: "Input Parameters"
                Layout.preferredWidth: 300
                Layout.minimumHeight: 230

                showSettings: true
                
                GridLayout {
                    anchors.fill: parent
                    anchors.margins: Style.spacing
                    columnSpacing: Style.spacing
                    rowSpacing: Style.spacing
                    columns: 2
                    Layout.fillWidth: true
                    
                    Label { text: "Input Voltage (V):" }
                    TextField {
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
                    TextField {
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
                    TextField {
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
                    
                    Button {
                        text: "Calculate"
                        Layout.columnSpan: 2
                        Layout.alignment: Qt.AlignRight
                        onClicked: calculateVoltageDivider()
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
                    anchors.margins: Style.spacing
                    columns: 2
                    columnSpacing: Style.spacing
                    rowSpacing: Style.spacing
                    Layout.fillWidth: true
                    
                    Label { text: "Output Voltage (V):" }
                    TextField {
                        id: voutField
                        readOnly: true
                        text: calculatorReady ? calculator.outputVoltage.toFixed(3) : "0.000"
                        Layout.fillWidth: true
                        background: Rectangle {
                            color: "#e8f6ff"
                            border.color: "#0078d7"
                            radius: 2
                        }
                    }
                    
                    Label { text: "Current (mA):" }
                    TextField {
                        id: currentField
                        readOnly: true
                        text: calculatorReady ? (calculator.current * 1000).toFixed(3) : "0.000"
                        Layout.fillWidth: true
                        background: Rectangle {
                            color: "#e8f6ff"
                            border.color: "#0078d7"
                            radius: 2
                        }
                    }
                    
                    Label { text: "Power in R1 (mW):" }
                    TextField {
                        id: powerR1Field
                        readOnly: true
                        text: calculatorReady ? (calculator.powerR1 * 1000).toFixed(3) : "0.000"
                        Layout.fillWidth: true
                        background: Rectangle {
                            color: "#e8f6ff"
                            border.color: "#0078d7"
                            radius: 2
                        }
                    }
                    
                    Label { text: "Power in R2 (mW):" }
                    TextField {
                        id: powerR2Field
                        readOnly: true
                        text: calculatorReady ? (calculator.powerR2 * 1000).toFixed(3) : "0.000"
                        Layout.fillWidth: true
                        background: Rectangle {
                            color: "#e8f6ff"
                            border.color: "#0078d7"
                            radius: 2
                        }
                    }

                    Label { Layout.fillHeight: true }
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
                anchors.margins: Style.spacing
                
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
