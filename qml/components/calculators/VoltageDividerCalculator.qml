import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../"

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
    
    ColumnLayout {
        anchors.centerIn: parent
        anchors.margins: 10
        spacing: 10
        
        RowLayout {
            // Input parameters
            WaveCard {
                title: "Input Parameters"
                Layout.preferredWidth: 400
                Layout.minimumHeight: 250
                
                GridLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    columns: 2
                    columnSpacing: 20
                    rowSpacing: 10
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
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: calculateVoltageDivider()
                    }
                }
            }
            
            // Results
            WaveCard {
                title: "Results"
                Layout.preferredWidth: 400
                Layout.minimumHeight: 250
                
                GridLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    columns: 2
                    columnSpacing: 20
                    rowSpacing: 10
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
                }
            }
        }
        
        // Circuit visualization
        WaveCard {
            title: "Circuit Visualization"
            Layout.fillWidth: true
            Layout.preferredHeight: 300  // Increased height
            Layout.minimumHeight: 300    // Set minimum height
            
            Canvas {
                id: circuitCanvas
                anchors.fill: parent
                anchors.margins: 20      // Increased margins
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    // Colors and dimensions
                    ctx.strokeStyle = "#333333";
                    ctx.fillStyle = "#333333";
                    ctx.lineWidth = 2;
                    ctx.font = "14px sans-serif";  // Increased font size
                    
                    var startX = width * 0.2;      // Adjusted starting position
                    var startY = height / 2;
                    var resistorLength = width * 0.2;  // Made relative to width
                    var resistorHeight = 30;
                    var wireLength = width * 0.1;     // Made relative to width
                    
                    // Draw battery with more space
                    ctx.beginPath();
                    ctx.moveTo(startX, startY - 25);  // Increased spacing
                    ctx.lineTo(startX, startY + 25);
                    ctx.stroke();
                    
                    // Battery symbol details
                    ctx.beginPath();
                    ctx.moveTo(startX - 15, startY - 15);
                    ctx.lineTo(startX + 15, startY - 15);
                    ctx.stroke();
                    
                    ctx.beginPath();
                    ctx.moveTo(startX - 7, startY);
                    ctx.lineTo(startX + 7, startY);
                    ctx.stroke();
                    
                    ctx.beginPath();
                    ctx.moveTo(startX - 15, startY + 15);
                    ctx.lineTo(startX + 15, startY + 15);
                    ctx.stroke();
                    
                    // Draw Vin label with better positioning
                    ctx.fillText("Vin = " + vinField.text + "V", startX - 60, startY - 35);
                    
                    // Draw top wire
                    ctx.beginPath();
                    ctx.moveTo(startX, startY - 25);
                    ctx.lineTo(startX + wireLength, startY - 25);
                    ctx.lineTo(startX + wireLength, startY - 60);
                    ctx.lineTo(startX + wireLength + resistorLength + wireLength, startY - 60);
                    ctx.lineTo(startX + wireLength + resistorLength + wireLength, startY - 25);
                    ctx.lineTo(startX + wireLength + resistorLength + wireLength + wireLength, startY - 25);
                    ctx.stroke();
                    
                    // Draw R1 with better label positioning
                    ctx.beginPath();
                    ctx.rect(startX + wireLength, startY - 25, resistorLength, resistorHeight);
                    ctx.stroke();
                    ctx.fillText("R1 = " + r1Field.text + "Ω", startX + wireLength, startY - 35);
                    
                    // Draw R2 with better label positioning
                    ctx.beginPath();
                    ctx.rect(startX + wireLength, startY + 25, resistorLength, resistorHeight);
                    ctx.stroke();
                    ctx.fillText("R2 = " + r2Field.text + "Ω", startX + wireLength, startY + 80);
                    
                    // Draw bottom wire
                    ctx.beginPath();
                    ctx.moveTo(startX, startY + 25);
                    ctx.lineTo(startX + wireLength, startY + 25);
                    ctx.moveTo(startX + wireLength + resistorLength, startY + 40);
                    ctx.lineTo(startX + wireLength + resistorLength + wireLength, startY + 40);
                    ctx.lineTo(startX + wireLength + resistorLength + wireLength, startY + 25);
                    ctx.lineTo(startX + wireLength + resistorLength + wireLength + wireLength, startY + 25);
                    ctx.stroke();
                    
                    // Draw Vout connection and label
                    ctx.beginPath();
                    ctx.moveTo(startX + wireLength + resistorLength, startY + 40);
                    ctx.lineTo(startX + wireLength + resistorLength, startY - 40);
                    ctx.stroke();
                    
                    // Draw Vout label with better positioning
                    ctx.fillText("Vout = " + voutField.text + "V", 
                               startX + wireLength + resistorLength + 10, 
                               startY - 35);
                    
                    // Draw ground symbol
                    var groundX = startX + wireLength + resistorLength + wireLength + wireLength;
                    var groundY = startY;
                    
                    ctx.beginPath();
                    ctx.moveTo(groundX, groundY - 10);
                    ctx.lineTo(groundX, groundY + 10);
                    ctx.moveTo(groundX - 10, groundY + 10);
                    ctx.lineTo(groundX + 10, groundY + 10);
                    ctx.moveTo(groundX - 8, groundY + 15);
                    ctx.lineTo(groundX + 8, groundY + 15);
                    ctx.moveTo(groundX - 6, groundY + 20);
                    ctx.lineTo(groundX + 6, groundY + 20);
                    ctx.stroke();
                }
            }
        }
        
        // Formula and explanation
        WaveCard {
            title: "Voltage Divider Formula"
            Layout.fillWidth: true
            Layout.minimumHeight: 300
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                width: parent.width
                
                Text {
                    text: "<b>Voltage Divider Equation:</b>"
                    font.pixelSize: 14
                }
                
                Text {
                    text: "Vout = Vin × (R2 / (R1 + R2))"
                    font.italic: true
                }
                
                Text {
                    text: "<b>Applications:</b>"
                    font.pixelSize: 14
                    Layout.topMargin: 10
                }
                
                Text {
                    text: "• Level shifting for ADC inputs\n" +
                          "• Reference voltage generation\n" +
                          "• Biasing circuits\n" +
                          "• Attenuators\n" +
                          "• Potential dividers for measurement"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                Text {
                    text: "<b>Note:</b> For high impedance loads, the output voltage closely follows the theoretical value. " +
                          "For low impedance loads, loading effects must be considered."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                }
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
