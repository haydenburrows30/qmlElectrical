import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: perfDisplay
    
    // Position in the bottom-right corner by default
    width: expanded ? 180 : 30
    height: expanded ? 120 : 30
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 10
    
    // Styling
    color: expanded ? "#aa222222" : "transparent"
    radius: 4
    border.color: expanded ? "#555555" : "transparent" 
    border.width: 1
    opacity: 0.9
    
    // State properties
    property bool expanded: false
    property bool monitoring: true
    
    // Performance metrics from the backend
    property double fps: perfMonitor ? perfMonitor.fps : 0
    property double renderTime: perfMonitor ? perfMonitor.renderTime : 0
    property double memoryUsage: perfMonitor ? perfMonitor.memoryUsage : 0
    property double cpuUsage: perfMonitor ? perfMonitor.cpuUsage : 0
    
    // Non-intrusive behavior
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        hoverEnabled: true
        
        // Only capture clicks specifically on the indicator button
        onPressed: function(mouse) {
            if (indicatorButton.contains(Qt.point(mouse.x, mouse.y))) {
                expanded = !expanded
                mouse.accepted = true
            } else {
                mouse.accepted = false
            }
        }
        
        // Forward all other events
        onReleased: function(mouse) { mouse.accepted = false }
        onClicked: function(mouse) { if (!indicatorButton.contains(Qt.point(mouse.x, mouse.y))) mouse.accepted = false }
        onDoubleClicked: function(mouse) { mouse.accepted = false }
    }
    
    // Animation for smooth transition
    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on color {
        ColorAnimation { duration: 200 }
    }
    
    // Performance display toggle button
    Rectangle {
        id: indicatorButton
        width: 30
        height: 30
        radius: 15
        color: "#33ffffff"
        border.color: "#555555"
        border.width: 1
        
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        
        Text {
            anchors.centerIn: parent
            text: "FPS"
            color: getFpsColor(fps)
            font.pixelSize: 10
            font.bold: true
        }

        function contains(point) {
            var dx = point.x - (x + width/2)
            var dy = point.y - (y + height/2)
            return (dx*dx + dy*dy) <= (width/2)*(width/2)
        }
    }
    
    // Main performance metrics display
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4
        visible: expanded
        
        Text {
            text: "Performance"
            font.pixelSize: 14
            font.bold: true
            color: "white"
            Layout.fillWidth: true
        }
        
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "FPS:"
                font.pixelSize: 12
                color: getFpsColor(fps)
                Layout.preferredWidth: 70
            }
            
            Text {
                text: fps.toFixed(1)
                font.pixelSize: 12
                font.bold: true
                color: "white"
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "Render:"
                font.pixelSize: 12
                color: renderTime > 16 ? "#ff6666" : "#66ff66"
                Layout.preferredWidth: 70
            }
            
            Text {
                text: renderTime.toFixed(1) + " ms"
                font.pixelSize: 12
                font.bold: true
                color: "white"
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "Memory:"
                font.pixelSize: 12
                color: "#aaaaaa"
                Layout.preferredWidth: 70
            }
            
            Text {
                text: memoryUsage.toFixed(1) + "%"
                font.pixelSize: 12
                color: memoryUsage > 80 ? "#ff6666" : "white"
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "CPU:"
                font.pixelSize: 12
                color: "#aaaaaa"
                Layout.preferredWidth: 70
            }
            
            Text {
                text: cpuUsage.toFixed(1) + "%"
                font.pixelSize: 12
                color: cpuUsage > 80 ? "#ff6666" : "white"
            }
        }
    }
    
    // Helper function to color fps text
    function getFpsColor(fps) {
        if (fps < 30) return "#ff6666"  // Red when below 30 fps
        if (fps < 55) return "#ffff66"  // Yellow when below 55 fps
        return "#66ff66"                // Green when 55+ fps
    }
}