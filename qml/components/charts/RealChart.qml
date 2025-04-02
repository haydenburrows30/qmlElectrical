import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts
import QtQuick.Window

import "../"
import "../style"
import "../backgrounds"
import "../popups"

import "../../../scripts/MaterialDesignRegular.js" as MD

import RealTime 1.0

Pane {
    anchors.fill: parent

    property var calculator
    property bool isActive: false
    property bool showTracker: !calculator.isRunning
    

    onIsActiveChanged: {
        if (isActive) {
            calculator.activate(true)
        } else {
            calculator.activate(false)
        }
    }
        
    Timer {
        interval: 100
        running: isActive
        repeat: true
        onTriggered: calculator.update()
    }

    Connections {
        target: calculator
        function onDataUpdated(t, valA, valB, valC) {
            seriesA.append(t, valA)
            seriesB.append(t, valB)
            seriesC.append(t, valC)

            while (seriesA.count > 300) {
                seriesA.remove(0)
                seriesB.remove(0)
                seriesC.remove(0)
            }
        }

        function onResetChart() {
            seriesA.clear()
            seriesB.clear()
            seriesC.clear()
        }
    }

    ChartView {
        id: chartView
        anchors.fill: parent

        antialiasing: true
        legend.visible: true
        theme: Universal.theme

        property real trackerX: 0
        property var trackerValues: []

        ValueAxis {
            id: axisY
            min: 0
            max: 300
        }

        ValueAxis {
            id: axisX
            min: 0
            max: 30
            tickCount: 7
            titleText: "Time (s)"
        }

        LineSeries {
            id: seriesA
            name: "Alpha"
            axisX: axisX
            axisY: axisY
            color: "#ff0000"
            width: 2
        }

        LineSeries {
            id: seriesB
            name: "Beta"
            axisX: axisX
            axisY: axisY
            color: "#00cc00"
            width: 2
        }

        LineSeries {
            id: seriesC
            name: "Gamma"
            axisX: axisX
            axisY: axisY
            color: "#0000ff"
            width: 2
        }

        Rectangle {
            id: trackerLine
            visible: showTracker
            x: chartView.trackerX || 0
            y: chartView.plotArea.y
            width: 1
            height: chartView.plotArea.height
            color: "red"
            z: 1000

            Column {
                x: 5
                y: 0
                visible: parent.visible
                

                Repeater {
                    model: chartView.trackerValues
                    delegate: Rectangle {
                        width: valueLabel.width + 10
                        height: valueLabel.height + 6
                        color: modelData.color
                        radius: 3
                        
                        Label {
                            id: valueLabel
                            anchors.centerIn: parent
                            text: modelData.value.toFixed(1)
                            color: "white"
                        }
                    }
                }
            }
        }

        Rectangle {
            id: dotA
            width: 8
            height: 8
            radius: 4
            color: "#ff0000"
            visible: showTracker
            z: 1001
        }

        Rectangle {
            id: dotB
            width: 8
            height: 8
            radius: 4
            color: "#00cc00"
            visible: showTracker
            z: 1001
        }

        Rectangle {
            id: dotC
            width: 8
            height: 8
            radius: 4
            color: "#0000ff"
            visible: showTracker
            z: 1001
        }

        MouseArea {
            id: chartMouseArea
            anchors {
                fill: parent
                topMargin: 40
            }
            hoverEnabled: true
            enabled: showTracker

            onPositionChanged: (mouse) => {
                if (showTracker) {
                    let chartPoint = mouse.x - chartView.plotArea.x
                    let xValue = axisX.min + (chartPoint / chartView.plotArea.width) * (axisX.max - axisX.min)
                    
                    chartView.trackerX = chartPoint + chartView.plotArea.x
                    chartView.trackerValues = calculator.getValuesAtTime(xValue)
                    
                    if (chartView.trackerValues.length === 3) {
                        let point = Qt.point(xValue, chartView.trackerValues[0].value)
                        let pos = chartView.mapToPosition(point, seriesA)
                        dotA.x = pos.x - dotA.width/2
                        dotA.y = pos.y - dotA.height/2

                        point = Qt.point(xValue, chartView.trackerValues[1].value)
                        pos = chartView.mapToPosition(point, seriesB)
                        dotB.x = pos.x - dotB.width/2
                        dotB.y = pos.y - dotB.height/2

                        point = Qt.point(xValue, chartView.trackerValues[2].value)
                        pos = chartView.mapToPosition(point, seriesC)
                        dotC.x = pos.x - dotC.width/2
                        dotC.y = pos.y - dotC.height/2
                    }
                }
            }
        }
    }
}