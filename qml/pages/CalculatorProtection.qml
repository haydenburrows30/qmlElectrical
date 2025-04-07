import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../components"
import "../components/buttons"
import "../components/style"

Page {
    id: protectionCalc
    background: Rectangle {
        color: window.modeToggled ? "#1a1a1a" : "#f5f5f5"
    }

    property var protection: [
        { name: qsTr("Discrimination Analysis"), source: "components/calculators/DiscriminationAnalyzer.qml", icon: "show_chart"},
        { name: qsTr("Protection Relay"), source: "components/calculators/ProtectionRelayCalculator.qml", icon: "devices" },
        { name: qsTr("Instrument Transformer"), source: "components/calculators/InstrumentTransformerCalculator.qml", icon: "transform" },
        { name: qsTr("Earthing Calculator"), source: "components/calculators/EarthingCalculator.qml", icon: "public" },
        { name: qsTr("Battery Calculator"), source: "components/calculators/BatteryCalculator.qml", icon: "battery_charging_full" },
        { name: qsTr("Open Delta"), source: "components/calculators/DeltaCalculator.qml", icon: "change_history" },
        { name: qsTr("RGF"), source: "components/calculators/RefRgfCalculator.qml", icon: "calculate" },
        { name: qsTr("Fault Current"), source: "components/calculators/FaultCurrentCalculator.qml", icon: "electric_bolt" },
        { name: qsTr("Transformer & Line"), source: "components/calculators/TransformerLineCalculator.qml", icon: "cell_tower" }
    ]

    ColumnLayout {
        id: menuText
        anchors.centerIn: parent

        Label {
            id: welcomeHeader
            text: "Protection Calculators"
            font.pixelSize: 32
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 30
        }

        GridLayout {
            id: buttonGrid
            columns: protectionCalc.width > 500 ? 3 : 2
            rowSpacing: 20
            columnSpacing: 20

            Repeater {
                model: protection

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
                        calculatorLoader.source = modelData.source
                    }

                    HoverHandler {
                        onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
                    }
                }
            }
        }
    }
}