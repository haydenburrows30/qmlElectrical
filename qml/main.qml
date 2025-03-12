import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0

import QtQuick.Controls.Universal

import QtQuick.Studio.DesignEffects

import PCalculator 1.0
import Charging 1.0
import Fault 1.0
import Sine 1.0
// import RFreq 1.0
import RLC 1.0
import VDrop 1.0
import Results 1.0
import SineCalc 1.0

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

    // ToolBar{
    //     id: toolBar
    //     width: parent.width
    //     onMySignal: sideBar.react()
    // }
    
    SideBar {
        id: sideBar
        y: menu.height
        height: window.height - menu.height
    }

    Settings {id: settings}

    StackView {
        id: stackView
        anchors {
            top: parent.top//menu.bottom
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
