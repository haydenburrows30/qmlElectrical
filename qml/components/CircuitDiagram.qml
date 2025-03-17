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
    
    // Add properties for highlighting components
    property bool highlightR: false
    property bool highlightL: false
    property bool highlightC: false
    
    // Add properties for current animation
    property bool animateCurrent: false
    property real frequency: 50.0 // Hz for animation speed
    property real currentPhase: 0.0 // Phase delay in radians
    property color currentColor: "#50FF00"
    
    // Get active highlight colors
    property color activeResistorColor: highlightR ? (darkMode ? "#FFFFFF" : "#000000") : resistorColor
    property color activeInductorColor: highlightL ? (darkMode ? "#FFFFFF" : "#000000") : inductorColor
    property color activeCapacitorColor: highlightC ? (darkMode ? "#FFFFFF" : "#000000") : capacitorColor
    
    // Anti-aliasing for smoother lines
    property bool antialiasing: true
    
    // Request repaint when props change
    onCircuitTypeChanged: requestPaint()
    onDarkModeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onHighlightRChanged: requestPaint()
    onHighlightLChanged: requestPaint()
    onHighlightCChanged: requestPaint()
    
    // Timer for current animation
    Timer {
        id: animationTimer
        interval: 16 // ~60 FPS
        running: animateCurrent
        repeat: true
        onTriggered: {
            currentPhase = (currentPhase + 0.1 * frequency/50) % (2 * Math.PI)
            circuitCanvas.requestPaint()
        }
    }
    
    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        
        if (antialiasing) {
            ctx.globalAlpha = 0.99; // Workaround to enable anti-aliasing
        }
        
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
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();
        ctx.moveTo(wireStartX, wireY);
        ctx.lineTo(wireEndX, wireY);
        ctx.stroke();
        
        // Draw source
        drawSource(ctx, sourceX, wireY);
        
        // Draw resistor with potential highlight
        drawResistor(ctx, resistorX, wireY, componentLength, activeResistorColor);
        
        // Draw inductor with potential highlight
        drawInductor(ctx, inductorX, wireY, componentLength, activeInductorColor);
        
        // Draw capacitor with potential highlight
        drawCapacitor(ctx, capacitorX, wireY, componentLength, activeCapacitorColor);
        
        // Add labels
        drawComponentLabels(ctx, resistorX, inductorX, capacitorX, wireY, componentLength);
        
        // Draw current flow animation if enabled
        if (animateCurrent) {
            drawSeriesCurrentFlow(ctx, wireStartX, wireY, wireEndX, sourceX, resistorX, inductorX, capacitorX, componentLength);
        }
        
        // Draw formula
        if (highlightR || highlightL || highlightC) {
            drawSeriesFormula(ctx);
        }
        
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
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
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
        
        // Draw resistor with potential highlight
        drawParallelResistor(ctx, resistorX, topRailY, bottomRailY, activeResistorColor);
        
        // Draw inductor with potential highlight
        drawParallelInductor(ctx, inductorX, topRailY, bottomRailY, activeInductorColor);
        
        // Draw capacitor with potential highlight
        drawParallelCapacitor(ctx, capacitorX, topRailY, bottomRailY, activeCapacitorColor);
        
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
        
        // Draw current flow animation if enabled
        if (animateCurrent) {
            drawParallelCurrentFlow(ctx, topRailY, bottomRailY, leftRailX, rightRailX, 
                                   resistorX, inductorX, capacitorX, sourceY, centerX);
        }
        
        // Draw formula
        if (highlightR || highlightL || highlightC) {
            drawParallelFormula(ctx);
        }
        
        // Add title
        drawTitle(ctx, "Parallel RLC Circuit");
    }
    
    // Draw current flow animation for series circuit
    function drawSeriesCurrentFlow(ctx, wireStartX, wireY, wireEndX, sourceX, resistorX, inductorX, capacitorX, componentLength) {
        // Number of particles and base amplitude for visual effect
        var numParticles = 10;
        var particleRadius = width * 0.006;
        
        // Phase shifts based on component behaviors
        var phaseShiftR = 0; // Current in phase with voltage for resistor
        var phaseShiftL = Math.PI/2; // Current lags voltage by 90° for inductor
        var phaseShiftC = -Math.PI/2; // Current leads voltage by 90° for capacitor
        
        // Draw current particles
        ctx.lineWidth = lineWidth * 0.5;
        
        for (var i = 0; i < numParticles; i++) {
            var t = (i / numParticles + currentPhase/(2*Math.PI)) % 1.0;
            var x = wireStartX + t * (wireEndX - wireStartX);
            
            // Calculate component-specific phases
            var currentInR = Math.cos(currentPhase + phaseShiftR);
            var currentInL = Math.cos(currentPhase + phaseShiftL);
            var currentInC = Math.cos(currentPhase + phaseShiftC);
            
            // Change color based on component
            var color = currentColor;
            var particleY = wireY;
            
            // Apply phase-specific position offset
            if (x >= resistorX && x < inductorX) {
                // In resistor segment
                color = Qt.rgba(1, 0.5, 0.5, 0.7 * Math.abs(currentInR));
            } else if (x >= inductorX && x < capacitorX) {
                // In inductor segment
                color = Qt.rgba(0.5, 0.7, 1, 0.7 * Math.abs(currentInL));
            } else if (x >= capacitorX) {
                // In capacitor segment
                color = Qt.rgba(1, 0.8, 0.2, 0.7 * Math.abs(currentInC));
            } else {
                // In wire segment
                color = Qt.rgba(0.3, 1, 0.5, 0.7);
            }
            
            // Draw particle
            ctx.beginPath();
            ctx.fillStyle = color;
            ctx.arc(x, particleY, particleRadius, 0, 2 * Math.PI);
            ctx.fill();
            
            // Draw glow effect
            var gradient = ctx.createRadialGradient(x, particleY, 0, x, particleY, particleRadius * 3);
            gradient.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.5));
            gradient.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0));
            
            ctx.beginPath();
            ctx.fillStyle = gradient;
            ctx.arc(x, particleY, particleRadius * 3, 0, 2 * Math.PI);
            ctx.fill();
        }
    }
    
    // Draw current flow animation for parallel circuit
    function drawParallelCurrentFlow(ctx, topRailY, bottomRailY, leftRailX, rightRailX, 
                                    resistorX, inductorX, capacitorX, sourceY, centerX) {
        var numParticles = 15;
        var particleRadius = width * 0.006;
        
        var sourcePhase = currentPhase;
        var phaseShiftR = 0; 
        var phaseShiftL = Math.PI/2;
        var phaseShiftC = -Math.PI/2;
        
        // Calculate component-specific current values
        var currentInR = Math.cos(sourcePhase + phaseShiftR);
        var currentInL = Math.cos(sourcePhase + phaseShiftL);
        var currentInC = Math.cos(sourcePhase + phaseShiftC);
        
        // Draw source current
        for (var i = 0; i < 4; i++) {
            var t = (i / 4 + sourcePhase/(2*Math.PI)) % 1.0;
            // Arc path from left to right through source
            var angle = Math.PI * t;
            var x = centerX + width * 0.05 * Math.cos(Math.PI + angle);
            var y = sourceY + width * 0.05 * Math.sin(Math.PI + angle);
            
            var color = Qt.rgba(0.3, 1, 0.5, 0.7);
            
            // Draw particle
            ctx.beginPath();
            ctx.fillStyle = color;
            ctx.arc(x, y, particleRadius, 0, 2 * Math.PI);
            ctx.fill();
            
            // Draw glow effect
            var gradient = ctx.createRadialGradient(x, y, 0, x, y, particleRadius * 3);
            gradient.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.5));
            gradient.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0));
            
            ctx.beginPath();
            ctx.fillStyle = gradient;
            ctx.arc(x, y, particleRadius * 3, 0, 2 * Math.PI);
            ctx.fill();
        }
        
        // Draw rail currents
        for (i = 0; i < 5; i++) {
            t = (i / 5 + sourcePhase/(2*Math.PI)) % 1.0;
            // Top rail
            var xTop = leftRailX + t * (rightRailX - leftRailX);
            // Bottom rail
            var xBottom = rightRailX - t * (rightRailX - leftRailX);
            
            // Draw particles on rails
            color = Qt.rgba(0.3, 1, 0.5, 0.7);
            
            // Top rail particle
            ctx.beginPath();
            ctx.fillStyle = color;
            ctx.arc(xTop, topRailY, particleRadius, 0, 2 * Math.PI);
            ctx.fill();
            
            // Bottom rail particle
            ctx.beginPath();
            ctx.fillStyle = color;
            ctx.arc(xBottom, bottomRailY, particleRadius, 0, 2 * Math.PI);
            ctx.fill();
        }
        
        // Draw resistor branch current
        for (i = 0; i < 3; i++) {
            t = (i / 3 + (sourcePhase + phaseShiftR)/(2*Math.PI)) % 1.0;
            y = topRailY + t * (bottomRailY - topRailY);
            
            // Skip if current is very low (for visual effect)
            if (Math.abs(currentInR) < 0.1) continue;
            
            color = Qt.rgba(1, 0.5, 0.5, 0.7 * Math.abs(currentInR));
            
            // Draw particle
            ctx.beginPath();
            ctx.fillStyle = color;
            ctx.arc(resistorX, y, particleRadius, 0, 2 * Math.PI);
            ctx.fill();
        }
        
        // Draw inductor branch current
        for (i = 0; i < 3; i++) {
            t = (i / 3 + (sourcePhase + phaseShiftL)/(2*Math.PI)) % 1.0;
            y = topRailY + t * (bottomRailY - topRailY);
            
            // Skip if current is very low
            if (Math.abs(currentInL) < 0.1) continue;
            
            color = Qt.rgba(0.5, 0.7, 1, 0.7 * Math.abs(currentInL));
            
            // Draw particle
            ctx.beginPath();
            ctx.fillStyle = color;
            ctx.arc(inductorX, y, particleRadius, 0, 2 * Math.PI);
            ctx.fill();
        }
        
        // Draw capacitor branch current
        for (i = 0; i < 3; i++) {
            t = (i / 3 + (sourcePhase + phaseShiftC)/(2*Math.PI)) % 1.0;
            y = topRailY + t * (bottomRailY - topRailY);
            
            // Skip if current is very low
            if (Math.abs(currentInC) < 0.1) continue;
            
            color = Qt.rgba(1, 0.8, 0.2, 0.7 * Math.abs(currentInC));
            
            // Draw particle
            ctx.beginPath();
            ctx.fillStyle = color;
            ctx.arc(capacitorX, y, particleRadius, 0, 2 * Math.PI);
            ctx.fill();
        }
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
    
    // Draw resistor (zigzag) with optional highlight
    function drawResistor(ctx, x, y, length, color) {
        var height = width * 0.04;
        var segments = 8;
        var segmentWidth = length / segments;
        
        // Draw highlight background for resistor
        if (highlightR) {
            ctx.beginPath();
            ctx.fillStyle = darkMode ? "rgba(255,255,255,0.2)" : "rgba(0,0,0,0.1)";
            ctx.rect(x, y - height - width * 0.01, length, 2 * height + width * 0.02);
            ctx.fill();
        }
        
        ctx.beginPath();
        ctx.strokeStyle = color;
        ctx.lineWidth = lineWidth * 1.2;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        
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
    function drawParallelResistor(ctx, x, topY, bottomY, color) {
        var width = height * 0.04;
        var segments = 8;
        var segmentHeight = (bottomY - topY) / segments;
        
        // Draw highlight background for resistor
        if (highlightR) {
            ctx.beginPath();
            ctx.fillStyle = darkMode ? "rgba(255,255,255,0.2)" : "rgba(0,0,0,0.1)";
            ctx.rect(x - width - height * 0.01, topY, 2 * width + height * 0.02, bottomY - topY);
            ctx.fill();
        }
        
        ctx.beginPath();
        ctx.strokeStyle = color;
        ctx.lineWidth = lineWidth * 1.2;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        
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
    
    // Draw inductor (sine wave) with optional highlight
    function drawInductor(ctx, x, y, length, color) {
        var radius = width * 0.03;
        var cycles = 4;
        
        // Draw highlight background for inductor
        if (highlightL) {
            ctx.beginPath();
            ctx.fillStyle = darkMode ? "rgba(255,255,255,0.2)" : "rgba(0,0,0,0.1)";
            ctx.rect(x, y - radius - width * 0.01, length, 2 * radius + width * 0.02);
            ctx.fill();
        }
        
        ctx.beginPath();
        ctx.strokeStyle = color;
        ctx.lineWidth = lineWidth * 1.2;
        ctx.lineCap = "round";
        
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
    
    // Draw vertical inductor for parallel circuit with optional highlight
    function drawParallelInductor(ctx, x, topY, bottomY, color) {
        var height = bottomY - topY;
        var coilSpacing = height / 6;
        var coilHeight = coilSpacing * 0.6;
        var coilWidth = width * 0.04;
        
        // Draw highlight background for inductor
        if (highlightL) {
            ctx.beginPath();
            ctx.fillStyle = darkMode ? "rgba(255,255,255,0.2)" : "rgba(0,0,0,0.1)";
            ctx.rect(x - coilWidth - height * 0.01, topY, 2 * coilWidth + height * 0.02, bottomY - topY);
            ctx.fill();
        }
        
        ctx.beginPath();
        ctx.strokeStyle = color;
        ctx.lineWidth = lineWidth * 1.2;
        ctx.lineCap = "round";
        
        // Connect to top rail
        ctx.moveTo(x, topY);
        ctx.lineTo(x, topY + coilSpacing / 2);
        ctx.stroke();
        
        // Draw coils
        for (var i = 0; i < 5; i++) {
            var centerY = topY + coilSpacing * (i + 1);
            
            ctx.beginPath();
            ctx.strokeStyle = color;
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
                ctx.strokeStyle = color;
                ctx.moveTo(x, centerY + coilHeight / 3);
                ctx.lineTo(x, centerY + coilSpacing - coilHeight / 3);
                ctx.stroke();
            }
        }
        
        // Connect to bottom rail
        ctx.beginPath();
        ctx.strokeStyle = color;
        ctx.moveTo(x, topY + coilSpacing * 5 + coilHeight / 3);
        ctx.lineTo(x, bottomY);
        ctx.stroke();
    }
    
    // Draw capacitor (two plates) with optional highlight
    function drawCapacitor(ctx, x, y, length, color) {
        var plateWidth = length * 0.1;
        var plateGap = width * 0.02;
        var plateHeight = width * 0.05;
        var centerX = x + length / 2;
        
        // Draw highlight background for capacitor
        if (highlightC) {
            ctx.beginPath();
            ctx.fillStyle = darkMode ? "rgba(255,255,255,0.2)" : "rgba(0,0,0,0.1)";
            ctx.rect(centerX - plateWidth/2 - width * 0.01, y - plateHeight - width * 0.01, 
                   plateWidth + width * 0.02, 2 * plateHeight + width * 0.02);
            ctx.fill();
        }
        
        ctx.lineWidth = lineWidth * 2;
        ctx.strokeStyle = color;
        ctx.lineCap = "round";
        
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
    
    // Draw vertical capacitor for parallel circuit with optional highlight
    function drawParallelCapacitor(ctx, x, topY, bottomY, color) {
        var centerY = (topY + bottomY) / 2;
        var plateWidth = width * 0.06;
        var plateGap = height * 0.04;
        
        // Draw highlight background for capacitor
        if (highlightC) {
            ctx.beginPath();
            ctx.fillStyle = darkMode ? "rgba(255,255,255,0.2)" : "rgba(0,0,0,0.1)";
            ctx.rect(x - plateWidth - height * 0.01, centerY - plateGap/2 - height * 0.01, 
                   2 * plateWidth + height * 0.02, plateGap + height * 0.02);
            ctx.fill();
        }
        
        // Connect to top rail
        ctx.beginPath();
        ctx.strokeStyle = wireColor;
        ctx.lineWidth = lineWidth;
        ctx.moveTo(x, topY);
        ctx.lineTo(x, centerY - plateGap / 2);
        ctx.stroke();
        
        // Top plate
        ctx.beginPath();
        ctx.strokeStyle = color;
        ctx.lineWidth = lineWidth * 2;
        ctx.lineCap = "round";
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
    
    // Draw series formula
    function drawSeriesFormula(ctx) {
        var formulaY = height * 0.85;
        var formulaColor = darkMode ? "#CCE0FF" : "#003366";
        
        ctx.fillStyle = formulaColor;
        ctx.font = `italic ${width * 0.04}px serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        
        if (highlightR && highlightL && highlightC) {
            ctx.fillText("f₀ = 1/(2π√LC)     Q = (1/R)√(L/C)", width / 2, formulaY);
        } else if (highlightR) {
            ctx.fillText("Z = R + jωL + 1/(jωC)", width / 2, formulaY);
        } else if (highlightL) {
            ctx.fillText("XL = ωL", width / 2, formulaY);
        } else if (highlightC) {
            ctx.fillText("XC = 1/(ωC)", width / 2, formulaY);
        }
    }
    
    // Draw parallel formula
    function drawParallelFormula(ctx) {
        var formulaY = height * 0.85;
        var formulaColor = darkMode ? "#CCE0FF" : "#003366";
        
        ctx.fillStyle = formulaColor;
        ctx.font = `italic ${width * 0.04}px serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        
        if (highlightR && highlightL && highlightC) {
            ctx.fillText("f₀ = 1/(2π√LC)     Q = R√(C/L)", width / 2, formulaY);
        } else if (highlightR) {
            ctx.fillText("1/Z = 1/R + 1/(jωL) + jωC", width / 2, formulaY);
        } else if (highlightL) {
            ctx.fillText("XL = ωL", width / 2, formulaY);
        } else if (highlightC) {
            ctx.fillText("XC = 1/(ωC)", width / 2, formulaY);
        }
    }
}
