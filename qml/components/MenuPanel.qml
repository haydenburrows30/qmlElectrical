import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal

import QtQuick.Studio.DesignEffects

Rectangle {
    id: menuPanel
    width: 391
    height: 725
    color: "transparent"

    Rectangle {
        id: background
        color: "#45d9d9d9"
        radius: 30
        border.color: "#ededed"
        border.width: 1
        anchors.fill: parent
    }

    Rectangle {
        id: menuColumn
        width: 350
        height: 613
        color: "transparent"
        anchors.verticalCenter: parent.verticalCenter
        ColumnLayout {
            id: menuColumn_layout
            anchors.fill: parent
            spacing: 19
            MenuButton {
                id: menuItem1
                state: "state_idle"
                menuText: "Draggable Panel"
                Layout.preferredWidth: 350
                Layout.preferredHeight: 60
                onClicked: {
                    console.log("clicked1")
                }
            }

            MenuButton {
                id: menuItem2
                state: "state_hover"
                Layout.preferredWidth: 350
                Layout.preferredHeight: 60
            }

            MenuButton {
                id: menuItem3
                state: "state_idle"
                Layout.preferredWidth: 350
                Layout.preferredHeight: 60
            }

            MenuButton {
                id: menuItem4
                state: "state_idle"
                Layout.preferredWidth: 350
                Layout.preferredHeight: 60
            }

            MenuButton {
                id: menuItem5
                state: "state_idle"
                Layout.preferredWidth: 350
                Layout.preferredHeight: 60
            }

            MenuButton {
                id: menuItem6
                state: "state_idle"
                Layout.preferredWidth: 350
                Layout.preferredHeight: 60
            }

            MenuButton {
                id: menuItem7
                state: "state_idle"
                Layout.preferredWidth: 350
                Layout.preferredHeight: 60
            }

            MenuButton {
                id: menuItem8
                state: "state_idle"
                Layout.preferredWidth: 350
                Layout.preferredHeight: 60
            }
        }
        anchors.verticalCenterOffset: 5
        anchors.horizontalCenterOffset: 3
        anchors.horizontalCenter: parent.horizontalCenter
    }
}