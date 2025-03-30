import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: button.width
    height: button.height + 30 // Fixed height to accommodate messages
    
    property string buttonText: "Click Me"
    property string defaultMessage: "Click for action"
    property string successMessage: "Operation successful!"
    property string errorMessage: "Operation failed!"
    property string waitingMessage: "P"
    property string currentState: "none" // "none", "default", "waiting", "success", "error"
    
    // Add properties to control button behavior during operations
    property bool disableDuringOperation: true
    property bool isProcessing: false
    
    // Add a signal that can be connected to external logic
    signal buttonClicked()
    
    // Start processing - show waiting message
    function startOperation() {
        hideAllMessages()
        currentState = "waiting"
        isProcessing = true
        messageItems["waiting"].show()
    }
    
    // Operation completed successfully
    function operationSucceeded(duration) {
        hideAllMessages()
        currentState = "success"
        isProcessing = false
        messageItems["success"].show()
        
        if (duration && duration > 0) {
            hideMessageTimer.interval = duration
            hideMessageTimer.start()
        }
    }
    
    // Operation failed
    function operationFailed(duration) {
        hideAllMessages()
        currentState = "error"
        isProcessing = false
        messageItems["error"].show()
        
        if (duration && duration > 0) {
            hideMessageTimer.interval = duration
            hideMessageTimer.start()
        }
    }
    
    // Helper function to hide all messages
    function hideAllMessages() {
        hideMessageTimer.stop()
        for (var key in messageItems) {
            messageItems[key].hide()
        }
    }
    
    Button {
        id: button
        text: buttonText
        anchors.top: parent.top
        enabled: !root.disableDuringOperation || !root.isProcessing
        
        onFocusChanged: {
            if (focus && !isProcessing) {
                hideAllMessages()
                currentState = "default"
                messageItems["default"].show()
            } else if (!isProcessing) {
                hideAllMessages()
                currentState = "none"
            }
        }
        
        onClicked: {
            root.buttonClicked()
        }
    }
    
    // Timer to hide messages after duration
    Timer {
        id: hideMessageTimer
        interval: 3000
        repeat: false
        onTriggered: {
            hideAllMessages()
            currentState = "none"
        }
    }
    
    // Common positioning for all messages
    QtObject {
        id: messageLayout
        property point position: Qt.point(button.right + 5, button.top)
    }
    
    // Create property to hold message items
    property var messageItems: ({
        "default": defaultMsg,
        "waiting": waitingMsg,
        "success": successMsg,
        "error": errorMsg
    })
    
    // Default message
    MessageItem {
        id: defaultMsg
        anchors.top: button.top
        anchors.leftMargin: 5
        anchors.left: button.right
        msgType: "default"
        msgText: root.defaultMessage
    }
    
    // Waiting message
    MessageItem {
        id: waitingMsg
        anchors.top: button.top
        anchors.leftMargin: 5
        anchors.left: button.right
        msgType: "info"
        msgText: root.waitingMessage
    }
    
    // Success message
    MessageItem {
        id: successMsg
        anchors.top: button.top
        anchors.leftMargin: 5
        anchors.left: button.right
        msgType: "success"
        msgText: root.successMessage
    }
    
    // Error message
    MessageItem {
        id: errorMsg
        anchors.top: button.top
        anchors.leftMargin: 5
        anchors.left: button.right
        msgType: "error" 
        msgText: root.errorMessage
    }
}
