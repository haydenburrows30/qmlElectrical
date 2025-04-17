import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../style"

WaveCard {
    Layout.fillHeight: true
    Layout.fillWidth: true
    title: "Starting Current Profile"

    property bool darkMode: false
    property bool showTorqueCurve: false
    property string activeTab: "current" // "current" or "torque"

    onDarkModeChanged: motorStartCanvas.requestPaint()
    onShowTorqueCurveChanged: motorStartCanvas.requestPaint()
    onActiveTabChanged: motorStartCanvas.requestPaint()
    
    // Add tab bar at the top for switching between current and torque views
    TabBar {
        id: vizTabs
        width: parent.width
        TabButton {
            text: "Current Profile"
            onClicked: {
                activeTab = "current"
                showTorqueCurve = false // Reset combined view flag
            }
        }
        TabButton {
            text: "Torque Curve"
            onClicked: {
                activeTab = "torque"
                showTorqueCurve = false // Reset combined view flag
            }
        }
        TabButton {
            text: "Combined View"
            onClicked: {
                activeTab = "current"
                showTorqueCurve = true
            }
        }
    }
    
    Canvas {
        id: motorStartCanvas
        anchors.fill: parent
        anchors.margins: 20
        anchors.topMargin: vizTabs.height + 10
        
        // Use the cached property directly instead of calling function
        property real startingMultiplier: cachedStartingMultiplier
        property real startingTorque: cachedStartingTorque || 1.0
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
            
            // Draw profiles based on active tab
            if (activeTab === "current" || showTorqueCurve) {
                drawCurrentProfile(ctx, canvasWidth, canvasHeight);
            }
            
            if (activeTab === "torque" || showTorqueCurve) {
                drawTorqueCurve(ctx, canvasWidth, canvasHeight);
            }
            
            // Draw annotations
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
        
        // Add function to draw torque curve
        function drawTorqueCurve(ctx, width, height) {
            // Get base position
            var baseY = height * 0.8;  // 80% from top
            var startX = width * 0.1;  // 10% from left for margin
            
            ctx.beginPath();
            
            // Different motor types have different torque characteristics
            var torqueShape = 1.0;
            var peakTorque = startingTorque;
            var peakPosition = 0.7; // Default position of peak torque (as percentage of speed)
            
            switch(motorTypeDisplay) {
                case "Synchronous Motor":
                    torqueShape = 1.1;
                    peakTorque = startingTorque * 0.9;
                    peakPosition = 0.8;
                    break;
                case "Wound Rotor Motor":
                    torqueShape = 0.8;
                    peakTorque = startingTorque * 1.2;
                    peakPosition = 0.6;
                    break;
                case "Permanent Magnet Motor":
                    torqueShape = 1.2;
                    peakTorque = startingTorque * 1.5;
                    peakPosition = 0.5;
                    break;
                case "Single Phase Motor":
                    torqueShape = 0.9;
                    peakTorque = startingTorque * 0.8;
                    peakPosition = 0.75;
                    break;
            }
            
            // Calculate torque curve points
            ctx.moveTo(startX, baseY - (baseY * 0.6 * startingTorque));
            
            // Draw appropriate torque curve based on starting method and motor type
            if (startingMethod.currentText === "VFD") {
                // VFD has more linear torque
                ctx.lineTo(width * 0.9, baseY - (baseY * 0.6));
            } else {
                // Draw torque curve with peak at peakPosition
                var points = [];
                var numPoints = 50;
                
                for (var i = 0; i < numPoints; i++) {
                    var x = startX + (width * 0.8) * (i / (numPoints - 1));
                    var normalizedPos = i / (numPoints - 1);
                    
                    var torqueVal;
                    if (normalizedPos < peakPosition) {
                        // Rising part of curve
                        torqueVal = startingTorque + (peakTorque - startingTorque) * 
                                    Math.pow(normalizedPos / peakPosition, torqueShape);
                    } else {
                        // Falling part of curve to nominal torque
                        torqueVal = peakTorque - (peakTorque - 1.0) * 
                                    Math.pow((normalizedPos - peakPosition) / (1.0 - peakPosition), 1/torqueShape);
                    }
                    
                    var y = baseY - (baseY * 0.6 * torqueVal);
                    points.push({x: x, y: y});
                    
                    if (i === 0) {
                        ctx.moveTo(x, y);
                    } else {
                        ctx.lineTo(x, y);
                    }
                }
            }
            
            // Set different color for torque curve to distinguish from current
            ctx.strokeStyle = "#FF6347"; // Tomato red
            ctx.lineWidth = 3;
            ctx.stroke();
            
            // Label the curve
            ctx.font = "bold 12px sans-serif";
            ctx.fillStyle = "#FF6347";
            ctx.fillText("Torque", width * 0.15, baseY - (baseY * 0.6 * startingTorque) - 10);
        }
        
        function drawAnnotations(ctx, width, height) {
            var baseY = height * 0.8;
            var startX = width * 0.1;
            
            // Annotate based on active tab
            ctx.font = "bold 14px sans-serif";
            
            if (activeTab === "current" || showTorqueCurve) {
                ctx.fillStyle = Universal.accent;
                ctx.fillText(startingMultiplier.toFixed(1) + "× FLC", startX + 10, baseY - (baseY * 0.8 * 0.7));
            }
            
            if (activeTab === "torque" || showTorqueCurve) {
                ctx.fillStyle = "#FF6347"; // Tomato red
                ctx.fillText(startingTorque.toFixed(2) + "× FLT", startX + 10, baseY - (baseY * 0.6 * startingTorque) - 25);
            }
            
            // Annotate method
            ctx.fillStyle = Universal.accent;
            ctx.fillText(startingMethod.currentText, width * 0.7, height * 0.15);
            
            // Annotate motor type
            ctx.fillStyle = Universal.foreground;
            ctx.font = "italic 12px sans-serif";
            ctx.fillText("Motor Type: " + motorTypeDisplay, width * 0.1, height * 0.95);
            
            // Add speed markers on x-axis
            if (activeTab === "torque" || showTorqueCurve) {
                ctx.fillStyle = Universal.foreground;
                ctx.font = "10px sans-serif";
                
                // Add speed percentage markers
                for (var i = 0; i <= 10; i += 2) {
                    var x = startX + (width * 0.8) * (i / 10);
                    ctx.fillText(i * 10 + "%", x - 10, baseY + 15);
                }
            }
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
    
    // Add legend for combined view
    Rectangle {
        visible: showTorqueCurve
        width: 120
        height: 60
        color: Universal.background
        border.color: Universal.foreground
        border.width: 1
        radius: 5
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 30
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 5
            
            RowLayout {
                Rectangle {
                    width: 15
                    height: 3
                    color: Universal.accent
                }
                Text {
                    text: "Current"
                    color: Universal.foreground
                }
            }
            
            RowLayout {
                Rectangle {
                    width: 15
                    height: 3
                    color: "#FF6347"
                }
                Text {
                    text: "Torque"
                    color: Universal.foreground
                }
            }
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