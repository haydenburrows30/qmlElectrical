import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    property double voltage: 0.0      // kV
    property double capacitance: 0.0  // μF/km
    property double frequency: 50.0   // Hz
    property double length: 1.0       // km
    property double current: 0.0      // A
    property color cableColor: "#409eff"
    property color textColor: "black"
    property color waveColor: "#ff7e00"

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var margin = 20;
            var width = canvas.width - 2 * margin;
            var height = canvas.height - 2 * margin;
            
            // Draw cable representation
            var cableY = margin + height * 0.3;
            var cableThickness = 15;
            var cableLength = width * 0.8;
            var cableStart = margin + width * 0.1;
            
            // Draw cable as a rectangle
            ctx.fillStyle = cableColor;
            ctx.fillRect(cableStart, cableY, cableLength, cableThickness);
            
            // Draw insulators
            var insulatorCount = Math.min(10, Math.max(3, Math.floor(length * 2)));
            var insulatorSpacing = cableLength / (insulatorCount - 1);
            var insulatorHeight = 15;
            
            ctx.fillStyle = "#aaaaaa";
            for (var i = 0; i < insulatorCount; i++) {
                var x = cableStart + i * insulatorSpacing;
                ctx.fillRect(x - 3, cableY + cableThickness, 6, insulatorHeight);
            }
            
            // Draw ground
            ctx.fillStyle = "#555555";
            ctx.fillRect(margin, cableY + cableThickness + insulatorHeight, width, 3);
            
            // Draw charging current as waves
            if (current > 0) {
                var waveHeight = Math.min(40, Math.max(5, current * 3));
                var waveY = cableY - 5;
                
                ctx.strokeStyle = waveColor;
                ctx.lineWidth = 2;
                
                // Multiple waves based on current magnitude
                var waveCount = Math.min(5, Math.max(1, Math.ceil(current / 2)));
                var waveSpacing = (cableLength - 40) / (waveCount + 1);
                
                for (var w = 1; w <= waveCount; w++) {
                    var waveX = cableStart + w * waveSpacing;
                    
                    // Draw a simple wave pattern
                    ctx.beginPath();
                    ctx.moveTo(waveX - 20, waveY);
                    
                    // Draw sine wave shape
                    for (var p = -20; p <= 20; p += 2) {
                        var waveMagnitude = Math.sin(p * 0.15) * waveHeight;
                        ctx.lineTo(waveX + p, waveY - waveMagnitude);
                    }
                    
                    ctx.stroke();
                    
                    // Draw arrow indicating direction (always upward for charging current)
                    ctx.beginPath();
                    ctx.moveTo(waveX, waveY - waveHeight - 10);
                    ctx.lineTo(waveX - 5, waveY - waveHeight);
                    ctx.lineTo(waveX + 5, waveY - waveHeight);
                    ctx.closePath();
                    ctx.fillStyle = waveColor;
                    ctx.fill();
                }
            }
            
            // Draw text information
            ctx.fillStyle = textColor;
            ctx.font = "12px sans-serif";
            ctx.fillText("Cable: " + length.toFixed(1) + " km", margin, height + margin - 10);
            ctx.fillText("Capacitance: " + capacitance.toFixed(2) + " μF/km", margin + width * 0.3, height + margin - 10);
            
            // Draw voltage and current near the cable
            ctx.font = "14px sans-serif";
            ctx.fillText(voltage.toFixed(1) + " kV", cableStart, cableY - 15);
            
            if (current > 0) {
                ctx.fillStyle = waveColor;
                ctx.fillText(current.toFixed(2) + " A", cableStart + cableLength - 50, cableY - 15);
            }
        }
    }

    onVoltageChanged: canvas.requestPaint()
    onCapacitanceChanged: canvas.requestPaint()
    onFrequencyChanged: canvas.requestPaint()
    onLengthChanged: canvas.requestPaint()
    onCurrentChanged: canvas.requestPaint()
}
