import QtQuick

Canvas {
    id: circuitCanvas
    
    // Properties to control the appearance
    property bool darkMode: false
    property int circuitType: 0  // 0 for series, 1 for parallel
    property color wireColor: darkMode ? "#CCCCCC" : "#404040"
    property color resistorColor: darkMode ? "#E0E0E0" : "#505050"
    property color inductorColor: darkMode ? "#80B0FF" : "#3070B0"
    property color capacitorColor: darkMode ? "#FF9090" : "#D04030"
    property color labelColor: darkMode ? "#FFFFFF" : "#000000"
    property color bgColor: "transparent"
    property real lineWidth: width * 0.005
    
    // Request repaint when props change
    onCircuitTypeChanged: requestPaint()
    onDarkModeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    
    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        
        if (circuitType === 0) {
            drawSeriesCircuit(ctx);
        } else {
            drawParallelCircuit(ctx);
        }
    }
    
    // Draw series RLC circuit
    function drawSeriesCircuit(ctx) {
        // Set up dimensions
        var margin = width * 0.05;
        var centerY = height * 0.5;
        var componentLength = (width - 3 * margin) / 5;
        var wireY = centerY;
        
        // Components positions
        var sourceX = margin;
        var wireStartX = sourceX + margin;
        var resistorX = wireStartX;
        var inductorX = resistorX + componentLength;
        var capacitorX = inductorX + componentLength;
        var wireEndX = capacitorX + componentLength;
        
        // Draw wire
        ctx.lineWidth = lineWidth;
        ctx.strokeStyle = wireColor;
        ctx.beginPath();
        ctx.moveTo(wireStartX, wireY);
        ctx.lineTo(wireEndX, wireY);
        ctx.stroke();
        
        // Draw source
        drawSource(ctx, sourceX, wireY);
        
        // Draw resistor
        drawResistor(ctx, resistorX, wireY, componentLength);
        
        // Draw inductor
        drawInductor(ctx, inductorX, wireY, componentLength);
        
        // Draw capacitor
        drawCapacitor(ctx, capacitorX, wireY, componentLength);
        
        // Add labels
        drawComponentLabels(ctx, resistorX, inductorX, capacitorX, wireY, componentLength);
        
        // Add title
        drawTitle(ctx, "Series RLC Circuit");
    }
    
    // Draw parallel RLC circuit
    function drawParallelCircuit(ctx) {
        // Set up dimensions
        var margin = width * 0.1;
        var railLength = width - 2 * margin;
        var railSpacing = height * 0.5;
        var centerX = width * 0.5;
        
        // Draw rails
        var topRailY = height * 0.25;
        var bottomRailY = topRailY + railSpacing;
        var leftRailX = margin;
        var rightRailX = width - margin;
        
        ctx.lineWidth = lineWidth;
        ctx.strokeStyle = wireColor;
        ctx.beginPath();
        ctx.moveTo(leftRailX, topRailY);
        ctx.lineTo(rightRailX, topRailY);
        ctx.moveTo(leftRailX, bottomRailY);
        ctx.lineTo(rightRailX, bottomRailY);
        ctx.stroke();
        
        // Component positions
        var componentSpacing = railLength / 4;
        var resistorX = leftRailX + componentSpacing;
        var inductorX = resistorX + componentSpacing;
        var capacitorX = inductorX + componentSpacing;
        
        // Draw resistor
        drawParallelResistor(ctx, resistorX, topRailY, bottomRailY);
        
        // Draw inductor
        drawParallelInductor(ctx, inductorX, topRailY, bottomRailY);
        
        // Draw capacitor
        drawParallelCapacitor(ctx, capacitorX, topRailY, bottomRailY);
        
        // Draw source at the bottom
        var sourceY = bottomRailY + height * 0.15;
        drawSource(ctx, centerX, sourceY);
        
        // Connect source to bottom rail
        ctx.beginPath();
        ctx.strokeStyle = wireColor;
        ctx.moveTo(leftRailX, bottomRailY);
        ctx.lineTo(leftRailX, sourceY);
        ctx.arc(centerX, sourceY, width * 0.05, Math.PI, 0, false);
        ctx.lineTo(rightRailX, bottomRailY);
        ctx.stroke();
        
        // Add labels
        drawParallelComponentLabels(ctx, resistorX, inductorX, capacitorX, topRailY, bottomRailY);
        
        // Add title
        drawTitle(ctx, "Parallel RLC Circuit");
    }
    
    // Draw voltage source
    function drawSource(ctx, x, y) {
        var radius = width * 0.035;
        
        // Circle
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, 2 * Math.PI);
        ctx.fillStyle = bgColor;
        ctx.fill();
        ctx.strokeStyle = wireColor;
        ctx.lineWidth = lineWidth;
        ctx.stroke();
        
        // + and - symbols
        var symbolSize = radius * 0.5;
        
        // + symbol
        ctx.beginPath();
        ctx.strokeStyle = wireColor;
        ctx.lineWidth = lineWidth * 1.2;
        ctx.moveTo(x - symbolSize / 2, y - radius * 0.3);
        ctx.lineTo(x + symbolSize / 2, y - radius * 0.3);
        ctx.stroke();
        
        ctx.beginPath();
        ctx.moveTo(x, y - radius * 0.3 - symbolSize / 2);
        ctx.lineTo(x, y - radius * 0.3 + symbolSize / 2);
        ctx.stroke();
        
        // - symbol
        ctx.beginPath();
        ctx.moveTo(x - symbolSize / 2, y + radius * 0.3);
        ctx.lineTo(x + symbolSize / 2, y + radius * 0.3);
        ctx.stroke();
        
        // Add V label
        ctx.fillStyle = labelColor;
        ctx.font = `${width * 0.03}px sans-serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText("V", x, y);
    }
    
    // Draw resistor (zigzag)
    function drawResistor(ctx, x, y, length) {
        var height = width * 0.04;
        var segments = 8;
        var segmentWidth = length / segments;
        
        ctx.beginPath();
        ctx.strokeStyle = resistorColor;
        ctx.lineWidth = lineWidth * 1.2;
        ctx.lineJoin = "round";
        
        ctx.moveTo(x, y);
        
        for (var i = 0; i < segments; i++) {
            if (i % 2 === 0) {
                ctx.lineTo(x + (i + 1) * segmentWidth, y + height);
            } else {
                ctx.lineTo(x + (i + 1) * segmentWidth, y - height);
            }
        }
        
        ctx.stroke();
    }
    
    // Draw vertical resistor for parallel circuit
    function drawParallelResistor(ctx, x, topY, bottomY) {
        var width = height * 0.04;
        var segments = 8;
        var segmentHeight = (bottomY - topY) / segments;
        
        ctx.beginPath();
        ctx.strokeStyle = resistorColor;
        ctx.lineWidth = lineWidth * 1.2;
        ctx.lineJoin = "round";
        
        ctx.moveTo(x, topY);
        
        for (var i = 0; i < segments; i++) {
            if (i % 2 === 0) {
                ctx.lineTo(x + width, topY + (i + 1) * segmentHeight);
            } else {
                ctx.lineTo(x - width, topY + (i + 1) * segmentHeight);
            }
        }
        
        ctx.stroke();
    }
    
    // Draw inductor (sine wave)
    function drawInductor(ctx, x, y, length) {
        var radius = width * 0.03;
        var cycles = 4;
        
        ctx.beginPath();
        ctx.strokeStyle = inductorColor;
        ctx.lineWidth = lineWidth * 1.2;
        
        for (var i = 0; i <= 100; i++) {
            var t = i / 100;
            var xPos = x + t * length;
            var yPos = y + radius * Math.sin(t * 2 * Math.PI * cycles);
            
            if (i === 0) {
                ctx.moveTo(xPos, yPos);
            } else {
                ctx.lineTo(xPos, yPos);
            }
        }
        
        ctx.stroke();
    }
    
    // Draw vertical inductor for parallel circuit
    function drawParallelInductor(ctx, x, topY, bottomY) {
        var height = bottomY - topY;
        var coilSpacing = height / 6;
        var coilHeight = coilSpacing * 0.6;
        var coilWidth = width * 0.04;
        
        ctx.beginPath();
        ctx.strokeStyle = inductorColor;
        ctx.lineWidth = lineWidth * 1.2;
        
        // Connect to top rail
        ctx.moveTo(x, topY);
        ctx.lineTo(x, topY + coilSpacing / 2);
        ctx.stroke();
        
        // Draw coils
        for (var i = 0; i < 5; i++) {
            var centerY = topY + coilSpacing * (i + 1);
            
            ctx.beginPath();
            for (var t = 0; t <= 100; t++) {
                var angle = t / 100 * 2 * Math.PI;
                var xPos = x + coilWidth * Math.sin(angle);
                var yPos = centerY + coilHeight * (1 - Math.cos(angle)) / 3;
                
                if (t === 0) {
                    ctx.moveTo(xPos, yPos);
                } else {
                    ctx.lineTo(xPos, yPos);
                }
            }
            ctx.stroke();
            
            // Connect coils
            if (i < 4) {
                ctx.beginPath();
                ctx.strokeStyle = inductorColor;
                ctx.moveTo(x, centerY + coilHeight / 3);
                ctx.lineTo(x, centerY + coilSpacing - coilHeight / 3);
                ctx.stroke();
            }
        }
        
        // Connect to bottom rail
        ctx.beginPath();
        ctx.strokeStyle = inductorColor;
        ctx.moveTo(x, topY + coilSpacing * 5 + coilHeight / 3);
        ctx.lineTo(x, bottomY);
        ctx.stroke();
    }
    
    // Draw capacitor (two plates)
    function drawCapacitor(ctx, x, y, length) {
        var plateWidth = length * 0.1;
        var plateGap = width * 0.02;
        var plateHeight = width * 0.05;
        var centerX = x + length / 2;
        
        ctx.lineWidth = lineWidth * 2;
        ctx.strokeStyle = capacitorColor;
        
        // Top plate
        ctx.beginPath();
        ctx.moveTo(centerX - plateWidth / 2, y - plateHeight);
        ctx.lineTo(centerX + plateWidth / 2, y - plateHeight);
        ctx.stroke();
        
        // Bottom plate
        ctx.beginPath();
        ctx.moveTo(centerX - plateWidth / 2, y + plateHeight);
        ctx.lineTo(centerX + plateWidth / 2, y + plateHeight);
        ctx.stroke();
        
        // Connectors
        ctx.lineWidth = lineWidth;
        ctx.strokeStyle = wireColor;
        
        ctx.beginPath();
        ctx.moveTo(centerX, y);
        ctx.lineTo(centerX, y - plateHeight);
        ctx.stroke();
        
        ctx.beginPath();
        ctx.moveTo(centerX, y);
        ctx.lineTo(centerX, y + plateHeight);
        ctx.stroke();
    }
    
    // Draw vertical capacitor for parallel circuit
    function drawParallelCapacitor(ctx, x, topY, bottomY) {
        var centerY = (topY + bottomY) / 2;
        var plateWidth = width * 0.06;
        var plateGap = height * 0.04;
        
        // Connect to top rail
        ctx.beginPath();
        ctx.strokeStyle = wireColor;
        ctx.lineWidth = lineWidth;
        ctx.moveTo(x, topY);
        ctx.lineTo(x, centerY - plateGap / 2);
        ctx.stroke();
        
        // Top plate
        ctx.beginPath();
        ctx.strokeStyle = capacitorColor;
        ctx.lineWidth = lineWidth * 2;
        ctx.moveTo(x - plateWidth, centerY - plateGap / 2);
        ctx.lineTo(x + plateWidth, centerY - plateGap / 2);
        ctx.stroke();
        
        // Bottom plate
        ctx.beginPath();
        ctx.moveTo(x - plateWidth, centerY + plateGap / 2);
        ctx.lineTo(x + plateWidth, centerY + plateGap / 2);
        ctx.stroke();
        
        // Connect to bottom rail
        ctx.beginPath();
        ctx.strokeStyle = wireColor;
        ctx.lineWidth = lineWidth;
        ctx.moveTo(x, centerY + plateGap / 2);
        ctx.lineTo(x, bottomY);
        ctx.stroke();
    }
    
    // Draw component labels for series circuit
    function drawComponentLabels(ctx, resistorX, inductorX, capacitorX, wireY, componentLength) {
        var labelY = wireY - height * 0.2;
        
        ctx.fillStyle = labelColor;
        ctx.font = `${width * 0.04}px sans-serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        
        ctx.fillText("R", resistorX + componentLength / 2, labelY);
        ctx.fillText("L", inductorX + componentLength / 2, labelY);
        ctx.fillText("C", capacitorX + componentLength / 2, labelY);
    }
    
    // Draw component labels for parallel circuit
    function drawParallelComponentLabels(ctx, resistorX, inductorX, capacitorX, topY, bottomY) {
        var centerY = (topY + bottomY) / 2;
        
        ctx.fillStyle = labelColor;
        ctx.font = `${width * 0.04}px sans-serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        
        ctx.fillText("R", resistorX - width * 0.06, centerY);
        ctx.fillText("L", inductorX - width * 0.06, centerY);
        ctx.fillText("C", capacitorX + width * 0.06, centerY);
    }
    
    // Draw circuit title
    function drawTitle(ctx, title) {
        ctx.fillStyle = labelColor;
        ctx.font = `bold ${width * 0.05}px sans-serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "top";
        ctx.fillText(title, width / 2, height * 0.02);
    }
}
