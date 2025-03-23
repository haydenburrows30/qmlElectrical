import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"

WaveCard {
    title: "Single-Line Diagram"
    Layout.rowSpan: 2
    Layout.minimumHeight: 200
    Layout.minimumWidth: 800
    
    // Simple single-line diagram
    Canvas {
        anchors.fill: parent
        
        onPaint: {
            var ctx = getContext("2d")
            ctx.strokeStyle = "#333333"
            ctx.lineWidth = 2
            
            // Start with LV source
            var startX = 50
            var lineY = height/2
            
            // Draw LV source
            ctx.beginPath()
            ctx.moveTo(startX, lineY-20)
            ctx.lineTo(startX, lineY+20)
            ctx.stroke()
            
            // Draw LV line
            ctx.beginPath()
            ctx.moveTo(startX, lineY)
            ctx.lineTo(startX + 50, lineY)
            ctx.stroke()
            
            // Draw transformer
            ctx.beginPath()
            ctx.moveTo(startX + 50, lineY - 25)
            ctx.lineTo(startX + 50, lineY + 25)
            ctx.stroke()
            
            ctx.beginPath()
            ctx.moveTo(startX + 60, lineY - 25)
            ctx.lineTo(startX + 60, lineY + 25)
            ctx.stroke()
            
            // Draw HV Line with distance label
            ctx.beginPath()
            ctx.moveTo(startX + 60, lineY)
            ctx.lineTo(width - 100, lineY)
            ctx.stroke()
            
            // Draw relay
            ctx.beginPath()
            ctx.arc(startX + 90, lineY - 20, 15, 0, 2*Math.PI)
            ctx.stroke()
            
            // Draw load
            ctx.beginPath()
            ctx.moveTo(width - 100, lineY - 20)
            ctx.lineTo(width - 100, lineY + 20)
            ctx.lineTo(width - 60, lineY)
            ctx.lineTo(width - 100, lineY - 20)
            ctx.stroke()
            
            // Add labels
            ctx.font = "12px sans-serif"
            ctx.fillStyle = "#333333"
            ctx.fillText("400V", startX, lineY - 30)
            ctx.fillText("11kV", startX + 70, lineY - 30)
            ctx.fillText("5km Cable", width/2 - 30, lineY - 10)
            ctx.fillText("Relay", startX + 75, lineY - 30)
            ctx.fillText("Load", width - 80, lineY + 30)
        }
    }
}