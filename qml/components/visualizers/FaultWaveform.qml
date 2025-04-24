import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Canvas {
    id: root
    
    property string faultType: "Balanced System" // Default to balanced system
    property color phaseAColor: "#f44336" // Red
    property color phaseBColor: "#4caf50" // Green
    property color phaseCColor: "#2196f3" // Blue
    property color gridColor: "#888888"
    property color textColor: "#333333"
    property int cycleCount: 2 // Show two cycles of waveform
    
    onFaultTypeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        
        // Draw background
        ctx.fillStyle = "transparent"
        ctx.fillRect(0, 0, width, height)
        
        // Define parameters
        var margin = 20
        var graphWidth = width - 2 * margin
        var graphHeight = height - 2 * margin
        var centerY = height / 2
        var amplitude = graphHeight / 2 - 10
        
        // Draw time axis (x-axis)
        ctx.beginPath()
        ctx.strokeStyle = gridColor
        ctx.lineWidth = 1
        ctx.moveTo(margin, centerY)
        ctx.lineTo(width - margin, centerY)
        ctx.stroke()
        
        // Draw amplitude axis (y-axis)
        ctx.beginPath()
        ctx.moveTo(margin, margin)
        ctx.lineTo(margin, height - margin)
        ctx.stroke()
        
        // Draw grid lines
        ctx.setLineDash([2, 2]) // Dashed lines for grid
        
        // Horizontal grid lines
        var gridSteps = 4
        for (var i = 1; i < gridSteps; i++) {
            var y = margin + (graphHeight / gridSteps) * i
            if (y !== centerY) { // Skip the center line as we already drew it solid
                ctx.beginPath()
                ctx.moveTo(margin, y)
                ctx.lineTo(width - margin, y)
                ctx.stroke()
            }
        }
        
        // Vertical grid lines (one per quarter cycle)
        var quarters = cycleCount * 4
        for (var j = 1; j < quarters; j++) {
            var x = margin + (graphWidth / quarters) * j
            ctx.beginPath()
            ctx.moveTo(x, margin)
            ctx.lineTo(x, height - margin)
            ctx.stroke()
        }
        ctx.setLineDash([]) // Reset to solid line
        
        // Draw axes labels
        ctx.fillStyle = textColor
        ctx.font = "10px Arial"
        ctx.textAlign = "center"
        
        // X-axis labels (time)
        ctx.fillText("0°", margin, centerY + 15)
        ctx.fillText("180°", margin + graphWidth/2, centerY + 15)
        ctx.fillText("360°", width - margin, centerY + 15)
        
        // Y-axis labels (voltage/current)
        ctx.textAlign = "right"
        ctx.fillText("+1.0", margin - 5, margin + 10)
        ctx.fillText("0", margin - 5, centerY)
        ctx.fillText("-1.0", margin - 5, height - margin)
        
        // Title based on fault type
        ctx.fillStyle = textColor
        ctx.font = "12px Arial"
        ctx.textAlign = "center"
        
        var title = ""
        switch(faultType) {
            case "Balanced System": 
                title = "Balanced System - Normal Operation"
                break;
            case "Unbalanced System": 
                title = "Unbalanced System - Phase Magnitudes/Angles Differ"
                break;
            case "Single Line-to-Ground Fault": 
                title = "Phase A to Ground Fault"
                break;
            case "Line-to-Line Fault": 
                title = "Phase B to Phase C Fault"
                break;
            case "Double Line-to-Ground Fault": 
                title = "Phases B & C to Ground Fault"
                break;
            case "Three-Phase Fault": 
                title = "Three-Phase Fault"
                break;
            default:
                title = faultType
        }
        ctx.fillText(title, width/2, margin - 5)
        
        // Draw waveforms based on fault type
        drawWaveforms(ctx, margin, graphWidth, centerY, amplitude)
    }
    
    function drawWaveforms(ctx, margin, graphWidth, centerY, amplitude) {
        var steps = 100 * cycleCount // Resolution of the sine wave
        
        // Draw Phase A
        ctx.beginPath()
        ctx.strokeStyle = phaseAColor
        ctx.lineWidth = 2
        
        // Draw Phase B
        var phaseB = []
        ctx.beginPath()
        ctx.strokeStyle = phaseBColor
        ctx.lineWidth = 2
        
        // Draw Phase C
        var phaseC = []
        ctx.beginPath()
        ctx.strokeStyle = phaseCColor
        ctx.lineWidth = 2
        
        // Prepare values based on fault type
        var phaseAMag = 1.0; // Default amplitude
        var phaseBMag = 1.0;
        var phaseCMag = 1.0;
        var phaseAShift = 0; // Phase shift in degrees
        var phaseBShift = -120;
        var phaseCShift = 120;
        
        // Distort waveforms based on fault type
        switch(faultType) {
            case "Unbalanced System":
                // Slight unbalance in magnitude and phase
                phaseAMag = 1.0;
                phaseBMag = 0.85;
                phaseCMag = 1.15;
                phaseAShift = 0;
                phaseBShift = -115;
                phaseCShift = 125;
                break;
                
            case "Single Line-to-Ground Fault":
                // Phase A voltage collapses
                phaseAMag = 0.2;  // Greatly reduced
                phaseBMag = 1.0;  // Normal
                phaseCMag = 1.0;  // Normal
                phaseAShift = 0;
                phaseBShift = -120;
                phaseCShift = 120;
                break;
                
            case "Line-to-Line Fault":
                // Phase B and C voltages are affected (equalize somewhat)
                phaseAMag = 1.0;   // Normal
                phaseBMag = 0.7;   // Reduced
                phaseCMag = 0.7;   // Reduced
                phaseAShift = 0;
                phaseBShift = -150; // Shifted from normal
                phaseCShift = 150;  // Shifted from normal
                break;
                
            case "Double Line-to-Ground Fault":
                // Phases B and C collapsed
                phaseAMag = 1.0;  // Normal
                phaseBMag = 0.15; // Collapsed
                phaseCMag = 0.15; // Collapsed
                phaseAShift = 0;
                phaseBShift = -120;
                phaseCShift = 120;
                break;
                
            case "Three-Phase Fault":
                // All phases reduced but balanced
                phaseAMag = 0.3;  // All reduced
                phaseBMag = 0.3;
                phaseCMag = 0.3;
                phaseAShift = 0;
                phaseBShift = -120;
                phaseCShift = 120;
                break;
                
            default: // Balanced System
                phaseAMag = 1.0;
                phaseBMag = 1.0;
                phaseCMag = 1.0;
                phaseAShift = 0;
                phaseBShift = -120;
                phaseCShift = 120;
        }

        // Draw waveforms
        // Phase A (red)
        ctx.beginPath()
        ctx.strokeStyle = phaseAColor
        for (var i = 0; i <= steps; i++) {
            var x = margin + (graphWidth / steps) * i
            var angle = (360 / steps) * i * cycleCount + phaseAShift
            var y = centerY - amplitude * phaseAMag * Math.sin(angle * Math.PI / 180)
            if (i === 0) {
                ctx.moveTo(x, y)
            } else {
                ctx.lineTo(x, y)
            }
        }
        ctx.stroke()
        
        // Phase B (green)
        ctx.beginPath()
        ctx.strokeStyle = phaseBColor
        for (var i = 0; i <= steps; i++) {
            var x = margin + (graphWidth / steps) * i
            var angle = (360 / steps) * i * cycleCount + phaseBShift
            var y = centerY - amplitude * phaseBMag * Math.sin(angle * Math.PI / 180)
            if (i === 0) {
                ctx.moveTo(x, y)
            } else {
                ctx.lineTo(x, y)
            }
        }
        ctx.stroke()
        
        // Phase C (blue)
        ctx.beginPath()
        ctx.strokeStyle = phaseCColor
        for (var i = 0; i <= steps; i++) {
            var x = margin + (graphWidth / steps) * i
            var angle = (360 / steps) * i * cycleCount + phaseCShift
            var y = centerY - amplitude * phaseCMag * Math.sin(angle * Math.PI / 180)
            if (i === 0) {
                ctx.moveTo(x, y)
            } else {
                ctx.lineTo(x, y)
            }
        }
        ctx.stroke()
        
        // Draw legend
        var legendX = margin + 10
        var legendY = margin + 15
        var legendSpacing = 15
        
        // Phase A
        ctx.beginPath()
        ctx.strokeStyle = phaseAColor
        ctx.lineWidth = 2
        ctx.moveTo(legendX, legendY)
        ctx.lineTo(legendX + 20, legendY)
        ctx.stroke()
        ctx.fillStyle = textColor
        ctx.textAlign = "left"
        ctx.fillText("Phase A", legendX + 25, legendY + 4)
        
        // Phase B
        legendY += legendSpacing
        ctx.beginPath()
        ctx.strokeStyle = phaseBColor
        ctx.moveTo(legendX, legendY)
        ctx.lineTo(legendX + 20, legendY)
        ctx.stroke()
        ctx.fillText("Phase B", legendX + 25, legendY + 4)
        
        // Phase C
        legendY += legendSpacing
        ctx.beginPath()
        ctx.strokeStyle = phaseCColor
        ctx.moveTo(legendX, legendY)
        ctx.lineTo(legendX + 20, legendY)
        ctx.stroke()
        ctx.fillText("Phase C", legendX + 25, legendY + 4)
    }
}
