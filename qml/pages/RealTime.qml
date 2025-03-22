import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../components"
import "../components/charts/"

Page {
    id: home

    // Add theme-aware text color property
    property color textColor: sideBar.toggle1 ? "#ffffff" : "#000000"

    background: Rectangle {
        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
    }

    onVisibleChanged: {
        if (rtChart && rtChart.visible) {
            rtChart.isActive = visible
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: rtChart.height + 10
    
            RealTimeChart {
                id: rtChart
                Layout.fillWidth: true
                Layout.fillHeight: true
                isActive: home.visible
            }
        }
    }
}