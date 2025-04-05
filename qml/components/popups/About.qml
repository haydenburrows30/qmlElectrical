import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ConfigBridge 1.0

Popup {
    id: aboutProgram

    width: 400
    height: 300

    anchors.centerIn: Overlay.overlay

    property ConfigBridge calculator: ConfigBridge {}

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        Label {
            id: title
            text: calculator.appName
            font.pixelSize: 20
            font.bold: true
        }

        Label {
            id: version
            text: "Version: " + calculator.version
            font.pixelSize: 16
        }

        Label {
            id: style
            text: "Style: " + calculator.style
            font.pixelSize: 16
        }

        Label {
            id: system
            text: "Platform: " + calculator.system
            font.pixelSize: 16
        }

        Label {
            id: systemVersion
            Layout.maximumWidth: 360
            text: "System: " + calculator.system_version
            font.pixelSize: 16
            wrapMode: Text.WordWrap
        }

        Label {
            id: pythonVersion
            text: "Python Version: " + calculator.python_version
            font.pixelSize: 16
        }
    }
}