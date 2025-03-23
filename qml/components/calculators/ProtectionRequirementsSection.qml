import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../displays"

Item {
    id: protectionSection

    property var transformerCalculator
    property var windTurbineCalculator
    property bool transformerReady
    property bool windTurbineReady
    property real totalGeneratedPower
    property var safeValueFunction

    signal calculate()

    Accordian {
        anchors.fill: parent
    }
}