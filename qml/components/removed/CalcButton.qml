import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    Layout.fillWidth: true
    Layout.minimumWidth: 120
    Layout.minimumHeight: 35
    
    background: Rectangle {
        color: parent.hovered ? (sideBar.toggle1 ? "#404040" : "#e0e0e0") 
                            : (sideBar.toggle1 ? "#2a2a2a" : "#f0f0f0")
        radius: 3
        border.width: 1
        border.color: sideBar.toggle1 ? "#505050" : "#d0d0d0"
    }
    
    contentItem: Text {
        text: parent.text
        color: sideBar.toggle1 ? "#ffffff" : "#000000"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
