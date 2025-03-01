import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0

import QtQuick.Studio.DesignEffects

import Python 1.0
import Calculator 1.0
import Charging 1.0
import Fault 1.0
import Sine 1.0

import 'components'

ApplicationWindow {
    id: window
   
    minimumWidth: 1200
    minimumHeight: 800
    visible: true

    PythonModel {
        id: pythonModel
    }

    PowerCalculator {
        id: powerCalculator
    }

    ChargingCalc {
        id: chargingCalc
    }

    FaultCalculator {
        id: faultCalc
    }

    SineWaveModel {
        id: threePhaseSineModel
    }

    FontLoader {
        id: sourceSansProFont

        source: "../fonts/SourceSansPro-Regular.ttf"
        // name: "SourceSansPro"
    }

    ToolBar{
        id: toolBar
        width: parent.width
        onMySignal: sideBar.react()
    }
    
    SideBar {
        id: sideBar
        y: toolBar.height
        height: window.height - toolBar.height

    }

    Settings {
        id: settings
    }

    // Rectangle {
    //     id: detailed
    //     width: 120
    //     height: 60
    //     // anchors.left: sideBar.right
    //     z:99
    //     // Layout.fillHeight: true
    //     color: "red"
    //     visible: sideBar.sideBar

    //     // state: 'close'

    //     // transitions: [
    //     //     Transition {
    //     //         from: 'close'
    //     //         to: 'open'

    //     //         NumberAnimation {
    //     //             properties: "Layout.preferredWidth,x,y,opacity"
    //     //             easing.type: Easing.InOutQuad
    //     //             duration: 250
    //     //             }
    //     //         NumberAnimation {
    //     //             properties: "visible"
    //     //             easing.type: Easing.InOutQuad
    //     //             duration: 100
    //     //             }
    //     //     },
    //     //     Transition {
    //     //         from: 'open'
    //     //         to: 'close'

    //     //         NumberAnimation {
    //     //             properties: "Layout.preferredWidth,x,y,opacity"
    //     //             easing.type: Easing.InOutQuad
    //     //             duration: 250
    //     //             }

    //     //         NumberAnimation {
    //     //             properties: "visible"
    //     //             easing.type: Easing.InOutQuad
    //     //             duration: 350
    //     //             }
    //     //     }
    //     // ]

    //     // states: [
    //     //     State {
    //     //         name: 'open'
    //     //             PropertyChanges {
    //     //                 target: detailed
    //     //                 // Layout.preferredWidth: 120
    //     //                 x: 60
    //     //                 y: 120
    //     //                 visible: true
    //     //                 opacity: 1
    //     //             }
    //     //     },
    //     //     State {
    //     //         name: 'close'
    //     //             PropertyChanges {
    //     //                 target: detailed
    //     //                 // Layout.preferredWidth: 0
    //     //                 x: -100
    //     //                 y: 0
    //     //                 visible: true
    //     //                 opacity: 0
    //     //             }
    //     //     }
    //     // ]
    // }

    StackView {
        id: stackView
        anchors {
            top: toolBar.bottom
            bottom: parent.bottom
            left: parent.left
            leftMargin: 0
            right: parent.right
        }
        Component.onCompleted: stackView.push(Qt.resolvedUrl("pages/home.qml"),StackView.Immediate)

        states: [State {
            name: "closed"; when: sideBar.hide
            PropertyChanges { target: stackView; anchors.leftMargin: 0;}
        },
        State {
            name: "open"; when: sideBar.show
            PropertyChanges { target: stackView; anchors.leftMargin: sideBar.width + 5;}
        }]

        transitions: Transition {
            NumberAnimation { properties: "anchors.leftMargin"; easing.type: Easing.InOutQuad; duration: 200  }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Select CSV File"
        nameFilters: ["CSV Files (*.csv)"]
        onAccepted: {
            if (fileDialog.selectedFile) {
                voltageDropModel.load_csv_file(fileDialog.selectedFile.toString().replace("file://", ""))
            }
        }
    }

    Universal.theme: toolBar.toggle ? Universal.Dark : Universal.Light
    Universal.accent: toolBar.toggle ? Universal.Red : Universal.Cyan
}
