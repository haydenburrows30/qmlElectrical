import QtQuick
import QtCharts

import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Page {
    id: settings

    property string theme: theme

    MouseArea {
        anchors.fill: parent

        onClicked:  {
            sideBar.close()
        }
    }

    RowLayout {
        spacing: 5

        Button {
            text: "Settings"
            onClicked: settingsDialog.open()
        }
        Button {
            text: "Help"
            onClicked: help()
        }
        Button {
            text: "About"
            onClicked: aboutDialog.open() 
        }
    }

    Dialog {
        id: settingsDialog
        x: Math.round((window.width - width) / 2)
        y: Math.round(window.height / 6)
        width: Math.round(Math.min(window.width, window.height) / 3 * 2)
        modal: true
        focus: true
        title: "Settings"

        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            settingsDialog.close()
        }
        onRejected: {
            settingsDialog.close()
        }

        ColumnLayout {
            id: settingsColumn
            spacing: 20

            RowLayout {
                spacing: 10

                Label {
                    text: "Style:"
                }

                ComboBox {
                    id: themey
                    model: ['Light', 'Dark']
                    flat: true
                    Layout.fillWidth: true
                }
            }
        }
    }

    Dialog {
        id: aboutDialog
        modal: true
        focus: true
        title: "About"
        x: (window.width - width) / 2
        y: window.height / 6
        width: Math.min(window.width, window.height) / 3 * 2
        contentHeight: aboutColumn.height

        Column {
            id: aboutColumn
            spacing: 20

            Label {
                width: aboutDialog.availableWidth
                text: "The Qt Quick Controls module delivers the next generation user interface controls based on Qt Quick."
                wrapMode: Label.Wrap
                font.pixelSize: 12
            }

            Label {
                width: aboutDialog.availableWidth
                text: "In comparison to Qt Quick Controls 1, Qt Quick Controls "
                    + "are an order of magnitude simpler, lighter, and faster."
                wrapMode: Label.Wrap
                font.pixelSize: 12
            }
        }
    }

    Shortcut {
        sequence: "Menu"
        onActivated: optionsMenuAction.trigger()
    }

    Action {
        id: optionsMenuAction
        icon.name: "menu"
        onTriggered: optionsMenu.open()
    }
}