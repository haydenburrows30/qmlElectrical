import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ConfigBridge 1.0

Popup {
    id: aboutProgram

    width: 600
    height: 300

    anchors.centerIn: Overlay.overlay

    property ConfigBridge configBridge

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
    }
}