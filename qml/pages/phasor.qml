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

//|22/Button|36/Image|41/Content|
//|127/Button|140/Image|145/Content|
//|247/Button|260/Image|265/Content|
//|331/End|

Page {
    id: phasor

// Series RLC Chart
    GroupBox {
        id: seriesRLC
        title: 'Series RLC Gain Chart'
        width: 500
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.topMargin: 10
        anchors.leftMargin: 10
        anchors.bottomMargin: 10

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                spacing: 10

                Label {
                    text: "Resistance (Ω):"
                    Layout.preferredWidth: 110
                }

                TextField {
                    id: resistanceInput
                    placeholderText: "Enter Resistance"
                    text: "10"  // Default value
                    onTextChanged: seriesRLCChart.setResistance(parseFloat(text))
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Inductance (H):"
                    Layout.preferredWidth: 110
                }

                TextField {
                    id: inductanceInput1
                    placeholderText: "Enter Inductance"
                    text: "0.1"  // Default value
                    onTextChanged: seriesRLCChart.setInductance(parseFloat(text))
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Capacitance (F):"
                    Layout.preferredWidth: 110
                }

                TextField {
                    id: capacitanceInput1
                    placeholderText: "Enter Capacitance"
                    text: "0.0001013"  // 101.3µF
                    onTextChanged: seriesRLCChart.setCapacitance(parseFloat(text))
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Frequency (Hz):"
                    Layout.preferredWidth: 110
                }

                TextField {
                    id: minFreqInput
                    placeholderText: "Min"
                    text: "0"
                    Layout.preferredWidth: 60
                    onTextChanged: {
                        var min = Number(text);
                        var max = Number(maxFreqInput.text);
                        if (!isNaN(min) && !isNaN(max) && min >= 0 && max > min) {
                            seriesRLCChart.setFrequencyRange(min, max);
                        }
                    }
                }

                Label {
                    text: "to"
                }

                TextField {
                    id: maxFreqInput
                    placeholderText: "Max"
                    text: "100"
                    Layout.preferredWidth: 60
                    onTextChanged: {
                        var min = Number(minFreqInput.text);
                        var max = Number(text);
                        if (!isNaN(min) && !isNaN(max) && min >= 0 && max > min) {
                            seriesRLCChart.setFrequencyRange(min, max);
                        }
                    }
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Frequency Axis Controls:"
                    Layout.preferredWidth: 150
                }
                
                Button {
                    text: "−"
                    onClicked: seriesRLCChart.zoomX(0.7)
                }
                
                Button {
                    text: "+"
                    onClicked: seriesRLCChart.zoomX(1.5)
                }
                
                Button {
                    text: "←"
                    onClicked: seriesRLCChart.panX(-0.2)
                }
                
                Button {
                    text: "→"
                    onClicked: seriesRLCChart.panX(0.2)
                }
                
                Button {
                    text: "Reset"
                    onClicked: seriesRLCChart.resetZoom()
                }
            }

            ChartView {
                id: rlcChartView
                width: parent.width
                height: 400
                antialiasing: true

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    property point lastMousePos

                    onPressed: (mouse)=> {
                        lastMousePos = Qt.point(mouse.x, mouse.y)
                    }

                    onPositionChanged: (mouse)=> {
                        if (pressed) {
                            // Calculate drag distance and pan chart
                            var dx = (mouse.x - lastMousePos.x) / width
                            seriesRLCChart.panX(-dx)
                            lastMousePos = Qt.point(mouse.x, mouse.y)
                        }
                    }

                    onWheel: (wheel)=> {
                        if (wheel.angleDelta.y > 0) {
                            seriesRLCChart.zoomX(0.9)  // Zoom in
                        } else {
                            seriesRLCChart.zoomX(1.1)  // Zoom out
                        }
                    }
                }

                Component.onCompleted: {
                    // Create series programmatically
                    var gainSeries = createSeries(ChartView.SeriesTypeLine, "Gain", axisX, axisY)
                    // gainSeries.useOpenGL = true
                    gainSeries.color = "blue"
                    gainSeries.width = 2
                    
                    var resonantSeries = createSeries(ChartView.SeriesTypeLine, "Resonant Frequency", axisX, axisY)
                    resonantSeries.color = "red"
                    resonantSeries.width = 2
                    resonantSeries.style = Qt.DashLine

                    // Initialize with default values
                    seriesRLCChart.setResistance(10.0)
                    seriesRLCChart.setInductance(0.1)
                    seriesRLCChart.setCapacitance(0.0001013)
                    seriesRLCChart.setFrequencyRange(0, 100)
                }

                ValueAxis {
                    id: axisX
                    min: 0
                    max: 1000
                    tickCount: 10
                    labelFormat: "%.1f"
                    titleText: "Frequency (Hz)"
                }

                ValueAxis {
                    id: axisY
                    min: 0
                    max: 100
                    tickCount: 10
                    labelFormat: "%.3f"
                    titleText: "Gain (ratio)"
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Resonant Frequency:"
                    Layout.preferredWidth: 200
                }
                Text {
                    text: seriesRLCChart.resonantFreq.toFixed(2) + " Hz"
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                    color: "red"
                }
            }

            Connections {
                target: seriesRLCChart
                function onFormattedDataChanged(data) {
                    var gainSeries = rlcChartView.series(0)
                    var resonantSeries = rlcChartView.series(1)
                    
                    gainSeries.clear()
                    resonantSeries.clear()
                    
                    // Use Python fill_series for gain data
                    seriesRLCChart.fill_series(gainSeries)
                    
                    // Fill resonant line directly since it's just 2 points
                    resonantSeries.append(data[1][0].x, data[1][0].y)
                    resonantSeries.append(data[1][1].x, data[1][1].y)
                }

                function onAxisRangeChanged() {
                    axisX.min = seriesRLCChart.axisXMin
                    axisX.max = seriesRLCChart.axisXMax
                    axisY.min = seriesRLCChart.axisYMin
                    axisY.max = seriesRLCChart.axisYMax
                }
            }
        }
    }

    GroupBox {
        id: phasorPlot
        title: 'Phasor Plot'
        anchors.left: seriesRLC.right
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.leftMargin: 10

        ColumnLayout {
            anchors.fill: parent
            spacing: 20

            GridLayout {
                columns: 4
                Layout.fillWidth: true
                rowSpacing: 10
                columnSpacing: 20

                Label { text: "Magnitude:" }
                TextField {
                    id: magnitudeInput
                    text: "1.0"
                    onTextChanged: {
                        let val = parseFloat(text)
                        if (!isNaN(val)) {
                            phasorPlotter.setMagnitude(val)
                        }
                    }
                    Layout.preferredWidth: 100
                }

                Label { text: "Angle (°):" }
                TextField {
                    id: angleInput
                    text: "0"
                    onTextChanged: {
                        let val = parseFloat(text)
                        if (!isNaN(val)) {
                            phasorPlotter.setAngle(val)
                        }
                    }
                    Layout.preferredWidth: 100
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 300
                Layout.minimumWidth: 300

                PhasorDisplay {
                    id: phasorPlotter
                    anchors.fill: parent
                    anchors.margins: 10
                }
            }
        }
    }
}