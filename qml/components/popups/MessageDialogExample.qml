import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCharts

MessageDialog {
    id: messageDialog
    text: "The document has been modified."
    informativeText: "Do you want to save your changes?"
    buttons: MessageDialog.Ok | MessageDialog.Cancel

    onButtonClicked: function (button, role) {
        switch (button) {
        case MessageDialog.Ok:
            console.log("OK clicked")
            break;
        case MessageDialog.Cancel:
            console.log("Cancel clicked")
            break;
        }
    }
}