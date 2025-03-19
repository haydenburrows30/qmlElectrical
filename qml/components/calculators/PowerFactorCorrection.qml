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

    Popup {
        id: tipsPopup
        width: 600
        height: 500
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
            text: {"<h3>Power Factor Correction</h3><br>" +
                "Power factor correction is a technique used to improve the power factor of a power system by adding capacitors to the system. This helps to reduce the reactive power drawn from the grid, which in turn reduces the losses in the system and improves the efficiency of the system.<br><br>" +
                "The power factor is the ratio of the real power (kW) to the apparent power (kVA) in the system. A power factor of 1 indicates that all the power is being used effectively, while a power factor of 0 indicates that all the power is being wasted. Power factor correction is used to bring the power factor closer to 1, which reduces the reactive power and improves the efficiency of the system.<br><br>" +
                "The power factor correction calculator helps you calculate the required capacitor size and capacitance needed to improve the power factor of a system. Simply enter the active power (kW), current power factor, and target power factor, and the calculator will provide you with the required capacitor size and capacitance needed to achieve the target power factor.<br><br>" +
                "The calculator also provides you with the annual savings that can be achieved by improving the power factor of the system. Power factor correction can help reduce the losses in the system, improve the efficiency of the system, and save you money on your electricity bills."}
            wrapMode: Text.WordWrap
        }
    }

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
                id: results
                title: "System Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 200

                showSettings: true

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
