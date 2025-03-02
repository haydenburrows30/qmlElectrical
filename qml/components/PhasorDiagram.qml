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
    property var phaseAngles: []

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

            ctx.strokeStyle = "black"
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
            ctx.stroke()

            var colors = ["red", "yellow", "blue"]
            for (var i = 0; i < phaseAngles.length; i++) {
                var angle = phaseAngles[i] * Math.PI / 180
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

    // Add angle labels
    Repeater {
        model: 12
        Text {
            text: (index * 30) + "°"
            transformOrigin: Item.Center
            x: parent.width / 2 + Math.cos(-index * 30 * Math.PI / 180) * (parent.width / 2 + 10) - width / 2
            y: parent.height / 2 - Math.sin(-index * 30 * Math.PI / 180) * (parent.height / 2 + 10) - height / 2
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
                            height / 2 - Math.sin(-i * 30 * Math.PI / 180) * height / 2)
                ctx.stroke()
            }
        }
    }
}
