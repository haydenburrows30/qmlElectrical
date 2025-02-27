import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCharts

Page {

    function updateSeries() {
        line_view.removeAllSeries()
        var series1 = line_view.createSeries(ChartView.SeriesTypeLine,"A",xAxis,yAxis)
        var series2 = line_view.createSeries(ChartView.SeriesTypeLine,"B",xAxis,yAxis)
        var series3 = line_view.createSeries(ChartView.SeriesTypeLine,"C",xAxis,yAxis)

        series1.color = "red"
        series2.color = "yellow"
        series3.color = "blue"
        threePhaseSineModel.fill_series1(line_view.series(0))
        threePhaseSineModel.fill_series2(line_view.series(1))
        threePhaseSineModel.fill_series3(line_view.series(2))
    }


    ChartView {
        id: line_view
        width: parent.width
        height: 350
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

        Component.onCompleted: updateSeries()
    }

    GroupBox {
        id: settings
        title: 'Power -> Current'
        width: 350
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10
        anchors.top: line_view.bottom

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "RMS Value A: " + threePhaseSineModel.rmsA.toFixed(2)
            }
            Label {
                text: "RMS Value B: " + threePhaseSineModel.rmsB.toFixed(2)
            }
            Label {
                text: "RMS Value C: " + threePhaseSineModel.rmsC.toFixed(2)
            }

            Label {
                text: "Peak-to-Peak Value A: " + threePhaseSineModel.peakA.toFixed(2)
            }
            Label {
                text: "Peak-to-Peak Value B: " + threePhaseSineModel.peakB.toFixed(2)
            }
            Label {
                text: "Peak-to-Peak Value C: " + threePhaseSineModel.peakC.toFixed(2)
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
}