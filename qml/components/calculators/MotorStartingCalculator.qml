import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import MotorStarting 1.0  // Import the correct namespace

WaveCard {
    id: motorStartingCard
    title: 'Motor Starting Calculator'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 250

    info: ""
    
    // Create a local instance of our calculator
    property MotorStartingCalculator calculator: MotorStartingCalculator {}

    ColumnLayout {
        anchors.fill: parent
        
        RowLayout {
            spacing: 10

            Label {
                text: "Motor Power (kW):"
                Layout.preferredWidth: 120
            }

            TextField {
                id: motorPower
                placeholderText: "Enter Power"
                onTextChanged: calculator.setMotorPower(parseFloat(text))
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignRight
            }
            
            Label {
                text: "Efficiency (%):"
                Layout.preferredWidth: 120
            }

            TextField {
                id: motorEfficiency
                placeholderText: "Enter Efficiency"
                text: "90"
                onTextChanged: calculator.setEfficiency(parseFloat(text) / 100)
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignRight
            }
        }

        RowLayout {
            spacing: 10

            Label {
                text: "Power Factor:"
                Layout.preferredWidth: 120
            }

            TextField {
                id: motorPowerFactor
                placeholderText: "Enter PF"
                text: "0.85"
                onTextChanged: calculator.setPowerFactor(parseFloat(text))
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignRight
            }
            
            Label {
                text: "Starting Method:"
                Layout.preferredWidth: 120
            }

            ComboBox {
                id: startingMethod
                model: ["DOL", "Star-Delta", "Soft-Starter", "VFD"]
                onCurrentTextChanged: {
                    if (currentText) {
                        console.log("Selecting starting method:", currentText)
                        calculator.startingMethod = currentText
                    }
                }
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignRight
            }
        }

        RowLayout {
            spacing: 10
            Layout.topMargin: 10

            ColumnLayout {
                Layout.preferredWidth: 280
                
                RowLayout {
                    Label {
                        text: "Full Load Current:"
                        Layout.preferredWidth: 150
                        font.bold: true
                    }
                    
                    Text {
                        text: !isNaN(calculator.startingCurrent / calculator.startingMultiplier) ? 
                              (calculator.startingCurrent / calculator.startingMultiplier).toFixed(1) + " A" : "0.0 A"
                        Layout.preferredWidth: 120
                        font.bold: true
                    }
                }
                
                RowLayout {
                    Label {
                        text: "Starting Current:"
                        Layout.preferredWidth: 150
                    }
                    
                    Text {
                        text: !isNaN(calculator.startingCurrent) ? 
                              calculator.startingCurrent.toFixed(1) + " A" : "0.0 A"
                        color: "red"
                        Layout.preferredWidth: 120
                    }
                }
                
                RowLayout {
                    Label {
                        text: "Starting Torque:"
                        Layout.preferredWidth: 150
                    }
                    
                    Text {
                        text: !isNaN(calculator.startingTorque) ? 
                              (calculator.startingTorque * 100).toFixed(0) + "% FLT" : "0% FLT"
                        Layout.preferredWidth: 120
                    }
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 150
                color: "transparent"
                border.color: "gray"
                border.width: 1
                
                Canvas {
                    id: motorStartCanvas
                    anchors.fill: parent
                    anchors.margins: 10
                    
                    property real startingMultiplier: calculator ? calculator.startingMultiplier : 7.0
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        
                        var width = motorStartCanvas.width;
                        var height = motorStartCanvas.height;
                        
                        // Draw starting current profile
                        ctx.beginPath();
                        ctx.moveTo(0, height * 0.1);  // Start at 10% from top
                        
                        // Draw different profiles based on starting method
                        switch(startingMethod.currentText) {
                            case "DOL":
                                // Direct square wave
                                ctx.lineTo(width * 0.1, height * 0.1);
                                ctx.lineTo(width * 0.1, height * 0.9);
                                ctx.lineTo(width, height * 0.9);
                                break;
                                
                            case "Star-Delta":
                                // Two-step start
                                ctx.lineTo(width * 0.1, height * 0.1);
                                ctx.lineTo(width * 0.1, height * 0.4);
                                ctx.lineTo(width * 0.3, height * 0.4);
                                ctx.lineTo(width * 0.3, height * 0.9);
                                ctx.lineTo(width, height * 0.9);
                                break;
                                
                            case "Soft-Starter":
                                // Gradual ramp
                                ctx.lineTo(width * 0.1, height * 0.1);
                                ctx.quadraticCurveTo(
                                    width * 0.4, height * 0.4,
                                    width * 0.8, height * 0.9
                                );
                                ctx.lineTo(width, height * 0.9);
                                break;
                                
                            case "VFD":
                                // Controlled ramp
                                ctx.lineTo(width * 0.1, height * 0.1);
                                ctx.lineTo(width * 0.1, height * 0.9);
                                ctx.lineTo(width, height * 0.9);
                                break;
                        }
                        
                        ctx.strokeStyle = "blue";
                        ctx.lineWidth = 2;
                        ctx.stroke();
                        
                        // Add labels
                        ctx.font = "12px sans-serif";
                        ctx.fillStyle = "black";
                        ctx.fillText("Time →", width - 40, height - 5);
                        ctx.save();
                        ctx.translate(10, height/2);
                        ctx.rotate(-Math.PI/2);
                        ctx.fillText("Current →", 0, 0);
                        ctx.restore();
                    }
                }
                
                Connections {
                    target: calculator
                    function onResultsCalculated() {
                        motorStartCanvas.requestPaint();
                    }
                }
            }
        }
    }
}
