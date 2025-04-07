import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../components"
import "../components/buttons"
import "../components/style"

Page {
    id: theoryCalc

    background: Rectangle {
        color: window.modeToggled ? "#1a1a1a" : "#f5f5f5"
    }

    property var theory: [
        { name: qsTr("Transformer Calculator"), source: "../components/calculators/TransformerCalculator.qml", icon: "air" },
        { name: qsTr("Harmonics Analysis"), source: "../components/calculators/HarmonicsAnalyzer.qml", icon: "air" },
        { name: qsTr("Machine Calculator"), source: "../components/calculators/ElectricMachineCalculator.qml", icon: "air" },
        { name: qsTr("Motor Starting"), source: "../components/calculators/MotorStartingCalculator.qml", icon: "air" },
        { name: qsTr("RLC"), source: "../components/calculators/RLC.qml", icon: "air" },
        { name: qsTr("Realtime"), source: "../components/calculators/RealTime.qml", icon: "air" },
        { name: qsTr("Three Phase"), source: "../components/calculators/ThreePhase.qml", icon: "air" }
    ]

    ColumnLayout {
        id: menuText
        anchors.centerIn: parent

        Label {
            id: welcomeHeader
            text: "Theory Calculators"
            font.pixelSize: 32
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 30
        }

        GridLayout {
            id: buttonGrid
            columns: theoryCalc.width > 500 ? 3 : 2
            rowSpacing: 20
            columnSpacing: 20

            Repeater {
                model: theory

                HButton {
                    id: hbuttonParent
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    icon.source: "../../icons/svg/" + modelData.icon + "/baseline.svg"
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