import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    default property alias content: contentItem.data
    property string title: ""

    color: "white"
    border.color: "#cccccc"
    border.width: 1
    radius: 4

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Label {
            Layout.fillWidth: true
            text: root.title
            font.bold: true
            font.pixelSize: 16
        }

        Item {
            id: contentItem
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
