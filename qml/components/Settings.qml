import QtQuick
import QtCharts

import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

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