import QtQuick
import QtQuick.Controls.Universal

Item {
    id: root
    
    // Machine properties
    property string machineType: "Induction Motor"
    property real ratedPower: 5.0
    property real efficiency: 0.9
    property real losses: 0.55
    property real speedRPM: 1450
    property real torque: 33
    property real slip: 0.033
    property real temperatureRise: 75.0
    
    // Theme properties
    property bool darkMode: Universal.theme === Universal.Dark
    property color textColor: Universal.foreground
    
    // Update on property changes
    onDarkModeChanged: canvas.requestPaint()
    onTextColorChanged: canvas.requestPaint()
    onMachineTypeChanged: canvas.requestPaint()
    onRatedPowerChanged: canvas.requestPaint()
    onEfficiencyChanged: canvas.requestPaint()
    onLossesChanged: canvas.requestPaint()
    onSpeedRPMChanged: canvas.requestPaint()
    onTorqueChanged: canvas.requestPaint()
    onSlipChanged: canvas.requestPaint()
    onTemperatureRiseChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var width = canvas.width;
            var height = canvas.height;
            
            // Define colors based on theme
            var statorColor = darkMode ? "#555555" : "#AAAAAA";
            var rotorColor = darkMode ? "#6CB4EE" : "#2196F3";
            var windingColor = darkMode ? "#FFA07A" : "#FF6347";
            var arrowColor = darkMode ? "#90EE90" : "#00CC00";
            var lossColor = darkMode ? "#FF9999" : "#FF0000";
            
            // Draw machine cross section
            drawMachineCrossSection(ctx, width * 0.5, height * 0.35, 
                                  Math.min(width, height) * 0.3,
                                  statorColor, rotorColor, windingColor);
            
            // Draw power flow diagram
            drawPowerFlow(ctx, width * 0.1, height * 0.7, width * 0.8, height * 0.2, 
                        arrowColor, lossColor);
            
            // Draw labels and information
            ctx.fillStyle = textColor.toString();
            ctx.font = "14px sans-serif";
            ctx.textAlign = "center";
            
            // Machine type label
            ctx.font = "bold 16px sans-serif";
            ctx.fillText(machineType, width * 0.5, height * 0.08);
            
            // Power, torque and speed information
            ctx.font = "14px sans-serif";
            ctx.textAlign = "left";
            var infoX = width * 0.05;
            var infoY = height * 0.12;
            var lineSpacing = 20;
            
            ctx.fillText("Power: " + ratedPower.toFixed(2) + " kW", infoX, infoY);
            ctx.fillText("Efficiency: " + (efficiency * 100).toFixed(1) + "%", infoX, infoY + lineSpacing);
            ctx.fillText("Speed: " + speedRPM.toFixed(0) + " RPM", infoX, infoY + 2 * lineSpacing);
            ctx.fillText("Torque: " + torque.toFixed(2) + " N·m", infoX, infoY + 3 * lineSpacing);
            
            if (machineType === "Induction Motor") {
                ctx.fillText("Slip: " + (slip * 100).toFixed(2) + "%", infoX, infoY + 4 * lineSpacing);
            }
            
            // Draw speed-torque curve
            drawSpeedTorqueCurve(ctx, width * 0.7, height * 0.25, width * 0.25, height * 0.25);
        }
        
        function drawMachineCrossSection(ctx, centerX, centerY, radius, statorColor, rotorColor, windingColor) {
            // Ensure radius is valid
            radius = Math.max(10, radius || 100);  // Default to 100 if radius is undefined
            
            // Draw stator
            ctx.fillStyle = statorColor;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
            ctx.fill();
            
            // Draw rotor
            ctx.fillStyle = rotorColor;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius * 0.7, 0, 2 * Math.PI);
            ctx.fill();
            
            // Draw inner shaft
            ctx.fillStyle = darkMode ? "#888888" : "#444444";
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius * 0.2, 0, 2 * Math.PI);
            ctx.fill();
            
            // Draw windings in stator slots
            ctx.fillStyle = windingColor;
            var slots = 12;  // Number of slots to draw
            var slotRadius = (radius + radius * 0.7) / 2;  // Middle of air gap
            var slotWidth = radius * 0.15;
            
            for (var i = 0; i < slots; i++) {
                var angle = (i / slots) * 2 * Math.PI;
                var x = centerX + slotRadius * Math.cos(angle);
                var y = centerY + slotRadius * Math.sin(angle);
                
                ctx.beginPath();
                ctx.arc(x, y, slotWidth / 2, 0, 2 * Math.PI);
                ctx.fill();
            }
            
            // Draw shaft extension lines
            ctx.strokeStyle = darkMode ? "#AAAAAA" : "#444444";
            ctx.lineWidth = radius * 0.05;
            
            // Left shaft
            ctx.beginPath();
            ctx.moveTo(centerX - radius * 1.2, centerY);
            ctx.lineTo(centerX - radius, centerY);
            ctx.stroke();
            
            // Right shaft
            ctx.beginPath();
            ctx.moveTo(centerX + radius, centerY);
            ctx.lineTo(centerX + radius * 1.2, centerY);
            ctx.stroke();
            
            // Rotation direction arrow
            ctx.strokeStyle = textColor.toString();
            ctx.lineWidth = 2;
            var arrowSize = radius * 0.15;
            
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius * 0.45, 0.75 * Math.PI, 1.75 * Math.PI);
            ctx.stroke();
            
            // Arrow head
            ctx.beginPath();
            ctx.moveTo(centerX, centerY - radius * 0.45);
            ctx.lineTo(centerX - arrowSize, centerY - radius * 0.45 - arrowSize/2);
            ctx.lineTo(centerX - arrowSize, centerY - radius * 0.45 + arrowSize/2);
            ctx.closePath();
            ctx.fillStyle = textColor.toString();
            ctx.fill();
        }
        
        function drawPowerFlow(ctx, x, y, width, height, powerColor, lossColor) {
            // Settings
            var arrowHeight = height * 0.6;
            var gap = 10;
            
            // Calculate input and output power
            var inputPower = machineType.endsWith("Motor") ? 
                ratedPower / efficiency : ratedPower;
            var outputPower = machineType.endsWith("Motor") ?
                ratedPower : ratedPower * efficiency;
            
            // Draw flow direction
            var flowRight = machineType.endsWith("Motor");
            
            // Draw input power arrow
            ctx.fillStyle = powerColor;
            if (flowRight) {
                drawArrow(ctx, x, y + height/2, width * 0.4, arrowHeight, "right");
                ctx.fillStyle = textColor.toString();
                ctx.textAlign = "center";
                ctx.fillText("Electric Input: " + inputPower.toFixed(2) + " kW", 
                           x + width * 0.2, y + height + 15);
            } else {
                drawArrow(ctx, x + width * 0.6, y + height/2, width * 0.4, arrowHeight, "right");
                ctx.fillStyle = textColor.toString();
                ctx.textAlign = "center";
                ctx.fillText("Mechanical Input: " + inputPower.toFixed(2) + " kW", 
                           x + width * 0.8, y + height + 15);
            }
            
            // Draw losses arrow
            ctx.fillStyle = lossColor;
            drawArrow(ctx, x + width * 0.45, y + height/2, height * 0.4, arrowHeight * 0.6, "up");
            ctx.fillStyle = textColor.toString();
            ctx.textAlign = "center";
            ctx.fillText("Losses: " + losses.toFixed(2) + " kW", x + width * 0.45, y - 10);
            
            // Draw output power arrow
            ctx.fillStyle = powerColor;
            if (flowRight) {
                drawArrow(ctx, x + width * 0.6, y + height/2, width * 0.4, arrowHeight, "right");
                ctx.fillStyle = textColor.toString();
                ctx.textAlign = "center";
                ctx.fillText("Mechanical Output: " + outputPower.toFixed(2) + " kW", 
                           x + width * 0.8, y + height + 15);
            } else {
                drawArrow(ctx, x, y + height/2, width * 0.4, arrowHeight, "right");
                ctx.fillStyle = textColor.toString();
                ctx.textAlign = "center";
                ctx.fillText("Electric Output: " + outputPower.toFixed(2) + " kW", 
                           x + width * 0.2, y + height + 15);
            }
            
            // Add efficiency text
            ctx.fillStyle = textColor.toString();
            ctx.textAlign = "center";
            ctx.fillText("Efficiency: " + (efficiency * 100).toFixed(1) + "%", x + width/2, y - 30);
        }
        
        function drawArrow(ctx, x, y, width, height, direction) {
            var headWidth = height;
            var headLength = width * 0.2;
            var bodyLength = width - headLength;
            
            if (direction === "right") {
                // Draw arrow body
                ctx.fillRect(x, y - height/4, bodyLength, height/2);
                
                // Draw arrow head
                ctx.beginPath();
                ctx.moveTo(x + bodyLength, y - height/4);
                ctx.lineTo(x + bodyLength, y - height/2);
                ctx.lineTo(x + width, y);
                ctx.lineTo(x + bodyLength, y + height/2);
                ctx.lineTo(x + bodyLength, y + height/4);
                ctx.closePath();
                ctx.fill();
            } else if (direction === "up") {
                // For upward arrow, swap width and height
                // Draw arrow body
                ctx.fillRect(x - height/4, y - bodyLength, height/2, bodyLength);
                
                // Draw arrow head
                ctx.beginPath();
                ctx.moveTo(x - height/4, y - bodyLength);
                ctx.lineTo(x - height/2, y - bodyLength);
                ctx.lineTo(x, y - width);
                ctx.lineTo(x + height/2, y - bodyLength);
                ctx.lineTo(x + height/4, y - bodyLength);
                ctx.closePath();
                ctx.fill();
            }
        }
        
        function drawSpeedTorqueCurve(ctx, x, y, width, height) {
            // Set up coordinates
            var originX = x;
            var originY = y + height;
            var maxX = x + width;
            var maxY = y;
            
            // Axes
            ctx.strokeStyle = textColor.toString();
            ctx.lineWidth = 1;
            
            // X axis (speed)
            ctx.beginPath();
            ctx.moveTo(originX, originY);
            ctx.lineTo(maxX + 10, originY);
            ctx.stroke();
            
            // Y axis (torque)
            ctx.beginPath();
            ctx.moveTo(originX, originY);
            ctx.lineTo(originX, maxY - 10);
            ctx.stroke();
            
            // Labels
            ctx.fillStyle = textColor.toString();
            ctx.textAlign = "center";
            ctx.fillText("Speed", (originX + maxX) / 2, originY + 15);
            
            ctx.save();
            ctx.translate(originX - 15, (originY + maxY) / 2);
            ctx.rotate(-Math.PI/2);
            ctx.fillText("Torque", 0, 0);
            ctx.restore();
            
            // Draw curve based on machine type
            ctx.strokeStyle = "#FF6600";
            ctx.lineWidth = 2;
            ctx.beginPath();
            
            if (machineType === "Induction Motor") {
                // Draw more detailed characteristic curve
                ctx.moveTo(originX, originY - height * 0.6);  // Starting torque point
                
                // Pull-up region
                ctx.bezierCurveTo(
                    originX + width * 0.2, originY - height * 0.5,  // Control point 1
                    originX + width * 0.3, originY - height * 0.7,  // Control point 2
                    originX + width * 0.4, originY - height * 0.7   // Pull-up point
                );
                
                // Breakdown region
                ctx.bezierCurveTo(
                    originX + width * 0.5, originY - height * 0.7,  // Control point 1
                    originX + width * 0.6, originY - height * 0.95, // Control point 2
                    originX + width * 0.7, originY - height * 0.95  // Breakdown point
                );
                
                // Operating region
                ctx.bezierCurveTo(
                    originX + width * 0.8, originY - height * 0.95, // Control point 1
                    originX + width * 0.85, originY - height * 0.7, // Control point 2
                    originX + width * 0.95, originY - height * 0.1  // End point
                );
                
                // Draw operating points
                drawOperatingPoint(ctx, originX, originY - height * 0.6, "Starting");
                drawOperatingPoint(ctx, originX + width * 0.4, originY - height * 0.7, "Pull-up");
                drawOperatingPoint(ctx, originX + width * 0.7, originY - height * 0.95, "Breakdown");
                drawOperatingPoint(ctx, originX + width * 0.8, originY - height * 0.7, "Rated");
            } else if (machineType === "DC Motor" || machineType === "DC Generator") {
                // DC motor/generator - linear speed-torque relationship
                ctx.moveTo(originX, originY - height * 0.9);
                ctx.lineTo(originX + width, originY - height * 0.1);
                
                // Mark the rated point
                var ratedX = originX + width * 0.7;
                var ratedY = originY - height * 0.3;
                ctx.fillStyle = "#FF6600";
                ctx.beginPath();
                ctx.arc(ratedX, ratedY, 5, 0, 2 * Math.PI);
                ctx.fill();
                
            } else {
                // Synchronous machines - constant speed
                ctx.moveTo(originX + width * 0.8, originY);
                ctx.lineTo(originX + width * 0.8, originY - height * 0.9);
                ctx.lineTo(originX + width, originY - height * 0.9);
                
                // Mark the rated point
                var ratedX = originX + width * 0.8;
                var ratedY = originY - height * 0.7;
                ctx.fillStyle = "#FF6600";
                ctx.beginPath();
                ctx.arc(ratedX, ratedY, 5, 0, 2 * Math.PI);
                ctx.fill();
            }
            
            ctx.stroke();
            
            // Add temperature indicator
            var tempGradient = ctx.createLinearGradient(x + width + 10, y, x + width + 30, y);
            tempGradient.addColorStop(0, "#00ff00");
            tempGradient.addColorStop(0.5, "#ffff00");
            tempGradient.addColorStop(1, "#ff0000");
            
            ctx.fillStyle = tempGradient;
            ctx.fillRect(x + width + 10, y, 20, height);
            
            // Temperature marker
            var tempHeight = (1 - temperatureRise / 150) * height;
            ctx.fillStyle = "#000000";
            ctx.beginPath();
            ctx.moveTo(x + width + 5, y + tempHeight);
            ctx.lineTo(x + width + 35, y + tempHeight);
            ctx.stroke();
            
            ctx.fillStyle = textColor;
            ctx.textAlign = "left";
            ctx.fillText(temperatureRise.toFixed(1) + "°C", x + width + 40, y + tempHeight);

            // Add temperature warning if over limit
            if (temperatureRise > 80) {
                ctx.fillStyle = "#FF0000";
                ctx.font = "bold 14px sans-serif";
                ctx.fillText("⚠️ Temperature Limit Exceeded", 
                           x + width/2, y - 20);
                ctx.fillText("Efficiency Derated", 
                           x + width/2, y - 40);
            }
        }
        
        function drawOperatingPoint(ctx, x, y, label) {
            ctx.fillStyle = "#FF6600";
            ctx.beginPath();
            ctx.arc(x, y, 5, 0, 2 * Math.PI);
            ctx.fill();
            
            ctx.fillStyle = textColor;
            ctx.textAlign = "right";
            ctx.fillText(label, x - 10, y);
        }
    }
}
