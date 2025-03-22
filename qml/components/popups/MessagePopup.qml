import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    width: 400
    height: 200
    
    property string messageText: ""
    property bool isError: false
    
    function showSuccess(message) {
        messageText = message
        isError = false
        open()
    }
    
    function showError(message) {
        messageText = message
        isError = true
        open()
    }

    contentItem: ColumnLayout {
        Label {
            text: root.messageText
            wrapMode: Text.WordWrap
            color: root.isError ? "red" : (sideBar.toggle1 ? "#ffffff" : "#000000")
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }
        Button {
            text: "OK"
            Layout.alignment: Qt.AlignHCenter
            onClicked: root.close()
        }
    }
}
