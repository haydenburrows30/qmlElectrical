import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../components"
import "../components/buttons"

Page {

    background: Rectangle {
        color: sideBar.modeToggled ? "#1a1a1a" : "#f5f5f5"
    }

    Popup {
        id: tipsPopup
        width: 500
        height: 300
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        Text {
            anchors.fill: parent
            text: {"Placeholder text for information"}
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    property var basic: [
        { name: qsTr("Impedance Calculator"), source: "../components/calculators/ImpedanceCalculator.qml" },
        { name: qsTr("kVA / kw / A"), source: "../components/calculators/PowerCurrentCalculator.qml" },
        { name: qsTr("Unit Converter"), source: "../components/calculators/UnitConverter.qml" },
        { name: qsTr("Power Factor Correction"), source: "../components/calculators/PowerFactorCorrection.qml" },
        { name: qsTr("Ohm's Law"), source: "../components/calculators/OhmsLawCalculator.qml" },
        { name: qsTr("Voltage Divider"), source: "../components/calculators/VoltageDividerCalculator.qml" }
    ]

    property var protection: [
        { name: qsTr("Discrimination Analysis"), source: "../components/calculators/DiscriminationAnalyzer.qml" },
        { name: qsTr("Protection Relay"), source: "../components/calculators/ProtectionRelayCalculator.qml" },
        { name: qsTr("Instrument Transformer"), source: "../components/calculators/InstrumentTransformerCalculator.qml" },
        { name: qsTr("Earthing Calculator"), source: "../components/calculators/EarthingCalculator.qml" },
        { name: qsTr("Battery Calculator"), source: "../components/calculators/BatteryCalculator.qml" },
        { name: qsTr("Open Delta"), source: "../components/calculators/DeltaCalculator.qml" },
        { name: qsTr("RGF"), source: "../components/calculators/RefRgfCalculator.qml" },
        { name: qsTr("Fault Current"), source: "../components/calculators/FaultCurrentCalculator.qml" },
        { name: qsTr("Transformer & Line"), source: "../components/calculators/TransformerLineCalculator.qml" }
    ]

    property var cable: [
        { name: qsTr("Cable Ampacity"), source: "../components/calculators/CableAmpacityCalculator.qml" },
        { name: qsTr("Charging Current"), source: "../components/calculators/ChargingCurrentCalculator.qml" },
        { name: qsTr("Voltage Drop"), source: "../components/calculators/VoltageDropCalculator.qml" },
        { name: qsTr("Transmission Line"), source: "../components/calculators/TransmissionLineCalculator.qml" },
        { name: qsTr("Switchboard"), source: "../components/calculators/SwitchboardPanel.qml" }
    ]
    
    property var theory: [
        { name: qsTr("Transformer Calculator"), source: "../components/calculators/TransformerCalculator.qml" },
        { name: qsTr("Harmonics Analysis"), source: "../components/calculators/HarmonicsAnalyzer.qml" },
        { name: qsTr("Machine Calculator"), source: "../components/calculators/ElectricMachineCalculator.qml" },
        { name: qsTr("Motor Starting"), source: "../components/calculators/MotorStartingCalculator.qml" }
    ]
    
    property var renewables: [
        { name: qsTr("Wind & Grid Connection"), source: "../components/calculators/WindTransformerLineCalculator.qml" }
    ]

    Row {
        id: menuBar1
        height: menuBar.height
        anchors.horizontalCenter : parent.horizontalCenter

        StyledButton {
            id: control
            text: "Home"
            width: 100
            height: menuBar.height
            onClicked: calculatorLoader.source = "../components/CalculatorMenu.qml"
        }

        MenuBar {
            id: menuBar
            
            background: 
                Rectangle {
                    color: "#21be2b"
                    width: parent.width
                    height: 1
                    anchors.bottom: parent.bottom
                }

            Menu {
                title: "Basic Calculators"
                Repeater {
                    model: basic

                    MenuItem {
                        text: modelData.name
                        onTriggered: calculatorLoader.source = modelData.source
                    }
                }
            }

            Menu {
                title: "Protection"
                Repeater {
                    model: protection

                    MenuItem {
                        text: modelData.name
                        onTriggered: calculatorLoader.source = modelData.source
                    }
                }
            }
            Menu {
                title: "Cable"
                Repeater {
                    model: cable

                    MenuItem {
                        text: modelData.name
                        onTriggered: calculatorLoader.source = modelData.source
                    }
                }
            }
            Menu {
                title: "Theory"
                Repeater {
                    model: theory

                    MenuItem {
                        text: modelData.name
                        onTriggered: calculatorLoader.source = modelData.source
                    }
                }
            }
            Menu {
                title: "Renewables"
                Repeater {
                    model: renewables

                    MenuItem {
                        text: modelData.name
                        onTriggered: calculatorLoader.source = modelData.source
                    }
                }
            }
            Menu {
                title: "Info"
                MenuItem {
                    text: "i"
                    onTriggered: tipsPopup.open()
                }
            }
        }
    }

    Loader {
        id: calculatorLoader
        anchors.left: parent.left
        anchors.top: menuBar1.bottom
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        source: "../components/CalculatorMenu.qml"
    }
}