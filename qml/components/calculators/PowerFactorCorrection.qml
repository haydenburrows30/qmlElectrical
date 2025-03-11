import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import PFCorrection 1.0

WaveCard {
    id: pfCorrectionCard
    title: 'Power Factor Correction'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 300

    property PowerFactorCorrectionCalculator calculator: PowerFactorCorrectionCalculator {}  // Match registered name

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // Input Section
        ColumnLayout {
            Layout.preferredWidth: 300

            GroupBox {
                title: "System Parameters"
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Label { text: "Active Power (kW):" }
                    TextField {
                        id: activePowerInput
                        placeholderText: "Enter power"
                        onTextChanged: if(text) calculator.activePower = parseFloat(text)
                        Layout.fillWidth: true
                    }

                    Label { text: "Current PF:" }
                    TextField {
                        id: currentPFInput
                        placeholderText: "Enter current PF"
                        onTextChanged: if(text) calculator.currentPF = parseFloat(text)
                        Layout.fillWidth: true
                    }

                    Label { text: "Target PF:" }
                    TextField {
                        id: targetPFInput
                        placeholderText: "Enter target PF"
                        text: "0.95"
                        onTextChanged: if(text) calculator.targetPF = parseFloat(text)
                        Layout.fillWidth: true
                    }
                }
            }

            // Results Section
            GroupBox {
                title: "Results"
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 5
                    columnSpacing: 10

                    Label { text: "Required Capacitor:" }
                    Label { 
                        text: calculator.capacitorSize.toFixed(2) + " kVAR"
                        font.bold: true 
                    }

                    Label { text: "Capacitance Required:" }
                    Label { 
                        text: calculator.capacitance.toFixed(2) + " μF"
                        font.bold: true 
                    }

                    Label { text: "Annual Savings:" }
                    Label { 
                        text: "$" + calculator.annualSavings.toFixed(2)
                        font.bold: true 
                        color: "green"
                    }
                }
            }
        }

        // Power Triangle Visualization
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            
            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    
                    // Draw power triangle
                    var centerX = width/2
                    var centerY = height/2
                    var scale = 100
                    
                    var p = calculator.activePower
                    var pf = calculator.currentPF
                    var q = p * Math.tan(Math.acos(pf))
                    var s = p / pf
                    
                    // Scale to fit
                    var maxDim = Math.max(p, q, s)
                    scale = Math.min(width, height) / (maxDim * 2)
                    
                    // Draw triangle
                    ctx.beginPath()
                    ctx.moveTo(centerX - p*scale/2, centerY)
                    ctx.lineTo(centerX + p*scale/2, centerY)
                    ctx.lineTo(centerX + p*scale/2, centerY - q*scale)
                    ctx.closePath()
                    ctx.stroke()
                }
            }
        }
    }
}
