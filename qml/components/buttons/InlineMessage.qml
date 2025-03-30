import QtQuick
import QtQuick.Controls

Rectangle {
    id: messageBox
    
    property string defaultMessage: "Default message"
    property string successMessage: "Success!"
    property string errorMessage: "Error occurred"
    property string warningMessage: "Warning!"
    property string infoMessage: "Information"
    
    property string currentMessage: defaultMessage
    property string messageType: "default" // can be "default", "success", "error", "warning", "info"
    
    // property bool visible: false
    
    width: messageText.width + 20
    height: messageText.height + 10
    radius: 5
    opacity: visible ? 1.0 : 0.0
    
    // Color based on message type
    color: {
        if (messageType === "success") return "#DFF2BF"
        else if (messageType === "error") return "#FFBABA"
        else if (messageType === "warning") return "#FEEFB3"
        else if (messageType === "info") return "#BDE5F8"
        else return "#F0F0F0"
    }
    
    border.color: {
        if (messageType === "success") return "#4F8A10"
        else if (messageType === "error") return "#D8000C"
        else if (messageType === "warning") return "#9F6000"
        else if (messageType === "info") return "#00529B"
        else return "#D0D0D0"
    }
    border.width: 1
    
    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }
    
    Text {
        id: messageText
        text: {
            if (messageType === "success") return successMessage
            else if (messageType === "error") return errorMessage
            else if (messageType === "warning") return warningMessage
            else if (messageType === "info") return infoMessage
            else return defaultMessage
        }
        anchors.centerIn: parent
        color: {
            if (messageType === "success") return "#4F8A10"
            else if (messageType === "error") return "#D8000C"
            else if (messageType === "warning") return "#9F6000"
            else if (messageType === "info") return "#00529B"
            else return "#303030"
        }
    }
}
