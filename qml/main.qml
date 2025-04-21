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

    Universal.theme: appConfig.darkMode ? Universal.Dark : Universal.Light
    Universal.accent: Universal.Cyan

    property bool modeToggled: appConfig.darkMode

    ResultsManager {id: resultsManager}

    SplashScreen {
        id: splashScreen
    }

    LogViewerPopup {
        id: logViewerPopup
    }

    SettingsMenu {
        id: settingsMenu
    }

    // Initialize logManager with a Timer to avoid binding loops
    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            if (typeof logManager !== 'undefined') {
                logViewerPopup.logManager = logManager;
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
        // This is positioned in the bottom-left corner by default
        z: 999 // Keep it above regular content but below popups
    }

    Component.onCompleted: {
        calculatorLoader.push("pages/Home.qml")
        
        // Initialize dark mode from configuration
        if (typeof appConfig !== 'undefined') {
            modeToggled = appConfig.darkMode
        }
        
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
                Menu {
                    title: "Tools"
                    MenuItem {
                        text: "Settings"
                        onTriggered: settingsMenu.open()
                    }
                    MenuItem {
                        text: "Log Viewer"
                        onTriggered: logViewerPopup.open()
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
                    checked: appConfig.darkMode

                    onClicked: {
                        modeToggled = modeButton.checked
                        if (typeof appConfig !== 'undefined') {
                            appConfig.save_setting("dark_mode", modeButton.checked)
                        }
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
}
