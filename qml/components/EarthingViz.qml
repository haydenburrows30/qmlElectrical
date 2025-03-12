import QtQuick
import QtQuick.Controls.Universal

Item {
    id: root
    
    // Input properties
    property real gridLength: 20.0
    property real gridWidth: 20.0
    property int rodCount: 4
    property real rodLength: 3.0
    property real gridResistance: 0.0
    
    // Theme properties
    property bool darkMode: Universal.theme === Universal.Dark
    property color textColor: Universal.foreground
    
    // Update visualization when properties change
    onDarkModeChanged: canvas.requestPaint()
    onTextColorChanged: canvas.requestPaint()
    onGridLengthChanged: canvas.requestPaint()
    onGridWidthChanged: canvas.requestPaint()
    onRodCountChanged: canvas.requestPaint()
    onRodLengthChanged: canvas.requestPaint()
    onGridResistanceChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var width = canvas.width;
            var height = canvas.height;
            
            // Define colors based on theme
            var gridColor = darkMode ? "#6CB4EE" : "#2196F3";
            var rodColor = darkMode ? "#FFA07A" : "#FF6347";  // Move rodColor definition up here
            var soilColor = darkMode ? "#555555" : "#D2B48C";
            var voltageColor = darkMode ? "#90EE90" : "#00CC00";
            
            // Draw top view (upper half)
            drawTopView(ctx, 0, 0, width, height * 0.45, gridColor, rodColor);  // Pass rodColor as parameter
            
            // Draw side view (lower half)
            drawSideView(ctx, 0, height * 0.55, width, height * 0.45, 
                        gridColor, rodColor, soilColor);
            
            // Draw voltage profile
            drawVoltageProfile(ctx, width * 0.1, height * 0.45, width * 0.8, height * 0.1, 
                             voltageColor);
        }
        
        function drawTopView(ctx, x, y, width, height, gridColor, rodColor) {  // Add rodColor parameter
            var margin = 40;
            var gridPixelWidth = width - 2 * margin;
            var gridPixelHeight = height - 2 * margin;
            
            // Draw grid outline
            ctx.strokeStyle = gridColor;
            ctx.lineWidth = 2;
            ctx.strokeRect(x + margin, y + margin, gridPixelWidth, gridPixelHeight);
            
            // Draw grid conductors
            var numLengthConductors = 5;
            var numWidthConductors = 5;
            var lengthSpacing = gridPixelWidth / (numLengthConductors - 1);
            var widthSpacing = gridPixelHeight / (numWidthConductors - 1);
            
            ctx.beginPath();
            // Vertical lines
            for (var i = 0; i < numLengthConductors; i++) {
                ctx.moveTo(x + margin + i * lengthSpacing, y + margin);
                ctx.lineTo(x + margin + i * lengthSpacing, y + margin + gridPixelHeight);
            }
            // Horizontal lines
            for (var j = 0; j < numWidthConductors; j++) {
                ctx.moveTo(x + margin, y + margin + j * widthSpacing);
                ctx.lineTo(x + margin + gridPixelWidth, y + margin + j * widthSpacing);
            }
            ctx.stroke();
            
            // Draw ground rods (as dots)
            ctx.fillStyle = rodColor;
            var rodSpacing = gridPixelWidth / (Math.ceil(Math.sqrt(rodCount)) + 1);
            var rodCount2D = Math.ceil(Math.sqrt(rodCount));
            var rodsPlaced = 0;
            
            for (var row = 0; row < rodCount2D && rodsPlaced < rodCount; row++) {
                for (var col = 0; col < rodCount2D && rodsPlaced < rodCount; col++) {
                    ctx.beginPath();
                    ctx.arc(x + margin + (col + 1) * rodSpacing, 
                           y + margin + (row + 1) * widthSpacing, 
                           5, 0, 2 * Math.PI);
                    ctx.fill();
                    rodsPlaced++;
                }
            }
            
            // Add dimensions
            ctx.fillStyle = textColor.toString();
            ctx.font = "12px sans-serif";
            ctx.textAlign = "center";
            ctx.fillText(gridLength.toFixed(1) + "m", x + width/2, y + height - 5);
            
            ctx.save();
            ctx.translate(x + 10, y + height/2);
            ctx.rotate(-Math.PI/2);
            ctx.fillText(gridWidth.toFixed(1) + "m", 0, 0);
            ctx.restore();
        }
        
        function drawSideView(ctx, x, y, width, height, gridColor, rodColor, soilColor) {
            var margin = 40;
            var groundLevel = y + margin;
            var maxDepth = y + height - margin;
            
            // Draw soil layers
            var gradient = ctx.createLinearGradient(x, groundLevel, x, maxDepth);
            gradient.addColorStop(0, soilColor);
            gradient.addColorStop(1, darkMode ? "#333333" : "#8B4513");
            
            ctx.fillStyle = gradient;
            ctx.fillRect(x + margin, groundLevel, width - 2 * margin, maxDepth - groundLevel);
            
            // Draw grid conductor
            ctx.strokeStyle = gridColor;
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(x + margin, groundLevel + 20);  // 20px below ground level
            ctx.lineTo(x + width - margin, groundLevel + 20);
            ctx.stroke();
            
            // Draw ground rods
            ctx.strokeStyle = rodColor;
            ctx.lineWidth = 3;
            var rodSpacing = (width - 2 * margin) / (rodCount + 1);
            
            for (var i = 0; i < rodCount; i++) {
                var rodX = x + margin + (i + 1) * rodSpacing;
                ctx.beginPath();
                ctx.moveTo(rodX, groundLevel + 20);
                ctx.lineTo(rodX, groundLevel + 20 + rodLength * 30);  // Scale rod length
                ctx.stroke();
            }
            
            // Add dimensions
            ctx.fillStyle = textColor.toString();
            ctx.font = "12px sans-serif";
            ctx.textAlign = "left";
            ctx.fillText("Depth: " + rodLength.toFixed(1) + "m", x + width - 80, y + height - 10);
        }
        
        function drawVoltageProfile(ctx, x, y, width, height, voltageColor) {
            ctx.strokeStyle = voltageColor;
            ctx.lineWidth = 2;
            
            // Draw voltage profile curve
            ctx.beginPath();
            ctx.moveTo(x, y + height);
            
            // Create bell-shaped curve
            for (var i = 0; i <= width; i++) {
                var normalizedX = i / width;
                var voltage = Math.exp(-Math.pow((normalizedX - 0.5) * 4, 2));
                ctx.lineTo(x + i, y + height * (1 - voltage));
            }
            ctx.stroke();
            
            // Add resistance value
            ctx.fillStyle = textColor.toString();
            ctx.font = "12px sans-serif";
            ctx.textAlign = "right";
            ctx.fillText("Grid Resistance: " + gridResistance.toFixed(3) + "Ω", 
                        x + width, y + height/2);
        }
    }
}
