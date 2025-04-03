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
import "components/backgrounds"
import "components/popups"

ApplicationWindow {
    id: window
   
    minimumWidth: 1280
    minimumHeight: 860
    visible: true

    SineWaveModel {id: sineModel}
    VoltageDrop {id: voltageDrop}
    ResultsManager {id: resultsManager}

    // Splash screen
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
            icon_name: "Menu"
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
    }

    Settings {
        id: settings
        property real menuX
        property real menuY
    }

    Universal.theme: sideBar.modeToggled ? Universal.Dark : Universal.Light
    Universal.accent: sideBar.modeToggled ? Universal.Red : Universal.Cyan
}
