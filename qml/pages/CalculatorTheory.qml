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
        { name: qsTr("Transformer Calculator"), source: "../calculators/theory/TransformerCalculator.qml", icon: "calculate" },
        { name: qsTr("Harmonics Analysis"), source: "../calculators/theory/HarmonicsAnalyzer.qml", icon: "troubleshoot" },
        { name: qsTr("Machine Calculator"), source: "../calculators/theory/ElectricMachineCalculator.qml", icon: "forward_circle" },
        { name: qsTr("Motor Starting"), source: "../calculators/theory/MotorStartingCalculator.qml", icon: "show_chart" },
        { name: qsTr("RLC"), source: "../calculators/theory/RLC.qml", icon: "general_device" },
        { name: qsTr("Realtime"), source: "../calculators/theory/RealTime.qml", icon: "timeline" },
        { name: qsTr("Three Phase"), source: "../calculators/theory/ThreePhase.qml", icon: "density_medium" },
        { name: qsTr("Instrument Tx Naming"), source: "../calculators/theory/TransformerNamingGuide.qml", icon: "density_medium" }
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