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

    // Image {
    //     anchors.centerIn: parent
    //     fillMode: Image.PreserveAspectFit
    //     source: "../../icons/gallery/20x20/logo.png" 
    // }

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
                max: 100
                labelFormat: "%.0f"
                titleText: "Time"
            }

            ValueAxis {
                id: yAxis
                min: -2
                max: 2
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

                function updateSeries() {
                    sineSeries.clear();
                    for (var i = 0; i < sineModel.yValues.length; i++) {
                        sineSeries.append(i, sineModel.yValues[i]);
                    }
                    xAxis.max = sineModel.yValues.length;
                    yAxis.min = -sineModel.yScale * sineModel.amplitude;
                    yAxis.max = sineModel.yScale * sineModel.amplitude;
                }

                Component.onCompleted: updateSeries()

                Connections {
                    target: sineModel
                    onDataChanged: sineSeries.updateSeries()
                }
            }
        }

        Label {
            text: "RMS Value: " + sineModel.rms.toFixed(3)
        }

        Label {
            text: "Peak Value: " + sineModel.peak.toFixed(3)
        }

        Row {
            spacing: 10
            Slider {
                id: freqSlider
                from: 0.5; to: 5.0; value: 1.0
                onValueChanged: sineModel.setFrequency(value)
            }
            Label { text: "Frequency: " + freqSlider.value.toFixed(1) }
        }

        Row {
            spacing: 10
            Slider {
                id: ampSlider
                from: 0.5; to: 2.0; value: 1.0
                onValueChanged: sineModel.setAmplitude(value)
            }
            Label { text: "Amplitude: " + ampSlider.value.toFixed(1) }
        }

        Row {
            spacing: 10
            Slider {
                id: yScaleSlider
                from: 0.5; to: 5.0; value: 1.0
                onValueChanged: sineModel.setYScale(value)
            }
            Label { text: "Y Scale: " + yScaleSlider.value.toFixed(1) }
        }

        Row {
            spacing: 10
            Slider {
                id: xScaleSlider
                from: 0.5; to: 5.0; value: 1.0
                onValueChanged: sineModel.setXScale(value)
            }
            Label { text: "X Scale: " + xScaleSlider.value.toFixed(1) }
        }
    }
}