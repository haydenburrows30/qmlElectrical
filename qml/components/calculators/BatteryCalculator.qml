import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import "../style"
import "../backgrounds"

import Battery 1.0

Item {
    id: batteryCalculator

    property BatteryCalculator calculator: BatteryCalculator {}
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
            text: { "<h3>Battery Calculator</h3><br>" +
                    "This calculator estimates the battery capacity required for a given load and backup time.<br><br>" +
                    "<b>Load:</b> The power consumption in watts.<br>" +
                    "<b>System Voltage:</b> The voltage of the battery system.<br>" +
                    "<b>Backup Time:</b> The duration for which the battery should provide power.<br>" +
                    "<b>Depth of Discharge:</b> The percentage of battery capacity that can be used.<br>" +
                    "<b>Battery Type:</b> The type of battery used.<br><br>" +
                    "The calculator estimates the current draw, required capacity, recommended capacity, and energy storage.<br>" +
                    "The battery visualization shows the depth of discharge and recommended capacity." }
            wrapMode: Text.WordWrap
        }
    }
        
    RowLayout {
        anchors.centerIn: parent
        spacing: Style.spacing

        ColumnLayout {
            id: inputLayout
            Layout.preferredWidth: 400
            Layout.alignment: Qt.AlignTop
            spacing: Style.spacing

            //Inputs
            WaveCard {
                id: results
                title: "System Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 260

                showSettings: true
                    
                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    // Layout.fillWidth: true
                    
                    Label { text: "Load (watts):" }
                    TextField {
                        id: loadInput
                        placeholderText: "Enter load"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.load = parseFloat(text)
                        Layout.fillWidth: true
                        Layout.minimumWidth: 180
                    }

                    Label { text: "System Voltage (V):" }
                    ComboBox {
                        id: systemVoltageCombo
                        model: [12, 24, 48]
                        onCurrentTextChanged: calculator.systemVoltage = parseInt(currentText)
                        Layout.fillWidth: true
                    }
                    
                    Label { text: "Backup Time (hours):" }
                    TextField {
                        id: backupTimeInput
                        placeholderText: "Enter hours"
                        text: "4"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.backupTime = parseFloat(text)
                        Layout.fillWidth: true
                    }
                    
                    Label { text: "Depth of Discharge (%):" }

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Slider {
                            id: dodSlider
                            from: 30
                            to: 80
                            value: 50
                            stepSize: 5
                            onValueChanged: calculator.depthOfDischarge = value
                            Layout.maximumWidth: 150
                        }

                        Label { 
                            text: dodSlider.value + "%" 
                            Layout.alignment: Qt.AlignRight
                            Layout.minimumWidth: 50
                            Layout.fillWidth: true
                        }
                    }
                    
                    Label { text: "Battery Type:" }
                    ComboBox {
                        id: batteryType
                        model: ["Lead Acid", "Lithium Ion", "AGM"]
                        onCurrentTextChanged: calculator.batteryType = currentText
                        Layout.fillWidth: true
                    }
                }
            }
            // Results
            WaveCard {
                Layout.minimumHeight: 200
                title: "Results"
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    Layout.fillWidth: true

                    Label { text: "Current Draw:" }
                    TextField { 
                        text: calculator.currentDraw.toFixed(2) + " A"
                        background: ProtectionRectangle {}
                        Layout.fillWidth: true
                        Layout.minimumWidth: 180
                        readOnly: true
                    }

                    Label { text: "Required Capacity:" }
                    TextField { 
                        text: calculator.requiredCapacity.toFixed(1) + " Ah"
                        background: ProtectionRectangle {}
                        Layout.fillWidth: true
                        readOnly: true
                    }
                    
                    Label { text: "Recommended Capacity:" }
                    TextField { 
                        text: calculator.recommendedCapacity.toFixed(1) + " Ah"
                        font.bold: true 
                        color: Universal.theme === Universal.Dark ? "#90EE90" : "green"  // Theme-aware color
                        background: ProtectionRectangle {}
                        Layout.fillWidth: true
                        readOnly: true
                    }
                    
                    Label { text: "Energy Storage:" }
                    TextField { 
                        text: calculator.energyStorage.toFixed(2) + " kWh"
                        background: ProtectionRectangle {}
                        Layout.fillWidth: true
                        readOnly: true
                    }
                }
            }
        }

        WaveCard {
            Layout.minimumHeight: inputLayout.height
            Layout.minimumWidth: 400
            
            Canvas {
                id: batteryVizCanvas
                anchors.fill: parent

                // Track theme changes to trigger repaints
                property bool darkMode: Universal.theme === Universal.Dark
                onDarkModeChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    var width = batteryVizCanvas.width;
                    var height = batteryVizCanvas.height;
                    
                    // Battery dimensions
                    var batteryWidth = width * 0.7;
                    var batteryHeight = height * 0.6;
                    var batteryX = (width - batteryWidth) / 2;
                    var batteryY = (height - batteryHeight) / 2;
                    var terminalWidth = batteryWidth * 0.1;
                    var terminalHeight = batteryHeight * 0.2;
                    
                    // Draw battery outline
                    ctx.strokeStyle = darkMode ? "#888" : "#555";
                    ctx.lineWidth = 2;
                    ctx.fillStyle = darkMode ? "#333" : "#f0f0f0";
                    ctx.beginPath();
                    ctx.rect(batteryX, batteryY, batteryWidth, batteryHeight);
                    ctx.fill();
                    ctx.stroke();
                    
                    // Draw positive terminal
                    ctx.beginPath();
                    ctx.rect(batteryX + batteryWidth, batteryY + batteryHeight/2 - terminalHeight/2,
                            terminalWidth, terminalHeight);
                    ctx.fill();
                    ctx.stroke();
                    
                    // Draw capacity level
                    var capacity = Math.min(calculator.depthOfDischarge / 100, 0.9);
                    // Use theme-appropriate colors for capacity level
                    ctx.fillStyle = capacity > 0.3 ? 
                        (darkMode ? "#60C060" : "#8eff8e") : 
                        (darkMode ? "#C06060" : "#ff8e8e");
                    ctx.beginPath();
                    ctx.rect(batteryX + 10, batteryY + 10, 
                            (batteryWidth - 20) * capacity, batteryHeight - 20);
                    ctx.fill();
                    
                    // Draw indicator lines
                    ctx.strokeStyle = darkMode ? "#666" : "#888";
                    ctx.lineWidth = 1;
                    for (var i = 0.25; i <= 0.75; i += 0.25) {
                        ctx.beginPath();
                        ctx.moveTo(batteryX + batteryWidth * i, batteryY);
                        ctx.lineTo(batteryX + batteryWidth * i, batteryY + batteryHeight);
                        ctx.stroke();
                    }
                    
                    // Draw labels - use theme colors
                    ctx.fillStyle = textColor;
                    ctx.font = "12px sans-serif";
                    ctx.textAlign = "center";
                    ctx.fillText("DoD: " + calculator.depthOfDischarge + "%", 
                                width/2, batteryY + batteryHeight + 20);
                    ctx.fillText("Capacity: " + calculator.recommendedCapacity.toFixed(1) + " Ah", 
                                width/2, batteryY - 10);
                }
            }
        }
    }
    
    Connections {
        target: calculator
        function onDepthOfDischargeChanged() { batteryVizCanvas.requestPaint() }
        function onRecommendedCapacityChanged() { batteryVizCanvas.requestPaint() }
    }
}
