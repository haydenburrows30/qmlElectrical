import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../style"

WaveCard {
    // id: 
    title: "Power Triangle"

    property var activePower: "12"
    property var currentPF: "0.8"

    onActivePowerChanged: powerTriangleCard.requestPaint()
    onCurrentPFChanged: powerTriangleCard.requestPaint()

    Canvas {
        id: powerTriangleCard
        anchors.fill: parent
        anchors.topMargin: 20

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            
            // Get values with safety checks
            var p = activePower || 0
            var pf = currentPF || 0
            
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
            var centerY = height/1.5
            
            // Draw triangle with thicker lines
            ctx.strokeStyle = "#2196F3";
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(centerX - p*scale/2, centerY)
            ctx.lineTo(centerX + p*scale/2, centerY)
            ctx.lineTo(centerX + p*scale/2, centerY - q*scale)
            ctx.closePath()
            ctx.stroke()

            var foregroundColor = textColor.toString()
            ctx.fillStyle = foregroundColor
            ctx.font = "12px sans-serif"
            ctx.textAlign = "center"
            
            // Active Power (P)
            ctx.fillText(p.toFixed(1) + " kW", centerX, centerY + 20)
            
            // Reactive Power (Q)
            ctx.fillText(q.toFixed(1) + " kVAR", 
                centerX + p*scale/2 + 40, 
                centerY - q*scale/2)
            
            // Apparent Power (S)
            ctx.fillText(s.toFixed(1) + " kVA",
                centerX - p*scale/2,
                centerY - q*scale/2 )
            
            // Power Factor Angle
            ctx.fillText("φ = " + (Math.acos(pf) * 180/Math.PI).toFixed(1) + "°",
                centerX + p*scale/4,
                centerY - q*scale/4)
        }
    }
}