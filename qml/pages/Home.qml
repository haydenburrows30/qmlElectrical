import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../components"
import "../components/buttons/"
import "../components/popups"

import ConfigBridge 1.0

Page {
    id: home

    property ConfigBridge calculator: ConfigBridge {}
    
    // Pass the calculator instance to the About popup
    About {
        id: about
        configBridge: home.calculator
    }

    ColumnLayout {
        id: menuText
        anchors.centerIn: parent

        Label {
            id: welcomeHeader
            text: "Electrical Engineering Tools"
            font.pixelSize: 32
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        Label {
            id: welcomeSubtitle
            text: "Select a category to get started"
            font.pixelSize: 16
            opacity: 0.7
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 50
        }

        // Main buttons
        GridLayout {
            id: buttonGrid
            Layout.minimumWidth: Math.min(parent.width * 0.9, 600)
            columns: home.width > 500 ? 3 : 2
            rowSpacing: 20
            columnSpacing: 20

            // Basic
            HButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                icon.source: "../../icons/rounded/calculate.svg"
                back: Qt.lighter(palette.accent, 1.5)
                fore: Qt.lighter(palette.accent, 1.0)
                
                Item {
                    anchors.fill: parent
                    
                    Text {
                        text: "Basic"
                        font.bold: true
                        font.pixelSize: 16
                        color: palette.buttonText
                        anchors {
                            top: parent.top
                            topMargin: 8
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    Text {
                        text: "Ohms Law, Voltage Divider"
                        font.pixelSize: 12
                        color: palette.buttonText
                        opacity: 0.8
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                            bottomMargin: 15
                        }
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
                
                onClicked: {
                    calculatorLoader.push("CalculatorBasic.qml")
                }
                
                HoverHandler {
                    onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
                }
            }
            
            // Protection
            HButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                icon.source: "../../icons/rounded/shield.svg"
                back: Qt.lighter(palette.accent, 1.5)
                fore: Qt.lighter(palette.accent, 1.0)

                Behavior on scale { NumberAnimation { duration: 100 } }

                Item {
                    anchors.fill: parent                
                    Text {
                        text: "Protection"
                        font.bold: true
                        font.pixelSize: 16
                        color: palette.buttonText
                        anchors {
                            top: parent.top
                            topMargin: 8
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    Text {
                        text: "Relay, Battery, Fault Current"
                        font.pixelSize: 12
                        color: palette.buttonText
                        opacity: 0.8
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                            bottomMargin: 15
                        }
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
                
                onClicked: {
                    calculatorLoader.push("CalculatorProtection.qml")
                }

                HoverHandler {
                    onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
                }
            }

            // Cable
            HButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                icon.source: "../../icons/rounded/cable.svg"
                back: Qt.lighter(palette.accent, 1.5)
                fore: Qt.lighter(palette.accent, 1.0)
                
                Item {
                    anchors.fill: parent
                    
                    Text {
                        text: "Cable"
                        font.bold: true
                        font.pixelSize: 16
                        color: palette.buttonText
                        anchors {
                            top: parent.top
                            topMargin: 8
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    Text {
                        text: "Volt Drop, Charging Current"
                        font.pixelSize: 12
                        color: palette.buttonText
                        opacity: 0.8
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                            bottomMargin: 15
                        }
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
                
                onClicked: {
                    calculatorLoader.push("CalculatorCable.qml")
                }
                
                HoverHandler {
                    onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
                }
            }

            // Theory
            HButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                icon.source: "../../icons/rounded/book_5.svg"
                back: Qt.lighter(palette.accent, 1.5)
                fore: Qt.lighter(palette.accent, 1.0)
                
                Item {
                    anchors.fill: parent
                    
                    Text {
                        text: "Theory"
                        font.bold: true
                        font.pixelSize: 16
                        color: palette.buttonText
                        anchors {
                            top: parent.top
                            topMargin: 8
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    Text {
                        text: "Harmonics, Transformers"
                        font.pixelSize: 12
                        color: palette.buttonText
                        opacity: 0.8
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                            bottomMargin: 15
                        }
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
                
                onClicked: {
                    calculatorLoader.push("CalculatorTheory.qml")
                }
                
                HoverHandler {
                    onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
                }
            }
            
            // Renewables
            HButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                icon.source: "../../icons/rounded/energy.svg"
                back: Qt.lighter(palette.accent, 1.5)
                fore: Qt.lighter(palette.accent, 1.0)
                
                Item {
                    anchors.fill: parent
                    Text {
                        text: "Renewables"
                        font.bold: true
                        font.pixelSize: 16
                        color: palette.buttonText
                        anchors {
                            top: parent.top
                            topMargin: 8
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    Text {
                        text: "Wind Calculator"
                        font.pixelSize: 12
                        color: palette.buttonText
                        opacity: 0.8
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                            bottomMargin: 15
                        }
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
                
                onClicked: {
                    calculatorLoader.push("CalculatorRenewables.qml")
                }
                
                HoverHandler {
                    onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
                }
            }
        }
    }
    // Buttons bottom right
    RowLayout {
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 10
        }

        height: 70

        // About button
        Button {
            id: aboutProgram
            contentItem: Label {text: calculator.version}
            font.pixelSize: 14

            background: 
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: aboutProgram.hovered ? "blue" : "transparent"
                    radius: 5
                }

            onClicked: about.open()
        }
        
        // Logs button
        Button {
            id: logsButton
            contentItem: Label {
                text: "View Logs"
                font.pixelSize: 14
            }
            
            background: 
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: logsButton.hovered ? "blue" : "transparent"
                    radius: 5
                }
            
            onClicked: {
                console.log("Log button clicked")
                // access the logViewerPopup from the application window
                var appWindow = window || applicationWindow
                if (appWindow && appWindow.logViewerPopup) {
                    console.log("Opening log viewer popup")
                    appWindow.logViewerPopup.open()
                } else {
                    console.error("Could not find log viewer popup")
                }
                
                // Log that the user viewed logs if logManager is available
                if (typeof logManager !== "undefined") {
                    logManager.log("INFO", "User opened log viewer from home page")
                } else if (appWindow && appWindow.logManagerInstance) {
                    appWindow.logManagerInstance.log("INFO", "User opened log viewer from home page")
                } else {
                    console.log("No log manager available")
                }
            }
        }
    }
}