import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../components"
import "../components/buttons"
import "../components/style"
import "../components/menus"

Page {

    ColumnLayout {
        id: menuText
        anchors.centerIn: parent

        Label {
            id: welcomeHeader
            text: "Renewable Calculators"
            font.pixelSize: 32
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 30
        }

        GridLayout {
            id: buttonGrid
            columns: width > 500 ? 3 : 2
            rowSpacing: 20
            columnSpacing: 20

            Repeater {
                model: MenuItems.renewables

                HomeButton {
                    id: hbuttonParent
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    icon.source: "../../icons/rounded/" + modelData.icon + ".svg"

                    Behavior on scale { NumberAnimation { duration: 100 } }

                    Item {
                        anchors.fill: parent
                        Text {
                            text: modelData.name
                            width: hbuttonParent.width
                            font.bold: true
                            font.pixelSize: 16
                            color: palette.buttonText
                            horizontalAlignment: Text.AlignHCenter 

                            wrapMode: Text.Wrap
                            anchors {
                                top: parent.top
                                topMargin: 8
                                horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                    
                    onClicked: {
                        calculatorLoader.push("../" + modelData.source)
                    }

                    HoverHandler {
                        onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
                    }
                }
            }
        }
    }
}