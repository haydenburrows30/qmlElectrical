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
    width: 250
    height: 400
    color: "transparent"

    property var barChart: barChart

    Rectangle {
        id: background
        color: "#45d9d9d9"
        border.color: "#ededed"
        border.width: 1
        anchors.fill: parent
    }

    BarChart {
        id: barChart
        anchors.fill: parent
    }
}