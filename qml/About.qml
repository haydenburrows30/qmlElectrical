import QtQuick
import QtQuick.Controls

import ConfigBridge 1.0

Item {
    id: aboutProgram

    width: 400
    height: 200

    property ConfigBridge calculator: ConfigBridge {}

    Column {
        anchors.centerIn: parent
        spacing: 10

        Label {
            id: title
            text: calculator.appName
            font.pixelSize: 20
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            id: version
            text: "Version: " + calculator.version
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            id: style
            text: "Style: " + calculator.style
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
        }
    }
}