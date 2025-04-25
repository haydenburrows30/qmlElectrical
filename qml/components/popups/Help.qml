import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: aboutProgram

    width: 500
    height: 180
    modal: true

    anchors.centerIn: Overlay.overlay

    GridLayout {
        anchors.centerIn: parent
        anchors.margins: 20
        columns: 2

        Label {
            id: title
            text: "Help"
            font.pixelSize: 20
            font.bold: true
            Layout.columnSpan: 2
            Layout.bottomMargin: 10
        }

        Label {
            id: help
            text: "For help with the calculator and calculations visit:"
            Layout.columnSpan: 2
        }

        Label {
            id: linkText
            text: '<a href="https://github.com/haydenburrows30/qmlElectrical/wiki">https://github.com/haydenburrows30/qmlElectrical/wiki</a>'
            font.pixelSize: 16
            textFormat: Text.RichText
            color: "blue"
            wrapMode: Text.Wrap
            
            onLinkActivated: function(linkUrl) {
                Qt.openUrlExternally(linkUrl)
            }
            
            Layout.columnSpan: 2
        }
    }
}