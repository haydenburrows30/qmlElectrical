import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import '../components'

Page {
    id: home
    
    // Track when page becomes visible
    onVisibleChanged: {
        if (rtChart && rtChart.visible) {
            rtChart.isActive = visible
        }
    }

    RealTimeChart {
        id: rtChart
        anchors.fill: parent
        isActive: home.visible  // Initialize with current visibility
    }
}