import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"

Canvas {
    id: batteryVizCanvas
    anchors.fill: parent

    // Track theme changes to trigger repaints
    property bool darkMode: Universal.theme === Universal.Dark
    onDarkModeChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        
        var width = batteryVizCanvas.width;
        var height = batteryVizCanvas.height;
        
        // Battery dimensions
        var batteryWidth = width * 0.7;
        var batteryHeight = height * 0.6;
        var batteryX = (width - batteryWidth) / 2;
        var batteryY = (height - batteryHeight) / 2;
        var terminalWidth = batteryWidth * 0.1;
        var terminalHeight = batteryHeight * 0.2;
        
        // Draw battery outline
        ctx.strokeStyle = darkMode ? "#888" : "#555";
        ctx.lineWidth = 2;
        ctx.fillStyle = darkMode ? "#333" : "#f0f0f0";
        ctx.beginPath();
        ctx.rect(batteryX, batteryY, batteryWidth, batteryHeight);
        ctx.fill();
        ctx.stroke();
        
        // Draw positive terminal
        ctx.beginPath();
        ctx.rect(batteryX + batteryWidth, batteryY + batteryHeight/2 - terminalHeight/2,
                terminalWidth, terminalHeight);
        ctx.fill();
        ctx.stroke();
        
        // Draw capacity level
        var capacity = Math.min(calculator.depthOfDischarge / 100, 0.9);
        // Use theme-appropriate colors for capacity level
        ctx.fillStyle = capacity > 0.3 ? 
            (darkMode ? "#60C060" : "#8eff8e") : 
            (darkMode ? "#C06060" : "#ff8e8e");
        ctx.beginPath();
        ctx.rect(batteryX + 10, batteryY + 10, 
                (batteryWidth - 20) * capacity, batteryHeight - 20);
        ctx.fill();
        
        // Draw indicator lines
        ctx.strokeStyle = darkMode ? "#666" : "#888";
        ctx.lineWidth = 1;
        for (var i = 0.25; i <= 0.75; i += 0.25) {
            ctx.beginPath();
            ctx.moveTo(batteryX + batteryWidth * i, batteryY);
            ctx.lineTo(batteryX + batteryWidth * i, batteryY + batteryHeight);
            ctx.stroke();
        }
        
        // Draw labels - use theme colors
        ctx.fillStyle = Universal.foreground;
        ctx.font = "12px sans-serif";
        ctx.textAlign = "center";
        ctx.fillText("DoD: " + calculator.depthOfDischarge + "%", 
                    width/2, batteryY + batteryHeight + 20);
        ctx.fillText("Capacity: " + calculator.recommendedCapacity.toFixed(1) + " Ah", 
                    width/2, batteryY - 10);
    }
}