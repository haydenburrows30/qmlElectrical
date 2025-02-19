import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

MenuBar {

    property bool toggle : {darkModeToggle.checked}

    background: Rectangle {
        height: 1
        color: "#21be2b"
        width: parent.width
        anchors.bottom: parent.bottom
    }

    Menu {
        title: qsTr("File")
        Action { text: qsTr("New...") }
        Action { text: qsTr("Open...") }
        Action { text: qsTr("Save") }
        Action { text: qsTr("Save As...") }
        MenuSeparator { }
        Action { text: qsTr("Quit") }
    }
    Menu {
        title: qsTr("Edit")
        Action { text: qsTr("Cut") }
        Action { text: qsTr("Copy") }
        Action { text: qsTr("Paste") }
    }
    Menu {
        title: qsTr("Help")
        Action { text: qsTr("About") }
        Switch {
            id: darkModeToggle
            text: qsTr("Dark mode")
        }
    }
}