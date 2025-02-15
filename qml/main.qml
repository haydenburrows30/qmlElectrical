import QtQuick
import QtQuick.Controls
import Qt.labs.qmlmodels 1.0
import QtQml
import QtQuick.Dialogs
import QtQuick.Layouts

import Python 1.0

import 'components'

Window {
   
    minimumWidth: 1080
    minimumHeight: 400
    visible: true    

    PythonModel {
        id: pythonModel
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

    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            leftMargin: sideBar.width + 5
            right: parent.right
        }

        StackView {
            id: stackView
            anchors.fill: parent
            Component.onCompleted: stackView.push(Qt.resolvedUrl("pages/home.qml"),StackView.Immediate)
        }
    }

    SideBar {
        id: sideBar
        height: parent.height
    }
}
