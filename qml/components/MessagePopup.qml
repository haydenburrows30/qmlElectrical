import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: messagePopup
    
    width: messageText.width + 60
    height: messageLayout.height + 40
    modal: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    property string message: ""
    property bool isError: false
    
    background: Rectangle {
        color: isError ? "#FFEBEE" : "#E8F5E9"
        border.color: isError ? "#F44336" : "#4CAF50"
        border.width: 1
        radius: 5
    }
    
    function showSuccess(msg) {
        message = msg
        isError = false
        open()
        closeTimer.restart()
    }
    
    function showError(msg) {
        message = msg
        isError = true
        open()
        closeTimer.restart()
    }
    
    Timer {
        id: closeTimer
        interval: 3000
        onTriggered: messagePopup.close()
    }
    
    ColumnLayout {
        id: messageLayout
        anchors.centerIn: parent
        spacing: 10
        
        Text {
            id: messageText
            text: messagePopup.message
            color: messagePopup.isError ? "#D32F2F" : "#2E7D32"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
