import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../components"
import "../components/buttons"
import "../components/style"

Page {

    background: Rectangle {
        color: sideBar.modeToggled ? "#1a1a1a" : "#f5f5f5"
    }

    property var home: [
        {name: qsTr("Home"), source: "../components/CalculatorMenu.qml"}
    ]

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

    property var info: [
        { name: qsTr("Info"), source: "../components/popups/About.qml" }
    ]

    MenuBar {
        id: menuBar
        anchors.horizontalCenter : parent.horizontalCenter
        
        background: 
            Rectangle {
                color: "#21be2b"
                width: parent.width
                height: 1
                anchors.bottom: parent.bottom
            }

        Menu {
            title: "Home"
            Repeater {
                model: home

                MenuItem {
                    text: modelData.name
                    onTriggered: {
                        calculatorLoader.source = modelData.source
                        
                    }
                }
            }
        }

        Menu {
            title: "Basic Calculators"
            Repeater {
                model: basic

                MenuItem {
                    text: modelData.name
                    onTriggered: { 
                        calculatorLoader.source = modelData.source
                        
                    }
                }
            }
        }

        Menu {
            title: "Protection"
            Repeater {
                model: protection

                MenuItem {
                    text: modelData.name
                    onTriggered: {
                        calculatorLoader.source = modelData.source
                        
                    }
                }
            }
        }
        Menu {
            title: "Cable"
            Repeater {
                model: cable

                MenuItem {
                    text: modelData.name
                    onTriggered: {
                        calculatorLoader.source = modelData.source
                        
                    }
                }
            }
        }
        Menu {
            title: "Theory"
            Repeater {
                model: theory

                MenuItem {
                    text: modelData.name
                    onTriggered: {
                        calculatorLoader.source = modelData.source
                        
                    }
                }
            }
        }
        Menu {
            title: "Renewables"
            Repeater {
                model: renewables

                MenuItem {
                    text: modelData.name
                    onTriggered: {
                        calculatorLoader.source = modelData.source
                        
                    }
                }
            }
        }
    }

    Loader {
        id: calculatorLoader
        anchors.left: parent.left
        anchors.top: menuBar.bottom
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: 5
        source: "../components/CalculatorMenu.qml"
    }
}