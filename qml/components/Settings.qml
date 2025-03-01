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
        switch(icon_style.currentIndex) {
            case 0: iconFont.source = "../fonts/MaterialIcons-Regular.ttf"; break;
            case 1: iconFont.source = "../fonts/MaterialIconsRound-Regular.otf"; break;
            case 2: iconFont.source = "../fonts/MaterialIconsSharp-Regular.otf"; break;
            case 3: iconFont.source = "../fonts/MaterialIconsOutlined-Regular.otf"; break;
            case 4: iconFont.source = "../fonts/MaterialIconsTwoTone-Regular.otf"; break;
        }
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
                text: "Icon Style:"
            }

            ComboBox {
                id: icon_style
                model: ['Regular', 'Round', 'Sharp', 'Outlined', 'Two Tone']
                flat: true
                Layout.fillWidth: true
            }
        }
    }
}