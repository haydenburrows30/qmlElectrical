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
    property var colors: ["red", "yellow", "blue"]
    property real clickRadius: 20
    property real phasorRadius: Math.min(width, height) * 0.4

    width: 200
    height: 200

    anchors.rightMargin: 20

    onPhaseAnglesChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, canvas.width, canvas.height)

            var centerX = canvas.width / 2
            var centerY = canvas.height / 2
            var radius = Math.min(centerX, centerY) - 10

            // Draw circle
            ctx.strokeStyle = "black"
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
            ctx.stroke()

            // Draw phasors
            for (var i = 0; i < phaseAngles.length; i++) {
                var angle = -phaseAngles[i] * Math.PI / 180  // Negative angle for clockwise rotation
                var x = centerX + radius * Math.cos(angle)
                var y = centerY + radius * Math.sin(angle)

                ctx.strokeStyle = colors[i]
                ctx.lineWidth = 3
                ctx.beginPath()
                ctx.moveTo(centerX, centerY)
                ctx.lineTo(x, y)
                ctx.stroke()
            }
        }
    }

    // Add angle labels (clockwise)
    Repeater {
        model: 12
        Text {
            text: (index * 30) + "°"
            transformOrigin: Item.Center
            x: parent.width / 2 + Math.cos(index * 30 * Math.PI / 180) * (parent.width / 2 + 10) - width / 2
            y: parent.height / 2 + Math.sin(index * 30 * Math.PI / 180) * (parent.height / 2 + 10) - height / 2
        }
    }

    // Add lines for every 30 degrees
    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = "gray"
            ctx.lineWidth = 1
            for (var i = 0; i < 12; i++) {
                ctx.beginPath()
                ctx.moveTo(width / 2, height / 2)
                ctx.lineTo(width / 2 + Math.cos(-i * 30 * Math.PI / 180) * width / 2,
                          height / 2 + Math.sin(-i * 30 * Math.PI / 180) * height / 2)
                ctx.stroke()
            }
        }
    }

    MouseArea {
        id: mouseArea  // Add id to reference the MouseArea
        anchors.fill: parent
        property int selectedPhasor: -1
        property int hoveredPhasor: -1
        property point center: Qt.point(width/2, height/2)
        hoverEnabled: true
        cursorShape: hoveredPhasor !== -1 ? Qt.PointingHandCursor : Qt.ArrowCursor

        function getEndPoint(index) {
            let angle = -phaseAngles[index] * Math.PI / 180  // Negative angle for clockwise rotation
            return {
                x: center.x + phasorRadius * Math.cos(angle),
                y: center.y + phasorRadius * Math.sin(angle)
            }
        }

        function isNearPhasorEnd(mouseX, mouseY, index) {
            let end = getEndPoint(index)
            let distance = Math.sqrt(Math.pow(mouseX - end.x, 2) + Math.pow(mouseY - end.y, 2))
            return distance < clickRadius
        }

        onPositionChanged: {
            if (selectedPhasor === -1) {
                // Handle hover state
                hoveredPhasor = -1
                for (let i = 0; i < 3; i++) {
                    if (isNearPhasorEnd(mouseX, mouseY, i)) {
                        hoveredPhasor = i
                        break
                    }
                }
            } else {
                // Handle drag rotation
                let dx = mouseX - center.x
                let dy = mouseY - center.y
                let angle = Math.atan2(dy, dx) * 180 / Math.PI
                angle = (360 - angle) % 360  // Convert to clockwise angle
                phasorDiagram.angleChanged(selectedPhasor, angle)
            }
        }

        onPressed: {
            selectedPhasor = -1
            for (let i = 0; i < 3; i++) {
                if (isNearPhasorEnd(mouseX, mouseY, i)) {
                    selectedPhasor = i
                    break
                }
            }
        }

        onReleased: {
            selectedPhasor = -1
        }
    }

    // Add tooltips for phasor ends
    Rectangle {
        id: tooltip
        width: tooltipText.width + 10
        height: tooltipText.height + 6
        color: "white"
        border.color: "black"
        radius: 3
        visible: mouseArea.hoveredPhasor !== -1
        x: mouseArea.hoveredPhasor !== -1 ? 
           mouseArea.getEndPoint(mouseArea.hoveredPhasor).x : 0
        y: mouseArea.hoveredPhasor !== -1 ? 
           mouseArea.getEndPoint(mouseArea.hoveredPhasor).y - height : 0

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: {
                switch(mouseArea.hoveredPhasor) {
                    case 0: return "Phase A"
                    case 1: return "Phase B"
                    case 2: return "Phase C"
                    default: return ""
                }
            }
        }
    }
}
