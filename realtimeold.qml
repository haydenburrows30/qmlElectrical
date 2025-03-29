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

import RealTimeChart 1.0

Pane {
    id: root
    anchors.fill: parent
    property bool isActive: false
    property bool showTracker: !realTimeChart.isRunning

    background: Rectangle {
        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
    }
    
    onIsActiveChanged: {
        if (isActive) {
            realTimeChart.activate(true)
        } else {
            realTimeChart.activate(false)
        }
    }

    FontLoader {
        id: iconFont
        source: "../../../icons/MaterialIcons-Regular.ttf"
    }

    RealTimePopup {
        id: tipsPopup
    }

    RowLayout {
        anchors.fill: parent
        spacing: Style.spacing
            
        ColumnLayout {
            id: mainLayout
            Layout.fillHeight: true
            Layout.minimumWidth: 350
            Layout.maximumWidth: 350
            spacing: Style.spacing

            ButtonCard {
                Layout.fillWidth: true
                Layout.minimumHeight: 80

                RowLayout {
                    anchors.centerIn: parent

                    ShadowRectangle {
                        Layout.alignment: Qt.AlignLeft
                        implicitHeight: 52
                        implicitWidth: 52
                        radius: implicitHeight / 2
                        ImageButton {
                            anchors.centerIn: parent
                            iconName: realTimeChart.isRunning ? '\ue034' : '\ue037'
                            iconWidth: 24
                            iconHeight: 24
                            color: realTimeChart.isRunning ? Style.red : Style.green
                            backgroundColor: Style.alphaColor(color,0.1)
                            onClicked: {
                                realTimeChart.toggleRunning()
                            }
                        }
                    }
                    ShadowRectangle {
                        Layout.alignment: Qt.AlignLeft
                        implicitHeight: 52
                        implicitWidth: 52
                        radius: implicitHeight / 2
                        ImageButton {
                            anchors.centerIn: parent
                            iconName: '\uf053'
                            iconWidth: 24
                            iconHeight: 24
                            color: Style.blueGreen
                            backgroundColor: Style.alphaColor(color,0.1)
                            onClicked: {
                                realTimeChart.restart()
                            }
                        }
                    }

                    ShadowRectangle {
                        Layout.alignment: Qt.AlignRight
                        implicitHeight: 52
                        implicitWidth: 52
                        radius: implicitHeight / 2
                        ImageButton {
                            anchors.centerIn: parent
                            iconName: '\ue161'
                            iconWidth: 24
                            iconHeight: 24
                            color: Style.black
                            backgroundColor: Style.alphaColor(color,0.1)
                            onClicked: {
                                realTimeChart.saveConfiguration()
                            }
                        }
                    }
                    ShadowRectangle {
                        Layout.alignment: Qt.AlignRight
                        implicitHeight: 52
                        implicitWidth: 52
                        radius: implicitHeight / 2
                        ImageButton {
                            anchors.centerIn: parent
                            iconName: '\ue2c6'
                            iconWidth: 24
                            iconHeight: 24
                            color: Style.charcoalGrey
                            backgroundColor: Style.alphaColor(color,0.1)
                            onClicked: {
                                realTimeChart.loadConfiguration()
                            }
                        }
                    }
                }
            }
            
            // Wave type controls
            WaveCard {
                title: "Wave Types"
                Layout.fillWidth: true
                Layout.minimumHeight: 180
                id: results
                showSettings: true

                ColumnLayout {
                    spacing: Style.spacing
                    Layout.fillWidth: true
                    
                    Repeater {
                        model: [{name: "Alpha", color: "#ff0000"}, 
                            {name: "Beta", color: "#00cc00"}, 
                            {name: "Gamma", color: "#0000ff"}]
                        RowLayout {
                            Layout.minimumWidth: 300
                            spacing: Style.spacing
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
                                spacing: Style.spacing
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
        }

        // Chart
        WaveCard {
            title: "Real Time Chart"
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
                property real viewPortWidth: 30
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

                Connections {
                    target: realTimeChart
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
                
                Timer {
                    interval: 100
                    running: root.isActive
                    repeat: true
                    onTriggered: realTimeChart.update()
                }

                Rectangle {
                    id: trackerLine
                    visible: root.showTracker
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
                        spacing: Style.spacing

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
                    visible: root.showTracker
                    z: 1001
                }

                Rectangle {
                    id: dotB
                    width: 8
                    height: 8
                    radius: 4
                    color: "#00cc00"
                    visible: root.showTracker
                    z: 1001
                }

                Rectangle {
                    id: dotC
                    width: 8
                    height: 8
                    radius: 4
                    color: "#0000ff"
                    visible: root.showTracker
                    z: 1001
                }

                MouseArea {
                    id: chartMouseArea
                    anchors {
                        fill: parent
                        topMargin: 40
                    }
                    hoverEnabled: true
                    enabled: root.showTracker

                    onPositionChanged: (mouse) => {
                        if (root.showTracker) {
                            let chartPoint = mouse.x - chartView.plotArea.x
                            let xValue = axisX.min + (chartPoint / chartView.plotArea.width) * (axisX.max - axisX.min)
                            
                            chartView.trackerX = chartPoint + chartView.plotArea.x
                            chartView.trackerValues = realTimeChart.getValuesAtTime(xValue)
                            
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