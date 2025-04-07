import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Menu {
    id: logsMenu
    
    property var logManager: null
    
    MenuItem {
        text: "View Logs"
        onTriggered: {
            var appWindow = window || applicationWindow
            if (appWindow) {
                if (appWindow.openLogViewer) {
                    // Use the global function
                    appWindow.openLogViewer()
                } else if (appWindow.logViewerPopup) {
                    appWindow.logViewerPopup.open()
                } else {
                    console.error("Could not find log viewer popup")
                }
            }
        }
    }
    
    MenuItem {
        text: "Open Log File"
        onTriggered: {
            if (logManager) {
                logManager.openLogFile()
            }
        }
    }
    
    MenuItem {
        text: "Open Log Directory"
        onTriggered: {
            if (logManager) {
                var logDir = logManager.getLogDirectory()
                if (platform.system() === "Windows") {
                    Qt.openUrlExternally("file:///" + logDir.replace(/\\/g, "/"))
                } else {
                    Qt.openUrlExternally("file://" + logDir)
                }
            }
        }
    }
    
    MenuSeparator {}
    
    MenuItem {
        text: "Clear Logs"
        onTriggered: {
            if (logManager) {
                logManager.clearLogs()
            }
        }
    }
}
