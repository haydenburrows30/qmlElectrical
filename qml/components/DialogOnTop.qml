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

Window {
    id: myWindow

    property var barChart: barChart

    width: 300
    height: 300

    flags:  Qt.Window | Qt.WindowSystemMenuHint
            | Qt.WindowTitleHint | Qt.WindowMinimizeButtonHint
            | Qt.WindowMaximizeButtonHint | Qt.WindowStaysOnTopHint


    visible: true
    modality: Qt.NonModal // no need for this as it is the default value

    BarChart {
        id: barChart
    }

}