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
    property real correctedRatio: 1
    property string vectorGroup: "Dyn11"
    
    // Theme properties
    property bool darkMode: Universal.theme === Universal.Dark
    property color textColor: Universal.foreground
    
    // Animation properties
    property real animationSpeed: 1.0
    
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
    onCorrectedRatioChanged: canvas.requestPaint()
    onVectorGroupChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var width = canvas.width;
            var height = canvas.height;
            
            // Define colors based on theme
            var primaryColor = darkMode ? "#6CB4EE" : "#2196F3";
            var secondaryColor = darkMode ? "#FFA07A" : "#FF6347";
            var windingColor = darkMode ? "#FFD700" : "#FFA500";
            var coreColor = darkMode ? "#A0A0A0" : "#696969";
            
            // Get vector group configuration
            var primaryConfig = vectorGroup.charAt(0) === "D" ? "Delta" : "Wye";
            var secondaryConfig = vectorGroup.charAt(1).toLowerCase() === "y" ? "Wye" : 
                                  vectorGroup.charAt(1).toLowerCase() === "d" ? "Delta" : "Zigzag";

            // Format values with fewer decimal places
            var primaryVStr = primaryVoltage.toFixed(0) + "V";
            var secondaryVStr = secondaryVoltage.toFixed(0) + "V";
            var primaryIStr = primaryCurrent.toFixed(1) + "A";
            var secondaryIStr = secondaryCurrent.toFixed(1) + "A";

            // Draw transformer
            drawTransformer(ctx, width * 0.1, height * 0.2, width * 0.8, height * 0.6, 
                           primaryVStr, secondaryVStr, primaryIStr, secondaryIStr,
                           primaryConfig, secondaryConfig,
                           primaryColor, secondaryColor, coreColor);
                           
            // Draw vector group diagram
            drawVectorGroupInfo(ctx, width * 0.5, height * 0.90, width * 0.8, height * 0.15,
                               vectorGroup, turnsRatio, correctedRatio);
        }
        
        function drawTransformer(ctx, x, y, width, height, primaryV, secondaryV, primaryI, secondaryI, 
                                primaryConfig, secondaryConfig, primaryColor, secondaryColor, coreColor) {
            var coreWidth = width * 0.2;
            var coreHeight = height * 0.7;
            var coreX = x + (width - coreWidth) / 2;
            var coreY = y + (height - coreHeight) / 2;
            
            // Draw core
            ctx.fillStyle = coreColor;
            ctx.fillRect(coreX, coreY, coreWidth, coreHeight);
            
            // Draw primary winding (left side)
            if (primaryConfig === "Delta") {
                drawDeltaWinding(ctx, x, y + height * 0.1, width * 0.35, height * 0.8, primaryColor);
            } else {
                drawWyeWinding(ctx, x, y + height * 0.1, width * 0.35, height * 0.8, primaryColor);
            }
            
            // Draw secondary winding (right side)
            if (secondaryConfig === "Delta") {
                drawDeltaWinding(ctx, x + width * 0.65, y + height * 0.1, width * 0.35, height * 0.8, secondaryColor);
            } else if (secondaryConfig === "Wye") {
                drawWyeWinding(ctx, x + width * 0.65, y + height * 0.1, width * 0.35, height * 0.8, secondaryColor);
            } else {
                drawZigzagWinding(ctx, x + width * 0.65, y + height * 0.1, width * 0.35, height * 0.8, secondaryColor);
            }
            
            // Draw labels
            ctx.fillStyle = textColor.toString();
            ctx.font = "14px sans-serif";
            ctx.textAlign = "center";
            
            // Primary voltage and current
            ctx.fillText(primaryV, x + width * 0.175, y + height * 0.05);
            ctx.fillText(primaryI, x + width * 0.175, y + height * 0.95);
            
            // Secondary voltage and current
            ctx.fillText(secondaryV, x + width * 0.825, y + height * 0.05);
            ctx.fillText(secondaryI, x + width * 0.825, y + height * 0.95);
            
            // Configuration labels
            ctx.font = "bold 12px sans-serif";
            ctx.fillText(primaryConfig + " Primary", x + width * 0.175, y + height * 0.5);
            ctx.fillText(secondaryConfig + " Secondary", x + width * 0.825, y + height * 0.5);
        }
        
        function drawDeltaWinding(ctx, x, y, width, height, color) {
            ctx.strokeStyle = color;
            ctx.lineWidth = 2;
            
            // Draw delta shape outline - improved symmetry
            var centerX = x + width * 0.5;
            var topY = y + height * 0.15;
            var bottomY = y + height * 0.85;
            
            // Draw equilateral delta for better symmetry
            ctx.beginPath();
            ctx.moveTo(x + width * 0.25, topY);               // Top left
            ctx.lineTo(x + width * 0.75, topY);               // Top right
            ctx.lineTo(centerX, bottomY);                     // Bottom center
            ctx.closePath();
            ctx.stroke();
            
            // Draw windings with more symmetry
            var turns = 8;
            var widthStep = (width * 0.5) / turns;
            var heightStep = (bottomY - topY) / turns;
            
            for (var i = 0; i < turns; i++) {
                // Left side windings
                ctx.beginPath();
                ctx.moveTo(x + width * 0.25 + i * widthStep, topY + i * heightStep * 0.5);
                ctx.lineTo(centerX - i * widthStep * 0.5, topY + i * heightStep * 0.5);
                ctx.stroke();
                
                // Right side windings
                ctx.beginPath();
                ctx.moveTo(x + width * 0.75 - i * widthStep, topY + i * heightStep * 0.5);
                ctx.lineTo(centerX + i * widthStep * 0.5, topY + i * heightStep * 0.5);
                ctx.stroke();
                
                // Bottom windings
                ctx.beginPath();
                var yPos = bottomY - i * heightStep * 0.5;
                var leftX = centerX - (width * 0.25) * (i / turns);
                var rightX = centerX + (width * 0.25) * (i / turns);
                ctx.moveTo(leftX, yPos);
                ctx.lineTo(rightX, yPos);
                ctx.stroke();
            }
        }
        
        function drawWyeWinding(ctx, x, y, width, height, color) {
            ctx.strokeStyle = color;
            ctx.lineWidth = 2;
            
            var centerX = x + width * 0.5;
            var centerY = y + height * 0.4;
            var bottomY = y + height * 0.85;
            var topY = y + height * 0.15;
            var radius = width * 0.3;
            
            // Draw Y shape outline with improved symmetry
            ctx.beginPath();
            // Top left arm
            ctx.moveTo(x + width * 0.2, topY);
            ctx.lineTo(centerX, centerY);
            // Top right arm
            ctx.moveTo(x + width * 0.8, topY);
            ctx.lineTo(centerX, centerY);
            // Vertical arm
            ctx.lineTo(centerX, bottomY);
            ctx.stroke();
            
            // Draw windings with better symmetry
            var turns = 10;
            var armLength = Math.sqrt(Math.pow(centerX - (x + width * 0.2), 2) + 
                                     Math.pow(centerY - topY, 2));
            var stepSize = armLength / turns;
            
            for (var i = 1; i < turns; i++) {
                var ratio = i / turns;
                
                // Left arm winding
                var leftX1 = x + width * 0.2 + (centerX - (x + width * 0.2)) * ratio;
                var leftY1 = topY + (centerY - topY) * ratio;
                var leftAngle = Math.atan2(centerY - topY, centerX - (x + width * 0.2));
                var leftX2 = leftX1 + Math.cos(leftAngle + Math.PI/2) * stepSize * 0.3;
                var leftY2 = leftY1 + Math.sin(leftAngle + Math.PI/2) * stepSize * 0.3;
                
                ctx.beginPath();
                ctx.moveTo(leftX1, leftY1);
                ctx.lineTo(leftX2, leftY2);
                ctx.stroke();
                
                // Right arm winding
                var rightX1 = x + width * 0.8 - (x + width * 0.8 - centerX) * ratio;
                var rightY1 = topY + (centerY - topY) * ratio;
                var rightAngle = Math.atan2(centerY - topY, (x + width * 0.8) - centerX);
                var rightX2 = rightX1 + Math.cos(rightAngle - Math.PI/2) * stepSize * 0.3;
                var rightY2 = rightY1 + Math.sin(rightAngle - Math.PI/2) * stepSize * 0.3;
                
                ctx.beginPath();
                ctx.moveTo(rightX1, rightY1);
                ctx.lineTo(rightX2, rightY2);
                ctx.stroke();
                
                // Vertical arm winding
                if (i > turns/2) {
                    var vRatio = (i - turns/2) / (turns/2);
                    var vY = centerY + (bottomY - centerY) * vRatio;
                    
                    ctx.beginPath();
                    ctx.moveTo(centerX - stepSize * 0.3, vY);
                    ctx.lineTo(centerX + stepSize * 0.3, vY);
                    ctx.stroke();
                }
            }
        }
        
        function drawZigzagWinding(ctx, x, y, width, height, color) {
            var turns = 8;
            var turnHeight = height / turns;
            
            ctx.strokeStyle = color;
            ctx.lineWidth = 2;
            
            // Draw zigzag pattern
            ctx.beginPath();
            ctx.moveTo(x + width * 0.2, y + height * 0.15);
            
            for (var i = 0; i < turns; i++) {
                var yStart = y + height * 0.15 + i * height * 0.8 / turns;
                var yEnd = y + height * 0.15 + (i + 1) * height * 0.8 / turns;
                
                if (i % 2 === 0) {
                    ctx.lineTo(x + width * 0.8, yStart);
                    ctx.lineTo(x + width * 0.2, yEnd);
                } else {
                    ctx.lineTo(x + width * 0.8, yStart);
                    ctx.lineTo(x + width * 0.2, yEnd);
                }
            }
            
            ctx.stroke();
        }
        
        function drawVectorGroupInfo(ctx, x, y, width, height, vectorGroup, turnsRatio, correctedRatio) {
            ctx.fillStyle = textColor.toString();
            ctx.font = "12px sans-serif";
            ctx.textAlign = "center";
            
            var phase = vectorGroup.substring(2) || "0";
            var phaseAngle = phase === "11" ? "30°" : phase === "1" ? "-30°" : "0°";
            
            var info = "Vector Group: " + vectorGroup + 
                      " | Phase Shift: " + phaseAngle +
                      " | Ratio: " + turnsRatio.toFixed(1) +
                      " | Corrected: " + correctedRatio.toFixed(1);
                      
            ctx.fillText(info, x, y);
            
            // Draw vector diagram
            var radius = height * 0.6;
            var cx = x;
            var cy = y + radius * 0.8;
            
            // Primary vectors
            ctx.strokeStyle = "#2196F3";
            ctx.lineWidth = 2;
            
            // Draw primary vectors (120° apart)
            drawVector(ctx, cx, cy, radius, 0);
            drawVector(ctx, cx, cy, radius, 120);
            drawVector(ctx, cx, cy, radius, 240);
            
            // Secondary vectors with phase shift
            ctx.strokeStyle = "#FF6347";
            ctx.lineWidth = 2;
            
            var shift = phase === "11" ? 30 : phase === "1" ? -30 : 0;
            
            // Draw secondary vectors with phase shift
            drawVector(ctx, cx, cy, radius * 0.7, 0 + shift);
            drawVector(ctx, cx, cy, radius * 0.7, 120 + shift);
            drawVector(ctx, cx, cy, radius * 0.7, 240 + shift);
        }
        
        function drawVector(ctx, cx, cy, length, angle) {
            var radians = (angle - 90) * Math.PI / 180;
            var x2 = cx + length * Math.cos(radians);
            var y2 = cy + length * Math.sin(radians);
            
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.lineTo(x2, y2);
            ctx.stroke();
            
            // Draw arrow tip
            var tipLength = length * 0.1;
            var tipRadians1 = (angle - 90 - 20) * Math.PI / 180;
            var tipRadians2 = (angle - 90 + 20) * Math.PI / 180;
            
            var tipX1 = x2 - tipLength * Math.cos(tipRadians1);
            var tipY1 = y2 - tipLength * Math.sin(tipRadians1);
            var tipX2 = x2 - tipLength * Math.cos(tipRadians2);
            var tipY2 = y2 - tipLength * Math.sin(tipRadians2);
            
            ctx.beginPath();
            ctx.moveTo(x2, y2);
            ctx.lineTo(tipX1, tipY1);
            ctx.lineTo(tipX2, tipY2);
            ctx.closePath();
            ctx.fill();
        }
    }
}
