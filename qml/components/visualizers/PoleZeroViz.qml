import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import Qt.labs.platform

import "../visualizers/"
import "../buttons/"

Rectangle {
    id: poleZeroPlot
    width: parent.width
    height: parent.height * 0.45
    
    color: root.backgroundColor
    border.color: root.gridColor
    border.width: 1
    radius: 5

    property var pzCanvas: pzCanvas
    
    Canvas {
        id: pzCanvas
        anchors.fill: parent
        anchors.margins: 10
        
        property real centerX: width / 2
        property real centerY: height / 2
        property real radius: Math.min(width, height) * 0.4
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            
            // Draw coordinate system
            ctx.strokeStyle = root.gridColor;
            ctx.lineWidth = 1;
            
            // Draw unit circle
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
            ctx.stroke();
            
            // Draw coordinate axes
            ctx.beginPath();
            ctx.moveTo(0, centerY);
            ctx.lineTo(width, centerY);
            ctx.moveTo(centerX, 0);
            ctx.lineTo(centerX, height);
            ctx.stroke();
            
            // Draw poles
            ctx.fillStyle = root.poleColor;
            ctx.strokeStyle = root.poleColor;
            ctx.lineWidth = 2;
            
            for (var i = 0; i < poleLocations.length; i++) {
                var pole = poleLocations[i];
                var poleX = centerX + pole.x * radius;
                var poleY = centerY - pole.y * radius; // Note the negative sign for y coordinates
                
                // Draw cross for pole
                ctx.beginPath();
                ctx.moveTo(poleX - 7, poleY - 7);
                ctx.lineTo(poleX + 7, poleY + 7);
                ctx.moveTo(poleX + 7, poleY - 7);
                ctx.lineTo(poleX - 7, poleY + 7);
                ctx.stroke();
            }
            
            // Draw zeros
            ctx.fillStyle = root.zeroColor;
            ctx.strokeStyle = root.zeroColor;
            ctx.lineWidth = 2;
            
            for (var j = 0; j < zeroLocations.length; j++) {
                var zero = zeroLocations[j];
                var zeroX = centerX + zero.x * radius;
                var zeroY = centerY - zero.y * radius; // Note the negative sign for y coordinates
                
                // Draw circle for zero
                ctx.beginPath();
                ctx.arc(zeroX, zeroY, 7, 0, 2 * Math.PI);
                ctx.stroke();
            }
            
            // Add grid lines for better readability
            ctx.strokeStyle = root.gridColor;
            ctx.lineWidth = 0.5;
            ctx.setLineDash([3, 3]); // Dotted line
            
            // Draw horizontal grid lines
            for (var k = -2; k <= 2; k++) {
                if (k === 0) continue; // Skip center line, already drawn
                var gridY = centerY + k * radius/2;
                ctx.beginPath();
                ctx.moveTo(0, gridY);
                ctx.lineTo(width, gridY);
                ctx.stroke();
            }
            
            // Draw vertical grid lines
            for (var l = -2; l <= 2; l++) {
                if (l === 0) continue; // Skip center line, already drawn
                var gridX = centerX + l * radius/2;
                ctx.beginPath();
                ctx.moveTo(gridX, 0);
                ctx.lineTo(gridX, height);
                ctx.stroke();
            }
            
            // Reset line dash
            ctx.setLineDash([]);
            
            // Draw labels
            ctx.fillStyle = root.textColor;
            ctx.font = "12px sans-serif";
            ctx.textAlign = "center";
            
            ctx.fillText("Re(z)", width - 20, centerY - 5);
            ctx.fillText("Im(z)", centerX + 5, 15);
            ctx.fillText("|z| = 1", centerX, centerY - radius - 5);
            
            // Draw +/- 0.5 markers
            ctx.fillText("0.5", centerX + radius/2, centerY - 5);
            ctx.fillText("-0.5", centerX - radius/2, centerY - 5);
            ctx.fillText("0.5j", centerX + 5, centerY - radius/2);
            ctx.fillText("-0.5j", centerX + 5, centerY + radius/2);
            
            // Draw legend
            var legendX = 60;
            var legendY = height - 30;
            
            // Pole legend
            ctx.strokeStyle = root.poleColor;
            ctx.beginPath();
            ctx.moveTo(legendX - 5, legendY - 5);
            ctx.lineTo(legendX + 5, legendY + 5);
            ctx.moveTo(legendX + 5, legendY - 5);
            ctx.lineTo(legendX - 5, legendY + 5);
            ctx.stroke();
            
            ctx.fillStyle = root.textColor;
            ctx.textAlign = "left";
            ctx.fillText("Pole", legendX + 10, legendY + 5);
            
            // Zero legend
            legendX += 80;
            ctx.strokeStyle = root.zeroColor;
            ctx.beginPath();
            ctx.arc(legendX, legendY, 5, 0, 2 * Math.PI);
            ctx.stroke();
            
            ctx.fillStyle = root.textColor;
            ctx.fillText("Zero", legendX + 10, legendY + 5);
        }
    }
    
    Text {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Pole-Zero Plot"
        color: root.textColor
        font.pixelSize: 14
        font.bold: true
    }
    
    Component.onCompleted: {
        updatePoleZeroPlot();
    }
}