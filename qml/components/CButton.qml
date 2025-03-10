import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

RoundButton {
    id: control

    // implicitWidth: 50
    // implicitHeight: 50
    icon.width: 30
    icon.height: 30
    // Layout.rightMargin: 10
    icon.name: icon_name

    property var icon_name : ""
    property string tooltip_text: ""

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
        visible: !control.flat || control.down || control.checked || control.highlighted
        color: control.down ? control.Universal.baseMediumLowColor :
            control.enabled && (control.highlighted || control.checked) ? control.Universal.accent :
                                                                            "white"

        Rectangle {
            width: parent.width
            height: parent.height
            radius: control.radius
            color: "white" //"transparent"
            visible: enabled && control.hovered
            border.width: 2
            border.color: control.Universal.baseMediumLowColor
        }
    }

    onClicked: {toolTip.hide()}
}