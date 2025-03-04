import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import PPlot 1.0

Item {
    id: root
    property alias magnitude: phasor.magnitude
    property alias angle: phasor.angle

    // Add functions to match the expected interface
    function setMagnitude(value) {
        if (phasor) phasor.magnitude = value
    }

    function setAngle(value) {
        if (phasor) phasor.angle = value
    }

    Rectangle {
        anchors.fill: parent
        color: "white"
        border.color: "gray"
        border.width: 1

        PhasorPlot {
            id: phasor
            anchors.fill: parent
            anchors.margins: 5
        }
    }
}
