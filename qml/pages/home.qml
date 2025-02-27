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
        sineSeries.clear();
        for (var i = 0; i < sineModel.yValues.length; i++) {
            sineSeries.append(i, sineModel.yValues[i]);
        }
        // xAxis.max = sineModel.yValues.length;
        // yAxis.min = -sineModel.yScale * sineModel.amplitude;
        // yAxis.max = sineModel.yScale * sineModel.amplitude;
    }

    Column {
        anchors.fill: parent
        spacing: 10

        ChartView {
            width: parent.width
            height: 250
            antialiasing: true

            ValueAxis {
                id: xAxis
                min: 0
                max: 50
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

            LineSeries {
                name: "Sine Wave"
                id: sineSeries
                useOpenGL: true
                color: "blue"
                axisX: xAxis
                axisY: yAxis

                Component.onCompleted: updateSeries()
            }
        }

        Label {
            text: "RMS Value: " + sineModel.rms.toFixed(1)
        }

        Label {
            text: "Peak Value: " + sineModel.peak.toFixed(1)
        }

        Row {
            spacing: 10
            Slider {
                id: freqSlider
                from: 1; to: 50.0; value: 50
                onValueChanged: {
                    sineModel.setFrequency(value)
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
                    sineModel.setAmplitude(value)
                    updateSeries()
                }
            }
            Label { text: "Amplitude: " + ampSlider.value.toFixed(1) }
        }

        // Row {
        //     spacing: 10
        //     Slider {
        //         id: yScaleSlider
        //         from: 0.5; to: 5.0; value: 1.0
        //         onValueChanged: sineModel.setYScale(value)
        //     }
        //     Label { text: "Y Scale: " + yScaleSlider.value.toFixed(1) }
        // }

        // Row {
        //     spacing: 10
        //     Slider {
        //         id: xScaleSlider
        //         from: 0.5; to: 5.0; value: 1.0
        //         onValueChanged: sineModel.setXScale(value)
        //     }
        //     Label { text: "X Scale: " + xScaleSlider.value.toFixed(1) }
        // }
    }
}