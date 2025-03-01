import QtQuick
import QtQuick.Controls

ToolTip {
    id: atooltip
    visible: parent.hovered
    text: atooltip.text
    x: parent.width
    y: parent.height
    delay: 500
}