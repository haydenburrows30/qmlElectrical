import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCharts

Page {
    id: home

    MouseArea {
        anchors.fill: parent

        onClicked:  {
            sideBar.close()
        }
    }
}