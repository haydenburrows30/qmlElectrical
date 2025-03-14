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

    SeriesRLCChart {id: seriesRLCChart}
    SineWaveModel {id: sineModel}
    VoltageDrop {id: voltageDrop}
    ResultsManager {id: resultsManager}

    CButton {
        id: menu
        icon_name: "Menu"
        width: sideBar.width
        height: 60
        z:99
        anchors.top: parent.top
        anchors.left: parent.left
        tooltip_text: sideBar.open_closed ? "Close Menu":"Open Menu"
        onClicked: { 
            sideBar.react()
        }
    }
    
    SideBar {
        id: sideBar
        y: menu.height
        height: window.height - menu.height
    }

    Settings {id: settings}

    StackView {
        id: stackView
        objectName: "stackView"  // Add this line to make it findable
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            leftMargin: 0
            right: parent.right
        }
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

    Universal.theme: sideBar.toggle1 ? Universal.Dark : Universal.Light
    Universal.accent: sideBar.toggle1 ? Universal.Red : Universal.Cyan
}
