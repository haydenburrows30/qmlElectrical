import QtQuick
import QtQuick.Controls

Item {
    id: root
    property var canvas: null

    function setupCanvas() {
        if (canvas) {
            try {
                canvas.parent = root
                if (canvas.anchors) {
                    canvas.anchors.fill = root
                }
            } catch (e) {
                console.error("Error setting up canvas:", e)
            }
        }
    }

    onCanvasChanged: setupCanvas()
    Component.onCompleted: setupCanvas()
}
