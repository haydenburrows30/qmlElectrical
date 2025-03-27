import QtQuick
import QtQuick.Controls

import "../charts"

Popup {
    id: root
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    width: 700
    height: 700
    
    property real percentage: 0
    property string cableSize: "0"
    property real currentValue: 0
    readonly property alias chartComponent: chartComponent
    
    signal saveRequested(real scale)

    function prepareChart() {
        chartComponent.percentage = root.percentage
        chartComponent.cableSize = root.cableSize
        chartComponent.currentValue = root.currentValue
        chartComponent.updateChart()
    }

    function grabImage(callback, scale) {
        if (chartComponent) {
            chartComponent.grabChartImage(callback, scale)
        }
    }

    VoltageDropChart {
        id: chartComponent
        anchors.fill: parent

        onCloseRequested: root.close()
        onSaveRequested: function(scale) {
            root.saveRequested(scale)
        }
    }
}
