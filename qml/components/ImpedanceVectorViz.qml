import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    property double resistance: 3.0
    property double reactance: 4.0
    property double impedance: 5.0
    property double phaseAngle: 53.1
    property color vectorColor: "#409eff"
    property color textColor: "black"
    property color gridColor: "#eeeeee"

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var margin = 30;
            var width = canvas.width - 2 * margin;
            var height = canvas.height - 2 * margin;
            var centerX = margin + width / 2;
            var centerY = margin + height / 2;
            var scale = Math.min(width, height) / 2 / Math.max(8, impedance * 1.2);
            
            // Draw grid
            ctx.strokeStyle = gridColor;
            ctx.lineWidth = 1;
            
            // Horizontal grid lines
            for (var y = -4; y <= 4; y++) {
                ctx.beginPath();
                ctx.moveTo(margin, centerY - y * scale);
                ctx.lineTo(margin + width, centerY - y * scale);
                ctx.stroke();
            }
            
            // Vertical grid lines
            for (var x = -4; x <= 4; x++) {
                ctx.beginPath();
                ctx.moveTo(centerX + x * scale, margin);
                ctx.lineTo(centerX + x * scale, margin + height);
                ctx.stroke();
            }
            
            // Draw axes
            ctx.strokeStyle = textColor;
            ctx.lineWidth = 2;
            
            // X-axis (Resistance)
            ctx.beginPath();
            ctx.moveTo(margin, centerY);
            ctx.lineTo(margin + width, centerY);
            ctx.stroke();
            
            // Y-axis (Reactance)
            ctx.beginPath();
            ctx.moveTo(centerX, margin);
            ctx.lineTo(centerX, margin + height);
            ctx.stroke();
            
            // Draw impedance vector
            ctx.strokeStyle = vectorColor;
            ctx.lineWidth = 3;
            ctx.beginPath();
            ctx.moveTo(centerX, centerY);
            ctx.lineTo(centerX + resistance * scale, centerY - reactance * scale);
            ctx.stroke();
            
            // Draw resistance component
            ctx.strokeStyle = "rgba(255, 0, 0, 0.7)";
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(centerX, centerY);
            ctx.lineTo(centerX + resistance * scale, centerY);
            ctx.stroke();
            
            // Draw reactance component
            ctx.strokeStyle = "rgba(0, 128, 255, 0.7)";
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(centerX + resistance * scale, centerY);
            ctx.lineTo(centerX + resistance * scale, centerY - reactance * scale);
            ctx.stroke();
            
            // Labels
            ctx.fillStyle = textColor;
            ctx.font = "12px sans-serif";
            
            // R, X, Z labels
            ctx.fillText("R = " + resistance.toFixed(2) + " Ω", 
                        centerX + resistance * scale / 2 - 30, 
                        centerY + 20);
                        
            ctx.fillText("X = " + reactance.toFixed(2) + " Ω", 
                        centerX + resistance * scale + 5, 
                        centerY - reactance * scale / 2);
                        
            ctx.fillText("Z = " + impedance.toFixed(2) + " Ω, θ = " + phaseAngle.toFixed(1) + "°",
                        centerX + resistance * scale / 2 - 30, 
                        centerY - reactance * scale / 2 - 10);
            
            // Axis labels
            ctx.fillText("Resistance (R)", margin + width - 80, centerY - 10);
            ctx.fillText("Reactance (X)", centerX + 10, margin + 15);
        }
    }

    onResistanceChanged: canvas.requestPaint()
    onReactanceChanged: canvas.requestPaint()
    onImpedanceChanged: canvas.requestPaint()
    onPhaseAngleChanged: canvas.requestPaint()
}
