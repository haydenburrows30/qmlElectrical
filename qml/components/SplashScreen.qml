import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: splashScreen
    modal: true
    closePolicy: Popup.NoAutoClose
    anchors.centerIn: parent
    width: 400
    height: 300
    
    // Keep splash screen visible until explicitly closed
    visible: true
    
    background: Rectangle {
        color: "#242424"
        radius: 10
        border.color: "#555555"
        border.width: 1
    }
    
    // Enhanced progress properties
    property real progress: preloadManager ? preloadManager.progress : loadingManager.progress
    property string statusMessage: preloadManager ? preloadManager.statusMessage : "Loading application..."
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        
        Image {
            source: "../icons/app_logo.png"  // Adjust path to your logo
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 100
        }
        
        Text {
            text: applicationTitle
            color: "#ffffff"
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        Text {
            text: splashScreen.statusMessage
            color: "#cccccc"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
        
        ProgressBar {
            id: loadingBar
            value: splashScreen.progress
            from: 0.0
            to: 1.0
            Layout.fillWidth: true
            Layout.preferredHeight: 10
            
            background: Rectangle {
                implicitWidth: 200
                implicitHeight: 10
                color: "#333333"
                radius: 5
            }
            
            contentItem: Item {
                implicitWidth: 200
                implicitHeight: 10
                
                Rectangle {
                    width: loadingBar.visualPosition * parent.width
                    height: parent.height
                    radius: 5
                    color: "#21be2b"
                }
            }
        }
        
        // Version info
        Text {
            text: "Version " + appVersion
            color: "#888888"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
        }
    }
    
    // Close the splash screen when loading is complete
    // or after minimum display time
    Timer {
        id: minimumDisplayTimer
        interval: 1500  // Minimum 1.5 seconds to display splash
        running: true
        repeat: false
    }
    
    Connections {
        target: preloadManager
        function onLoadingFinished() {
            closeSplashIfReady()
        }
    }
    
    Connections {
        target: loadingManager
        function onLoadingChanged() {
            if (!loadingManager.loading) {
                closeSplashIfReady()
            }
        }
    }
    
    function closeSplashIfReady() {
        // Only close if minimum display time has elapsed and loading is complete
        if (minimumDisplayTimer.running) {
            return; // Don't close until minimum time has elapsed
        }
        
        if (preloadManager && preloadManager.progress < 1.0) {
            return; // Still preloading components
        }
        
        if (loadingManager.loading) {
            return; // Still loading other resources
        }
        
        // All conditions met, close the splash screen
        splashScreen.close()
    }
    
    Component.onCompleted: {
        // Connect timer finished to the same check
        minimumDisplayTimer.triggered.connect(closeSplashIfReady)
    }
}