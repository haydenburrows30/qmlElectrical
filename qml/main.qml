import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0


import QtQuick.Studio.DesignEffects

import Python 1.0

import 'components'

ApplicationWindow {
    id: window
   
    minimumWidth: 1080
    minimumHeight: 800
    visible: true

    PythonModel {
        id: pythonModel
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

        MenuPanel {
            id: menuPanel
            visible: true
            z:0
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
}
