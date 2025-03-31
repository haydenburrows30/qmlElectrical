import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../style"
import "../backgrounds"

Rectangle {
    // border.width: 1
    // border.color: sideBar.toggle1 ? Universal.Dark : Qt.lighter("#cccccc",1.1)
    radius: 20

    color: Universal.background

    default property alias content: contentItem.data

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: 10
    }
}