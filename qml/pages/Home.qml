import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../"
import "."
import "../components"
import "../components/buttons/"
import "../components/popups"

Page {
    id: home

    WhatsNew {
        id: whatsNewPopup
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
            color: window.modeToggled ? "white" : "black"
        }
        
        Label {
            id: welcomeSubtitle
            text: "Select a category to get started"
            font.pixelSize: 16
            opacity: 0.7
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 50
            color: window.modeToggled ? "white" : "black"
        }

        // Main buttons
        GridLayout {
            id: buttonGrid
            Layout.minimumWidth: Math.min(parent.width * 0.9, 600)
            columns: home.width > 500 ? 3 : 2
            rowSpacing: 20
            columnSpacing: 20

            // Basic
            HomeButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                icon.source: "../../icons/rounded/calculate.svg"
                
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
            HomeButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                icon.source: "../../icons/rounded/shield.svg"

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
            HomeButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                icon.source: "../../icons/rounded/cable.svg"
                
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
            HomeButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                icon.source: "../../icons/rounded/book_5.svg"
                
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
            HomeButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                icon.source: "../../icons/rounded/energy.svg"
                
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

        // What's New button
        Button {
            id: whatsNewButton
            contentItem: Label {
                text: "What's New"
                font.pixelSize: 14
                color: window.modeToggled ? "white" : "black"
            }
            
            background: Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: whatsNewButton.hovered ? "blue" : "transparent"
                radius: 5
            }
            
            onClicked: whatsNewPopup.open()
        }

        // About button
        Button {
            id: aboutProgram
            contentItem: Label {
                text: appConfig.version
                color: window.modeToggled ? "white" : "black"
            }
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
                color: window.modeToggled ? "white" : "black"
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
                logViewerPopup.open()
            }
        }
    }
}