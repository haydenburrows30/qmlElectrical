import QtQuick

Rectangle {
    color: "#f5f5f5"
    border.color: "#dddddd"
    radius: 5
    
    // Single-line diagram of wind turbine + transformer + line
    Canvas {
        anchors.fill: parent
        anchors.margins: 10
        
        onPaint: {
            var ctx = getContext("2d")
            ctx.strokeStyle = "#333333"
            ctx.lineWidth = 2
            
            // Start with wind turbine source
            var startX = 50
            var lineY = height/2
            
            // Draw wind turbine symbol
            ctx.beginPath()
            var turbineRadius = 15
            ctx.arc(startX, lineY-30, turbineRadius, 0, 2*Math.PI)
            ctx.stroke()
            
            // Draw blades
            for (var i = 0; i < 3; i++) {
                var angle = (i * 2 * Math.PI / 3) - Math.PI/6
                ctx.beginPath()
                ctx.moveTo(startX, lineY-30)
                ctx.lineTo(
                    startX + Math.cos(angle) * turbineRadius*2.5,
                    (lineY-30) + Math.sin(angle) * turbineRadius*2.5
                )
                ctx.stroke()
            }
            
            // Connect turbine to LV side
            ctx.beginPath()
            ctx.moveTo(startX, lineY-15)
            ctx.lineTo(startX, lineY)
            ctx.stroke()
            
            // Draw 400V busbar
            ctx.beginPath()
            ctx.moveTo(startX-20, lineY)
            ctx.lineTo(startX+90, lineY)
            ctx.stroke()
            
            // Draw LV protection/breaker
            ctx.beginPath()
            ctx.rect(startX+40, lineY-10, 20, 20)
            ctx.stroke()
            
            // Connect to transformer
            ctx.beginPath()
            ctx.moveTo(startX+90, lineY)
            ctx.lineTo(startX+120, lineY)
            ctx.stroke()
            
            // Draw transformer
            ctx.beginPath()
            ctx.moveTo(startX+120, lineY-25)
            ctx.lineTo(startX+120, lineY+25)
            ctx.stroke()
            
            ctx.beginPath()
            ctx.moveTo(startX+130, lineY-25)
            ctx.lineTo(startX+130, lineY+25)
            ctx.stroke()
            
            // Draw HV Line with distance label
            ctx.beginPath()
            ctx.moveTo(startX+130, lineY)
            ctx.lineTo(width-100, lineY)
            ctx.stroke()
            
            // Draw HV protection/relay
            ctx.beginPath()
            ctx.arc(startX+160, lineY-20, 15, 0, 2*Math.PI)
            ctx.stroke()
            
            // Draw load/grid
            ctx.beginPath()
            ctx.moveTo(width-100, lineY-20)
            ctx.lineTo(width-100, lineY+20)
            ctx.lineTo(width-60, lineY)
            ctx.lineTo(width-100, lineY-20)
            ctx.stroke()
            
            // Add labels
            ctx.font = "12px sans-serif"
            ctx.fillStyle = "#333333"
            ctx.fillText("Wind Generator", startX-30, lineY-55)
            ctx.fillText("400V", startX-20, lineY-10)
            ctx.fillText("LV Protection", startX+20, lineY+30)
            ctx.fillText("11kV", startX+140, lineY-30)
            ctx.fillText("5km Cable", width/2-30, lineY-10)
            ctx.fillText("HV Relay", startX+145, lineY-30)
            ctx.fillText("Grid", width-80, lineY+30)
        }
    }
}
