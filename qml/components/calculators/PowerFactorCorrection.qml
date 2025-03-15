import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import PFCorrection 1.0

Item {
    id: pfCorrectionCard

    property PowerFactorCorrectionCalculator calculator: PowerFactorCorrectionCalculator {}
    property color textColor: Universal.foreground

    RowLayout {
        spacing: 10
        anchors.centerIn: parent
        anchors.margins: 10

        // Input Section
        ColumnLayout {
            id: inputColumn
            Layout.minimumWidth: 350
            spacing: 10

            WaveCard {
                title: "System Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 200

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 1
                    
                    Label { text: "Active Power (kW):" }
                    TextField {
                        id: activePowerInput
                        placeholderText: "Enter power"
                        onTextChanged: if(text) calculator.activePower = parseFloat(text)
                        Layout.minimumWidth: 150
                        // Layout.fillWidth: true
                    }

                    Label { text: "Current PF:" }
                    TextField {
                        id: currentPFInput
                        placeholderText: "Enter current PF"
                        onTextChanged: if(text) calculator.currentPF = parseFloat(text)
                        Layout.minimumWidth: 150
                        // Layout.fillWidth: true
                    }

                    Label { text: "Target PF:" }
                    TextField {
                        id: targetPFInput
                        placeholderText: "Enter target PF"
                        text: "0.95"
                        onTextChanged: if(text) calculator.targetPF = parseFloat(text)
                        Layout.minimumWidth: 150
                        // Layout.fillWidth: true
                    }
                }
            }

            // Results Section
            WaveCard {
                title: "Results"
                Layout.fillWidth: true
                Layout.minimumHeight: 150

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Label { text: "Required Capacitor:" }
                    Label { 
                        text: calculator.capacitorSize.toFixed(2) + " kVAR"
                        font.bold: true 
                        color: Universal.foreground  // Use theme color
                    }

                    Label { text: "Capacitance Required:" }
                    Label { 
                        text: calculator.capacitance.toFixed(2) + " μF"
                        font.bold: true 
                        color: Universal.foreground  // Use theme color
                    }

                    Label { text: "Annual Savings:" }
                    Label { 
                        text: "$" + calculator.annualSavings.toFixed(2)
                        font.bold: true 
                        // Use theme-appropriate green (lighter in dark mode)
                        color: Universal.theme === Universal.Dark ? "#90EE90" : "green"
                    }
                }
            }
        }

        // Power Triangle Visualization    
        WaveCard {
            title: "Power Triangle"
            Layout.minimumWidth: inputColumn.height
            Layout.minimumHeight: inputColumn.height

            Canvas {
                id: powerTriangle
                anchors.fill: parent
                anchors.margins: 2 // Small margin to avoid painting over the border
                
                // Force repaint when theme changes
                property bool darkMode: Universal.theme === Universal.Dark
                onDarkModeChanged: requestPaint()
                
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    
                    // Get values with safety checks
                    var p = calculator.activePower || 0
                    var pf = calculator.currentPF || 0
                    
                    // Prevent division by zero and invalid PF
                    if (p <= 0 || pf <= 0 || pf >= 1) return
                    
                    // Calculate triangle dimensions
                    var q = p * Math.tan(Math.acos(pf))
                    var s = p / pf
                    
                    // Set up scaling
                    var margin = 40
                    var maxDim = Math.max(p, q, s)
                    var scale = (Math.min(width, height) - 2 * margin) / maxDim
                    
                    // Center the triangle
                    var centerX = width/2
                    var centerY = height/2
                    
                    // Draw triangle with thicker lines
                    // Use color that works in both light and dark themes
                    ctx.strokeStyle = Universal.theme === Universal.Dark ? "#6CB4EE" : "#2196F3";
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.moveTo(centerX - p*scale/2, centerY)
                    ctx.lineTo(centerX + p*scale/2, centerY)
                    ctx.lineTo(centerX + p*scale/2, centerY - q*scale)
                    ctx.closePath()
                    ctx.stroke()
                    
                    // Add labels - use explicit theme color reference
                    // Convert the color to string format that Canvas can use
                    var foregroundColor = textColor.toString()
                    ctx.fillStyle = foregroundColor
                    ctx.font = "12px sans-serif"
                    ctx.textAlign = "center"
                    
                    // Active Power (P)
                    ctx.fillText(p.toFixed(1) + " kW", centerX, centerY + 20)
                    
                    // Reactive Power (Q)
                    ctx.fillText(q.toFixed(1) + " kVAR", 
                        centerX + p*scale/2 + 20, 
                        centerY - q*scale/2)
                    
                    // Apparent Power (S)
                    ctx.fillText(s.toFixed(1) + " kVA",
                        centerX, centerY - q*scale - 20)
                    
                    // Power Factor Angle
                    ctx.fillText("φ = " + (Math.acos(pf) * 180/Math.PI).toFixed(1) + "°",
                        centerX + p*scale/4,
                        centerY - q*scale/4)
                }
                
                Connections {
                    target: calculator
                    function onActivePowerChanged() { powerTriangle.requestPaint() }
                    function onCurrentPFChanged() { powerTriangle.requestPaint() }
                }
            }
        }
    }
}
