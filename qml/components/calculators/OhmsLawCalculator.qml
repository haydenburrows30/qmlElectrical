import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../"

import OhmsLaw 1.0

Item {
    id: root
    
    // Simplified safeValue function
    function safeValue(value, defaultVal) {
        return (value === undefined || value === null || isNaN(value) || !isFinite(value)) ? defaultVal : value;
    }
    
    // Add property for calculator
    property OhmsLawCalculator calculator: OhmsLawCalculator {}
    property bool calculatorReady: calculator !== null

    // Simplified calculateOhmsLaw function
    function calculateOhmsLaw() {
        if (!calculatorReady) return;
        
        let value1 = parseFloat(param1Value.text);
        let value2 = parseFloat(param2Value.text);
        
        if (isNaN(value1) || isNaN(value2)) return;
        
        switch(selectedParam1.currentIndex + "_" + selectedParam2.currentIndex) {
            case "0_1": calculator.calculateFromVI(value1, value2); break;
            case "0_2": calculator.calculateFromVR(value1, value2); break;
            case "0_3": calculator.calculateFromVP(value1, value2); break;
            case "1_2": calculator.calculateFromIR(value1, value2); break;
            case "1_3": calculator.calculateFromIP(value1, value2); break;
            case "2_3": calculator.calculateFromRP(value1, value2); break;
        }
    }
    
    function updateVisualization() {
        ohmsLawCanvas.requestPaint();
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
            
        WaveCard {
            title: "Input Parameters"
            Layout.fillWidth: true
            Layout.minimumHeight: 300
            Layout.minimumWidth: 500
            Layout.maximumWidth: 500
            Layout.alignment: Qt.AlignTop
            
            GridLayout {
                anchors.fill: parent
                anchors.margins: 10
                columns: 3
                columnSpacing: 10
                rowSpacing: 15
                Layout.fillWidth: true
                
                Text { text: "Select Two Known Parameters:" }
                Item { Layout.fillWidth: true }
                Item { Layout.fillWidth: true }
                
                Label { text: "Parameter 1:" }
                ComboBox {
                    id: selectedParam1
                    Layout.fillWidth: true
                    model: ["Voltage (V)", "Current (I)", "Resistance (R)", "Power (P)"]
                    currentIndex: 0
                    onActivated: {
                        updateParamUnit(0);
                    }
                }
                TextField {
                    id: param1Value
                    placeholderText: "Enter value"
                    text: "12"
                    validator: DoubleValidator {
                        bottom: 0.00001
                        notation: DoubleValidator.StandardNotation
                    }
                    Layout.preferredWidth: 150
                    onEditingFinished: calculateOhmsLaw()
                }
                
                Label { text: "Parameter 2:" }
                ComboBox {
                    id: selectedParam2
                    Layout.fillWidth: true
                    model: ["Voltage (V)", "Current (I)", "Resistance (R)", "Power (P)"]
                    currentIndex: 2
                    onActivated: {
                        updateParamUnit(1);
                    }
                }
                TextField {
                    id: param2Value
                    placeholderText: "Enter value"
                    text: "100"
                    validator: DoubleValidator {
                        bottom: 0.00001
                        notation: DoubleValidator.StandardNotation
                    }
                    Layout.preferredWidth: 150
                    onEditingFinished: calculateOhmsLaw()
                }
                
                Button {
                    text: "Calculate"
                    Layout.columnSpan: 3
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: calculateOhmsLaw()
                }
            }
        }
        
        // Results
        WaveCard {
            title: "Results"
            Layout.fillWidth: true
            Layout.minimumHeight: 300
            Layout.minimumWidth: 400
            Layout.maximumWidth: 400
            Layout.alignment: Qt.AlignTop
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                width: parent.width
                spacing: 20
                
                Text {
                    id: resultText
                    text: calculatorReady ? 
                        "Results:\n\n" +
                        "Voltage (V): " + calculator.voltage.toFixed(3) + " V\n" +
                        "Current (I): " + calculator.current.toFixed(3) + " A\n" +
                        "Resistance (R): " + calculator.resistance.toFixed(3) + " Ω\n" +
                        "Power (P): " + calculator.power.toFixed(3) + " W" :
                        "Results will appear here..."
                    Layout.fillWidth: true
                }
                
                Canvas {
                    id: ohmsLawCanvas
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 200
                    
                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        
                        // Draw a simple circuit for visualization
                        ctx.strokeStyle = "#333333";
                        ctx.fillStyle = "#333333";
                        ctx.lineWidth = 2;
                        ctx.font = "12px sans-serif";
                        
                        let centerX = width / 2;
                        let centerY = height / 2;
                        let radius = Math.min(width, height) / 2.5;
                        
                        // Draw the circuit
                        ctx.beginPath();
                        ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                        ctx.stroke();
                        
                        // Draw the Ohm's Law formula in the middle
                        ctx.fillText("V = I × R", centerX - 30, centerY - 10);
                        ctx.fillText("P = V × I", centerX - 30, centerY + 10);
                        
                        // Draw spokes with labels
                        let angleStep = Math.PI / 2;
                        let labels = ["V", "I", "R", "P"];
                        let values = [
                            parseFloat(resultText.text.match(/Voltage.*?(\d+\.\d+)/)[1]) || 0,
                            parseFloat(resultText.text.match(/Current.*?(\d+\.\d+)/)[1]) || 0,
                            parseFloat(resultText.text.match(/Resistance.*?(\d+\.\d+)/)[1]) || 0,
                            parseFloat(resultText.text.match(/Power.*?(\d+\.\d+)/)[1]) || 0
                        ];
                        
                        for (let i = 0; i < 4; i++) {
                            let angle = i * angleStep;
                            let x1 = centerX + radius * Math.cos(angle);
                            let y1 = centerY + radius * Math.sin(angle);
                            let x2 = centerX + (radius + 20) * Math.cos(angle);
                            let y2 = centerY + (radius + 20) * Math.sin(angle);
                            
                            ctx.beginPath();
                            ctx.moveTo(centerX, centerY);
                            ctx.lineTo(x1, y1);
                            ctx.stroke();
                            
                            // Position labels appropriately
                            let labelX = x2 - 10;
                            let labelY = y2 + 5;
                            ctx.fillText(labels[i] + ": " + values[i].toFixed(2), labelX, labelY);
                        }
                    }
                }
            }
        }
        
        // Formulas and explanation
        WaveCard {
            title: "Ohm's Law Formulas"
            Layout.fillWidth: true
            Layout.minimumHeight: 500
            Layout.minimumWidth: 500
            Layout.maximumWidth: 500
            Layout.alignment: Qt.AlignTop
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                width: parent.width
                spacing: 10
                
                Text {
                    text: "<b>Basic Ohm's Law Equations:</b>"
                    font.pixelSize: 14
                }
                
                GridLayout {
                    columns: 2
                    Layout.fillWidth: true
                    columnSpacing: 30
                    
                    Text { text: "Voltage (V):" }
                    Text { text: "V = I × R" }
                    
                    Text { text: "Current (I):" }
                    Text { text: "I = V / R" }
                    
                    Text { text: "Resistance (R):" }
                    Text { text: "R = V / I" }
                    
                    Text { text: "Power (P):" }
                    Text { text: "P = V × I = I² × R = V² / R" }
                }
                
                Text {
                    text: "<b>Applications:</b>"
                    font.pixelSize: 14
                    Layout.topMargin: 10
                }
                
                Text {
                    text: "Ohm's Law is the foundation of electrical engineering and is used for circuit analysis, " +
                          "component selection, power calculations, fuse and circuit protection sizing, voltage " +
                          "regulation, and more. Understanding these relationships is essential for designing and " +
                          "troubleshooting electrical and electronic circuits."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                Text {
                    text: "<b>Note:</b> Ohm's Law applies to resistive elements in DC circuits and to the magnitude " +
                          "of voltage, current, and impedance in sinusoidal AC circuits."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
    
    // Helper function to update unit labels based on selection
    function updateParamUnit(paramIndex) {
        // Logic to enforce different selections if needed
        if (selectedParam1.currentIndex === selectedParam2.currentIndex) {
            // Adjust the other parameter to avoid duplication
            if (paramIndex === 0) {
                selectedParam2.currentIndex = (selectedParam1.currentIndex + 2) % 4;
            } else {
                selectedParam1.currentIndex = (selectedParam2.currentIndex + 2) % 4;
            }
        }
    }
    
    Component.onCompleted: {
        // Calculate initial values
        calculateOhmsLaw()
    }

    // Add Connections object
    Connections {
        target: calculator
        function onCalculationCompleted() {
            updateVisualization()
        }
    }
}
