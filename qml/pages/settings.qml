import QtQuick
import QtCharts

import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Page {
    id: settings

        MouseArea {
            anchors.fill: parent

            onClicked:  {
                if (sideBar.expanded.state == 'open') {
                            sideBar.expanded.state = 'close'
                    }
            }
        }

    Text {
        anchors.centerIn: parent
        text: "Settings"
    }
}