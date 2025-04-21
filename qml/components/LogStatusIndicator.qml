import QtQuick
import QtQuick.Controls

Rectangle {
    id: logIndicator
    width: 20
    height: 20
    radius: 10
    color: "green"
    property var logManager: null
    property int errorCount: 0
    property int warnCount: 0
    
    signal clicked()
    
    ToolTip.text: "Error logs: " + errorCount + ", Warning logs: " + warnCount + 
                  "\nClick to open log viewer"
    ToolTip.visible: mouseArea.containsMouse
    ToolTip.delay: 500
    
    // Connect to logManager signals when available
    Timer {
        interval: 100
        running: logManager !== null
        repeat: false
        onTriggered: {
            if (logManager) {
                logManager.newLogMessage.connect(onNewLogMessage);
            }
        }
    }
    
    // Handle log messages
    function onNewLogMessage(level, message) {
        if (level === "ERROR" || level === "CRITICAL") {
            errorCount++;
            pulseAnimation.start();
            color = "red";
        } else if (level === "WARNING") {
            warnCount++;
            if (color !== "red") {
                color = "orange";
            }
        }
    }
    
    SequentialAnimation {
        id: pulseAnimation
        loops: 3
        
        PropertyAnimation {
            target: logIndicator
            property: "scale"
            to: 1.3
            duration: 200
        }
        
        PropertyAnimation {
            target: logIndicator
            property: "scale"
            to: 1.0
            duration: 200
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            logIndicator.clicked()
        }
    }
    
    Text {
        visible: errorCount > 0 || warnCount > 0
        anchors.centerIn: parent
        text: errorCount > 0 ? errorCount.toString() : warnCount.toString()
        color: "white"
        font.pixelSize: 10
        font.bold: true
    }
}
