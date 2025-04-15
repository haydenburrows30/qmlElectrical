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
import "components/menus"

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

    // Non-intrusive performance monitor that won't interfere with input
    LightPerformanceDisplay {
        id: performanceDisplay
        // This is positioned in the bottom-right corner by default
        z: 999 // Keep it above regular content but below popups
    }

    Component.onCompleted: {
        calculatorLoader.push("pages/Home.qml")
        
        // Start monitoring performance (using updated monitor)
        if (typeof perfMonitor !== 'undefined') {
            perfMonitor.beginRenderTiming()
        }
    }
    
    // Render timing hooks - only run if performance monitor is available
    onAfterRendering: {
        if (typeof perfMonitor !== 'undefined') {
            perfMonitor.endRenderTiming()
            perfMonitor.beginRenderTiming()
            perfMonitor.frameRendered()
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
                        model: MenuItems.basic

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
                        model: MenuItems.protection

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
                        model: MenuItems.cable

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
                        model: MenuItems.theory

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
                        model: MenuItems.renewables

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
