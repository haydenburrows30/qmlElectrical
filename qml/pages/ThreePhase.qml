import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCharts

import '../components'

Page {

    function updateSeries() {
        phase_chart.removeAllSeries()
        var series1 = phase_chart.createSeries(ChartView.SeriesTypeLine,"A",xAxis,yAxis)
        var series2 = phase_chart.createSeries(ChartView.SeriesTypeLine,"B",xAxis,yAxis)
        var series3 = phase_chart.createSeries(ChartView.SeriesTypeLine,"C",xAxis,yAxis)

        series1.color = "red"
        series2.color = "yellow"
        series3.color = "blue"
        threePhaseSineModel.fill_series(phase_chart.series(0),phase_chart.series(1),phase_chart.series(2))
    }

    function updatePhasorDiagram() {
        phasorDiagram.phaseAngles = [threePhaseSineModel.phaseAngleA, threePhaseSineModel.phaseAngleB, threePhaseSineModel.phaseAngleC]
    }

    ChartView {
        id: phase_chart
        width: parent.width
        height: 350
        antialiasing: true
        animationOptions: ChartView.NoAnimation

        theme: Universal.theme

        ValueAxis {
            id: xAxis
            min: 0
            max: 1000
            labelFormat: "%.0f"
            titleText: "Time (ms)"
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
        title: 'Settings'
        // Layout.fillWidth: true
        anchors.left: parent.left
        anchors.top: phase_chart.bottom
        anchors.leftMargin: 5
        GridLayout {
            anchors.fill: parent
            columns: 4
            Label { 
                text: "Frequency: "
                Layout.alignment: Qt.AlignHCenter
                }
            Slider {
                id: freqSlider
                from: 1; to: 100.0; value: 50
                stepSize: 1.0
                onValueChanged: {
                    threePhaseSineModel.setFrequency(value)
                    updateSeries()
                }
            }

            TextField { 
                text: freqSlider.value.toFixed(0)
                validator: IntValidator{bottom: 1; top: 100;}
                inputMethodHints: Qt.ImhDigitsOnly
                onEditingFinished: {
                    freqSlider.value = text
                    threePhaseSineModel.setFrequency(text)
                    updateSeries()
                }
                onFocusChanged:{
                    if(focus)
                        selectAll()
                }
            }
            Label { text: "Hz" }

            Label { text: "RMSA: "}

            Slider {
                    id: ampSliderA
                    from: 100; to: 400.0; value: 230
                    stepSize: 1.0
                    onValueChanged: {
                        threePhaseSineModel.setAmplitudeA(value * Math.sqrt(2))
                        updateSeries()
                    }
                }
            TextField { 
                text: ampSliderA.value.toFixed(0)
                validator: IntValidator{bottom: 100; top: 400;}
                inputMethodHints: Qt.ImhDigitsOnly
                onEditingFinished: {
                    ampSliderA.value = text
                    threePhaseSineModel.setAmplitudeA(text * Math.sqrt(2))
                    updateSeries()
                }
                onFocusChanged:{
                    if(focus)
                        selectAll()
                }
            }
            Label { text: "V" }

            Label { text: "RMSB: " }

            Slider {
                    id: ampSliderB
                    from: 100; to: 400.0; value: 230
                    stepSize: 1.0
                    onValueChanged: {
                        threePhaseSineModel.setAmplitudeB(value * Math.sqrt(2))
                        updateSeries()
                    }
                }
            TextField { 
                text: ampSliderB.value.toFixed(0)
                validator: IntValidator{bottom: 100; top: 400;}
                inputMethodHints: Qt.ImhDigitsOnly
                onEditingFinished: {
                    ampSliderB.value = text
                    threePhaseSineModel.setAmplitudeB(text * Math.sqrt(2))
                    updateSeries()
                }
                onFocusChanged:{
                    if(focus)
                        selectAll()
                }
            }

            Label { text: "V" }

            Label { text: "RMSC: "}

            Slider {
                id: ampSliderC
                from: 100; to: 400.0; value: 230
                stepSize: 1.0
                onValueChanged: {
                    threePhaseSineModel.setAmplitudeC(value * Math.sqrt(2))
                    updateSeries()
                }
            }

            TextField { 
                text: ampSliderC.value.toFixed(0)
                validator: IntValidator{bottom: 100; top: 400;}
                inputMethodHints: Qt.ImhDigitsOnly
                onEditingFinished: {
                    ampSliderC.value = text
                    threePhaseSineModel.setAmplitudeC(text * Math.sqrt(2))
                    updateSeries()
                }

                onFocusChanged:{
                    if(focus)
                        selectAll()
                }
            }

            Label { text: "V" }

            Label { text: "Phase Angle A: " }
            Slider {
                id: phaseSliderA
                from: 0; to: 360.0; value: 0
                stepSize: 1.0
                onValueChanged: {
                    threePhaseSineModel.setPhaseAngleA(value)
                    updateSeries()
                }
            }
            TextField { 
                text: phaseSliderA.value.toFixed(0)
                validator: IntValidator{bottom: 0; top: 360;}
                inputMethodHints: Qt.ImhDigitsOnly
                onEditingFinished: {
                    phaseSliderA.value = text
                    threePhaseSineModel.setPhaseAngleA(text)
                    updateSeries()
                }
                onFocusChanged:{
                    if(focus)
                        selectAll()
                }
            }
            Label { text: "°" }

            Label { text: "Phase Angle B: " }
            Slider {
                id: phaseSliderB
                from: 0; to: 360.0; value: 120
                stepSize: 1.0
                onValueChanged: {
                    threePhaseSineModel.setPhaseAngleB(value)
                    updateSeries()
                }
            }
            TextField { 
                text: phaseSliderB.value.toFixed(0)
                validator: IntValidator{bottom: 0; top: 360;}
                inputMethodHints: Qt.ImhDigitsOnly
                onEditingFinished: {
                    phaseSliderB.value = text
                    threePhaseSineModel.setPhaseAngleB(text)
                    updateSeries()
                }
                onFocusChanged:{
                    if(focus)
                        selectAll()
                }
            }
            Label { text: "°" }

            Label { text: "Phase Angle C: " }
            Slider {
                id: phaseSliderC
                from: 0; to: 360.0; value: 240
                stepSize: 1.0
                onValueChanged: {
                    threePhaseSineModel.setPhaseAngleC(value)
                    updateSeries()
                }
            }
            TextField { 
                text: phaseSliderC.value.toFixed(0)
                validator: IntValidator{bottom: 0; top: 360;}
                inputMethodHints: Qt.ImhDigitsOnly
                onEditingFinished: {
                    phaseSliderC.value = text
                    threePhaseSineModel.setPhaseAngleC(text)
                    updateSeries()
                }
                onFocusChanged:{
                    if(focus)
                        selectAll()
                }
            }
            Label { text: "°" }
        }
    }

    GroupBox {
        id: settingsA
        title: 'Values'
        // Layout.fillWidth: true
        anchors.left: settings.right
        anchors.top: phase_chart.bottom
        anchors.leftMargin: 5
        GridLayout {
            anchors.fill: parent
            columns: 3

            Label {
                text: ""
            }

            Label {
                text: "Pk-Pk: "
            }

            Label {
                text: "Ph-Ph"
            }

            Label {
                text: "A: "
            }

            // TextField {
            //     text: threePhaseSineModel.rmsA.toFixed(0)
            //     onEditingFinished: {
            //         threePhaseSineModel.setAmplitudeA(text * Math.sqrt(2))
            //         ampSliderA.value = text * Math.sqrt(2)
            //         updateSeries()
            //     }
            //     onFocusChanged:{
            //         if(focus)
            //             selectAll()
            //     }
            // }

            Label {
                text: threePhaseSineModel.peakA.toFixed(0)
            }

            Label {
                text: + threePhaseSineModel.rmsAB.toFixed(0)
            }

            Label {
                text: "B: "
            }

            Label {
                text: threePhaseSineModel.peakB.toFixed(0)
            }

            Label {
                text: threePhaseSineModel.rmsBC.toFixed(0)
            }

            Label {
                text: "C: "
            }

            Label {
                text: threePhaseSineModel.peakC.toFixed(0)
            }

            Label {
                text: threePhaseSineModel.rmsCA.toFixed(0)
            }
        }
    }

    PhasorDiagram {
        id: phasorDiagram
        width: parent.width
        height: 200
        anchors.top: settingsA.bottom
        anchors.topMargin: 10
        phaseAngles: [threePhaseSineModel.phaseAngleA, threePhaseSineModel.phaseAngleB, threePhaseSineModel.phaseAngleC]
    }
}