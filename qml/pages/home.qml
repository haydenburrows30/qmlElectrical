import QtQuick
import QtCharts

import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Page {
    id: home

    MouseArea {
        anchors.fill: parent

        onClicked:  {
            stackView.anchors.leftMargin = 0
            sideBar.close()
        }
    }

    Image {
        anchors.centerIn: parent
        fillMode: Image.PreserveAspectFit
        source: "../../icons/gallery/20x20/logo.png" 
    }
}