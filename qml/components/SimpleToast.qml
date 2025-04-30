import QtQuick
import QtQuick.Controls

Rectangle {
    id: toast
    
    property string message: ""
    property string type: "info"  // info, success, error, warning
    property int displayTime: 3000
    property int fadeTime: 300
    
    function show() {
        toast.opacity = 0.9;
        hideTimer.start();
    }
    
    width: toastText.width + 40
    height: 40
    radius: 20
    opacity: 0
    
    // Set color based on type
    color: {
        switch(type) {
            case "success": return "#4CAF50"; // Green
            case "error": return "#F44336";   // Red
            case "warning": return "#FF9800"; // Orange
            default: return "#2196F3";        // Blue (info)
        }
    }
    
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 50
    
    // Property to auto-destroy after hiding
    property bool selfDestruct: true
    
    Text {
        id: toastText
        text: toast.message
        color: "white"
        font.pixelSize: 14
        anchors.centerIn: parent
    }
    
    // Timer to hide the toast
    Timer {
        id: hideTimer
        interval: displayTime
        onTriggered: hideAnim.start()
    }
    
    // Fade-in animation
    Behavior on opacity {
        NumberAnimation { duration: fadeTime }
    }
    
    // Fade-out animation
    NumberAnimation {
        id: hideAnim
        target: toast
        property: "opacity"
        to: 0
        duration: fadeTime
        onFinished: {
            if (selfDestruct) {
                toast.destroy();
            }
        }
    }
    
    Component.onCompleted: {
        // Make it appear above other elements
        z = 9999;
    }
}
