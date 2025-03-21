import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../"

import OhmsLaw 1.0

Item {
    id: root

    property OhmsLawCalculator calculator: OhmsLawCalculator {}
    property bool calculatorReady: calculator !== null

    function calculateOhmsLaw() {
        if (!calculatorReady) return;
        
        let value1 = parseFloat(param1Value.text);
        let value2 = parseFloat(param2Value.text);
        
        if (isNaN(value1) || isNaN(value2)) return;
        
        // Create mapping for parameter combinations
        const calculationMap = {
            "0_1": calculator.calculateFromVI,
            "0_2": calculator.calculateFromVR,
            "0_3": calculator.calculateFromVP,
            "1_2": calculator.calculateFromIR,
            "1_3": calculator.calculateFromIP,
            "2_3": calculator.calculateFromRP
        };
        
        const key = selectedParam1.currentIndex + "_" + selectedParam2.currentIndex;
        const calcFunction = calculationMap[key];
        
        if (calcFunction) {
            calcFunction(value1, value2);
        }
    }
    
    function updateVisualization() {
        ohmsLawCanvas.requestPaint();
    }

    ColumnLayout {
        anchors.centerIn: parent
        anchors.margins: 10
        spacing: 10

        RowLayout {

            WaveCard {
                title: "Input Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 200
                Layout.minimumWidth: 350
                Layout.maximumWidth: 350
                Layout.alignment: Qt.AlignTop
                
                GridLayout {
                    anchors.margins: 10
                    columns: 3
                    columnSpacing: 10
                    rowSpacing: 10
                    Layout.fillWidth: true
                    
                    Label { text: "Select Two Known Parameters:"; Layout.columnSpan: 3 }
                    
                    Label { text: "Parameter 1:" }
                    ComboBox {
                        id: selectedParam1
                        Layout.minimumWidth: 120
                        Layout.fillWidth: true
                        model: ["Voltage (V)", "Current (I)", "Resistance (R)", "Power (P)"]
                        currentIndex: 0
                        onActivated: {
                            updateParamUnit(0);
                        }
                    }
                    TextField {
                        id: param1Value
                        Layout.minimumWidth: 100
                        placeholderText: "Enter value"
                        text: "12"
                        validator: DoubleValidator {
                            bottom: 0.00001
                            notation: DoubleValidator.StandardNotation
                        }
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
                        Layout.minimumWidth: 100
                        placeholderText: "Enter value"
                        text: "100"
                        validator: DoubleValidator {
                            bottom: 0.00001
                            notation: DoubleValidator.StandardNotation
                        }
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

            WaveCard {
                title: "Results"
                Layout.fillWidth: true
                Layout.minimumHeight: 200
                Layout.minimumWidth: 250
                Layout.maximumWidth: 250
                Layout.alignment: Qt.AlignTop
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    width: parent.width
                    spacing: 20

                    GridLayout {
                        id: resultGrid
                        columns: 2
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        columnSpacing: 10
                        
                        Text { text: "Voltage (V):" ; Layout.minimumWidth: 100 }
                        Text { text: calculatorReady ? calculator.voltage.toFixed(1) + " V" : "N/A" ; font.bold: true }
                        
                        Text { text: "Current (I):" }
                        Text { text: calculatorReady ? calculator.current.toFixed(1) + " A" : "N/A" ; font.bold: true }
                        
                        Text { text: "Resistance (R):" }
                        Text { text: calculatorReady ? calculator.resistance.toFixed(1) + " Ω" : "N/A" ; font.bold: true }
                        
                        Text { text: "Power (P):" }
                        Text { text: calculatorReady ? calculator.power.toFixed(1) + " W" : "N/A" ; font.bold: true }
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
                                calculator.voltage,
                                calculator.current,
                                calculator.resistance,
                                calculator.power
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

                                let labelX = x2 - 10;
                                let labelY = y2 + 5;
                                ctx.fillText(labels[i] + ": " + values[i].toFixed(2), labelX, labelY);
                            }
                        }
                    }
                }
            }
        }

        WaveCard {
            title: "Ohm's Law Formulas"
            Layout.fillWidth: true
            Layout.minimumHeight: 400
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
    }

    function updateParamUnit(paramIndex) {
        if (selectedParam1.currentIndex === selectedParam2.currentIndex) {
            if (paramIndex === 0) {
                selectedParam2.currentIndex = (selectedParam1.currentIndex + 2) % 4;
            } else {
                selectedParam1.currentIndex = (selectedParam2.currentIndex + 2) % 4;
            }
        }
    }
    
    Component.onCompleted: {
        calculateOhmsLaw()
    }

    Connections {
        target: calculator
        function onCalculationCompleted() {
            updateVisualization()
        }
    }
}
