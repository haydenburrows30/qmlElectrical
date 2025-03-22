import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import FaultCurrent 1.0

Item {
    id: root
    
    property FaultCurrentCalculator calculator: FaultCurrentCalculator {}
    property color textColor: Universal.foreground

    Popup {
        id: tipsPopup
        width: 500
        height: 300
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
            text: {"<h3>Fault Current Calculator</h3><br>" +
                  "This calculator estimates fault currents in an electrical system based on:" +
                  "<ul>" +
                  "<li>System voltage and MVA</li>" +
                  "<li>Transformer impedance</li>" +
                  "<li>Cable/line impedance</li>" +
                  "<li>Fault location</li>" +
                  "</ul>" +
                  "Results include:<br>" +
                  "• Initial symmetrical fault current<br>" + 
                  "• Peak fault current<br>" +
                  "• Breaking current<br>" +
                  "• Thermal equivalent current"}
            wrapMode: Text.WordWrap
        }
    }

    // Left side inputs and results
    ColumnLayout {
        anchors.centerIn: parent
        anchors.margins: 10
        spacing: 10

        RowLayout {
            id: firstRow
            spacing: 10

            WaveCard {
                title: "System Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 380
                Layout.minimumWidth: 350
                
                id: results
                showSettings: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

                    Label { text: "System Voltage (kV):" }
                    TextField {
                        id: systemVoltage
                        text: "11"
                        validator: DoubleValidator { bottom: 0.4; decimals: 1 }
                        onTextChanged: if(acceptableInput) calculator.setSystemVoltage(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "System MVA:" }
                    TextField {
                        id: systemMva
                        text: "500"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(acceptableInput) calculator.setSystemMva(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Transformer Rating (MVA):" }
                    TextField {
                        id: transformerMva
                        text: "5"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(acceptableInput) calculator.setTransformerMva(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Transformer Z%:" }
                    TextField {
                        id: transformerZ
                        text: "6"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(acceptableInput) calculator.setTransformerZ(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Cable Length (km):" }
                    TextField {
                        id: cableLength
                        text: "0.5"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(acceptableInput) calculator.setCableLength(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Cable Z (Ω/km):" }
                    TextField {
                        id: cableZ
                        text: "0.25"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(acceptableInput) calculator.setCableZ(parseFloat(text))
                        Layout.fillWidth: true
                    }

                    Label { text: "Fault Type:" }
                    ComboBox {
                        id: faultType
                        model: ["3-Phase", "Line-Line", "Line-Ground"]
                        onCurrentTextChanged: calculator.setFaultType(currentText)
                        Layout.fillWidth: true
                    }

                    Label { text: "X/R Ratio:" }
                    TextField {
                        id: xrRatio
                        text: "15"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(acceptableInput) calculator.setXrRatio(parseFloat(text))
                        Layout.fillWidth: true
                    }
                }
            }

            // Results section
            WaveCard {
                title: "Results"
                Layout.fillWidth: true
                Layout.minimumHeight: 380
                Layout.minimumWidth: 250

                GridLayout {
                    columns: 2
                    rowSpacing: 15
                    columnSpacing: 10

                    Label { text: "Initial Sym. Current:" }
                    Label { 
                        text: calculator.initialSymCurrent.toFixed(1) + " kA"
                        color: textColor
                        font.bold: true
                    }

                    Label { text: "Peak Fault Current:" }
                    Label { 
                        text: calculator.peakFaultCurrent.toFixed(1) + " kA"
                        color: textColor
                        font.bold: true
                    }

                    Label { text: "Breaking Current:" }
                    Label { 
                        text: calculator.breakingCurrent.toFixed(1) + " kA"
                        color: textColor
                        font.bold: true
                    }

                    Label { text: "Thermal Current:" }
                    Label { 
                        text: calculator.thermalCurrent.toFixed(1) + " kA"
                        color: textColor
                        font.bold: true
                    }

                    Label { text: "Total Impedance:" }
                    Label { 
                        text: calculator.totalImpedance.toFixed(3) + " Ω"
                        color: textColor
                        font.bold: true
                    }
                }
            }
        }

        // Right side visualization
        WaveCard {
            Layout.minimumWidth: firstRow.width
            Layout.minimumHeight: 300
            title: "Fault Current Diagram"

            Canvas {
                id: faultDiagram
                anchors.fill: parent
                anchors.margins: 10
                
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    
                    // Set colors based on theme
                    var lineColor = root.Universal.theme === Universal.Dark ? "#FFFFFF" : "#000000"
                    var accentColor = root.Universal.theme === Universal.Dark ? "#00B4FF" : "#0078D4"
                    ctx.strokeStyle = lineColor
                    ctx.fillStyle = lineColor
                    ctx.lineWidth = 2
                    
                    // Draw system source
                    var startX = 50
                    var centerY = height/2
                    drawSource(ctx, startX, centerY - 50, accentColor)
                    
                    // Draw busbar
                    ctx.lineWidth = 3
                    ctx.beginPath()
                    ctx.moveTo(startX, centerY - 20)
                    ctx.lineTo(width - 50, centerY - 20)
                    ctx.stroke()
                    
                    // Draw transformer
                    drawTransformer(ctx, startX + 100, centerY, accentColor)
                    
                    // Draw cable
                    drawCable(ctx, startX + 200, centerY, lineColor)
                    
                    // Draw fault location with lightning bolt
                    drawFault(ctx, width - 100, centerY + 20, "#FFB900")
                    
                    // Add labels with improved styling
                    ctx.fillStyle = lineColor
                    ctx.font = "bold 12px sans-serif"
                    ctx.textAlign = "center"
                    ctx.fillText(systemVoltage.text + " kV", startX, centerY - 90)
                    ctx.font = "11px sans-serif"
                    ctx.fillText("System MVA: " + systemMva.text, startX, centerY - 75)
                    ctx.fillText("Z = " + transformerZ.text + "%", startX + 115, centerY + 50)
                    ctx.fillText(cableLength.text + " km", startX + 300, centerY - 40)
                    
                    // Draw fault current with highlight
                    ctx.font = "bold 13px sans-serif"
                    ctx.fillStyle = "#FFB900"
                    ctx.fillText("If = " + calculator.initialSymCurrent.toFixed(1) + " kA", width - 100, centerY + 60)
                }
                
                function drawSource(ctx, x, y, accentColor) {
                    // Outer circle
                    ctx.beginPath()
                    ctx.strokeStyle = accentColor
                    ctx.lineWidth = 2.5
                    ctx.arc(x, y, 22, 0, 2 * Math.PI)
                    ctx.stroke()
                    
                    // Inner symbol
                    ctx.beginPath()
                    ctx.strokeStyle = ctx.fillStyle
                    ctx.lineWidth = 2
                    ctx.moveTo(x-12, y)
                    ctx.lineTo(x+12, y)
                    ctx.moveTo(x, y-12)
                    ctx.lineTo(x, y+12)
                    ctx.stroke()
                }
                
                function drawTransformer(ctx, x, y, accentColor) {
                    ctx.strokeStyle = accentColor
                    ctx.lineWidth = 2.5
                    
                    // Primary winding
                    ctx.beginPath()
                    drawRoundedLine(ctx, x, y-25, x, y+25, 4)
                    
                    // Secondary winding
                    ctx.beginPath()
                    drawRoundedLine(ctx, x+20, y-25, x+20, y+25, 4)
                    
                    // Core lines
                    ctx.lineWidth = 1.5
                    ctx.beginPath()
                    ctx.moveTo(x-5, y-20)
                    ctx.lineTo(x+25, y-20)
                    ctx.moveTo(x-5, y+20)
                    ctx.lineTo(x+25, y+20)
                    ctx.stroke()
                }
                
                function drawRoundedLine(ctx, x1, y1, x2, y2, radius) {
                    ctx.moveTo(x1, y1 + radius)
                    ctx.arcTo(x1, y1, x1 + radius, y1, radius)
                    ctx.lineTo(x2, y1)
                    ctx.arcTo(x2, y1, x2, y1 + radius, radius)
                    ctx.lineTo(x2, y2 - radius)
                    ctx.arcTo(x2, y2, x2 - radius, y2, radius)
                    ctx.stroke()
                }
                
                function drawCable(ctx, x, y, lineColor) {
                    ctx.strokeStyle = lineColor
                    ctx.lineWidth = 2.5
                    
                    // Main line
                    ctx.beginPath()
                    ctx.moveTo(x, y-20)
                    ctx.lineTo(x+200, y-20)
                    ctx.stroke()
                    
                    // Impedance symbol
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    var amplitude = 12
                    var period = 15
                    ctx.moveTo(x + 20, y-20)
                    for(var i = 0; i <= 180; i++) {
                        var xPos = x + 20 + i
                        var yPos = y - 20 + Math.sin(i/period) * amplitude
                        ctx.lineTo(xPos, yPos)
                    }
                    ctx.stroke()
                }
                
                function drawFault(ctx, x, y, faultColor) {
                    ctx.strokeStyle = faultColor
                    ctx.lineWidth = 3
                    ctx.beginPath()
                    ctx.moveTo(x, y-40)
                    ctx.lineTo(x-8, y-25)
                    ctx.lineTo(x+8, y-10)
                    ctx.lineTo(x-8, y+5)
                    ctx.lineTo(x+8, y+20)
                    ctx.lineTo(x, y+35)
                    ctx.stroke()
                    
                    // Add glow effect
                    ctx.strokeStyle = faultColor + "40" // 40 = 25% opacity
                    ctx.lineWidth = 6
                    ctx.stroke()
                }
            }

            // Update diagram when values change
            Connections {
                target: calculator
                function onCalculationComplete() {
                    faultDiagram.requestPaint()
                }
            }
        }
    }
}
