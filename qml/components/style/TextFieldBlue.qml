import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

TextField {
    id: textField
    readOnly: true
    Layout.fillWidth: true

    text: ""
    color: textField.activeFocus ? sideBar.modeToggled ? "white" : "black" : sideBar.modeToggled ? "white" : "black"
    // ToolTip.visible: hovered
    // ToolTip.delay: 500
    
    background: Rectangle {
        color: sideBar.modeToggled ? "transparent":"#e8f6ff"
        border.color: "#0078d7"
        radius: 3
    }
}