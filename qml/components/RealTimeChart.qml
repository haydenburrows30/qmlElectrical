import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

import "../components"

import RealTimeChart 1.0

ChartView {
    id: chartView
    antialiasing: true
    legend.visible: true

    theme: Universal.theme

    // only one instance of RealTimeChart.  its not declared in main.qml

    RealTimeChart {id: realTimeChart}
    
    property real viewPortStart: 0
    property real viewPortWidth: 30  // 30 seconds view

    // Add tracker properties
    property bool showTracker: !realTimeChart.isRunning
    property real trackerX: 0
    property var trackerValues: []

    // Add property to track if chart is active
    property bool isActive: false
    
    onIsActiveChanged: {
        if (isActive) {
            realTimeChart.activate(true)
        } else {
            realTimeChart.activate(false)
        }
    }

    // Move buttons to front and exclude from MouseArea
    Row {
        id: controlButtons
        z: 1001  // Above tracker line
        anchors {
            top: parent.top
            right: parent.right
            margins: 10
        }
        spacing: 10

        Button {
            text: realTimeChart.isRunning ? "Pause" : "Resume"
            onClicked: realTimeChart.toggleRunning()
        }

        Button {
            text: "Restart"
            onClicked: realTimeChart.restart()
        }
    }

    ValueAxis {
        id: axisY
        min: 0
        max: 300
    }

    ValueAxis {
        id: axisX
        min: 0
        max: 30  // Fixed 30 second window
        tickCount: 7  // Show tick every 5 seconds
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

    Connections {
        target: realTimeChart
        function onDataUpdated(t, valA, valB, valC) {
            seriesA.append(t, valA)
            seriesB.append(t, valB)
            seriesC.append(t, valC)

            // Remove old points when beyond 30 seconds
            while (seriesA.count > 300) {  // Keep 300 points for smooth display
                seriesA.remove(0)
                seriesB.remove(0)
                seriesC.remove(0)
            }
        }

        function onResetChart() {
            // Clear all series when 30s is up
            seriesA.clear()
            seriesB.clear()
            seriesC.clear()
        }
    }
    
    Timer {
        interval: 100
        running: chartView.isActive  // Only run when chart is active
        repeat: true
        onTriggered: realTimeChart.update()
    }

    // Add tracker line
    Rectangle {
        id: trackerLine
        visible: showTracker
        x: trackerX
        y: chartView.plotArea.y
        width: 1
        height: chartView.plotArea.height
        color: "red"
        z: 1000  // Ensure it's above the plot

        // Value labels
        Column {
            x: 5
            y: 0
            visible: parent.visible
            spacing: 5

            Repeater {
                model: trackerValues
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

    // Add dots to track points on series
    Rectangle {
        id: dotA
        width: 8
        height: 8
        radius: 4
        color: "#ff0000"
        visible: showTracker
        z: 1001
        // Position will be set dynamically
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

    // Modified MouseArea
    MouseArea {
        id: chartMouseArea
        anchors {
            fill: parent
            topMargin: controlButtons.height + 20  // Exclude button area
        }
        hoverEnabled: true
        enabled: showTracker

        onPositionChanged: (mouse) => {
            if (showTracker) {
                let chartPoint = mouse.x - chartView.plotArea.x
                let xValue = axisX.min + (chartPoint / chartView.plotArea.width) * (axisX.max - axisX.min)
                
                trackerX = chartPoint + chartView.plotArea.x
                trackerValues = realTimeChart.getValuesAtTime(xValue)
                
                // Position the dots using chart's mapToPosition
                if (trackerValues.length === 3) {
                    let point = Qt.point(xValue, trackerValues[0].value)
                    let pos = chartView.mapToPosition(point, seriesA)
                    dotA.x = pos.x - dotA.width/2
                    dotA.y = pos.y - dotA.height/2

                    point = Qt.point(xValue, trackerValues[1].value)
                    pos = chartView.mapToPosition(point, seriesB)
                    dotB.x = pos.x - dotB.width/2
                    dotB.y = pos.y - dotB.height/2

                    point = Qt.point(xValue, trackerValues[2].value)
                    pos = chartView.mapToPosition(point, seriesC)
                    dotC.x = pos.x - dotC.width/2
                    dotC.y = pos.y - dotC.height/2
                }
            }
        }
    }
}

