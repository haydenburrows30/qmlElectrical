import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Dialog {
    id: logViewerPopup

    title: "Application Logs"

    width: Math.min(800, parent ? parent.width * 0.9 : 800)
    height: Math.min(600, parent ? parent.height * 0.9 : 600)
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0

    modal: true
    padding: 0

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    property var logManager: null
    property var lastOpenTime: 0
    
    LogViewer {
        id: logViewerComponent
        anchors.fill: parent
        logManager: logViewerPopup.logManager
        anchors.margins: 1
    }
    
    footer: DialogButtonBox {
        Button {
            text: "Close"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
    }
    
    onOpened: {
        // Add debouncing to prevent duplicate logs - check time since last open
        var currentTime = Date.now()
        if (logManager && (currentTime - lastOpenTime > 2000)) { // 2 seconds debounce
            logManager.log("INFO", "Log viewer opened by user")
            lastOpenTime = currentTime
        }
    }
    
    Component.onCompleted: {
        // Remove debug log
    }
}
