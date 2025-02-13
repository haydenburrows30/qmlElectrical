import QtQuick 6.2
import QtQuick.Controls 6.2
import Qt.labs.qmlmodels 1.0
import QtQml 6.2
import QtQuick.Dialogs
import QtQuick.Layouts

import Python 1.0

import 'components'

Window {
    id: window
    
    minimumWidth: 1080
    minimumHeight: 900
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

    FontLoader {
        id: sourceSansProFont
        source: '../fonts/SourceSansPro-Regular.ttf'
    }

    Rectangle {
        id: mainview

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            leftMargin: sideBar.width + 2
            right: parent.right
        }

        StackView {
            id: stackView
            anchors.fill: parent
            Component.onCompleted: stackView.push(Qt.resolvedUrl("pages/home.qml"))
        }
    }

    SideBar {
        id: sideBar
        anchors.left: parent.left
    }
}
