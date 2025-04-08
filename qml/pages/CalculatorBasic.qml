import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../components"
import "../components/buttons"
import "../components/style"

Page {
    id: basicCalc

    background: Rectangle {
        color: window.modeToggled ? "#1a1a1a" : "#f5f5f5"
    }

    property var basic: [
        { name: qsTr("Impedance Calculator"), source: "../components/calculators/ImpedanceCalculator.qml", icon: "function" },
        { name: qsTr("kVA / kw / A"), source: "../components/calculators/PowerCurrentCalculator.qml", icon: "electric_meter" },
        { name: qsTr("Unit Converter"), source: "../components/calculators/UnitConverter.qml", icon: "change_circle" },
        { name: qsTr("Power Factor Correction"), source: "../components/calculators/PowerFactorCorrection.qml", icon: "trending_down" },
        { name: qsTr("Ohm's Law"), source: "../components/calculators/OhmsLawCalculator.qml", icon: "calculate" },
        { name: qsTr("Voltage Divider"), source: "../components/calculators/VoltageDividerCalculator.qml", icon: "call_split" }
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
            columns: basicCalc.width > 500 ? 3 : 2
            rowSpacing: 20
            columnSpacing: 20

            Repeater {
                model: basic

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