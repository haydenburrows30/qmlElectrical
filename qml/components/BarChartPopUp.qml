import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

Rectangle {
    id: menuPanel
    x: Math.round((window.width - width) / 2)
    y: Math.round(window.height / 6)
    width: 400
    height: 400
    z: 99
    visible: false
    color: "transparent"

    property var barChart: barChart

    Rectangle {
        id: background
        color: "#45d9d9d9"
        border.color: "#ededed"
        border.width: 1
        anchors.fill: parent
    }

    Button {
        id: close
        width: 40
        height: 40
        anchors.right: parent.right
        anchors.top: parent.top
        icon.name: "Close"
        onClicked: {
            menuPanel.visible = false
        }
    }

    BarChart {
        id: barChart
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: close.bottom
    }
    
    DragHandler {
        xAxis.minimum: 0
        yAxis.minimum: 0
        xAxis.maximum: voltage_drop.width - parent.width
        yAxis.maximum: voltage_drop.height - parent.height
    }

    DesignEffect {
        backgroundBlurRadius: 500
        backgroundLayer: parent
        effects: [
            DesignDropShadow {}
        ]
    }
}