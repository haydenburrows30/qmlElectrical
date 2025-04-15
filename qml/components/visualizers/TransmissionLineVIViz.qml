import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../style" // Update import path to find WaveCard.qml

import Transmission 1.0

// Add voltage/current profile visualization
WaveCard {
    id: vizRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 250
    
    // Add property to receive calculator instance from parent
    property var calculator
    property real lineLength: calculator ? calculator.length : 100
    
    // Debug property to show when data is received
    property bool hasData: false
    
    // Monitor calculator property changes to ensure it's properly connected
    onCalculatorChanged: {
        console.log("Calculator assigned to VI viz:", calculator)
        if (calculator) {
            profileCanvas.requestPaint()
        }
    }

    Rectangle {
        id: profileViz
        anchors.fill: parent
        anchors.margins: 5
        color: "transparent"
        
        // Overlay to show if no data is available
        Rectangle {
            anchors.fill: parent
            color: Universal.background
            opacity: 0.7
            visible: !hasData
            
            Text {
                anchors.centerIn: parent
                text: calculator ? "Waiting for profile data..." : "No calculator assigned"
                color: Universal.foreground
            }
        }
        
        Canvas {
            id: profileCanvas
            anchors.fill: parent
            
            // Update when calculation changes or when calculator is assigned
            Component.onCompleted: {
                if (calculator) {
                    requestPaint();
                }
            }
            
            // Force repainting when component becomes visible
            onVisibleChanged: {
                if (visible && calculator) {
                    requestPaint()
                }
            }
            
            // Update when calculation changes
            Connections {
                target: calculator
                enabled: calculator !== null
                function onResultsCalculated() {
                    console.log("Results calculated - requesting paint")
                    profileCanvas.requestPaint()
                }
            }
            
            onPaint: {
                // Don't try to draw if calculator is not available
                if (!calculator) {
                    console.log("No calculator available for drawing")
                    return
                }
                
                // Get profiles
                var vProfile = calculator.voltageProfile
                var iProfile = calculator.currentProfile
                
                console.log("Drawing profiles: V-profile length:", vProfile ? vProfile.length : 0, 
                           "I-profile length:", iProfile ? iProfile.length : 0)
                
                // Check if we have valid data
                vizRoot.hasData = (vProfile && vProfile.length > 0) || 
                                  (iProfile && iProfile.length > 0)
                
                if (!vizRoot.hasData) {
                    console.log("No valid profile data found")
                    return
                }
                
                var ctx = getContext("2d")
                ctx.reset()
                
                var width = profileCanvas.width
                var height = profileCanvas.height
                var margin = 30
                var graphWidth = width - 2*margin
                var graphHeight = height - 2*margin
                
                // Draw axes
                ctx.strokeStyle = Universal.foreground
                ctx.lineWidth = 1
                ctx.beginPath()
                
                // X-axis
                ctx.moveTo(margin, height - margin)
                ctx.lineTo(width - margin, height - margin)
                
                // Y-axis
                ctx.moveTo(margin, height - margin)
                ctx.lineTo(margin, margin)
                ctx.stroke()
                
                // Draw grid lines
                ctx.strokeStyle = Universal.foreground
                ctx.globalAlpha = 0.2
                ctx.beginPath()
                
                // Horizontal grid lines (5 lines)
                for (var h = 1; h <= 5; h++) {
                    var yPos = margin + (h * (graphHeight / 5))
                    ctx.moveTo(margin, yPos)
                    ctx.lineTo(width - margin, yPos)
                }
                
                // Vertical grid lines (5 lines)
                for (var v = 1; v <= 5; v++) {
                    var xPos = margin + (v * (graphWidth / 5))
                    ctx.moveTo(xPos, margin)
                    ctx.lineTo(xPos, height - margin)
                }
                ctx.stroke()
                ctx.globalAlpha = 1.0
                
                // Draw voltage profile
                if (vProfile && vProfile.length > 0) {
                    ctx.strokeStyle = "#0078D4" // Blue
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    
                    for (var i = 0; i < vProfile.length; i++) {
                        var point = vProfile[i]
                        var x = margin + (point[0] / lineLength) * graphWidth
                        var y = height - margin - (point[1] * graphHeight)
                        
                        if (i === 0) ctx.moveTo(x, y)
                        else ctx.lineTo(x, y)
                    }
                    ctx.stroke()
                }
                
                // Draw current profile
                if (iProfile && iProfile.length > 0) {
                    ctx.strokeStyle = "#D83B01" // Red/Orange
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    
                    // Scale current to fit on graph
                    var maxCurrent = 0
                    for (var j = 0; j < iProfile.length; j++) {
                        if (iProfile[j][1] > maxCurrent) maxCurrent = iProfile[j][1]
                    }
                    
                    var currentScale = maxCurrent > 0 ? 0.5 / maxCurrent : 1
                    
                    for (var k = 0; k < iProfile.length; k++) {
                        var iPoint = iProfile[k]
                        var ix = margin + (iPoint[0] / lineLength) * graphWidth
                        var iy = height - margin - (iPoint[1] * currentScale * graphHeight)
                        
                        if (k === 0) ctx.moveTo(ix, iy)
                        else ctx.lineTo(ix, iy)
                    }
                    ctx.stroke()
                }
                
                // Draw distance markers on x-axis
                ctx.font = "10px sans-serif"
                ctx.fillStyle = Universal.foreground
                ctx.textAlign = "center"
                
                // Distance markers
                for (var d = 0; d <= 5; d++) {
                    var distX = margin + (d * graphWidth / 5)
                    var distVal = (d * lineLength / 5).toFixed(0)
                    ctx.fillText(distVal, distX, height - margin + 15)
                }
                
                // Draw value markers on y-axis
                ctx.textAlign = "right"
                for (var val = 0; val <= 5; val++) {
                    var valueY = height - margin - (val * graphHeight / 5)
                    var valueText = (val * 0.2).toFixed(1)
                    ctx.fillText(valueText, margin - 5, valueY + 3)
                }
                
                // Draw axis labels
                ctx.font = "12px sans-serif"
                ctx.fillStyle = Universal.foreground
                
                // X-axis label
                ctx.textAlign = "center"
                ctx.fillText("Distance (km)", width/2, height - 5)
                
                // Y-axis label
                ctx.save()
                ctx.translate(10, height/2)
                ctx.rotate(-Math.PI/2)
                ctx.textAlign = "center"
                ctx.fillText("Magnitude (pu)", 0, 0)
                ctx.restore()
                
                // Legend items
                var legendX = width - margin - 100
                var legendY = margin + 20
                
                // Voltage legend
                ctx.fillStyle = "#0078D4"
                ctx.fillRect(legendX, legendY, 20, 2)
                ctx.fillStyle = Universal.foreground
                ctx.textAlign = "left"
                ctx.fillText("Voltage", legendX + 25, legendY + 5)
                
                // Current legend
                ctx.fillStyle = "#D83B01"
                ctx.fillRect(legendX, legendY + 20, 20, 2)
                ctx.fillStyle = Universal.foreground
                ctx.fillText("Current", legendX + 25, legendY + 25)
            }
        }
    }
}