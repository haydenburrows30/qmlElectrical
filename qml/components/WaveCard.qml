import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

Rectangle {
    id: controlRect
    color: Universal.background
    border.width: 1
    border.color: sideBar.toggle1 ? Universal.Dark : Qt.lighter("#cccccc",1.1)
    radius: 4
    
    property string title: ""
    property bool showSettings: false
    property bool open: false

    // property var popupContent: Item {}

    // property var popupParent: {"width": 0, "height": 0}

    default property alias content: contentItem.data

    // Popup {
    //     id: helpPopup
    //     width: popupContent.width
    //     height: popupContent.height
    //     x: popupParent["width"]/2 - width / 2
    //     y: popupParent["height"] //- height
    //     modal: true
    //     focus: true
    //     closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    //     contentItem : popupContent

    // }

    Button {
        id: helpButton
        text: "i"
        anchors.right: parent.right
        anchors.top: parent.top
        visible: showSettings
        onClicked: open = true //| helpPopup.open()
    }

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
