import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../components"
import "../components/buttons/"
import "../components/playground/"
import "../components/style"

import "../../scripts/MaterialDesignRegular.js" as MD

Page {

    FontLoader {
        id: iconFont
        source: "../../icons/MaterialIcons-Regular.ttf"
    }
    
    ColumnLayout {

        anchors.fill: parent

        CalculatorPad {}

        RowLayout {

            PrefsTabButton {
                title: "Rotate"
                textIcon: '\ue030'
            }

            DevicesTile {
                iconImage: "qrc:/icons/gallery/24x24/Reset.svg"
            }

            ShadowRectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: 52
                implicitWidth: 52

                ImageButton {
                    anchors.centerIn: parent
                    iconName: '\ue5d2'
                    iconWidth: 24
                    iconHeight: 24
                    color: sideBar.toggle1 ? Style.blue : Style.red
                    backgroundColor: sideBar.toggle1 ? Style.alphaColor(color,0.6) : Style.alphaColor(color,0.1)
                }
            }
        }
    }
}
