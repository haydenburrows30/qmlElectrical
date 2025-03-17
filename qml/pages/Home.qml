import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import '../components'

Page {
    id: home
    
    // Add a welcome header
    Text {
        id: welcomeHeader
        text: "Electrical Engineering Tools"
        font.pixelSize: 32
        font.bold: true
        color: palette.text
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 30
        }
    }
    
    Text {
        id: welcomeSubtitle
        text: "Select a tool to get started"
        font.pixelSize: 16
        color: palette.text
        opacity: 0.7
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: welcomeHeader.bottom
            topMargin: 10
        }
    }

    GridLayout {
        id: buttonGrid
        anchors {
            top: welcomeSubtitle.bottom
            topMargin: 40
            horizontalCenter: parent.horizontalCenter
        }
        width: Math.min(parent.width * 0.9, 600)
        columns: width > 500 ? 3 : 2
        rowSpacing: 20
        columnSpacing: 20

        HButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            icon.name: "Voltage Drop"
            back: Qt.lighter(palette.accent, 1.5)
            fore: Qt.lighter(palette.accent, 1.0)
            
            // Add hover effect
            Behavior on scale { NumberAnimation { duration: 100 } }
            
            // Improved description layout
            Item {
                anchors.fill: parent                
                Text {
                    text: "Voltage Drop"
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
                    text: "Calculate voltage drop"
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
                stackView.push("../pages/VoltageDrop.qml")
                sideBar.change(1)
            }
            
            // Add subtle hover effect
            HoverHandler {
                onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
            }
        }

        HButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            icon.name: "Calculator" 
            // text: "Calculators"
            back: Qt.lighter(palette.accent, 1.5)
            fore: Qt.lighter(palette.accent, 1.0)
            
            Item {
                anchors.fill: parent
                
                Text {
                    text: "Calculators"
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
                    text: "Electrical calculation tools"
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
                stackView.push("../pages/Calculator.qml")
                sideBar.change(2)
            }
            
            HoverHandler {
                onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
            }
        }

        HButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            icon.name: "Wave"
            // text: "3 Phase"
            back: Qt.lighter(palette.accent, 1.5)
            fore: Qt.lighter(palette.accent, 1.0)
            
            Item {
                anchors.fill: parent
                
                Text {
                    text: "3 Phase"
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
                    text: "Three phase power calculations"
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
                stackView.push("../pages/ThreePhase.qml")
                sideBar.change(3)
            }
            
            HoverHandler {
                onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
            }
        }

        HButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            icon.name: "RLC"
            // text: "RLC"
            back: Qt.lighter(palette.accent, 1.5)
            fore: Qt.lighter(palette.accent, 1.0)
            
            Item {
                anchors.fill: parent
                
                Text {
                    text: "RLC"
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
                    text: "Ohm-mH-uF circuit analysis"
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
                stackView.push("../pages/RLC.qml")
                sideBar.change(4)
            }
            
            HoverHandler {
                onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
            }
        }

        HButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            icon.name: "RealTime"
            // text: "Real Time Chart"
            back: Qt.lighter(palette.accent, 1.5)
            fore: Qt.lighter(palette.accent, 1.0)
            
            Item {
                anchors.fill: parent
                Text {
                    text: "Real Time Chart"
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
                    text: "Live data visualization tools"
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
                stackView.push("../pages/RealTime.qml")
                sideBar.change(5)
            }
            
            HoverHandler {
                onHoveredChanged: parent.scale = hovered ? 1.05 : 1.0
            }
        }
    }
    
    // App version footer
    Text {
        text: "v1.0.0"
        font.pixelSize: 12
        color: palette.text
        opacity: 0.5
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 10
        }
    }
}