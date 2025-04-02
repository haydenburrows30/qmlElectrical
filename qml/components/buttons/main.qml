import QtQuick
import QtQuick.Control
import QtQuick.Window
import QtQuick.Layouts

Window {
    width: 400
    height: 300
    visible: true
    title: "Inline Message Demo"
    
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20
        
        MessageButton {
            id: saveButton
            buttonText: "Save"
            defaultMessage: "Click to save your document"
        }
        
        MessageButton {
            id: deleteButton
            buttonText: "Delete"
            defaultMessage: "Click to delete the item"
            successMessage: "Item deleted successfully!"
            errorMessage: "Failed to delete item!"
        }
        
        Button {
            text: "Set Focus Here"
            onClicked: focus = true
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
