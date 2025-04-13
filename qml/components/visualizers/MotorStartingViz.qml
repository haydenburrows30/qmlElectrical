import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../style"

WaveCard {
    Layout.fillHeight: true
    Layout.fillWidth: true
    title: "Starting Current Profile"
    
    Canvas {
        id: motorStartCanvas
        anchors.fill: parent
        anchors.margins: 20
        
        // Use the cached property directly instead of calling function
        property real startingMultiplier: cachedStartingMultiplier
        property string motorTypeDisplay: motorType.currentText || "Induction Motor"
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            // Define dimensions first before using them
            var canvasWidth = motorStartCanvas.width;
            var canvasHeight = motorStartCanvas.height;
            
            // Add background fill to match theme
            ctx.fillStyle = Universal.background;
            ctx.fillRect(0, 0, canvasWidth, canvasHeight);
            
            // Draw grid
            drawGrid(ctx, canvasWidth, canvasHeight);
            
            // Draw axes
            drawAxes(ctx, canvasWidth, canvasHeight);
            
            // Draw starting current profile
            drawCurrentProfile(ctx, canvasWidth, canvasHeight);
            
            // Annotate the starting multiplier
            drawAnnotations(ctx, canvasWidth, canvasHeight);
        }
        
        function drawCurrentProfile(ctx, width, height) {
            // Get base position (full load current line)
            var baseY = height * 0.8;  // 80% from top
            var startX = width * 0.1;  // 10% from left for margin
            
            ctx.beginPath();
            ctx.moveTo(startX, height * 0.1);  // Start at 10% from top
            
            // Modify profile based on motor type
            var currentMultiplierFactor = 1.0;
            var torqueMultiplierFactor = 1.0;
            var curveShape = 1.0;
            
            // Different motor types have different starting characteristics
            switch(motorTypeDisplay) {
                case "Synchronous Motor":
                    currentMultiplierFactor = 0.9;  // Slightly lower peak current
                    curveShape = 1.2;  // Different curve shape
                    break;
                case "Wound Rotor Motor":
                    currentMultiplierFactor = 0.8;  // Lower peak current
                    curveShape = 0.9;  // Smoother curve
                    break;
                case "Permanent Magnet Motor":
                    currentMultiplierFactor = 1.3;  // Higher peak current
                    curveShape = 1.5;  // Sharper curve
                    break;
                case "Single Phase Motor":
                    currentMultiplierFactor = 1.2;  // Higher peak current
                    curveShape = 1.3;  // Different curve shape
                    break;
                default: // Induction Motor or any other
                    currentMultiplierFactor = 1.0;
                    curveShape = 1.0;
            }
            
            // Draw different profiles based on starting method
            switch(startingMethod.currentText) {
                case "DOL":
                    // Modified direct square wave based on motor type
                    ctx.lineTo(startX, height * 0.1);
                    var peak = baseY - (baseY * 0.8 * (startingMultiplier * currentMultiplierFactor - 1)/(startingMultiplier * currentMultiplierFactor));
                    ctx.lineTo(startX, peak);
                    
                    if (motorTypeDisplay === "Synchronous Motor") {
                        // Synchronous motors can have oscillations when starting
                        var oscPoint1 = width * 0.3;
                        var oscPoint2 = width * 0.5;
                        var oscHeight = baseY * 0.1;
                        
                        ctx.lineTo(oscPoint1, peak + oscHeight);
                        ctx.lineTo(oscPoint2, peak - oscHeight);
                    }
                    
                    ctx.lineTo(width * 0.9, baseY);
                    break;
                    
                case "Star-Delta":
                    // Two-step start with transition period based on motor type
                    ctx.lineTo(startX, height * 0.1);
                    var firstLevel = baseY - (baseY * 0.8 * 2/3 * currentMultiplierFactor);
                    ctx.lineTo(startX, firstLevel);
                    ctx.lineTo(width * 0.4, firstLevel);
                    
                    // Transition spike - height varies by motor type
                    var spikeHeight = baseY * 0.8 * 0.9 * currentMultiplierFactor;
                    ctx.lineTo(width * 0.4, baseY - spikeHeight);
                    ctx.lineTo(width * 0.45, baseY - spikeHeight);
                    
                    // Second level
                    var secondLevel = baseY - (baseY * 0.8 * 1/3 * currentMultiplierFactor);
                    ctx.lineTo(width * 0.45, secondLevel);
                    
                    // Add motor-specific curve to end
                    if (motorTypeDisplay === "Wound Rotor Motor") {
                        // Smoother decay
                        ctx.bezierCurveTo(
                            width * 0.6, secondLevel,
                            width * 0.75, baseY - (baseY * 0.1),
                            width * 0.9, baseY
                        );
                    } else {
                        ctx.lineTo(width * 0.9, baseY);
                    }
                    break;
                    
                case "Soft Starter":
                    // Gradual ramp with initial spike - modified by motor type
                    ctx.lineTo(startX, height * 0.1);
                    var softStartLevel = baseY - (baseY * 0.8 * 0.5 * currentMultiplierFactor);
                    ctx.lineTo(startX, softStartLevel);
                    
                    // Draw curve with motor type affecting shape
                    var cp1x = width * 0.4;
                    var cp1y = softStartLevel;
                    var cp2x = width * 0.6;
                    var cp2y = baseY - (baseY * 0.8 * 0.2 * currentMultiplierFactor / curveShape);
                    var endX = width * 0.9;
                    var endY = baseY;
                    
                    ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, endX, endY);
                    break;
                    
                case "VFD":
                    // Controlled ramp - smooth curve affected by motor type
                    ctx.lineTo(startX, height * 0.1);
                    var vfdStartLevel = baseY - (baseY * 0.8 * 0.2 * currentMultiplierFactor);
                    ctx.lineTo(startX, vfdStartLevel);
                    
                    // Controlled, motor-specific curve
                    if (motorTypeDisplay === "Permanent Magnet Motor") {
                        // Faster acceleration
                        ctx.quadraticCurveTo(
                            width * 0.4, baseY - (baseY * 0.1 * currentMultiplierFactor),
                            width * 0.9, baseY
                        );
                    } else {
                        // Standard curve
                        ctx.quadraticCurveTo(
                            width * 0.5, baseY - (baseY * 0.1 * currentMultiplierFactor / curveShape),
                            width * 0.9, baseY
                        );
                    }
                    break;
            }
            
            // Set color based on motor type
            var colorMap = {
                "Induction Motor": Universal.accent,
                "Synchronous Motor": "#1E90FF", // Dodger Blue
                "Wound Rotor Motor": "#32CD32", // Lime Green
                "Permanent Magnet Motor": "#FF6347", // Tomato
                "Single Phase Motor": "#9370DB"  // Medium Purple
            };
            
            ctx.strokeStyle = colorMap[motorTypeDisplay] || Universal.accent;
            ctx.lineWidth = 3;
            ctx.stroke();
        }
        
        function drawAnnotations(ctx, width, height) {
            var baseY = height * 0.8;
            var startX = width * 0.1;
            
            // Annotate the starting multiplier
            ctx.font = "bold 14px sans-serif";
            ctx.fillStyle = Universal.accent;
            ctx.fillText(startingMultiplier.toFixed(1) + "× FLC", startX + 10, baseY - (baseY * 0.8 * 0.7));
            
            // Annotate method
            ctx.fillText(startingMethod.currentText, width * 0.7, height * 0.15);
            
            // Annotate motor type
            ctx.fillStyle = Universal.foreground;
            ctx.font = "italic 12px sans-serif";
            ctx.fillText("Motor Type: " + motorTypeDisplay, width * 0.1, height * 0.95);
        }
        
        function drawGrid(ctx, width, height) {
            ctx.beginPath();
            ctx.strokeStyle = Qt.rgba(0.7, 0.7, 0.7, 0.3);
            ctx.lineWidth = 1;
            
            // Horizontal grid lines
            for (var i = 1; i < 10; i++) {
                var y = height * i / 10;
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
            }
            
            // Vertical grid lines
            for (var j = 1; j < 10; j++) {
                var x = width * j / 10;
                ctx.moveTo(x, 0);
                ctx.lineTo(x, height);
            }
            
            ctx.stroke();
        }
        
        function drawAxes(ctx, width, height) {
            ctx.beginPath();
            ctx.strokeStyle = Universal.foreground;
            ctx.lineWidth = 2;
            
            // X axis (time)
            ctx.moveTo(width * 0.1, height * 0.8);
            ctx.lineTo(width * 0.9, height * 0.8);
            
            // Y axis (current)
            ctx.moveTo(width * 0.1, height * 0.1);
            ctx.lineTo(width * 0.1, height * 0.8);
            
            ctx.stroke();
            
            // Add labels
            ctx.font = "12px sans-serif";
            ctx.fillStyle = Universal.foreground;
            
            // X-axis label
            ctx.fillText("Time →", width - 50, height * 0.8 + 15);
            
            // Y-axis label
            ctx.save();
            ctx.translate(width * 0.05, height/2);
            ctx.rotate(-Math.PI/2);
            ctx.fillText("Current →", 0, 0);
            ctx.restore();
            
            // Add markers for Full Load Current
            ctx.font = "10px sans-serif";
            ctx.fillText("FLC", width * 0.05, height * 0.8 + 5);
        }
    }
    
    Connections {
        target: calculator
        function onResultsCalculated() {
            motorStartCanvas.requestPaint()
        }
        function onStartingMethodChanged() {
            motorStartCanvas.requestPaint()
        }
        function onMotorTypeChanged() {
            motorStartCanvas.requestPaint()
        }
    }
}