import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "style"

Rectangle {
    id: controlRect
    color: sideBar.modeToggled ? "#000000" : "#ffffff"
    border.width: 1
    border.color: sideBar.modeToggled ? Universal.Dark : Qt.lighter("#cccccc",1.1)
    radius: 10
    
    property string title: ""
    property bool showSettings: false //show help button
    property bool open: false
    property bool titleVisible: true  //enable/disable the title

    default property alias content: contentItem.data

    RoundButton {
        id: helpButton
        text: "i"
        anchors.right: parent.right
        anchors.top: parent.top
        visible: showSettings
        onClicked: open = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: titleVisible ? 20 : 10 // change margins if title not visible
        
        Label {
            Layout.fillWidth: true
            text: controlRect.title
            font.bold: true
            font.pixelSize: 16
            bottomPadding: 10
            visible: titleVisible
        }

        Item {
            id: contentItem
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
