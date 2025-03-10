import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

RoundButton {
    id: round_button
    implicitWidth: 50
    implicitHeight: 50
    icon.width: 30
    icon.height: 30
    checkable: true

    icon.name: round_button.checked ? icon_name1:icon_name2

    property var icon_name1 : ""
    property var icon_name2 : ""
    property var mode_1 : ""
    property var mode_2 : ""

    ToolTip {
        id: toolTip
        text: round_button.checked ? mode_1:mode_2
        visible: parent.hovered
        x: parent.width
        y: parent.height
        delay: 500
        timeout: 2000
    }

    onClicked: {
        toolTip.hide()
    }

    background: Rectangle {
        radius: round_button.radius
        visible: !round_button.flat || round_button.down || round_button.checked || round_button.highlighted
        color: round_button.down ? round_button.Universal.baseMediumLowColor :
            round_button.enabled && (round_button.highlighted || round_button.checked) ? round_button.Universal.accent :
                                                                            "transparent"

        Rectangle {
            width: parent.width
            height: parent.height
            radius: round_button.radius
            color: "transparent"
            visible: enabled && round_button.hovered
            border.width: 2
            border.color: round_button.Universal.baseMediumLowColor
        }
    }
}