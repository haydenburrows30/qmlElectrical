import QtQuick
import QtQuick.Controls.Universal

Item {
    id: root
    
    // Transformer properties
    property real primaryVoltage: 0
    property real primaryCurrent: 0
    property real secondaryVoltage: 0
    property real secondaryCurrent: 0
    property real powerRating: 0
    property real turnsRatio: 1
    property real efficiency: 0
    
    // Theme properties
    property bool darkMode: Universal.theme === Universal.Dark
    property color textColor: Universal.foreground
    
    // Update on property changes
    onDarkModeChanged: canvas.requestPaint()
    onTextColorChanged: canvas.requestPaint()
    onPrimaryVoltageChanged: canvas.requestPaint()
    onPrimaryCurrentChanged: canvas.requestPaint()
    onSecondaryVoltageChanged: canvas.requestPaint()
    onSecondaryCurrentChanged: canvas.requestPaint()
    onPowerRatingChanged: canvas.requestPaint()
    onTurnsRatioChanged: canvas.requestPaint()
    onEfficiencyChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var width = canvas.width;
            var height = canvas.height;
            
            // Define colors based on theme
            var primaryColor = darkMode ? "#6CB4EE" : "#0066CC";
            var secondaryColor = darkMode ? "#FFA07A" : "#FF6347";
            var coreColor = darkMode ? "#555555" : "#AAAAAA";
            var powerFlowColor = darkMode ? "#90EE90" : "#00CC00";
            var lossColor = darkMode ? "#FF9999" : "#FF0000";
            
            // Draw transformer core
            drawTransformerCore(ctx, width * 0.1, height * 0.2, width * 0.8, height * 0.4, coreColor);
            
            // Draw windings
            var transformerWidth = width * 0.8;
            var transformerHeight = height * 0.4;
            var centerX = width * 0.1 + transformerWidth / 2;
            var centerY = height * 0.2 + transformerHeight / 2;
            
            // Primary winding (left)
            drawWinding(ctx, width * 0.1, height * 0.25, width * 0.25, height * 0.3, 
                       primaryColor, 8, turnsRatio > 1 ? 12 : 6);
            
            // Secondary winding (right)
            drawWinding(ctx, width * 0.65, height * 0.25, width * 0.25, height * 0.3, 
                       secondaryColor, 8, turnsRatio < 1 ? 12 : 6);
            
            // Draw transformer terminals
            drawTerminals(ctx, width * 0.05, centerY, width * 0.05, centerY - height * 0.15, 
                         width * 0.05, centerY + height * 0.15, primaryColor);
            drawTerminals(ctx, width * 0.95, centerY, width * 0.95, centerY - height * 0.15, 
                         width * 0.95, centerY + height * 0.15, secondaryColor);
            
            // Draw power flow diagram at bottom
            if (primaryVoltage > 0 && primaryCurrent > 0) {
                drawPowerFlow(ctx, width * 0.1, height * 0.75, width * 0.8, height * 0.15, 
                             powerRating, efficiency, powerFlowColor, lossColor);
            }
            
            // Labels
            ctx.fillStyle = textColor.toString();
            ctx.font = "14px sans-serif";
            ctx.textAlign = "center";
            
            // Primary labels
            if (primaryVoltage > 0) {
                ctx.fillText(primaryVoltage.toFixed(1) + "V", width * 0.2, height * 0.15);
            }
            if (primaryCurrent > 0) {
                ctx.fillText(primaryCurrent.toFixed(2) + "A", width * 0.2, height * 0.6);
            }
            
            // Secondary labels
            if (secondaryVoltage > 0) {
                ctx.fillText(secondaryVoltage.toFixed(1) + "V", width * 0.8, height * 0.15);
            }
            if (secondaryCurrent > 0) {
                ctx.fillText(secondaryCurrent.toFixed(2) + "A", width * 0.8, height * 0.6);
            }
            
            // Center label - transformer info
            if (turnsRatio > 0) {
                ctx.font = "bold 14px sans-serif";
                ctx.fillText("Ratio: " + turnsRatio.toFixed(2), centerX, height * 0.2 - 20);
                
                if (powerRating > 0) {
                    ctx.font = "14px sans-serif";
                    ctx.fillText(powerRating.toFixed(1) + " VA", centerX, height * 0.6 + 20);
                }
                
                if (efficiency > 0) {
                    ctx.fillText("η: " + efficiency.toFixed(1) + "%", centerX, height * 0.6 + 40);
                }
            }
        }
        
        // Draw transformer core
        function drawTransformerCore(ctx, x, y, width, height, color) {
            ctx.fillStyle = color;
            
            // Draw E-I core shape
            ctx.beginPath();
            
            // E shape (left)
            ctx.moveTo(x, y);
            ctx.lineTo(x + width * 0.3, y);
            ctx.lineTo(x + width * 0.3, y + height * 0.2);
            ctx.lineTo(x + width * 0.15, y + height * 0.2);
            ctx.lineTo(x + width * 0.15, y + height * 0.4);
            ctx.lineTo(x + width * 0.3, y + height * 0.4);
            ctx.lineTo(x + width * 0.3, y + height * 0.6);
            ctx.lineTo(x + width * 0.15, y + height * 0.6);
            ctx.lineTo(x + width * 0.15, y + height * 0.8);
            ctx.lineTo(x + width * 0.3, y + height * 0.8);
            ctx.lineTo(x + width * 0.3, y + height);
            ctx.lineTo(x, y + height);
            ctx.closePath();
            ctx.fill();
            
            // I shape (right)
            ctx.fillRect(x + width * 0.7, y, width * 0.3, height);
        }
        
        // Draw transformer winding
        function drawWinding(ctx, x, y, width, height, color, segments, turns) {
            ctx.strokeStyle = color;
            ctx.lineWidth = 2;
            
            var segmentHeight = height / segments;
            
            for (var i = 0; i < segments; i++) {
                for (var j = 0; j < turns; j++) {
                    var turnWidth = width / turns;
                    var turnX = x + j * turnWidth;
                    var turnY = y + i * segmentHeight;
                    
                    ctx.beginPath();
                    ctx.moveTo(turnX, turnY);
                    ctx.lineTo(turnX + turnWidth * 0.8, turnY);
                    ctx.lineTo(turnX + turnWidth * 0.8, turnY + segmentHeight * 0.8);
                    ctx.lineTo(turnX, turnY + segmentHeight * 0.8);
                    ctx.closePath();
                    ctx.stroke();
                }
            }
        }
        
        // Draw transformer terminals
        function drawTerminals(ctx, x, y, top, topY, bottom, bottomY, color) {
            ctx.strokeStyle = color;
            ctx.lineWidth = 3;
            
            // Horizontal line
            ctx.beginPath();
            ctx.moveTo(x, topY);
            ctx.lineTo(x, bottomY);
            ctx.stroke();
            
            // Terminal points
            ctx.beginPath();
            ctx.arc(x, topY, 4, 0, 2 * Math.PI);
            ctx.fill();
            
            ctx.beginPath();
            ctx.arc(x, bottomY, 4, 0, 2 * Math.PI);
            ctx.fill();
        }
        
        // Draw power flow diagram
        function drawPowerFlow(ctx, x, y, width, height, power, efficiency, powerColor, lossColor) {
            // Calculate loss
            var inputPower = power / (efficiency / 100);
            var loss = inputPower - power;
            
            // Normalize for display
            var totalWidth = width * 0.8;
            var inputWidth = totalWidth;
            var outputWidth = totalWidth * (efficiency / 100);
            var lossWidth = totalWidth - outputWidth;
            
            // Draw input power
            ctx.fillStyle = powerColor;
            ctx.fillRect(x, y, inputWidth, height);
            
            // Draw output power
            ctx.fillRect(x + width - outputWidth, y, outputWidth, height);
            
            // Draw loss
            ctx.fillStyle = lossColor;
            ctx.fillRect(x + inputWidth, y, lossWidth, height);
            
            // Add labels
            ctx.fillStyle = textColor.toString();
            ctx.font = "12px sans-serif";
            ctx.textAlign = "center";
            
            ctx.fillText("Input: " + inputPower.toFixed(1) + "W", 
                       x + inputWidth / 2, y + height / 2);
            
            ctx.fillText("Output: " + power.toFixed(1) + "W", 
                       x + width - outputWidth / 2, y + height / 2);
            
            if (lossWidth > 50) {  // Only draw if there's enough space
                ctx.fillText("Loss: " + loss.toFixed(1) + "W", 
                           x + inputWidth + lossWidth / 2, y + height / 2);
            }
        }
    }
}
