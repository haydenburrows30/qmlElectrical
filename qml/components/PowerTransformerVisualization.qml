import QtQuick
import QtQuick.Controls.Universal

Item {
    id: root
    
    // Transformer properties
    property real primaryVoltage: 0
    property real primaryCurrent: 0
    property real secondaryVoltage: 0
    property real secondaryCurrent: 0
    property real turnsRatio: 1
    property real efficiency: 0
    property real correctedRatio: 1
    property string vectorGroup: "Dyn11"
    
    // Add impedance properties
    property real impedancePercent: 6.0
    property real reactancePercent: 5.0
    property real resistancePercent: 1.0
    
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
    onTurnsRatioChanged: canvas.requestPaint()
    onEfficiencyChanged: canvas.requestPaint()
    onCorrectedRatioChanged: canvas.requestPaint()
    onVectorGroupChanged: canvas.requestPaint()
    onImpedancePercentChanged: canvas.requestPaint()
    onReactancePercentChanged: canvas.requestPaint()
    onResistancePercentChanged: canvas.requestPaint()

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
            drawTransformer(ctx, width * 0.1, height * 0.05, width * 0.8, height * 0.6, 
                           primaryVStr, secondaryVStr, primaryIStr, secondaryIStr,
                           primaryConfig, secondaryConfig,
                           primaryColor, secondaryColor, coreColor);
                           
            // Draw vector group diagram
            drawVectorGroupInfo(ctx, width * 0.5, height * 0.7, width * 0.7, height * 0.3,
                               vectorGroup, turnsRatio, correctedRatio);
        }
        
        function drawTransformer(ctx, x, y, width, height, primaryV, secondaryV, primaryI, secondaryI, 
                                primaryConfig, secondaryConfig, primaryColor, secondaryColor, coreColor) {
            var coreWidth = width * 0.2;
            var coreHeight = height * 0.7;
            var coreX = x + (width - coreWidth) / 2;
            var coreY = y + (height - coreHeight) / 2;
            
            // Draw core with lamination pattern
            drawTransformerCore(ctx, coreX, coreY, coreWidth, coreHeight, coreColor);
            
            // Draw primary winding symbol (left side)
            if (primaryConfig === "Delta") {
                drawDeltaSymbol(ctx, x + width * 0.05, y + height * 0.3, width * 0.25, height * 0.4, primaryColor);
            } else {
                drawWyeSymbol(ctx, x + width * 0.05, y + height * 0.3, width * 0.25, height * 0.4, primaryColor);
            }
            
            // Draw secondary winding symbol (right side)
            if (secondaryConfig === "Delta") {
                drawDeltaSymbol(ctx, x + width * 0.7, y + height * 0.3, width * 0.25, height * 0.4, secondaryColor);
            } else if (secondaryConfig === "Wye") {
                drawWyeSymbol(ctx, x + width * 0.7, y + height * 0.3, width * 0.25, height * 0.4, secondaryColor);
            } else {
                drawZigzagSymbol(ctx, x + width * 0.7, y + height * 0.3, width * 0.25, height * 0.4, secondaryColor);
            }
            
            // Draw labels
            ctx.fillStyle = textColor.toString();
            ctx.font = "14px sans-serif";
            ctx.textAlign = "center";
            
            // Primary voltage and current
            ctx.fillText(primaryV + " (L-L)", x + width * 0.175, y + height * 0.05);  // Added L-L
            ctx.fillText(primaryI, x + width * 0.175, y + height * 0.95);
            
            // Secondary voltage and current
            ctx.fillText(secondaryV + " (L-L)", x + width * 0.825, y + height * 0.05);  // Added L-L
            ctx.fillText(secondaryI, x + width * 0.825, y + height * 0.95);
            
            // Configuration labels
            ctx.font = "bold 12px sans-serif";
            ctx.fillText(primaryConfig + " Primary", x + width * 0.175, y + height * 0.2);
            ctx.fillText(secondaryConfig + " Secondary", x + width * 0.825, y + height * 0.2);
            
            // Draw connection lines to core
            ctx.strokeStyle = darkMode ? "#CCCCCC" : "#666666";
            ctx.lineWidth = 1;
            
            // Primary connection
            ctx.beginPath();
            ctx.moveTo(x + width * 0.175, y + height * 0.5);
            ctx.lineTo(coreX, y + height * 0.5);
            ctx.stroke();
            
            // Secondary connection
            ctx.beginPath();
            ctx.moveTo(x + width * 0.825, y + height * 0.5);
            ctx.lineTo(coreX + coreWidth, y + height * 0.5);
            ctx.stroke();
            
            // Add impedance visualization if values are set
            if (root.impedancePercent > 0) {
                drawImpedanceComponents(ctx, x + width * 0.4, y + height * 0.85, width * 0.2, height * 0.1, 
                                       root.impedancePercent, root.resistancePercent, root.reactancePercent);
            }
        }
        
        // Draw transformer core with lamination pattern
        function drawTransformerCore(ctx, x, y, width, height, color) {
            // Background fill
            ctx.fillStyle = color;
            ctx.fillRect(x, y, width, height);
            
            // Draw lamination lines to represent core
            ctx.strokeStyle = darkMode ? "#333333" : "#999999";
            ctx.lineWidth = 1;
            
            // Vertical laminations
            var laminationSpacing = width / 12;
            for (var i = 1; i < 12; i++) {
                ctx.beginPath();
                ctx.moveTo(x + i * laminationSpacing, y);
                ctx.lineTo(x + i * laminationSpacing, y + height);
                ctx.stroke();
            }
            
            // Add steel lamination texture effect
            ctx.fillStyle = darkMode ? "rgba(30,30,30,0.3)" : "rgba(150,150,150,0.3)";
            
            // Draw core label
            ctx.fillStyle = textColor.toString();
            ctx.font = "bold 12px sans-serif";
            ctx.textAlign = "center";
            ctx.fillText("Core", x + width/2, y + height/2);
            
            // Draw outer border for core
            ctx.strokeStyle = darkMode ? "#555555" : "#777777";
            ctx.lineWidth = 2;
            ctx.strokeRect(x, y, width, height);
        }
        
        // Simple Delta symbol (triangle)
        function drawDeltaSymbol(ctx, x, y, width, height, color) {
            ctx.strokeStyle = color;
            ctx.lineWidth = 3;
            
            ctx.beginPath();
            ctx.moveTo(x + width/2, y);             // Top point
            ctx.lineTo(x, y + height);              // Bottom left
            ctx.lineTo(x + width, y + height);      // Bottom right
            ctx.closePath();                        // Back to top
            ctx.stroke();
            
            // Add delta label
            ctx.fillStyle = color;
            ctx.font = "bold 24px sans-serif";
            ctx.textAlign = "center";
            ctx.fillText("Δ", x + width/2, y + height/2 + 8);
        }
        
        // Simple Wye/Star symbol (Y)
        function drawWyeSymbol(ctx, x, y, width, height, color) {
            ctx.strokeStyle = color;
            ctx.lineWidth = 3;
            
            var centerX = x + width/2;
            var centerY = y + height * 0.4;
            
            ctx.beginPath();
            // Top left arm
            ctx.moveTo(x, y);
            ctx.lineTo(centerX, centerY);
            // Top right arm
            ctx.moveTo(x + width, y);
            ctx.lineTo(centerX, centerY);
            // Bottom arm
            ctx.lineTo(centerX, y + height);
            ctx.stroke();
            
            // Add star label
            ctx.fillStyle = color;
            ctx.font = "bold 24px sans-serif";
            ctx.textAlign = "center";
            ctx.fillText("Y", x + width/2, y + height/2 + 10);
        }
        
        // Zigzag symbol (Z)
        function drawZigzagSymbol(ctx, x, y, width, height, color) {
            ctx.strokeStyle = color;
            ctx.lineWidth = 3;
            
            // Draw zigzag pattern
            ctx.beginPath();
            ctx.moveTo(x, y);                        // Top left
            ctx.lineTo(x + width, y);                // Top right
            ctx.lineTo(x, y + height/2);             // Middle left
            ctx.lineTo(x + width, y + height/2);     // Middle right
            ctx.lineTo(x, y + height);               // Bottom left
            ctx.lineTo(x + width, y + height);       // Bottom right
            ctx.stroke();
            
            // Add zigzag label
            ctx.fillStyle = color;
            ctx.font = "bold 24px sans-serif";
            ctx.textAlign = "center";
            ctx.fillText("Z", x + width/2, y + height/2 + 8);
        }
        
        function drawImpedanceComponents(ctx, x, y, width, height, z, r, x) {
            // Draw title
            ctx.fillStyle = textColor.toString();
            ctx.font = "10px sans-serif";
            ctx.textAlign = "center";
            ctx.fillText("Z = " + z.toFixed(1) + "%", x + width/2, y - 5);
            
            // Draw R-X components
            var rWidth = width * (r/z);
            var xWidth = width * (x/z);
            
            // Draw R (resistance) element
            ctx.strokeStyle = "#FF6347";
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.rect(x, y, rWidth, height);
            ctx.stroke();
            ctx.fillText("R", x + rWidth/2, y + height/2 + 4);
            
            // Draw X (reactance) element as inductor symbol
            ctx.strokeStyle = "#2196F3";
            ctx.beginPath();
            var xStart = x + rWidth + 5;
            var loops = 3;
            var loopWidth = xWidth / (loops + 1);
            
            ctx.moveTo(xStart, y + height/2);
            
            for (var i = 0; i < loops; i++) {
                var loopX = xStart + i * loopWidth;
                ctx.arc(loopX + loopWidth/2, y + height/2, loopWidth/2, Math.PI, 0, false);
            }
            
            ctx.lineTo(xStart + xWidth, y + height/2);
            ctx.stroke();
            ctx.fillText("X", xStart + xWidth/2, y + height + 10);
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
                      " | Corrected: " + correctedRatio.toFixed(1) +
                      " | Z: " + root.impedancePercent.toFixed(1) + "%";
                      
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
            var isZigzag = vectorGroup.charAt(1).toLowerCase() === "z";
            
            // Draw secondary vectors with phase shift
            if (isZigzag) {
                // Draw the main zigzag resultant vectors
                drawVector(ctx, cx, cy, radius * 0.7, 0 + shift);
                drawVector(ctx, cx, cy, radius * 0.7, 120 + shift);
                drawVector(ctx, cx, cy, radius * 0.7, 240 + shift);
                
                // Draw the component vectors that make up the zigzag
                // These are the two sets of windings that combine to create the zigzag effect
                ctx.strokeStyle = "#FF9E80"; // Lighter color for component vectors
                ctx.lineWidth = 1;
                ctx.setLineDash([2, 2]);
                
                // First set of components (at 0°, 120°, 240°)
                drawVector(ctx, cx, cy, radius * 0.35, 0 + shift);
                drawVector(ctx, cx, cy, radius * 0.35, 120 + shift);
                drawVector(ctx, cx, cy, radius * 0.35, 240 + shift);
                
                // Second set of components (at 180°, 300°, 60°) - these are the zigzag components
                drawVector(ctx, cx, cy, radius * 0.35, 180 + shift);
                drawVector(ctx, cx, cy, radius * 0.35, 300 + shift);
                drawVector(ctx, cx, cy, radius * 0.35, 60 + shift);
                
                ctx.setLineDash([]);
            } else {
                // Normal vector drawing for non-zigzag configurations
                drawVector(ctx, cx, cy, radius * 0.7, 0 + shift);
                drawVector(ctx, cx, cy, radius * 0.7, 120 + shift);
                drawVector(ctx, cx, cy, radius * 0.7, 240 + shift);
            }
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
