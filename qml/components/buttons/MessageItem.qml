import QtQuick 2.15
import QtQuick.Controls 2.15

InlineMessage {
    id: root
    
    property string msgType: "default"
    property string msgText: ""
    
    // Common properties
    opacity: 0
    visible: opacity > 0
    
    // Add high z-value to appear above parent elements
    z: 9999
    
    // Set message type and text based on properties
    messageType: msgType
    
    // Assign text to appropriate property based on message type
    defaultMessage: msgType === "default" ? msgText : ""
    successMessage: msgType === "success" ? msgText : ""
    errorMessage: msgType === "error" ? msgText : ""
    infoMessage: msgType === "info" ? msgText : ""
    
    // Smooth fade animation
    Behavior on opacity { 
        NumberAnimation { 
            duration: 150
            easing.type: Easing.InOutQuad
        }
    }
    
    // Function to show this message
    function show() {
        opacity = 1
    }
    
    // Function to hide this message
    function hide() {
        opacity = 0
    }
}
