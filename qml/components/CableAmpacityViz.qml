import QtQuick
import QtQuick.Controls.Universal

Item {
    id: root

    // Input properties
    property real cableSize: 10
    property string insulationType: "PVC"
    property string installMethod: "Conduit"
    property int ambientTemp: 30
    property int groupingNumber: 1
    property string conductorMaterial: "Copper"
    property real baseAmpacity: 0
    property real deratedAmpacity: 0
    
    // Theme properties
    property bool darkMode: Universal.theme === Universal.Dark
    property color textColor: Universal.foreground
    
    // Update the visualization when properties change
    onDarkModeChanged: canvas.requestPaint()
    onTextColorChanged: canvas.requestPaint()
    onCableSizeChanged: canvas.requestPaint()
    onInsulationTypeChanged: canvas.requestPaint()
    onInstallMethodChanged: canvas.requestPaint()
    onAmbientTempChanged: canvas.requestPaint()
    onGroupingNumberChanged: canvas.requestPaint()
    onConductorMaterialChanged: canvas.requestPaint()
    onBaseAmpacityChanged: canvas.requestPaint()
    onDeratedAmpacityChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var width = canvas.width;
            var height = canvas.height;
            
            // Define colors based on theme
            var cableColor = conductorMaterial === "Copper" ? "#CD7F32" : "#C0C0C0";
            var insulationColor = insulationType === "PVC" ? "#808080" : "#303030";
            var currentColor = darkMode ? "#6CB4EE" : "#2196F3";
            var deratedColor = darkMode ? "#FFA07A" : "#FF6347";
            var backgroundColor = darkMode ? "#333333" : "#F5F5F5";
            
            // Calculate cable diameter based on size (simplified approximation)
            var maxCableSize = 240; // largest in the model
            var minDiameter = 20;
            var maxDiameter = 100;
            var diameter = minDiameter + (cableSize / maxCableSize) * (maxDiameter - minDiameter);
            
            // Draw the cross-section view
            drawCableCrossSection(ctx, width * 0.25, height * 0.4, diameter, cableColor, insulationColor);
            
            // Draw the installation method visualization
            drawInstallationMethod(ctx, width * 0.7, height * 0.4, diameter * 0.7, installMethod, groupingNumber, backgroundColor);
            
            // Draw the ampacity scale
            drawAmpacityScale(ctx, width * 0.1, height * 0.75, width * 0.8, height * 0.15, 
                             baseAmpacity, deratedAmpacity, currentColor, deratedColor);
            
            // Draw label text
            ctx.fillStyle = textColor.toString();
            ctx.font = "14px sans-serif";
            ctx.textAlign = "center";
            
            // Cable specs text
            var specText = conductorMaterial + " " + cableSize.toString() + " mm² " + insulationType;
            ctx.fillText(specText, width * 0.25, height * 0.2);
            
            // Installation method text
            ctx.fillText(installMethod + " (" + groupingNumber + " circuits)", width * 0.7, height * 0.2);
            
            // Temperature text
            ctx.fillText("Ambient Temperature: " + ambientTemp.toString() + "°C", width * 0.5, height * 0.6);
        }
        
        // Draw a cable cross-section
        function drawCableCrossSection(ctx, x, y, diameter, cableColor, insulationColor) {
            var coreRadius = diameter * 0.4; // conductor is 40% of total diameter
            var insulationThickness = diameter * 0.1; // insulation is 10% of total diameter
            
            // Draw outer insulation
            ctx.fillStyle = insulationColor;
            ctx.beginPath();
            ctx.arc(x, y, diameter / 2, 0, 2 * Math.PI);
            ctx.fill();
            
            // Draw inner conductor
            ctx.fillStyle = cableColor;
            ctx.beginPath();
            ctx.arc(x, y, coreRadius, 0, 2 * Math.PI);
            ctx.fill();
            
            // Add conductor shine effect
            var gradient = ctx.createRadialGradient(x - coreRadius * 0.3, y - coreRadius * 0.3, 0, x, y, coreRadius);
            gradient.addColorStop(0, "rgba(255, 255, 255, 0.7)");
            gradient.addColorStop(1, "rgba(255, 255, 255, 0)");
            ctx.fillStyle = gradient;
            ctx.beginPath();
            ctx.arc(x, y, coreRadius, 0, 2 * Math.PI);
            ctx.fill();
        }
        
        // Draw the installation method
        function drawInstallationMethod(ctx, x, y, cableSize, method, groupCount, backgroundColor) {
            ctx.fillStyle = backgroundColor;
            
            switch (method) {
                case "Conduit":
                    // Draw circular conduit
                    ctx.beginPath();
                    ctx.arc(x, y, cableSize * 1.5, 0, 2 * Math.PI);
                    ctx.stroke();
                    
                    // Draw cable inside
                    drawMultipleCables(ctx, x, y, cableSize, groupCount, cableSize * 1.3);
                    break;
                    
                case "Tray":
                    // Draw cable tray
                    var trayWidth = cableSize * (groupCount + 1);
                    var trayHeight = cableSize * 1.5;
                    ctx.fillRect(x - trayWidth / 2, y - cableSize / 2, trayWidth, trayHeight);
                    ctx.strokeRect(x - trayWidth / 2, y - cableSize / 2, trayWidth, trayHeight);
                    
                    // Draw cables in tray
                    drawMultipleCables(ctx, x, y, cableSize, groupCount, 0);
                    break;
                    
                case "Direct Buried":
                    // Draw ground/soil
                    var groundWidth = cableSize * (groupCount + 2);
                    var groundHeight = cableSize * 3;
                    ctx.fillStyle = "#8B4513"; // Brown for soil
                    ctx.fillRect(x - groundWidth / 2, y - groundHeight / 2, groundWidth, groundHeight);
                    ctx.strokeRect(x - groundWidth / 2, y - groundHeight / 2, groundWidth, groundHeight);
                    
                    // Draw cables buried
                    drawMultipleCables(ctx, x, y, cableSize, groupCount, 0);
                    break;
                    
                case "Free Air":
                    // Just draw cables with space between them
                    drawMultipleCables(ctx, x, y, cableSize, groupCount, 0);
                    break;
                    
                case "Wall Surface":
                    // Draw wall
                    var wallWidth = cableSize * (groupCount + 2);
                    var wallHeight = cableSize * 3;
                    ctx.fillRect(x - wallWidth / 2, y - wallHeight / 2, wallWidth, wallHeight);
                    ctx.strokeRect(x - wallWidth / 2, y - wallHeight / 2, wallWidth, wallHeight);
                    
                    // Draw cables on surface
                    drawMultipleCables(ctx, x, y - cableSize, cableSize, groupCount, 0);
                    break;
            }
        }
        
        // Draw multiple cables for grouping visualization
        function drawMultipleCables(ctx, x, y, cableSize, count, radius) {
            if (count === 1) {
                // Single cable centered
                drawSimpleCable(ctx, x, y, cableSize);
                return;
            }
            
            // Multiple cables
            var spacing = cableSize * 1.2;
            var startX = x - (spacing * (count - 1)) / 2;
            
            for (var i = 0; i < count; i++) {
                var cableX = startX + i * spacing;
                // If circular arrangement (like in conduit)
                if (radius > 0 && count > 2) {
                    var angle = (i / count) * 2 * Math.PI;
                    cableX = x + radius * Math.cos(angle);
                    var cableY = y + radius * Math.sin(angle);
                    drawSimpleCable(ctx, cableX, cableY, cableSize * 0.6);
                } else {
                    // Linear arrangement
                    drawSimpleCable(ctx, cableX, y, cableSize * 0.8);
                }
            }
        }
        
        // Draw a simplified cable for grouping
        function drawSimpleCable(ctx, x, y, size) {
            ctx.strokeStyle = "#000000";
            ctx.lineWidth = 1;
            ctx.fillStyle = conductorMaterial === "Copper" ? "#CD7F32" : "#C0C0C0";
            
            ctx.beginPath();
            ctx.arc(x, y, size / 2, 0, 2 * Math.PI);
            ctx.fill();
            ctx.stroke();
        }
        
        // Draw the ampacity scale
        function drawAmpacityScale(ctx, x, y, width, height, baseValue, deratedValue, baseColor, deratedColor) {
            // Calculate a reasonable maximum for the scale
            var maxAmpacity = Math.max(baseValue, 400);
            
            // Base ampacity bar
            var baseWidth = (baseValue / maxAmpacity) * width;
            ctx.fillStyle = baseColor;
            ctx.fillRect(x, y, baseWidth, height * 0.4);
            
            // Derated ampacity bar
            var deratedWidth = (deratedValue / maxAmpacity) * width;
            ctx.fillStyle = deratedColor;
            ctx.fillRect(x, y + height * 0.5, deratedWidth, height * 0.4);
            
            // Draw scale markers
            ctx.strokeStyle = textColor.toString();
            ctx.lineWidth = 1;
            for (var i = 0; i <= 4; i++) {
                var markerX = x + (i / 4) * width;
                ctx.beginPath();
                ctx.moveTo(markerX, y - 5);
                ctx.lineTo(markerX, y + height + 5);
                ctx.stroke();
                
                // Add marker label
                ctx.fillStyle = textColor.toString();
                ctx.textAlign = "center";
                ctx.font = "12px sans-serif";
                ctx.fillText((maxAmpacity * i / 4).toFixed(0) + "A", markerX, y - 10);
            }
            
            // Add labels for the bars
            ctx.font = "12px sans-serif";
            ctx.textAlign = "left";
            ctx.fillStyle = textColor.toString();
            ctx.fillText("Base Ampacity: " + baseValue.toFixed(1) + "A", x + 10, y + height * 0.25);
            ctx.fillText("Derated: " + deratedValue.toFixed(1) + "A", x + 10, y + height * 0.75);
        }
    }
}
