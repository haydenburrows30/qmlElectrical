import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Shapes 1.15

Item {
    id: phasorDiagram
    property var phaseAngles: []

    width: 200
    height: 200

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
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
            ctx.stroke()

            var colors = ["red", "yellow", "blue"]
            for (var i = 0; i < phaseAngles.length; i++) {
                var angle = phaseAngles[i] * Math.PI / 180
                var x = centerX + radius * Math.cos(angle)
                var y = centerY + radius * Math.sin(angle)

                ctx.strokeStyle = colors[i]
                ctx.beginPath()
                ctx.moveTo(centerX, centerY)
                ctx.lineTo(x, y)
                ctx.stroke()
            }
        }
    }
}
