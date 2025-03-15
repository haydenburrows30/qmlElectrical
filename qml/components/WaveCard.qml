import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

Rectangle {
    id: controlRect
    color: Universal.background
    border.width: 1
    border.color: sideBar.toggle1 ? Universal.Dark : "#cccccc"
    radius: 4
    
    property string title: ""
    property bool showSettings: false

    default property alias content: contentItem.data

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Label {
            Layout.fillWidth: true
            text: controlRect.title
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
