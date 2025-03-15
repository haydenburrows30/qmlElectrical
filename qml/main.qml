import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal

import 'components'
import 'components/calculators'

ApplicationWindow {
    id: window
   
    minimumWidth: 1280
    minimumHeight: 860
    visible: true

    SeriesRLCChart {id: seriesRLCChart}
    SineWaveModel {id: sineModel}
    VoltageDrop {id: voltageDrop}
    ResultsManager {id: resultsManager}

    // Add splash screen
    Popup {
        id: splashScreen
        modal: true
        visible: true
        closePolicy: Popup.NoAutoClose
        anchors.centerIn: parent
        width: 300
        height: 300
        
        background: Rectangle {
            color: Universal.background
            radius: 10
            border.width: 1
            border.color: Universal.foreground
            
            Column {
                anchors.centerIn: parent
                spacing: 20
                
                // Add app logo/icon here
                Image {
                    source: "qrc:/icons/gallery/24x24/Calculator.svg"
                    width: 64
                    height: 64
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                BusyIndicator {
                    running: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                ProgressBar {
                    width: 200
                    value: loadingManager.progress
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Label {
                    text: loadingManager.loading ? "Loading..." : "Ready!"
                    color: Universal.foreground
                    font.pixelSize: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
    
    // Modified timer to close only when loading is complete
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

    // Add parent container for proper z-ordering
    Item {
        anchors.fill: parent

        StackView {
            id: stackView
            objectName: "stackView"
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                leftMargin: 0
                right: parent.right
            }
            z: 1
            Component.onCompleted: stackView.push(Qt.resolvedUrl("pages/Home.qml"),StackView.Immediate)

            states: [State {
                name: "closed"; when: sideBar.hide
                PropertyChanges { target: stackView; anchors.leftMargin: 0;}
            },
            State {
                name: "open"; when: sideBar.show
                PropertyChanges { target: stackView; anchors.leftMargin: sideBar.width}
            }]

            transitions: Transition {
                NumberAnimation { properties: "anchors.leftMargin"; easing.type: Easing.InOutQuad; duration: 200  }
            }
        }

        // Menu button and sidebar as separate elements
        CButton {
            id: menu
            icon_name: "Menu"
            width: 60
            height: 60
            z: 10
            anchors {
                bottom: parent.bottom
                left: parent.left
            }
            tooltip_text: sideBar.open_closed ? "Close Menu" : "Open Menu"

            background: Rectangle {
                radius: 0
                color: {
                    if (menu.down)
                        return sideBar.toggle1 ? "#2a2a2a" : "#d0d0d0"
                    if (menu.hovered)
                        return sideBar.toggle1 ? "#404040" : "#e0e0e0"
                    return sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
                }

                // Add border and top accent for better visibility
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: sideBar.toggle1 ? "#404040" : "#d0d0d0"

                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width
                        height: 2
                        visible: menu.hovered || menu.visualFocus
                        color: Universal.accent
                        opacity: 0.8
                    }
                }
            }

            // Add keyboard shortcut
            Shortcut {
                sequence: "Ctrl+M"
                onActivated: menu.clicked()
            }
            
            // Rotate icon on toggle
            transform: Rotation {
                id: iconRotation
                origin.x: menu.width / 2
                origin.y: menu.height / 2
                angle: sideBar.position * -180
                Behavior on angle {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }
            }

            onClicked: { 
                sideBar.react()
                forceActiveFocus() // Ensure button can receive keyboard focus
            }
        }
        
        SideBar {
            id: sideBar
            edge: Qt.LeftEdge
            width: 60
            height: parent.height - menu.height
            y: 0  // Start from top
            z: 5
        }
    }

    Settings {id: settings}

    Universal.theme: sideBar.toggle1 ? Universal.Dark : Universal.Light
    Universal.accent: sideBar.toggle1 ? Universal.Red : Universal.Cyan
}
