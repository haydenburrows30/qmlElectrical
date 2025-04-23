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

    background: Rectangle {
            color: Universal.background
            radius: 10
            anchors.fill: parent
    }
    
    property real percentage: 0
    property string cableSize: "0"
    property real currentValue: 0

    readonly property alias chartComponent: chartComponent

    function prepareChart() {
        chartComponent.percentage = root.percentage
        chartComponent.cableSize = root.cableSize
        chartComponent.currentValue = root.currentValue
        chartComponent.updateChart()
    }

    VoltageDropChart {
        id: chartComponent
        anchors.fill: parent

        onCloseRequested: root.close()
    }
}
