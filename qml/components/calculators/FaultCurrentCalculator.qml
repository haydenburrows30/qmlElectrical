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
                    ctx.strokeStyle = lineColor
                    ctx.fillStyle = lineColor
                    ctx.lineWidth = 2
                    
                    // Draw system source
                    var startX = 50
                    var centerY = height/2
                    drawSource(ctx, startX, centerY - 50)
                    
                    // Draw busbar
                    ctx.beginPath()
                    ctx.moveTo(startX, centerY - 20)
                    ctx.lineTo(width - 50, centerY - 20)
                    ctx.stroke()
                    
                    // Draw transformer
                    drawTransformer(ctx, startX + 100, centerY)
                    
                    // Draw cable
                    drawCable(ctx, startX + 200, centerY)
                    
                    // Draw fault location with lightning bolt
                    drawFault(ctx, width - 100, centerY + 20)
                    
                    // Add labels
                    ctx.font = "12px sans-serif"
                    ctx.fillText(systemVoltage.text + " kV", startX - 20, centerY - 70)
                    ctx.fillText("System MVA: " + systemMva.text, startX - 20, centerY - 90)
                    ctx.fillText("Z = " + transformerZ.text + "%", startX + 80, centerY + 50)
                    ctx.fillText(cableLength.text + "km", startX + 200, centerY - 40)
                    ctx.fillText("If = " + calculator.initialSymCurrent.toFixed(1) + " kA", width - 120, centerY + 60)
                }
                
                function drawSource(ctx, x, y) {
                    ctx.beginPath()
                    ctx.arc(x, y, 20, 0, 2 * Math.PI)
                    ctx.moveTo(x-10, y)
                    ctx.lineTo(x+10, y)
                    ctx.moveTo(x, y-10)
                    ctx.lineTo(x, y+10)
                    ctx.stroke()
                }
                
                function drawTransformer(ctx, x, y) {
                    ctx.beginPath()
                    ctx.moveTo(x, y-20)
                    ctx.lineTo(x, y+20)
                    ctx.moveTo(x+15, y-20)
                    ctx.lineTo(x+15, y+20)
                    ctx.stroke()
                }
                
                function drawCable(ctx, x, y) {
                    ctx.beginPath()
                    ctx.moveTo(x, y-20)
                    ctx.lineTo(x+200, y-20)
                    ctx.stroke()
                    
                    // Add zigzag for impedance
                    var zigzagWidth = 10
                    var zigzagHeight = 10
                    for(var i = 0; i < 8; i++) {
                        ctx.lineTo(x + (i+1)*zigzagWidth, y-20 + (i%2 ? -zigzagHeight : zigzagHeight))
                    }
                    ctx.stroke()
                }
                
                function drawFault(ctx, x, y) {
                    ctx.beginPath()
                    ctx.moveTo(x, y-40)
                    ctx.lineTo(x-10, y-20)
                    ctx.lineTo(x+5, y-10)
                    ctx.lineTo(x-5, y)
                    ctx.lineTo(x+10, y+10)
                    ctx.lineTo(x, y+20)
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
