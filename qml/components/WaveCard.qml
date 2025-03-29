import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "style"
import "backgrounds"

Rectangle {
    id: controlRect
    color: Universal.background
    border.width: 1
    border.color: sideBar.toggle1 ? Universal.Dark : Qt.lighter("#cccccc",1.1)
    radius: 10
    
    property string title: ""
    property bool showSettings: false
    property bool open: false

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
        anchors.margins: 20
        spacing: Style.spacing

        Label {
            Layout.fillWidth: true
            text: controlRect.title
            font.bold: true
            font.pixelSize: 16
            bottomPadding: 10
        }

        Item {
            id: contentItem
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
