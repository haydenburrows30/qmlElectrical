import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

TextField {
    id: textField
    readOnly: true
    Layout.fillWidth: true

    color: textField.activeFocus ? window.modeToggled ? "white" : "black" : window.modeToggled ? "white" : "black"
    
    background: Rectangle {
        color: window.modeToggled ? "transparent":"#e8f6ff"
        border.color: "#0078d7"
        radius: 3
    }
}