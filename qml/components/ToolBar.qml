import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import '..'

ToolBar {
    id:toolBar
    property bool toggle : {darkModeToggle.checked}

    background: Rectangle {
        implicitHeight: 60
        opacity: 0
    }

    signal mySignal()

    RowLayout {
        anchors.fill: parent

        RoundButton {
            text: qsTr("...")
            implicitWidth: 40
            implicitHeight: 40
            onClicked: {
                mySignal()
            }
            radius: 20
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 10
            
        }
        // empty label to push toggle to right
        Label {
            elide: Label.ElideRight
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            Layout.fillWidth: true
        }

        Switch {
            id: darkModeToggle
            // text: qsTr("Mode")
            Layout.alignment: Qt.AlignVCenter
            // contentItem: Text {
            //     text: parent.texts
            //     anchors.right: parent.left
            // }
        }
    }
}