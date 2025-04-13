import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "calculators"
import "components"
import "pages"
import "components/style"
import "components/popups"
import "components/buttons"
import "components/displays"


ApplicationWindow {
    id: window
   
    minimumWidth: 1280
    minimumHeight: 860
    visible: true

    Universal.theme: modeToggled ? Universal.Dark : Universal.Light
    Universal.accent: Universal.Cyan
    
    property var logViewerPopup: logViewerPopupInstance
    property var logManagerInstance: null
    property bool modeToggled: false

    property var home: [
            {name: qsTr("Home"), source: "pages/Home.qml"}
        ]

    property var basic: [
        { name: qsTr("Impedance Calculator"), source: "calculators/basic/ImpedanceCalculator.qml" },
        { name: qsTr("kVA / kw / A"), source: "calculators/basic/PowerCurrentCalculator.qml" },
        { name: qsTr("Unit Converter"), source: "calculators/basic/UnitConverter.qml" },
        { name: qsTr("Power Factor Correction"), source: "calculators/basic/PowerFactorCorrection.qml" },
        { name: qsTr("Ohm's Law"), source: "calculators/basic/OhmsLawCalculator.qml" },
        { name: qsTr("Voltage Divider"), source: "calculators/basic/VoltageDividerCalculator.qml" }
    ]

    property var protection: [
        { name: qsTr("Discrimination Analysis"), source: "calculators/protection/DiscriminationAnalyzer.qml" },
        { name: qsTr("Protection Relay"), source: "calculators/protection/ProtectionRelayCalculator.qml" },
        { name: qsTr("Instrument Transformer"), source: "calculators/protection/InstrumentTransformerCalculator.qml" },
        { name: qsTr("Earthing Calculator"), source: "calculators/protection/EarthingCalculator.qml" },
        { name: qsTr("Battery Calculator"), source: "calculators/protection/BatteryCalculator.qml" },
        { name: qsTr("Open Delta"), source: "calculators/protection/DeltaCalculator.qml" },
        { name: qsTr("Overcurrent Protection"), source: "calculators/protection/OvercurrentProtectionCalculator.qml" },
        { name: qsTr("RGF"), source: "calculators/protection/RefRgfCalculator.qml" },
        { name: qsTr("Fault Current"), source: "calculators/protection/FaultCurrentCalculator.qml" },
        { name: qsTr("Transformer + Line"), source: "calculators/protection/TransformerLineCalculator.qml" },
        { name: qsTr("Solkor Rf"), source: "calculators/protection/SolkorRf.qml" },
        { name: qsTr("VR Calculations"), source: "calculators/protection/VR32CL7Calculator.qml" }
    ]

    property var cable: [
        { name: qsTr("Cable Ampacity"), source: "calculators/cable/CableAmpacityCalculator.qml" },
        { name: qsTr("Charging Current"), source: "calculators/cable/ChargingCurrentCalculator.qml" },
        { name: qsTr("Voltage Drop"), source: "calculators/cable/VoltageDropCalculator.qml" },
        { name: qsTr("Transmission Line"), source: "calculators/cable/TransmissionLineCalculator.qml" },
        { name: qsTr("Switchboard"), source: "calculators/cable/SwitchboardPanel.qml" },
        { name: qsTr("Voltage Drop Orion"), source: "calculators/cable/VoltageDrop.qml" }
    ]
    
    property var theory: [
        { name: qsTr("Transformer Calculator"), source: "calculators/theory/TransformerCalculator.qml" },
        { name: qsTr("Harmonics Analysis"), source: "calculators/theory/HarmonicsAnalyzer.qml" },
        { name: qsTr("Machine Calculator"), source: "calculators/theory/ElectricMachineCalculator.qml" },
        { name: qsTr("Motor Starting"), source: "calculators/theory/MotorStartingCalculator.qml" },
        { name: qsTr("RLC"), source: "calculators/theory/RLC.qml" },
        { name: qsTr("Three Phase Waveforms"), source: "calculators/theory/ThreePhase.qml" },
        { name: qsTr("Real Time Chart"), source: "calculators/theory/RealTime.qml" },
        { name: qsTr("Instrument Tx Naming"), source: "calculators/theory/TransformerNamingGuide.qml" }
    ]
    
    property var renewables: [
        { name: qsTr("Wind & Grid Connection"), source: "calculators/grid_wind/WindTransformerLineCalculator.qml" }
    ]

    ResultsManager {id: resultsManager}

    SplashScreen {
        id: splashScreen
    }

    LogViewerPopup {
        id: logViewerPopupInstance
        logManager: logManagerInstance
    }

    Timer {
        interval: 10
        running: true
        repeat: false
        onTriggered: {
            if (typeof logManager !== 'undefined') {
                logManagerInstance = logManager
                logManager.log("INFO", "Application started successfully")
            } else {
                console.error("Log manager not available after timeout")
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (!loadingManager.loading) {
                splashScreen.close()
            }
        }
    }

    // Menu, Dark/Light Button, StackView
    Item {
        anchors.fill: parent

        RowLayout {
            id: menuBar
            height: mainMenu.height
            anchors.horizontalCenter: parent.horizontalCenter
            // Back button
            RoundButton {
                id: backButton
                visible: calculatorLoader.depth > 1
                text: "<"
                    onClicked: {
                        if (calculatorLoader.depth > 1) {
                        calculatorLoader.pop()
                    }
                }
                ToolTip.text: qsTr("Back")
                ToolTip.visible: backButton.hovered
                ToolTip.delay: 500
            }

            // Home button
            RoundButton {
                id: homeButton
                icon.source: "../icons/rounded/home_app_logo.svg"
                    onClicked: {
                        calculatorLoader.popToIndex(0) //return to home page
                    }
                ToolTip.text: qsTr("Home")
                ToolTip.visible: homeButton.hovered
                ToolTip.delay: 500
            }

            // Main menu
            MenuBar {
                id: mainMenu

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
                            onTriggered: { 
                                calculatorLoader.push(modelData.source)
                                
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
                                calculatorLoader.push(modelData.source)
                                
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
                                calculatorLoader.push(modelData.source)
                                
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
                                calculatorLoader.push(modelData.source)
                                
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
                                calculatorLoader.push(modelData.source)
                                
                            }
                        }
                    }
                }
            }

            // Dark/light mode button
            Rectangle {
                id: sideBar
                width: 40
                height: 40
                color: "transparent"

                DarkLightButton {
                    id: modeButton
                    anchors.centerIn: parent

                    icon_name1: "Dark"
                    icon_name2: "Light"
                    mode_1: "Light Mode"
                    mode_2: "Dark Mode"
                    implicitHeight: 40
                    implicitWidth: 40

                    onClicked: {
                        modeButton.checked ? modeToggled = true : modeToggled = false
                    }
                }
            }
        }

        StackView {
            id: calculatorLoader
            objectName: "calculatorLoader"
            anchors {
                top: menuBar.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            z: 1
            Component.onCompleted: calculatorLoader.push("pages/Home.qml")
        }
    }

    Settings {
        id: settings
        property real menuX
        property real menuY
    }

    // Expose a global function to open logs from anywhere in the app
    function openLogViewer() {
        console.log("openLogViewer function called")
        if (logViewerPopupInstance) {
            logViewerPopupInstance.open()
        } else {
            console.error("Log viewer popup not available")
        }
    }
}
