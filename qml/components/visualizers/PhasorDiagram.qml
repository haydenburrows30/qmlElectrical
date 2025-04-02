import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Shapes

import "../style"

Item {
    id: phasorDiagram
    property var phaseAngles: [0, 120, 240]
    property var currentPhaseAngles: [30, 150, 270]
    property var currentMagnitudes: [1, 1, 1]
    property bool showCurrentPhasors: false
    
    signal angleChanged(int index, real angle)
    signal currentAngleChanged(int index, real angle)

    property var colors: ["#f44336", "#4caf50", "#2196f3"]
    property var currentColors: ["#ffcdd2", "#c8e6c9", "#bbdefb"]
    property real clickRadius: 20
    property real phasorRadius: Math.min(width, height) * 0.4
    property real currentPhasorRadius: phasorRadius * 0.8
    property var scaleValues: [0.25, 0.5, 0.75, 1.0]

    width: 200
    height: 200

    anchors.rightMargin: 20

    onPhaseAnglesChanged: canvas.requestPaint()
    onCurrentPhaseAnglesChanged: canvas.requestPaint()
    onCurrentMagnitudesChanged: canvas.requestPaint()
    onShowCurrentPhasorsChanged: canvas.requestPaint()

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
            ctx.strokeStyle = sideBar.toggle1 ? "#404040" : "#e0e0e0"
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

                // Draw voltage phasors
                for (var i = 0; i < phaseAngles.length; i++) {
                    var angle = -phaseAngles[i] * Math.PI / 180
                    var x = centerX + radius * Math.cos(angle)
                    var y = centerY + radius * Math.sin(angle)

                    // Draw phasor line with glow effect
                    ctx.strokeStyle = colors[i]
                    ctx.lineWidth = 3
                    ctx.shadowColor = colors[i]
                    ctx.shadowBlur = sideBar.toggle1 ? 8 : 4
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

                // Draw current phasors if enabled
                if (showCurrentPhasors) {
                    for (var j = 0; j < currentPhaseAngles.length; j++) {
                        var currentAngle = -currentPhaseAngles[j] * Math.PI / 180
                        var magnitude = currentMagnitudes[j]
                        var cRad = currentPhasorRadius * magnitude
                        
                        var cx = centerX + cRad * Math.cos(currentAngle)
                        var cy = centerY + cRad * Math.sin(currentAngle)

                        // Draw current phasor with dashed line
                        ctx.strokeStyle = currentColors[j]
                        ctx.lineWidth = 2
                        ctx.shadowColor = currentColors[j]
                        ctx.shadowBlur = sideBar.toggle1 ? 6 : 3
                        
                        // Set dashed line style
                        ctx.setLineDash([5, 3])
                        ctx.beginPath()
                        ctx.moveTo(centerX, centerY)
                        ctx.lineTo(cx, cy)
                        ctx.stroke()
                        ctx.setLineDash([]) // Reset line style
                        
                        // Reset shadow for arrow head
                        ctx.shadowBlur = 0
                        
                        // Draw arrow head for current
                        drawArrowHead(ctx, cx, cy, currentAngle, 12, Math.PI / 6, currentColors[j])
                    }
                }
            }
        }

        // Drag handles for voltage phasors
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
                ToolTip.text: "Voltage Phase " + (["A", "B", "C"][index]) + "\n" +
                             "Angle: " + phaseAngles[index].toFixed(1) + "°"

                color: colors[index]
                border.color: "white"
                border.width: 2
            }
        }

        // Drag handles for current phasors
        Repeater {
            model: showCurrentPhasors ? 3 : 0
            
            Rectangle {
                id: currentHandle
                property int phasorIndex: index
                
                width: 24
                height: 24
                radius: width/2
                opacity: currentDragArea.drag.active ? 0.8 : 0.4
                
                // Position handle at end of current phasor
                x: phasorDisplay.width/2 + Math.cos(-currentPhaseAngles[index] * Math.PI / 180) * 
                   currentPhasorRadius * currentMagnitudes[index] - width/2
                y: phasorDisplay.height/2 + Math.sin(-currentPhaseAngles[index] * Math.PI / 180) * 
                   currentPhasorRadius * currentMagnitudes[index] - height/2

                MouseArea {
                    id: currentDragArea
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
                            
                            phasorDiagram.currentAngleChanged(index, angle)
                            canvas.requestPaint()
                        }
                    }
                }

                ToolTip.visible: currentDragArea.containsMouse
                ToolTip.text: "Current Phase " + (["A", "B", "C"][index]) + "\n" +
                             "Angle: " + currentPhaseAngles[index].toFixed(1) + "°\n" +
                             "Power Factor: " + Math.cos((currentPhaseAngles[index] - phaseAngles[index]) * Math.PI / 180).toFixed(3)

                color: currentColors[index]
                border.color: "white"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "I"
                    font.pixelSize: 12
                    font.bold: true
                    color: "black"
                }
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
            color: sideBar.toggle1 ? "#b0b0b0" : "#606060"
        }
    }

    // Legend for voltage and current phasors
    Column {
        x: 10
        y: 10
        
        visible: showCurrentPhasors
        
        Row {
            
            Rectangle {
                width: 15
                height: 3
                color: "#f44336"
                anchors.verticalCenter: parent.verticalCenter
            }
            Label {
                text: "Voltage"
                font.pixelSize: 12
            }
        }
        
        Row {
            
            Rectangle {
                width: 15
                height: 3
                color: "#ffcdd2"
                anchors.verticalCenter: parent.verticalCenter
            }
            Label {
                text: "Current"
                font.pixelSize: 12
            }
        }
    }
}
