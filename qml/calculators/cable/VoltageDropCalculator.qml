import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal


import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"

import VoltageDrop 1.0

Item {
    id: voltageDropCard

    property VoltageDropCalc calculator: VoltageDropCalc {}

    PopUpText {
        parentCard: results
        popupText: "<h3>Voltage Drop Calculator </h3><br>" +
                "Voltage drop is the reduction in voltage that occurs when current flows through a conductor. Voltage drop can cause electrical equipment to malfunction, reduce the efficiency of the system, and increase the risk of fire. Voltage drop is calculated using the formula VD = I * R * L / 1000, where VD is the voltage drop, I is the current, R is the resistance of the conductor, and L is the length of the conductor.<br><br>" +
                "The voltage drop calculator helps you calculate the voltage drop in a circuit based on the cable size, length, current, conductor material, and system voltage. Simply enter the required parameters, and the calculator will provide you with the voltage drop and drop percentage in the circuit. The calculator also highlights the drop percentage in red if it exceeds 3%, indicating that the voltage drop is too high and may cause issues in the system.<br><br>" +
                "The voltage drop visualization provides you with a visual representation of the voltage drop in the circuit. The source voltage is shown in blue, and the load voltage is shown in red. The drop percentage is displayed at the bottom of the visualization, with the drop percentage highlighted in red if it exceeds 3%. The visualization helps you understand the impact of voltage drop on the system and identify areas where voltage drop is too high."
    }

    RowLayout {
        anchors.centerIn: parent

        ColumnLayout {
            id: inputLayout
            Layout.preferredWidth: 300

            WaveCard {
                id: results
                title: "Voltage Drop Calculator"
                Layout.fillWidth: true
                Layout.minimumHeight: 250

                showSettings: true

                GridLayout {
                    id: cableParamsLayout
                    columns: 2

                    Label { text: "Cable Size (mm²):" }
                    ComboBoxRound {
                        id: cableSizeCombo
                        model: [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240]
                        onCurrentTextChanged: calculator.cableSize = parseFloat(currentText)
                        Layout.fillWidth: true
                    }

                    Label { text: "Length (m):" }
                    TextFieldRound {
                        id: lengthInput
                        placeholderText: "Enter length"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.length = parseFloat(text)
                        Layout.fillWidth: true
                    }

                    Label { text: "Current (A):" }
                    TextFieldRound {
                        id: currentInput
                        placeholderText: "Enter current"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.current = parseFloat(text)
                        Layout.fillWidth: true
                    }

                    Label { text: "Conductor Material:" }
                    ComboBoxRound {
                        id: conductorMaterial
                        model: ["Copper", "Aluminum"]
                        onCurrentTextChanged: calculator.conductorMaterial = currentText
                        Layout.fillWidth: true
                    }

                    Label { text: "System Voltage (V):" }
                    TextFieldRound {
                        id: systemVoltage
                        text: "230"
                        onTextChanged: if(text) calculator.setSystemVoltage(parseFloat(text))
                        Layout.fillWidth: true
                    }
                }
            }

            WaveCard {
                title: "Results"
                Layout.fillWidth: true
                Layout.minimumHeight: 140
                
                GridLayout {
                    id: resultsLayout
                    columns: 2

                    Label { text: "Voltage Drop:" ; Layout.minimumWidth: 135}
                    TextFieldBlue { 
                        text: calculator.voltageDrop.toFixed(2) + " V"
                        Layout.minimumWidth: 120
                        Layout.fillWidth: true
                    }

                    Label { text: "Drop Percentage:" }
                    TextFieldBlue { 
                        text: calculator.dropPercentage.toFixed(2) + "%"
                        color: calculator.dropPercentage > 3 ? "red" : "green"
                    }
                }
            }
        }

        WaveCard {
            title: "Voltage Drop Visualization"

            Layout.minimumHeight: inputLayout.height
            Layout.minimumWidth: inputLayout.height
            
            Canvas {
                id: dropVizCanvas
                anchors.fill: parent
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    // Define dimensions first before using them
                    var canvasWidth = dropVizCanvas.width;
                    var canvasHeight = dropVizCanvas.height;
                    
                    // Set background color to match theme
                    ctx.fillStyle = Universal.background;
                    ctx.fillRect(0, 0, canvasWidth, canvasHeight);
                    
                    // Calculate values
                    var dropPercentage = calculator.dropPercentage;
                    var dropRatio = Math.min(dropPercentage / 10, 1.0); // Cap at 10%
                    
                    // Draw voltage bar
                    var barHeight = canvasHeight * 0.4;
                    var barY = canvasHeight * 0.3;
                    var barWidth = canvasWidth * 0.8;
                    var barX = canvasWidth * 0.1;
                    
                    // Draw source voltage (100%)
                    ctx.fillStyle = "#88c0ff";
                    ctx.fillRect(barX, barY, barWidth, barHeight);
                    
                    // Draw voltage drop
                    ctx.fillStyle = "#ff8888";
                    ctx.fillRect(barX + barWidth * (1 - dropRatio), barY, barWidth * dropRatio, barHeight);
                    
                    // Draw separator line - use theme color
                    ctx.strokeStyle = Universal.foreground;
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.moveTo(barX + barWidth * (1 - dropRatio), barY);
                    ctx.lineTo(barX + barWidth * (1 - dropRatio), barY + barHeight);
                    ctx.stroke();
                    
                    // Labels - use theme color for text
                    ctx.fillStyle = Universal.foreground;
                    ctx.font = "12px sans-serif";
                    ctx.textAlign = "center";
                    
                    // Source voltage
                    ctx.fillText("Source", barX + barWidth * 0.5 * (1 - dropRatio), barY - 10);
                    
                    // Load voltage
                    ctx.fillText("Load", barX + barWidth - barWidth * 0.5 * dropRatio, barY - 10);
                    
                    // Drop percentage
                    ctx.fillText(dropPercentage.toFixed(2) + "% drop", barX + barWidth * (1 - dropRatio * 0.5), barY + barHeight + 20);
                }
            }
        }
    }

    Connections {
        target: calculator
        function onVoltageDropChanged() { dropVizCanvas.requestPaint() }
        function onDropPercentageChanged() { dropVizCanvas.requestPaint() }
    }
}
