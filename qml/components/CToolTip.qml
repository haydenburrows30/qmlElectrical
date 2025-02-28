import QtQuick
import QtQuick.Controls

ToolTip {
    id: control
    visible: parent.hovered | parent.down
    text: qsTr("A descriptive tool tip of what the button does")
    delay: 0

    x:  parent.width
    y: 0

    height: parent.height

    contentItem: Text {
        text: control.text
        font: control.font
        color: toolBar.toggle ? palette.base:palette.dark
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }

    // background: Rectangle {
    //     border.color: "#21be2b"
    // }
}