import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

RoundButton {
    id: control
    icon.width: 30
    icon.height: 30
    icon.name: icon_name

    property var icon_name : ""
    property string tooltip_text: ""
    z:99

    ToolTip {
        id: toolTip
        text: tooltip_text
        visible: parent.hovered
        x: parent.width
        y: parent.height
        delay: 500
    }
    
    background: Rectangle {
        radius: control.radius
        color: control.down ? "#404040" : control.hovered ? "#505050" : "#606060"
        border.width: 1
        border.color: "#808080"
    }

    onClicked: {toolTip.hide()}
}