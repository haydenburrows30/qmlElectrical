import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "components"
import "components/calculators"
import "components/buttons"
import "components/style"
import "components/popups"

ApplicationWindow {
    id: window
   
    minimumWidth: 1280
    minimumHeight: 860
    visible: true

    SineWaveModel {id: sineModel}
    VoltageDrop {id: voltageDrop}
    ResultsManager {id: resultsManager}

    SplashScreen {
        id: splashScreen
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

        CButton {
            id: menu
            icon.name: "Menu"
            tooltip_text: sideBar.open_closed ? "Close Menu" : "Open Menu"
        }

        SideBar {
            id: sideBar
            edge: Qt.LeftEdge
            width: 60
            height: menuMoved ? parent.height : parent.height - menu.height
            y: 0
            property bool menuMoved: false
        }

        Rectangle {
            id: fade
            width: menu.width + 1
            visible: !sideBar.menuMoved
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: - border.width
            anchors.topMargin: - border.width
            anchors.bottomMargin: - border.width

            height: 80
            // opacity: 0.8
            border.width: 1
            border.color: sideBar.modeToggled ? "#767676" : "#cccccc" // "#767676"

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: sideBar.modeToggled ? "#2b2b2b" : "#f2f2f2" }
                GradientStop { position: 0.6; color: sideBar.modeToggled ? Qt.lighter("#2b2b2b",1.3) : "#f2f2f2" }
                GradientStop { position: 1.0; color: sideBar.modeToggled ? palette.base : "#f2f2f2" }
            }
        }
    }

    Settings {
        id: settings
        property real menuX
        property real menuY
    }

    Universal.theme: sideBar.modeToggled ? Universal.Dark : Universal.Light
    Universal.accent: sideBar.modeToggled ? Universal.Red : Universal.Cyan
}
