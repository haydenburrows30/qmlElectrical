import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import '../components'

//https://forum.qt.io/topic/81646/expandible-collapsible-pane-with-smooth-animation-in-qml

Page {

    background: Rectangle {
        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
    }

    property var basic: [
        { name: qsTr("Impedance Calculator"), source: "../components/calculators/ImpedanceCalculator.qml" },
        { name: qsTr("Power Current"), source: "../components/calculators/PowerCurrentCalculator.qml" },
        { name: qsTr("Unit Converter"), source: "../components/calculators/UnitConverter.qml" }
    ]

    property var protection: [
        { name: qsTr("Discrimination Analysis"), source: "../components/calculators/DiscriminationAnalyzer.qml" },
        { name: qsTr("Protection Relay"), source: "../components/calculators/ProtectionRelayCalculator.qml" },
        { name: qsTr("Instrument Transformer"), source: "../components/calculators/InstrumentTransformerCalculator.qml" },
        { name: qsTr("Earthing Calculator"), source: "../components/calculators/EarthingCalculator.qml" },
                { name: qsTr("Battery Calculator"), source: "../components/calculators/BatteryCalculator.qml" }
    ]

    property var cable: [
        { name: qsTr("Cable Ampacity"), source: "../components/calculators/CableAmpacityCalculator.qml" },
        { name: qsTr("Charging Current"), source: "../components/calculators/ChargingCurrentCalculator.qml" },
        { name: qsTr("Voltage Drop"), source: "../components/calculators/VoltageDropCalculator.qml" },
        { name: qsTr("Transmission Line"), source: "../components/calculators/TransmissionLineCalculator.qml" },
    ]
    
    property var theory: [
        { name: qsTr("Transformer Calculator"), source: "../components/calculators/TransformerCalculator.qml" },
        { name: qsTr("Harmonics Analysis"), source: "../components/calculators/HarmonicsAnalyzer.qml" },
        { name: qsTr("Machine Calculator"), source: "../components/calculators/ElectricMachineCalculator.qml" },

    ]

    Row{
        id: menuBar1
        height: menuBar.height
        anchors.horizontalCenter : parent.horizontalCenter

        Button {
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