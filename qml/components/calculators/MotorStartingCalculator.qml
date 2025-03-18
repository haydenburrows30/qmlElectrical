import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import MotorStarting 1.0  // Import the correct namespace

Item {
    id: motorStartingCard

    property MotorStartingCalculator calculator: MotorStartingCalculator {}
    property real cachedStartingMultiplier: calculator ? calculator.startingMultiplier : 7.0
    
    // Update the cached value when needed - only reads from calculator without setting the property
    function getStartingMultiplier() {
        return calculator ? calculator.startingMultiplier : 7.0
    }

    // Connect to the signal to update our cached value when needed
    Connections {
        target: calculator
        function onStartingMultiplierChanged() {
            cachedStartingMultiplier = calculator.startingMultiplier
        }
    }

    Popup {
        id: tipsPopup
        width: parent.width * 0.6
        height: parent.height * 0.6
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
            text: {
                "This calculator helps you determine the starting current and torque of an electric motor based on its power, efficiency, and power factor. " +
                "You can also select the starting method to see how the current profile changes. " +
                "The starting current profile is displayed below the results."
            }
            wrapMode: Text.WordWrap
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        anchors.margins: 10

        RowLayout {
            WaveCard {
                id: results
                title: "DOL"
                Layout.minimumHeight: 200
                Layout.minimumWidth: 330

                showSettings: true
            
                GridLayout {
                    columns: 2

                    Label {
                        text: "Motor Power (kW):"
                        Layout.preferredWidth: 150
                    }

                    TextField {
                        id: motorPower
                        placeholderText: "Enter Power"
                        onTextChanged: calculator.setMotorPower(parseFloat(text))
                        Layout.preferredWidth: 150
                        Layout.alignment: Qt.AlignRight
                        validator: DoubleValidator { bottom: 0 ; top: 999 }
                        maximumLength: 4
                    }
                    
                    Label {
                        text: "Efficiency (%):"
                        Layout.preferredWidth: 150
                    }

                    TextField {
                        id: motorEfficiency
                        placeholderText: "Enter Efficiency"
                        text: "90"
                        onTextChanged: calculator.setEfficiency(parseFloat(text) / 100)
                        Layout.preferredWidth: 150
                        Layout.alignment: Qt.AlignRight
                        validator: DoubleValidator { bottom: 0 ; top: 99 }
                        maximumLength: 2
                    }

                    Label {
                        text: "Power Factor:"
                        Layout.preferredWidth: 150
                    }

                    TextField {
                        id: motorPowerFactor
                        placeholderText: "Enter PF"
                        text: "0.85"
                        onTextChanged: {
                            calculator.setPowerFactor(parseFloat(text))
                            
                        }
                        Layout.preferredWidth: 150
                        Layout.alignment: Qt.AlignRight
                        
                    }
                    
                    Label {
                        text: "Starting Method:"
                        Layout.preferredWidth: 150
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
                        Layout.preferredWidth: 150
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            WaveCard {
                title: "Results"
                // Layout.fillWidth: true
                Layout.minimumWidth: 280
                Layout.minimumHeight: 200

                GridLayout {
                    columns: 2
                    rowSpacing: 15

                    Label {
                        text: "Full Load Current:"
                        Layout.preferredWidth: 150
                        font.bold: true
                    }
                    
                    Text {
                        text: !isNaN(calculator.startingCurrent / getStartingMultiplier()) ? 
                                (calculator.startingCurrent / getStartingMultiplier()).toFixed(1) + " A" : "0.0 A"
                        Layout.preferredWidth: 150
                        font.bold: true
                    }
                
                    Label {
                        text: "Starting Current:"
                        Layout.preferredWidth: 150
                    }
                    
                    Text {
                        text: !isNaN(calculator.startingCurrent) ? 
                                calculator.startingCurrent.toFixed(1) + " A" : "0.0 A"
                        color: "red"
                        Layout.preferredWidth: 150
                    }
                    Label {
                        text: "Starting Torque:"
                        Layout.preferredWidth: 150
                    }
                    
                    Text {
                        text: !isNaN(calculator.startingTorque) ? 
                                (calculator.startingTorque * 100).toFixed(0) + "% FLT" : "0% FLT"
                        Layout.preferredWidth: 150
                    }
                }
            }
        }

        WaveCard {
            Layout.fillHeight: true
            Layout.fillWidth: true
            title: "Starting Current Profile"
            
            Canvas {
                id: motorStartCanvas
                anchors.fill: parent
                anchors.margins: 10
                
                // Use the cached property directly instead of calling function
                property real startingMultiplier: cachedStartingMultiplier
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    // Define dimensions first before using them
                    var canvasWidth = motorStartCanvas.width;
                    var canvasHeight = motorStartCanvas.height;
                    
                    // Add background fill to match theme
                    ctx.fillStyle = Universal.background;
                    ctx.fillRect(0, 0, canvasWidth, canvasHeight);
                    
                    // Draw starting current profile
                    ctx.beginPath();
                    ctx.moveTo(0, canvasHeight * 0.1);  // Start at 10% from top
                    
                    // Draw different profiles based on starting method
                    switch(startingMethod.currentText) {
                        case "DOL":
                            // Direct square wave
                            ctx.lineTo(canvasWidth * 0.1, canvasHeight * 0.1);
                            ctx.lineTo(canvasWidth * 0.1, canvasHeight * 0.9);
                            ctx.lineTo(canvasWidth, canvasHeight * 0.9);
                            break;
                            
                        case "Star-Delta":
                            // Two-step start
                            ctx.lineTo(canvasWidth * 0.1, canvasHeight * 0.1);
                            ctx.lineTo(canvasWidth * 0.1, canvasHeight * 0.4);
                            ctx.lineTo(canvasWidth * 0.3, canvasHeight * 0.4);
                            ctx.lineTo(canvasWidth * 0.3, canvasHeight * 0.9);
                            ctx.lineTo(canvasWidth, canvasHeight * 0.9);
                            break;
                            
                        case "Soft-Starter":
                            // Gradual ramp
                            ctx.lineTo(canvasWidth * 0.1, canvasHeight * 0.1);
                            ctx.quadraticCurveTo(
                                canvasWidth * 0.4, canvasHeight * 0.4,
                                canvasWidth * 0.8, canvasHeight * 0.9
                            );
                            ctx.lineTo(canvasWidth, canvasHeight * 0.9);
                            break;
                            
                        case "VFD":
                            // Controlled ramp
                            ctx.lineTo(canvasWidth * 0.1, canvasHeight * 0.1);
                            ctx.lineTo(canvasWidth * 0.1, canvasHeight * 0.9);
                            ctx.lineTo(canvasWidth, canvasHeight * 0.9);
                            break;
                    }
                    
                    ctx.strokeStyle = Universal.foreground;
                    ctx.lineWidth = 2;
                    ctx.stroke();
                    
                    // Add labels
                    ctx.font = "12px sans-serif";
                    ctx.fillStyle = Universal.foreground;  // Use theme foreground color
                    ctx.fillText("Time →", canvasWidth - 40, canvasHeight - 5);
                    ctx.save();
                    ctx.translate(10, canvasHeight/2);
                    ctx.rotate(-Math.PI/2);
                    ctx.fillText("Current →", 0, 0);
                    ctx.restore();
                }
            }
            
            Connections {
                target: calculator
                function onResultsCalculated() {
                    motorStartCanvas.requestPaint()
                }
            }
        }
    }
}
