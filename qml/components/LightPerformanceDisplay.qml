import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

Rectangle {
    id: root
    
    width: 150
    height: col.implicitHeight + 10
    color: Qt.rgba(0, 0, 0, 0.5)
    radius: 5
    
    x: 10
    y: parent.height - height - 10
    
    // Only show when the performance monitor is enabled
    visible: typeof perfMonitor !== 'undefined' ? perfMonitor.enabled : false
    
    // Animation for smooth appearance/disappearance
    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }
    
    Column {
        id: col
        anchors.fill: parent
        anchors.margins: 5
        spacing: 2
        
        Label {
            text: "FPS: " + (typeof perfMonitor !== 'undefined' ? Math.round(perfMonitor.fps) : "N/A")
            color: "white"
            font.pixelSize: 12
        }
        
        Label {
            text: "Render: " + (typeof perfMonitor !== 'undefined' ? Math.round(perfMonitor.renderTime) + "ms" : "N/A")
            color: "white"
            font.pixelSize: 12
        }
        
        Label {
            text: "Memory: " + (typeof perfMonitor !== 'undefined' ? Math.round(perfMonitor.memoryUsage) + "%" : "N/A")
            color: "white"
            font.pixelSize: 12
        }
        
        Label {
            text: "CPU: " + (typeof perfMonitor !== 'undefined' ? Math.round(perfMonitor.cpuUsage) + "%" : "N/A")
            color: "white"
            font.pixelSize: 12
        }
    }
}