import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: aboutProgram

    width: 600
    height: 400
    modal: true

    anchors.centerIn: Overlay.overlay

    property var configBridge

    GridLayout {
        anchors.fill: parent
        anchors.margins: 20
        columns: 2

        Label {
            id: title
            text: "About"
            font.pixelSize: 20
            font.bold: true
            Layout.columnSpan: 2
            Layout.bottomMargin: 10
        }

        Label {
            text: "App Name:"
            font.pixelSize: 16
        }

        Label {
            text: configBridge.appName
            font.pixelSize: 16
            font.bold: true
        }

        Label {
            text: "Version:"
            font.pixelSize: 16
        }

        Label {
            text: configBridge.version
            font.pixelSize: 16
            font.bold: true
        }

        Label {
            text: "Style:"
            font.pixelSize: 16
        }

        Label {
            text: configBridge.style
            font.pixelSize: 16
            font.bold: true
        }

        Label {
            text: "Platform:"
            font.pixelSize: 16
        }

        Label {
            text: configBridge.platform
            font.pixelSize: 16
            font.bold: true
        }

        Label {
            text: "System:"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignTop
        }

        Label {
            Layout.maximumWidth: 440
            text: configBridge.system_version
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            font.bold: true
        }

        Label {
            text: "Python Version:"
            font.pixelSize: 16
        }

        Label {
            text: configBridge.python_version
            font.pixelSize: 16
            font.bold: true
        }

        Label {
            text: "Qt Version:"
            font.pixelSize: 16
        }

        Label {
            text: configBridge.qt_version
            font.pixelSize: 16
            font.bold: true
        }

        Label {
            text: "Processor:"
            font.pixelSize: 16
        }

        Label {
            text: configBridge.processor
            font.pixelSize: 16
            font.bold: true
        }

        Label {
            id: help
            text: "Help"
            font.pixelSize: 20
            font.bold: true
            Layout.columnSpan: 2
            Layout.bottomMargin: 10
            Layout.topMargin: 10
        }

        Label {
            id: linkText
            text: '<a href="https://github.com/haydenburrows30/qmlElectrical/wiki">https://github.com/haydenburrows30/qmlElectrical/wiki</a>'
            font.pixelSize: 16
            textFormat: Text.RichText
            color: "blue"
            wrapMode: Text.Wrap
            Layout.columnSpan: 2
            
            onLinkActivated: function(linkUrl) {
                Qt.openUrlExternally(linkUrl)
            }
        }
    }
}