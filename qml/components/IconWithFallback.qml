import QtQuick
import QtQuick.Controls

// A component that handles icon loading with automatic fallbacks
Item {
    id: root
    
    property string source: ""
    property string fallbackText: ""
    property string fallbackColor: "#0074D9" // Default blue
    property int iconSize: 32
    
    width: iconSize
    height: iconSize
    
    Image {
        id: iconImage
        source: root.source
        width: root.width
        height: root.height
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: status === Image.Ready
        
        onStatusChanged: {
            if (status === Image.Error) {
                console.error("Failed to load icon:", source)
            }
        }
    }
    
    // Fallback for when image fails to load
    Rectangle {
        visible: iconImage.status !== Image.Ready
        anchors.fill: parent
        radius: width / 4
        color: fallbackColor
        border.width: 1
        border.color: Qt.darker(color, 1.1)
        
        Text {
            anchors.centerIn: parent
            text: fallbackText
            color: "white"
            font.bold: true
            font.pixelSize: Math.max(8, root.iconSize / 3)
        }
    }
}
