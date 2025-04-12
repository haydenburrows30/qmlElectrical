import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../components"
import "../components/buttons"
import "../components/style"

Page {
    id: cableCalc

    background: Rectangle {
        color: window.modeToggled ? "#1a1a1a" : "#f5f5f5"
    }

    property var cable: [
        { name: qsTr("Cable Ampacity"), source: "../calculators/cable/CableAmpacityCalculator.qml", icon: "electrical_services" },
        { name: qsTr("Charging Current"), source: "../calculators/cable/ChargingCurrentCalculator.qml", icon: "battery_saver" },
        { name: qsTr("Voltage Drop"), source: "../calculators/cable/VoltageDropCalculator.qml", icon: "bolt" },
        { name: qsTr("Transmission Line"), source: "../calculators/cable/TransmissionLineCalculator.qml", icon: "cell_tower" },
        { name: qsTr("Switchboard"), source: "../calculators/cable/SwitchboardPanel.qml", icon: "power" },
        { name: qsTr("Voltage Drop Orion"), source: "../calculators/cable/VoltageDrop.qml", icon: "bolt" }
    ]

    ColumnLayout {
        id: menuText
        anchors.centerIn: parent

        Label {
            id: welcomeHeader
            text: "Basic Calculators"
            font.pixelSize: 32
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 30
        }

        GridLayout {
            id: buttonGrid
            columns: cableCalc.width > 500 ? 3 : 2
            rowSpacing: 20
            columnSpacing: 20

            Repeater {
                model: cable

                HButton {
                    id: hbuttonParent
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    icon.source: "../../icons/rounded/" + modelData.icon + ".svg"
                    back: Qt.lighter(palette.accent, 1.5)
                    fore: Qt.lighter(palette.accent, 1.0)

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
                        calculatorLoader.push(modelData.source)
                    }

                    HoverHandler {
                        onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
                    }
                }
            }
        }
    }
}