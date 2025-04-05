import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ConfigBridge 1.0

Popup {
    id: aboutProgram

    width: 600
    height: 300

    anchors.centerIn: Overlay.overlay

    property ConfigBridge calculator: ConfigBridge {}

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
            text: calculator.appName
            font.pixelSize: 16
            font.bold: true
        }

        Label {
            text: "Version:"
            font.pixelSize: 16
        }

        Label {
            text: calculator.version
            font.pixelSize: 16
            font.bold: true
        }

        Label {
            text: "Style:"
            font.pixelSize: 16
        }

        Label {
            text: calculator.style
            font.pixelSize: 16
            font.bold: true
        }

        Label {
            text: "Platform:"
            font.pixelSize: 16
        }

        Label {
            text: calculator.system
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
            text: calculator.system_version
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            font.bold: true
        }

        Label {
            text: "Python Version:"
            font.pixelSize: 16
        }

        Label {
            text: calculator.python_version
            font.pixelSize: 16
            font.bold: true
        }

        Label {
            text: "Qt Version:"
            font.pixelSize: 16
        }

        Label {
            text: calculator.qt_version
            font.pixelSize: 16
            font.bold: true
        }
    }
}