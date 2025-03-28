import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal

ModernButton {
    id: control
    
    isCircular: true
    implicitWidth: 36
    implicitHeight: 36
    
    property string iconName: ""
    property int iconSize: 16
    
    contentItem: Item {
        Image {
            id: buttonIcon
            source: iconName ? "qrc:/icons/" + iconName + ".svg" : ""
            sourceSize.width: iconSize
            sourceSize.height: iconSize
            anchors.centerIn: parent
            visible: status === Image.Ready
        }
        
        Text {
            text: control.icon.name || ""
            visible: !buttonIcon.visible
            anchors.centerIn: parent
            color: control.down || control.hovered ? Qt.darker(textColor, 1.1) : textColor
            font.family: "FontAwesome"
            font.pixelSize: iconSize
        }
    }
}
