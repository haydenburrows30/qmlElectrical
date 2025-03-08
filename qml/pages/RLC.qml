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

Page {
    id: phasor

    background: Rectangle {
        color: toolBar.toggle ? "#1a1a1a" : "#f5f5f5"
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

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentHeight: mainLayout.height
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            RowLayout {
                id: mainLayout
                anchors.left: parent.left
                spacing: 5

                ColumnLayout {
                    WaveCard {
                        title: 'Series RLC Frequency Response'
                        Layout.minimumHeight: 220
                        Layout.minimumWidth: 450

                        showInfo: false
                        
                        GridLayout {
                            columns: 2

                            Label {
                                text: "Resistance (Ω):"
                                Layout.preferredWidth: 150
                            }

                            TextField {
                                id: resistanceInput
                                placeholderText: "Enter Resistance"
                                text: "10"  // Default value
                                onTextChanged: seriesRLCChart.setResistance(parseFloat(text))
                                Layout.preferredWidth: 150
                                Layout.alignment: Qt.AlignRight
                            }

                            Label {
                                text: "Inductance (H):"
                                Layout.preferredWidth: 150
                            }

                            TextField {
                                id: inductanceInput1
                                placeholderText: "Enter Inductance"
                                text: "0.1"  // Default value
                                onTextChanged: seriesRLCChart.setInductance(parseFloat(text))
                                Layout.preferredWidth: 150
                                Layout.alignment: Qt.AlignRight
                            }

                            Label {
                                text: "Capacitance (F):"
                                Layout.preferredWidth: 150
                            }

                            TextField {
                                id: capacitanceInput1
                                placeholderText: "Enter Capacitance"
                                text: "0.0001013"  // 101.3µF
                                onTextChanged: seriesRLCChart.setCapacitance(parseFloat(text))
                                Layout.preferredWidth: 150
                                Layout.alignment: Qt.AlignRight
                            }

                            Label {
                                text: "Frequency (Hz):"
                                Layout.preferredWidth: 150
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                TextField {
                                    id: minFreqInput
                                    placeholderText: "Min"
                                    text: "0"
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
                                    onTextChanged: {
                                        var min = Number(minFreqInput.text);
                                        var max = Number(text);
                                        if (!isNaN(min) && !isNaN(max) && min >= 0 && max > min) {
                                            seriesRLCChart.setFrequencyRange(min, max);
                                        }
                                    }
                                }
                            }

                            Label {
                                text: "Resonant Frequency:"
                                Layout.preferredWidth: 150
                                Layout.fillWidth:  true
                                
                            }
                            Label {
                                text: seriesRLCChart.resonantFreq.toFixed(2) + " Hz"
                                Layout.preferredWidth: 150
                                Layout.alignment: Qt.AlignHCenter
                                color: "red"
                            }
                        }
                    }

                    WaveCard {
                        title: 'Series RLC Chart'
                        Layout.minimumHeight: 500
                        Layout.minimumWidth: 450

                        showInfo: false

                        ColumnLayout {
                            anchors.fill: parent

                            ChartView {
                                id: rlcChartView
                                Layout.minimumHeight: 400
                                Layout.minimumWidth: 400
                                Layout.fillWidth: true
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
                                    var gainSeries = createSeries(ChartView.SeriesTypeLine, "Gain", axisX, axisY)

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

                            Button {
                                text: "Reset"
                                onClicked: seriesRLCChart.resetZoom()
                                Layout.fillWidth: true
                            }

                            // RowLayout {
                            //     spacing: 10
                            //     Label {
                            //         text: "Resonant Frequency:"
                            //         Layout.preferredWidth: 200
                            //     }
                            //     Text {
                            //         text: seriesRLCChart.resonantFreq.toFixed(2) + " Hz"
                            //         Layout.preferredWidth: 120
                            //         Layout.alignment: Qt.AlignRight
                            //         color: "red"
                            //     }
                            // }

                            // Label {
                            //     text: "Frequency Axis Controls:"
                            //     Layout.columnSpan: 2
                            //     Layout.alignment: Qt.AlignHCenter
                            // }

                            // RowLayout {
                                
                            //     Button {
                            //         text: "−"
                            //         onClicked: seriesRLCChart.zoomX(0.7)
                            //         Layout.fillWidth: true
                            //     }
                                
                            //     Button {
                            //         text: "+"
                            //         onClicked: seriesRLCChart.zoomX(1.5)
                            //         Layout.fillWidth: true
                            //     }
                                
                            //     Button {
                            //         text: "←"
                            //         onClicked: seriesRLCChart.panX(-0.2)
                            //         Layout.fillWidth: true
                            //     }
                                
                            //     Button {
                            //         text: "→"
                            //         onClicked: seriesRLCChart.panX(0.2)
                            //         Layout.fillWidth: true
                            //     }
                                
                            //     Button {
                            //         text: "Reset"
                            //         onClicked: seriesRLCChart.resetZoom()
                            //         Layout.fillWidth: true
                            //     }
                            // }
                        }
                    }
                }
            }
        }
    }
}

    