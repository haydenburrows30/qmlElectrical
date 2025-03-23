import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../"

Canvas {
    id: ohmsLawCanvas
    anchors.fill: parent

    onPaint: {
        let ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        
        // Draw a simple circuit for visualization
        ctx.strokeStyle = sideBar.toggle1 ? "white":"black"
        ctx.fillStyle = sideBar.toggle1 ? "white":"black"
        ctx.lineWidth = 2;
        ctx.font = "12px sans-serif";
        
        let centerX = width / 2;
        let centerY = height / 2;
        let radius = Math.min(width, height) / 2.5;
        
        // Draw the circuit
        ctx.beginPath();
        ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
        ctx.stroke();
        
        // Draw the Ohm's Law formula in the middle
        ctx.fillText("V = I × R", centerX - 30, centerY - 10);
        ctx.fillText("P = V × I", centerX - 30, centerY + 10);
        
        // Draw spokes with labels
        let angleStep = Math.PI / 2;
        let labels = ["V", "I", "R", "P"];
        
        let values = [
            calculator.voltage,
            calculator.current,
            calculator.resistance,
            calculator.power
        ];
        
        for (let i = 0; i < 4; i++) {
            let angle = i * angleStep;
            let x1 = centerX + radius * Math.cos(angle);
            let y1 = centerY + radius * Math.sin(angle);
            let x2 = centerX + (radius + 20) * Math.cos(angle);
            let y2 = centerY + (radius + 20) * Math.sin(angle);
            
            ctx.beginPath();
            ctx.moveTo(centerX, centerY);
            ctx.lineTo(x1, y1);
            ctx.stroke();

            let labelX = x2 - 10;
            let labelY = y2 + 5;
            ctx.fillText(labels[i] + ": " + values[i].toFixed(2), labelX, labelY);
        }
    }
}