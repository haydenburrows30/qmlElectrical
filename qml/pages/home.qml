import QtQuick
import QtCharts

import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Page {
    id: home

    Image {
        anchors.centerIn: parent
        width: home.availableWidth / 2
        height: home.availableHeight / 2
        anchors.verticalCenterOffset: -50
        anchors.horizontalCenterOffset: - sideBar.width
        fillMode: Image.PreserveAspectFit
        source: "../../icons/gallery/20x20/logo.png" 
    }
}