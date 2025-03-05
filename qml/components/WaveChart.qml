import QtQuick
import QtCharts
import QtQuick.Controls

ChartView {
    id: chartView
    property var model
    antialiasing: true
    legend.visible: false

    property bool showRmsA: false
    property bool showRmsB: false
    property bool showRmsC: false

    Component.onCompleted: {
        if (model) {
            model.fill_series(seriesA, seriesB, seriesC)
        }
    }

    onModelChanged: {
        if (model) {
            model.fill_series(seriesA, seriesB, seriesC)
        }
    }

    ValueAxis {
        id: axisY
        min: -400
        max: 400
        titleText: "Voltage (V)"
    }

    ValueAxis {
        id: axisX
        min: 0
        max: 1000
        titleText: "Time (ms)"
    }

    LineSeries {
        id: seriesA
        axisX: axisX
        axisY: axisY
        color: "#f44336"  // Red
        width: 2
        name: "Phase A" + (chartView.showRmsA ? " (RMS: " + model.rmsA.toFixed(1) + "V)" : "")
    }

    LineSeries {
        id: seriesB
        axisX: axisX
        axisY: axisY
        color: "#4caf50"  // Green
        width: 2
        name: "Phase B" + (chartView.showRmsB ? " (RMS: " + model.rmsB.toFixed(1) + "V)" : "")
    }

    LineSeries {
        id: seriesC
        axisX: axisX
        axisY: axisY
        color: "#2196f3"  // Blue
        width: 2
        name: "Phase C" + (chartView.showRmsC ? " (RMS: " + model.rmsC.toFixed(1) + "V)" : "")
    }

    Menu {
        id: contextMenu
        title: "Display Options"

        MenuItem {
            text: "Show Phase A RMS"
            checkable: true
            checked: chartView.showRmsA
            onTriggered: {
                chartView.showRmsA = !chartView.showRmsA
                chartView.legend.visible = chartView.showRmsA || chartView.showRmsB || chartView.showRmsC
            }
        }
        MenuItem {
            text: "Show Phase B RMS"
            checkable: true
            checked: chartView.showRmsB
            onTriggered: {
                chartView.showRmsB = !chartView.showRmsB
                chartView.legend.visible = chartView.showRmsA || chartView.showRmsB || chartView.showRmsC
            }
        }
        MenuItem {
            text: "Show Phase C RMS"
            checkable: true
            checked: chartView.showRmsC
            onTriggered: {
                chartView.showRmsC = !chartView.showRmsC
                chartView.legend.visible = chartView.showRmsA || chartView.showRmsB || chartView.showRmsC
            }
        }
        MenuSeparator { }
        MenuItem {
            text: "Hide All RMS"
            onTriggered: {
                chartView.showRmsA = false
                chartView.showRmsB = false
                chartView.showRmsC = false
                chartView.legend.visible = false
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup()
            }
        }
    }

    Connections {
        target: model
        function onDataChanged() {
            model.fill_series(seriesA, seriesB, seriesC)
        }
    }
}
