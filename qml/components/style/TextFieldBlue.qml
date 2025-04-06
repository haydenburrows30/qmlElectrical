import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

TextField {
    id: textField
    readOnly: true
    Layout.fillWidth: true

    color: textField.activeFocus ? sideBar.modeToggled ? "white" : "black" : sideBar.modeToggled ? "white" : "black"
    
    background: Rectangle {
        color: sideBar.modeToggled ? "transparent":"#e8f6ff"
        border.color: "#0078d7"
        radius: 3
    }
}