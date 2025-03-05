import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Studio.DesignEffects
import QtQuick.Shapes

Item {
    id: phasorDiagram
    property var phaseAngles: [0, 120, 240]
    signal angleChanged(int index, real angle)

    // Add properties for customization and reuse
    property var colors: ["#f44336", "#4caf50", "#2196f3"]  // Material Design colors
    property real clickRadius: 20
    property real phasorRadius: Math.min(width, height) * 0.4
    property var scaleValues: [0.25, 0.5, 0.75, 1.0]  // Add explicit scale values

    width: 200
    height: 200

    anchors.rightMargin: 20

    onPhaseAnglesChanged: canvas.requestPaint()

    // Background circle and grid
    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var centerX = width / 2
            var centerY = height / 2
            var radius = Math.min(centerX, centerY) - 20

            // Draw reference circles with theme support
            ctx.strokeStyle = toolBar.toggle ? "#404040" : "#e0e0e0"
            ctx.lineWidth = 1
            
            // Use for loop instead of forEach
            for (var i = 0; i < scaleValues.length; i++) {
                ctx.beginPath()
                ctx.arc(centerX, centerY, radius * scaleValues[i], 0, 2 * Math.PI)
                ctx.stroke()
            }

            // Draw grid lines
            for (var i = 0; i < 12; i++) {
                var angle = i * 30 * Math.PI / 180
                ctx.beginPath()
                ctx.moveTo(centerX, centerY)
                ctx.lineTo(
                    centerX + radius * Math.cos(angle),
                    centerY + radius * Math.sin(angle)
                )
                ctx.stroke()
            }
        }
    }

    // Main phasor canvas + drag handles
    Item {
        id: phasorDisplay
        anchors.fill: parent
        
        Canvas {
            id: canvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                var centerX = width / 2
                var centerY = height / 2
                var radius = Math.min(centerX, centerY) - 20

                // Draw phasors
                for (var i = 0; i < phaseAngles.length; i++) {
                    var angle = -phaseAngles[i] * Math.PI / 180
                    var x = centerX + radius * Math.cos(angle)
                    var y = centerY + radius * Math.sin(angle)

                    // Draw phasor line with glow effect
                    ctx.strokeStyle = colors[i]
                    ctx.lineWidth = 3
                    ctx.shadowColor = colors[i]
                    ctx.shadowBlur = toolBar.toggle ? 8 : 4
                    ctx.beginPath()
                    ctx.moveTo(centerX, centerY)
                    ctx.lineTo(x, y)
                    ctx.stroke()
                    
                    // Reset shadow for arrow head
                    ctx.shadowBlur = 0
                    
                    // Draw arrow head
                    var headLength = 15
                    var headAngle = Math.PI / 6
                    drawArrowHead(ctx, x, y, angle, headLength, headAngle, colors[i])
                }
            }
        }

        // Drag handles for phasors
        Repeater {
            model: 3
            
            Rectangle {
                id: handle
                property int phasorIndex: index
                
                width: 30
                height: 30
                radius: width/2
                opacity: dragArea.drag.active ? 0.8 : 0.4
                
                // Position handle at end of phasor
                x: phasorDisplay.width/2 + Math.cos(-phaseAngles[index] * Math.PI / 180) * phasorRadius - width/2
                y: phasorDisplay.height/2 + Math.sin(-phaseAngles[index] * Math.PI / 180) * phasorRadius - height/2

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    drag.target: parent
                    hoverEnabled: true
                    
                    onPositionChanged: {
                        if (pressed) {
                            var cx = phasorDisplay.width/2
                            var cy = phasorDisplay.height/2
                            var dx = parent.x + width/2 - cx
                            var dy = parent.y + height/2 - cy
                            
                            // Calculate angle in degrees
                            var angle = Math.atan2(dy, dx) * 180 / Math.PI
                            
                            // Convert to clockwise angle starting from right (0°)
                            angle = (-angle + 360) % 360
                            
                            phasorDiagram.angleChanged(index, angle)
                            canvas.requestPaint()
                        }
                    }
                }

                ToolTip.visible: dragArea.containsMouse
                ToolTip.text: "Phase " + (["A", "B", "C"][index]) + "\n" +
                             "Angle: " + phaseAngles[index].toFixed(1) + "°"
            }
        }
    }

    function drawArrowHead(ctx, x, y, angle, length, headAngle, color) {
        ctx.fillStyle = color
        ctx.beginPath()
        ctx.moveTo(x, y)
        ctx.lineTo(
            x - length * Math.cos(angle - headAngle),
            y - length * Math.sin(angle - headAngle)
        )
        ctx.lineTo(
            x - length * Math.cos(angle + headAngle),
            y - length * Math.sin(angle + headAngle)
        )
        ctx.closePath()
        ctx.fill()
    }

    // Angle labels
    Repeater {
        model: 12
        delegate: Label {
            required property int index
            text: (index * 30) + "°"
            x: parent.width/2 + Math.cos(-index * 30 * Math.PI / 180) * 
               (parent.width/2 - 30) - width/2
            y: parent.height/2 + Math.sin(-index * 30 * Math.PI / 180) * 
               (parent.height/2 - 30) - height/2
            font.pixelSize: 12
        }
    }
}
