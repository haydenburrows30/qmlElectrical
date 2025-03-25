import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import "../../style"

/*!
    \brief Custom round button with tooltip
    Provides consistent styling for round buttons
*/
RoundButton {
    id: control
    icon.width: Style.iconSize
    icon.height: Style.iconSize
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
        delay: Style.tooltipDelay
    }
    
    background: Rectangle {
        radius: control.radius
        color: {
            if (control.down) return Style.buttonPressed
            if (control.hovered) return Style.buttonHovered
            return Style.buttonBackground
        }
        border.width: 1
        border.color: Style.buttonBorder
    }

    onClicked: {toolTip.hide()}
}