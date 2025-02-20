import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    id: myWindow

    width: 200
    height: 200

    flags:  Qt.Window | Qt.WindowSystemMenuHint
            | Qt.WindowTitleHint | Qt.WindowMinimizeButtonHint
            | Qt.WindowMaximizeButtonHint | Qt.WindowStaysOnTopHint


    visible: true
    modality: Qt.NonModal // no need for this as it is the default value


    Rectangle {
        color: "lightskyblue"
        anchors.fill: parent
        Text {
            text: "Hello !"
            color: "navy"
            anchors.centerIn: parent
        }
    }
}