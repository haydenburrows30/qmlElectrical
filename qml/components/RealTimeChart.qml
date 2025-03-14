import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts

import "../components"

import RealTimeChart 1.0

Item {
    id: root

        property bool isActive: false
        property bool showTracker: !realTimeChart.isRunning
        
        onIsActiveChanged: {
            if (isActive) {
                realTimeChart.activate(true)
            } else {
                realTimeChart.activate(false)
            }
        }

    RowLayout {
        anchors.fill: parent
        spacing: 5
            
            // // Scrollable area for controls
            // ScrollView {
            //     contentWidth: availableWidth
            //     Layout.preferredWidth: 350
            //     Layout.fillHeight: true

            ColumnLayout {
                Layout.fillHeight: true
                // Layout.minimumHeight: 1000
                Layout.minimumWidth: 350
                Layout.maximumWidth: 350
                spacing: 5
                
                // Wave type controls
                WaveCard {
                    title: "Wave Types"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 180

                    ColumnLayout {
                        spacing: 10
                        Layout.fillWidth: true
                        
                        Repeater {
                            model: [{name: "Alpha", color: "#ff0000"}, 
                                {name: "Beta", color: "#00cc00"}, 
                                {name: "Gamma", color: "#0000ff"}]
                            RowLayout {
                                // Layout.fillWidth: true
                                Layout.minimumWidth: 300
                                spacing: 5
                                Label { 
                                    text: modelData.name
                                    color: modelData.color
                                    Layout.minimumWidth: 80
                                }
                                ComboBox {
                                    model: ["Sine", "Square", "Sawtooth", "Triangle"]
                                    Layout.fillWidth: true
                                    onCurrentIndexChanged: realTimeChart.setWaveType(index, currentIndex)
                                }
                            }
                        }
                    }
                }

                // Wave parameters
                WaveCard {
                    title: "Parameters"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 600
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        // Layout.fillHeight: true

                        Repeater {
                            model: ["Alpha", "Beta", "Gamma"]
                            Column {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 300
                                property int index: modelData === "Alpha" ? 0 : modelData === "Beta" ? 1 : 2
                                property color waveColor: index === 0 ? "#ff0000" : index === 1 ? "#00cc00" : "#0000ff"
                                
                                Label { 
                                    text: modelData
                                    color: parent.waveColor 
                                    font.bold: true
                                }
                                
                                Grid {
                                    columns: 2
                                    spacing: 5
                                    width: parent.width

                                    Label { text: "Frequency:" }
                                    Slider {
                                        id: freqSlider
                                        width: parent.width - 70
                                        from: 0.1; to: 2.0
                                        Component.onCompleted: value = realTimeChart.frequencies[index]
                                        onMoved: realTimeChart.setFrequency(index, value)
                                    }
                                    
                                    Label { text: "Amplitude:" }
                                    Slider {
                                        id: ampSlider
                                        width: parent.width - 70
                                        from: 10; to: 100
                                        Component.onCompleted: value = realTimeChart.amplitudes[index]
                                        onMoved: realTimeChart.setAmplitude(index, value)
                                    }
                                    
                                    Label { text: "Offset:" }
                                    Slider {
                                        id: offsetSlider
                                        width: parent.width - 70
                                        from: 50; to: 250
                                        Component.onCompleted: value = realTimeChart.offsets[index]
                                        onMoved: realTimeChart.setOffset(index, value)
                                    }
                                    
                                    Label { text: "Phase:" }
                                    Slider {
                                        id: phaseSlider
                                        width: parent.width - 70
                                        from: -Math.PI; to: Math.PI
                                        Component.onCompleted: value = realTimeChart.phases[index]
                                        onMoved: realTimeChart.setPhase(index, value)
                                    }
                                }
                            }
                        }
                    }
                }

                // // Control buttons
                WaveCard {
                    title: "Controls"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 80
                    
                    RowLayout {
                        Button {
                            text: realTimeChart.isRunning ? "Pause" : "Resume"
                            onClicked: realTimeChart.toggleRunning()
                            Layout.fillWidth: true
                        }
                        Button {
                            text: "Restart"
                            onClicked: realTimeChart.restart()
                            icon.name: "view-refresh"
                            Layout.fillWidth: true
                        }
                    }
                }

                // Save/Load
                WaveCard {
                    title: "Configuration"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 80
                    
                    RowLayout {
                        spacing: 10
                        Button {
                            text: "Save"
                            onClicked: realTimeChart.saveConfiguration()
                            Layout.fillWidth: true
                        }
                        Button {
                            text: "Load"
                            onClicked: realTimeChart.loadConfiguration()
                            Layout.fillWidth: true
                        }
                    }
                }

                Label {Layout.fillHeight: true}
            }

        // Chart
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: sideBar.toggle1 ? "black" : "white"

            ChartView {
                id: chartView
                anchors.fill: parent
                antialiasing: true
                legend.visible: true
                theme: Universal.theme

                RealTimeChart { id: realTimeChart }

                property real viewPortStart: 0
                property real viewPortWidth: 30  // 30 seconds view
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
                    running: root.isActive  // Changed from chartView.isActive
                    repeat: true
                    onTriggered: realTimeChart.update()
                }

                // Add tracker line
                Rectangle {
                    id: trackerLine
                    visible: root.showTracker  // Changed from showTracker
                    x: chartView.trackerX || 0
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

                // Add dots to track points on series
                Rectangle {
                    id: dotA
                    width: 8
                    height: 8
                    radius: 4
                    color: "#ff0000"
                    visible: root.showTracker  // Changed from showTracker
                    z: 1001
                    // Position will be set dynamically
                }

                Rectangle {
                    id: dotB
                    width: 8
                    height: 8
                    radius: 4
                    color: "#00cc00"
                    visible: root.showTracker  // Changed from showTracker
                    z: 1001
                }

                Rectangle {
                    id: dotC
                    width: 8
                    height: 8
                    radius: 4
                    color: "#0000ff"
                    visible: root.showTracker  // Changed from showTracker
                    z: 1001
                }

                // Modified MouseArea
                MouseArea {
                    id: chartMouseArea
                    anchors {
                        fill: parent
                        topMargin: 40  // Exclude button area
                    }
                    hoverEnabled: true
                    enabled: root.showTracker  // Changed from showTracker

                    onPositionChanged: (mouse) => {
                        if (root.showTracker) {  // Changed from showTracker
                            let chartPoint = mouse.x - chartView.plotArea.x
                            let xValue = axisX.min + (chartPoint / chartView.plotArea.width) * (axisX.max - axisX.min)
                            
                            chartView.trackerX = chartPoint + chartView.plotArea.x
                            chartView.trackerValues = realTimeChart.getValuesAtTime(xValue)
                            
                            // Position the dots using chart's mapToPosition
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
    }
}