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
            Layout.leftMargin: 5
            
        }
        // ToolButton {
        //     text: qsTr("Action 2")
        // }
        // empty label to push toggle to right
        Label {
            elide: Label.ElideRight
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            Layout.fillWidth: true
        }

        Switch {
            id: darkModeToggle
            text: qsTr("Mode")
            Layout.alignment: Qt.AlignVCenter
        }
    }
}