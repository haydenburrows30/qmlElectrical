import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "components"
import "components/calculators"
import "components/buttons"
import "components/style"
import "components/popups"
import "pages"

ApplicationWindow {
    id: window
   
    minimumWidth: 1280
    minimumHeight: 860
    visible: true
    
    // Make logViewerPopup and logManagerInstance explicit properties
    // so that other QML components can access them through the window
    property var logViewerPopup: logViewerPopupInstance
    property var logManagerInstance: null

    SineWaveModel {id: sineModel}
    VoltageDrop {id: voltageDrop}
    ResultsManager {id: resultsManager}

    SplashScreen {
        id: splashScreen
    }

    LogViewerPopup {
        id: logViewerPopupInstance
        logManager: logManagerInstance
    }

    // Timer to initialize logManager after it's available from C++
    Timer {
        interval: 10
        running: true
        repeat: false
        onTriggered: {
            // Set the log manager instance if it's available
            if (typeof logManager !== 'undefined') {
                logManagerInstance = logManager
                console.log("Log manager initialized")
                // Log app startup
                logManager.log("INFO", "Application started successfully")
            } else {
                console.error("Log manager not available after timeout")
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (!loadingManager.loading) {
                splashScreen.close()
            }
        }
    }

    

    Item {
        anchors.fill: parent

        StackView {
            id: stackView
            objectName: "stackView"
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                leftMargin: 0
                right: parent.right
            }
            z: 1
            Component.onCompleted: stackView.push(Qt.resolvedUrl("pages/Home.qml"),StackView.Immediate)
        }
        
        // Add logs button at the bottom right
        Button {
            id: logsButton
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            text: "Logs"
            icon.source: "../icons/svg/article/baseline.svg"
            
            ToolTip.visible: hovered
            ToolTip.text: "View application logs"
            
            onClicked: {
                console.log("Opening log viewer from main screen button")
                if (logViewerPopupInstance) {
                    logViewerPopupInstance.open()
                }
            }
            
            // Show indicator when there are new errors or warnings
            Rectangle {
                visible: logManagerInstance && logManagerInstance.count > 0
                width: 10
                height: 10
                radius: 5
                color: "red"
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: -2
                anchors.topMargin: -2
            }
        }
    }

    Settings {
        id: settings
        property real menuX
        property real menuY
    }

    Universal.theme: sideBar.modeToggled ? Universal.Dark : Universal.Light
    Universal.accent: sideBar.modeToggled ? Universal.Red : Universal.Cyan

    // Expose a global function to open logs from anywhere in the app
    function openLogViewer() {
        console.log("openLogViewer function called")
        if (logViewerPopupInstance) {
            logViewerPopupInstance.open()
        } else {
            console.error("Log viewer popup not available")
        }
    }
}
