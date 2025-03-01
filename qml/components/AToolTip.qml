import QtQuick
import QtQuick.Controls

ToolTip {
    id: control
    visible: parent.hovered
    delay: 0

    x: parent.width
    y: parent.height

    // height: parent.height

    contentItem: Text {
        text: control.text
        font: control.font
        color: toolBar.toggle ? "white": "black"
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
    }

    background: CustomBorderRect{
                    width : 110
                    height: 60
                    color: toolBar.toggle ? Qt.darker(palette.dark,5): palette.light

                    lBorderwidth: 5
                    rBorderwidth: 1
                    tBorderwidth: 1
                    bBorderwidth: 1
                    borderColor: palette.accent
                    }
}