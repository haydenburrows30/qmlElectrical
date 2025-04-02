import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../style"

Item {
    id: root
    width: button.width
    height: button.height //+ 30 // Fixed height to accommodate messages

    property string title: ""
    property string buttonText: ""
    property string defaultMessage: ""
    property string successMessage: "Operation successful!"
    property string errorMessage: "Operation failed!"
    property string waitingMessage: "Waiting"
    property string infoMessage: "Information"
    property string currentState: "none" // "none", "default", "waiting", "success", "error", "info"s

    property string buttonColor: Style.blueGreen
    property string buttonIcon: "\ue145"
    property bool textVisible: true

    // Add properties to control button behavior during operations
    property bool disableDuringOperation: true
    property bool isProcessing: false

    ToolTip.text: ""
    ToolTip.visible: buttonBackground.hovered
    ToolTip.delay: 1000
    ToolTip.timeout: 1000
    
    // Add a signal that can be connected to external logic
    signal buttonClicked()
    
    // Start processing - show waiting message
    function startOperation() {
        showMessage("waiting")
    }
    
    // Operation completed successfully
    function operationSucceeded(duration) {
        showMessage("success", duration)
    }
    
    // Operation failed
    function operationFailed(duration) {
        showMessage("error", duration)
    }

    // Operation info
    function operationInfo(duration) {
        showMessage("info", duration)
    }
    
    // Helper function to show a specific message type
    function showMessage(type, duration) {
        hideMessage()
        currentState = type
        isProcessing = (type === "waiting")
        
        // Prepare the message properties
        var msgProps = {
            msgType: type === "waiting" ? "info" : type,
            msgText: root[type + "Message"]
        }
        
        // Create and show the message
        messageLoader.setSource("MessageItem.qml", msgProps)
        messageLoader.item.show()
        
        if (duration && duration > 0 && type !== "waiting") {
            hideMessageTimer.interval = duration
            hideMessageTimer.start()
        }
    }
    
    // Helper function to hide all messages
    function hideMessage() {
        hideMessageTimer.stop()
        if (messageLoader.item) {
            messageLoader.item.hide()
        }
    }

    // Button
    ColumnLayout {
        id: button
        anchors.centerIn: parent
       
        ShadowRectangle {
            id: buttonBackground

            Layout.alignment: Qt.AlignHCenter

            implicitHeight: 52
            implicitWidth: 52
            radius: implicitHeight / 2
            
            ImageButton {
                text: buttonText
                enabled: !root.disableDuringOperation || !root.isProcessing

                anchors.centerIn: parent

                iconName: buttonIcon
                iconWidth: 24
                iconHeight: 24
                color: buttonColor
                backgroundColor: Style.alphaColor(color,0.1)

                onFocusChanged: {
                    if (focus && !isProcessing) {
                        showMessage("default")
                    } else if (!isProcessing) {
                        hideMessage()
                        currentState = "none"
                    }
                }
                
                onClicked: {
                    root.buttonClicked()
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10
            font.pixelSize: 14
            font.bold: Font.Bold
            font.weight: Font.Medium
            text: root.title
            visible: textVisible
        }
    }

    // Timer to hide messages after duration
    Timer {
        id: hideMessageTimer
        interval: 3000
        repeat: false
        onTriggered: {
            hideMessage()
            currentState = "none"
        }
    }
    
    // Common positioning for all messages
    QtObject {
        id: messageLayout
        function getOverlayPosition() {
            // Get the absolute position of the button in the window coordinates
            var buttonGlobalPos = button.mapToItem(null, 0, 0);
            // Get the absolute position of root in the window coordinates
            var rootGlobalPos = root.mapToItem(null, 0, 0);
            
            // Calculate the position beside the button
            var targetX = rootGlobalPos.x + button.width + 10;
            var targetY = rootGlobalPos.y + (button.height - 30) / 2; // Center vertically
            
            // Return the position adjusted for overlay coordinates
            return {x: targetX, y: targetY};
        }
        
        // Add a window reference for position updates
        property var window: Window.window
    }
    
    // Single Loader for all message types
    Loader {
        id: messageLoader
        parent: Overlay.overlay
        
        // Update position whenever any relevant property changes
        function updatePosition() {
            if (item) {
                var pos = messageLayout.getOverlayPosition()
                x = pos.x
                y = pos.y
            }
        }
        
        // Keep position updated with connections
        Connections {
            target: messageLayout.window
            function onWidthChanged() { messageLoader.updatePosition() }
            function onHeightChanged() { messageLoader.updatePosition() }
            function onXChanged() { messageLoader.updatePosition() }
            function onYChanged() { messageLoader.updatePosition() }
        }
        
        Connections {
            target: root
            function onXChanged() { messageLoader.updatePosition() }
            function onYChanged() { messageLoader.updatePosition() }
            function onWidthChanged() { messageLoader.updatePosition() }
            function onHeightChanged() { messageLoader.updatePosition() }
        }
        
        Connections {
            target: button
            function onXChanged() { messageLoader.updatePosition() }
            function onYChanged() { messageLoader.updatePosition() }
            function onWidthChanged() { messageLoader.updatePosition() }
            function onHeightChanged() { messageLoader.updatePosition() }
        }
        
        // Update position when component is loaded
        onLoaded: {
            updatePosition()
        }
    }
    
    // Create property to hold message items for backward compatibility
    property var messageItems: ({
        "default": { show: function() { showMessage("default"); }, hide: function() { hideMessage(); } },
        "waiting": { show: function() { showMessage("waiting"); }, hide: function() { hideMessage(); } },
        "success": { show: function() { showMessage("success"); }, hide: function() { hideMessage(); } },
        "error": { show: function() { showMessage("error"); }, hide: function() { hideMessage(); } },
        "info": { show: function() { showMessage("info"); }, hide: function() { hideMessage(); } }
    })
}
