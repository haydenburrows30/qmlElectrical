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
                if (sideBar.expanded.state == 'open') {
                            sideBar.expanded.state = 'close'
                    }
            }
        }

    Image {
        anchors.centerIn: parent
        fillMode: Image.PreserveAspectFit
        source: "../../icons/gallery/20x20/logo.png" 
    }
}