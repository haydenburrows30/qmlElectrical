import QtQuick
import QtQuick.Controls

Item {
    id: root
    property var model
    property real centerX: width / 2
    property real centerY: height / 2
    property real radius: Math.min(width, height) * 0.4
    property string activePhasor: "none"  // Track which phasor is being dragged

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            // Draw grid
            drawGrid(ctx);
            
            // Draw phasors
            drawPhasor(ctx, model.phaseAngleA, model.rmsA / 230, "#f44336"); // Phase A
            drawPhasor(ctx, model.phaseAngleB, model.rmsB / 230, "#4caf50"); // Phase B
            drawPhasor(ctx, model.phaseAngleC, model.rmsC / 230, "#2196f3"); // Phase C
        }

        function drawGrid(ctx) {
            ctx.strokeStyle = toolBar.toggle ? "#404040" : "#e0e0e0";
            ctx.lineWidth = 1;
            
            // Draw circles
            [0.25, 0.5, 0.75, 1.0].forEach(function(scale) {
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius * scale, 0, 2 * Math.PI);
                ctx.stroke();
            });
            
            // Draw axes
            ctx.beginPath();
            ctx.moveTo(centerX - radius, centerY);
            ctx.lineTo(centerX + radius, centerY);
            ctx.moveTo(centerX, centerY - radius);
            ctx.lineTo(centerX, centerY + radius);
            ctx.stroke();
            
            // Draw angle markers
            [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330].forEach(function(angle) {
                var rad = angle * Math.PI / 180;
                ctx.beginPath();
                ctx.moveTo(
                    centerX + Math.cos(rad) * radius * 0.95,
                    centerY - Math.sin(rad) * radius * 0.95
                );
                ctx.lineTo(
                    centerX + Math.cos(rad) * radius,
                    centerY - Math.sin(rad) * radius
                );
                ctx.stroke();
            });
        }

        function drawPhasor(ctx, angle, magnitude, color) {
            var rad = angle * Math.PI / 180;
            var length = radius * magnitude;
            
            ctx.strokeStyle = color;
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(centerX, centerY);
            ctx.lineTo(
                centerX + Math.cos(rad) * length,
                centerY - Math.sin(rad) * length
            );
            ctx.stroke();
            
            // Draw arrow head
            var headLength = 10;
            var headAngle = Math.PI / 6;
            
            var endX = centerX + Math.cos(rad) * length;
            var endY = centerY - Math.sin(rad) * length;
            
            ctx.beginPath();
            ctx.moveTo(endX, endY);
            ctx.lineTo(
                endX - headLength * Math.cos(rad - headAngle),
                endY + headLength * Math.sin(rad - headAngle)
            );
            ctx.moveTo(endX, endY);
            ctx.lineTo(
                endX - headLength * Math.cos(rad + headAngle),
                endY + headLength * Math.sin(rad + headAngle)
            );
            ctx.stroke();
        }
    }

    // Invisible touch areas for each phasor
    Repeater {
        model: ListModel {
            id: phasorModel
            // Initialize with default values
            Component.onCompleted: {
                append({ 
                    phase: "A", 
                    color: "#f44336", 
                    getAngle: function() { return root.model ? root.model.phaseAngleA : 0 },
                    getMagnitude: function() { return root.model ? root.model.rmsA / 230 : 0 },
                    setAngle: function(v) { root.model.setPhaseAngleA(v) },
                    setAmplitude: function(v) { root.model.setAmplitudeA(v) }
                });
                append({ 
                    phase: "B", 
                    color: "#4caf50", 
                    getAngle: function() { return root.model ? root.model.phaseAngleB : 120 },
                    getMagnitude: function() { return root.model ? root.model.rmsB / 230 : 0 },
                    setAngle: function(v) { root.model.setPhaseAngleB(v) },
                    setAmplitude: function(v) { root.model.setAmplitudeB(v) }
                });
                append({ 
                    phase: "C", 
                    color: "#2196f3", 
                    getAngle: function() { return root.model ? root.model.phaseAngleC : 240 },
                    getMagnitude: function() { return root.model ? root.model.rmsC / 230 : 0 },
                    setAngle: function(v) { root.model.setPhaseAngleC(v) },
                    setAmplitude: function(v) { root.model.setAmplitudeC(v) }
                });
            }
        }

        Rectangle {
            id: phasorHandle
            property real angle: model.getAngle()
            property real magnitude: model.getMagnitude()

            width: 40
            height: 40
            radius: 20
            color: model.color
            opacity: 0.5
            
            x: root.centerX + Math.cos(angle * Math.PI / 180) * (root.radius * magnitude) - width/2
            y: root.centerY - Math.sin(angle * Math.PI / 180) * (root.radius * magnitude) - height/2

            MouseArea {
                id: phasorMouseArea
                anchors.fill: parent
                drag.target: parent
                
                onPositionChanged: {
                    if (pressed && root.model) {
                        // Calculate new angle and magnitude from mouse position
                        var dx = parent.x + width/2 - root.centerX
                        var dy = -(parent.y + height/2 - root.centerY)
                        var newAngle = Math.atan2(dy, dx) * 180 / Math.PI
                        var newMagnitude = Math.sqrt(dx * dx + dy * dy) / root.radius
                        
                        // Update model using the functions from ListModel
                        model.setAngle(newAngle)
                        model.setAmplitude(newMagnitude * 230 * Math.SQRT2)
                        
                        canvas.requestPaint()
                    }
                }
            }

            ToolTip {
                visible: phasorMouseArea.pressed
                text: "Phase " + model.phase + "\n" +
                      "Angle: " + angle.toFixed(1) + "°\n" +
                      "Magnitude: " + (magnitude * 230).toFixed(1) + " V"
            }
        }
    }

    Connections {
        target: model
        function onDataChanged() {
            canvas.requestPaint()
        }
    }
}
