import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCharts

Page {
    id: home

    MouseArea {
        anchors.fill: parent

        onClicked:  {
            sideBar.close()
        }
    }

    function updateSeries() {
        line_view.removeAllSeries()
        var series1 = line_view.createSeries(ChartView.SeriesTypeLine,"Pressure",xAxis,yAxis)
        var series2 = line_view.createSeries(ChartView.SeriesTypeLine,"Pressure",xAxis,yAxis)
        var series3 = line_view.createSeries(ChartView.SeriesTypeLine,"Pressure",xAxis,yAxis)
        threePhaseSineModel.fill_series1(line_view.series(0))
        threePhaseSineModel.fill_series2(line_view.series(1))
        threePhaseSineModel.fill_series3(line_view.series(2))
        // threePhaseSineModel.fill_series(line_view.series(2))

    }

    Column {
        anchors.fill: parent
        spacing: 10

        ChartView {
            id: line_view
            width: parent.width
            height: 250
            antialiasing: true
            animationOptions: ChartView.NoAnimation

            ValueAxis {
                id: xAxis
                min: 0
                max: 100
                labelFormat: "%.0f"
                titleText: "Time"
            }

            ValueAxis {
                id: yAxis
                min: -400
                max: 400
                labelFormat: "%.1f"
                titleText: "Amplitude"
            }

            // Component.onCompleted: updateSeries()
        }

        Label {
            text: "RMS Value: " + threePhaseSineModel.rmsA.toFixed(2)
        }
        Label {
            text: "RMS Value: " + threePhaseSineModel.rmsB.toFixed(2)
        }
        Label {
            text: "RMS Value: " + threePhaseSineModel.rmsC.toFixed(2)
        }

        Label {
            text: "Peak-to-Peak Value: " + threePhaseSineModel.peakA.toFixed(2)
        }
        Label {
            text: "Peak-to-Peak Value: " + threePhaseSineModel.peakB.toFixed(2)
        }
        Label {
            text: "Peak-to-Peak Value: " + threePhaseSineModel.peakC.toFixed(2)
        }
        Label {
            text: "Frequency: " + threePhaseSineModel.frequency.toFixed(1)
        }

        Row {
            spacing: 10
            Slider {
                id: freqSlider
                from: 1; to: 50.0; value: 50
                onValueChanged: {
                    threePhaseSineModel.setFrequency(value)
                    updateSeries()
                }
            }
            Label { text: "Frequency: " + freqSlider.value.toFixed(1) }
        }

        Row {
            spacing: 10
            Slider {
                id: ampSlider
                from: 100; to: 400.0; value: 330
                onValueChanged: {
                    threePhaseSineModel.setAmplitude(value)
                    updateSeries()
                }
            }
            Label { text: "Amplitude: " + ampSlider.value.toFixed(1) }
        }
    }
}