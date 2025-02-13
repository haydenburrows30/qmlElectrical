import QtQuick 6.2
import QtQuick.Controls 6.2
import Qt.labs.qmlmodels 1.0
import QtQml 6.2
import QtQuick.Dialogs
import QtQuick.Layouts

import Python 1.0

Window {
    id: window
    
    minimumWidth: 900
    minimumHeight: 400
    height: 400
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
        // name: 'SourceSansPro'
    }

    Rectangle {
        id: mainview
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: sideBar.width + 2
        anchors.right: parent.right

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
