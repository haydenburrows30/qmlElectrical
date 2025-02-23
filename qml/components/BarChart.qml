import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

import '../components'

import Python 1.0

ChartView {
    id: barChart
    anchors.top: table.bottom
    anchors.bottom: parent.bottom
    anchors.left: settings.right
    anchors.leftMargin: 20
    width: table.width
    // Layout.rowSpan: 10
    title: "% Voltage Drop vs Cable Type"
    antialiasing: true
    legend.alignment: Qt.AlignBottom

    theme: Universal.theme

    titleFont {
        pointSize: 13
        bold: true
    }

    BarCategoryAxis {
        id: axisX
        // titleText: "Cable Type"
    }

    ValueAxis {
        id: axisY
        titleText: "Voltage Drop (%)"
        min: 0
        max: 10
    }

    HoverHandler {
        id: stylus
        acceptedPointerTypes: PointerDevice.AllPointerTypes
    }

    BarSeries {
        id: barSeries
        axisX: axisX
        axisY: axisY
        labelsVisible: true
        labelsPosition: AbstractBarSeries.LabelsOutsideEnd
        labelsPrecision: 2
        labelsAngle: 90
        labelsFormat: "@value %"
        barWidth: 0.9

        onHovered: (status, index, barset) => {
            if (status) {
                tooltiptext.text = barset.label + ": " + barset.at(index).toFixed(2) + " V"
                tooltip.visible = true
                tooltip.x = stylus.point.position.x
                tooltip.y = stylus.point.position.y - 20
                tooltip.visible = true
            } else {
                tooltip.visible = false
            }
        }
    }

    Rectangle {
        id: tooltip
        visible: false
        color: "#333"
        radius: 5
        opacity: 0.8
        width: 100
        height: 40
        Text {
            id: tooltiptext
            anchors.fill: parent
            text: ""
            font.pixelSize: 14
            color: "white"
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}