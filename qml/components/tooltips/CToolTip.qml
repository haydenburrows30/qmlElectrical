import QtQuick
import QtQuick.Controls

ToolTip {
    id: control
    visible: parent.hovered | parent.down
    delay: 0

    x: parent.width
    y: 0

    height: parent.height

    contentItem: Text {
        text: control.text
        font: control.font
        color: sideBar.toggle1? "white": "black"
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle{
                    width : 110
                    height: 60
                    color: sideBar.toggle1 ? Qt.darker(palette.dark,5): palette.light

                    anchors {
                        leftMargin: 5
                        rightMargin: 1
                        topMargin: 1
                        bottomMargin: 1
                    }
                    border.color: palette.accent
                    }
    }