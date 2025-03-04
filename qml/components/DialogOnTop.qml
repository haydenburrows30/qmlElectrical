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

Window {
    id: myWindow

    property var barChart: barChart
    visible: false

    width: 300
    height: 300

    flags:  Qt.Window //| Qt.WindowSystemMenuHint
            //| Qt.WindowTitleHint | Qt.WindowMinimizeButtonHint
            //| Qt.WindowMaximizeButtonHint | Qt.WindowStaysOnTopHint

    modality: Qt.NonModal // no need for this as it is the default value

    BarChart {
        anchors.fill: parent
        id: barChart
    }

}