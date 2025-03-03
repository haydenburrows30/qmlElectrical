import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCharts
import Qt.labs.animation

import '../components'

Page {
    id: phasePage
    property bool showRMSA: false
    property bool showRMSB: false
    property bool showRMSC: false

//update graph
    function updateSeries() {
        phase_chart.removeAllSeries()
        var series1 = phase_chart.createSeries(ChartView.SeriesTypeLine,"A",xAxis,yAxis)
        var series2 = phase_chart.createSeries(ChartView.SeriesTypeLine,"B",xAxis,yAxis)
        var series3 = phase_chart.createSeries(ChartView.SeriesTypeLine,"C",xAxis,yAxis)

        series1.color = "red"
        series2.color = "yellow"
        series3.color = "blue"
        threePhaseSineModel.fill_series(phase_chart.series(0),phase_chart.series(1),phase_chart.series(2))

        if (showRMSA) {
            var rmsLineA = phase_chart.createSeries(ChartView.SeriesTypeLine, "RMSA", xAxis, yAxis)
            rmsLineA.color = "red"
            rmsLineA.append(0, threePhaseSineModel.rmsA)
            rmsLineA.append(1000, threePhaseSineModel.rmsA)
            rmsTextA.text = "RMSA: " + threePhaseSineModel.rmsA.toFixed(0)
            rmsTextA.visible = true
            rmsTextA.y = phase_chart.height - (threePhaseSineModel.rmsA - yAxis.min) / (yAxis.max - yAxis.min) * phase_chart.height
        } else {
            rmsTextA.visible = false
        }

        if (showRMSB) {
            var rmsLineB = phase_chart.createSeries(ChartView.SeriesTypeLine, "RMSB", xAxis, yAxis)
            rmsLineB.color = "yellow"
            rmsLineB.append(0, threePhaseSineModel.rmsB)
            rmsLineB.append(1000, threePhaseSineModel.rmsB)
            rmsTextB.text = "RMSB: " + threePhaseSineModel.rmsB.toFixed(0) + "V"
            rmsTextB.visible = true
            rmsTextB.y = phase_chart.height - (threePhaseSineModel.rmsB - yAxis.min) / (yAxis.max - yAxis.min) * phase_chart.height
        } else {
            rmsTextB.visible = false
        }

        if (showRMSC) {
            var rmsLineC = phase_chart.createSeries(ChartView.SeriesTypeLine, "RMSC", xAxis, yAxis)
            rmsLineC.color = "blue"
            rmsLineC.append(0, threePhaseSineModel.rmsC)
            rmsLineC.append(1000, threePhaseSineModel.rmsC)
            rmsTextC.text = "RMSC: " + threePhaseSineModel.rmsC.toFixed(0)
            rmsTextC.visible = true
            rmsTextC.y = phase_chart.height - (threePhaseSineModel.rmsC - yAxis.min) / (yAxis.max - yAxis.min) * phase_chart.height
        } else {
            rmsTextC.visible = false
        }
    }
//update phasor
    function updatePhasorDiagram() {
        phasorDiagram.phaseAngles = [threePhaseSineModel.phaseAngleA, threePhaseSineModel.phaseAngleB, threePhaseSineModel.phaseAngleC]
    }

//Popup graph settings
    BarChartPopUp {
        id: graphPanel
    }

//chart
    ChartView {
        id: phase_chart
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: phasorDiagram.left
        height: 400
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

        legend.alignment: Qt.AlignBottom

        Component.onCompleted: updateSeries()

        Text {
            id: rmsTextA
            anchors.right: parent.right
            anchors.rightMargin: 10
            color: "red"
            visible: false
        }

        Text {
            id: rmsTextB
            anchors.right: parent.right
            anchors.rightMargin: 10
            color: "yellow"
            visible: false
        }

        Text {
            id: rmsTextC
            anchors.right: parent.right
            anchors.rightMargin: 10
            color: "blue"
            visible: false
        }

        ToolTip {
            id: id_tooltip
            contentItem: Text{
                color: "#21be2b"
                text: id_tooltip.text
            }
            background: Rectangle {
                border.color: "#21be2b"
            }
        }

        Rectangle{
            id: rectang
            color: "black"
            opacity: 0.6
            visible: false
        }

        Rectangle{
            id: linemarkerx
            y: parent.plotArea.y
            height: parent.plotArea.height
            width: 1
            visible: false
            border.width: 1
            color: "red"
        }

        Rectangle{
            id: linemarkery
            x: parent.plotArea.x
            width: parent.plotArea.width
            height: 1
            visible: false
            border.width: 1
            color: "red"
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons

            onPressed: {
                var point = Qt.point(mouseX, mouseY)
                rectang.x = point.x
                rectang.y = point.y
                rectang.visible = true
            }

            onClicked: (mouse)=> {
                var point = Qt.point(mouseX, mouseY)

                if (mouse.button == Qt.LeftButton) {
                    var cp = phase_chart.mapToValue(point,phase_chart.series(0))
                    var text = qsTr("x: %1 ms, y: %2 V").arg(cp.x.toFixed(1)).arg(cp.y.toFixed(1))

                    id_tooltip.x = point.x
                    id_tooltip.y = point.y - id_tooltip.height
                    id_tooltip.text = text
                    id_tooltip.delay = 500
                    id_tooltip.timeout = 10000
                    id_tooltip.visible = true
                    graphPanel.visible = false
                } else if (mouse.button == Qt.RightButton) {
                    graphPanel.x = point.x
                    graphPanel.y = point.y
                    graphPanel.visible = true                          
                }
            }

            onMouseXChanged: {
                var point = Qt.point(mouseX, mouseY)
                rectang.width = point.x - rectang.x
                linemarkerx.visible = true
                linemarkerx.x = mouseX - linemarkerx.width/2

                var theValue = phase_chart.mapToValue(Qt.point(mouseX, mouseY), phase_chart.series(0))

                currentxyposition.text = "x: " + theValue.x.toFixed(1) + " y: " + theValue.y.toFixed(1)
            }

            onMouseYChanged: {
                var point = Qt.point(mouseX, mouseY)
                rectang.height = point.y - rectang.y

                var theValue = phase_chart.mapToValue(Qt.point(mouseX, mouseY), phase_chart.series(0))

                linemarkery.visible = true
                linemarkery.y = mouseY - linemarkery.height/2

            }

            onReleased: {
                phase_chart.zoomIn(Qt.rect(rectang.x, rectang.y, rectang.width, rectang.height))
                rectang.visible = false
            }

            onDoubleClicked: { 
                phase_chart.zoomReset()
                yAxis.min = -400
                yAxis.max = 400
                xAxis.min = 0
                xAxis.max = 1000
            }

            onPositionChanged: {
                id_tooltip.visible = false
            }

            onExited: {
                linemarkery.visible = false
                linemarkerx.visible = false
            }
        }
    }

//Phasor diagram

    PhasorDiagram {
        id: phasorDiagram
        width: 300
        height: 300
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        phaseAngles: [threePhaseSineModel.phaseAngleA, threePhaseSineModel.phaseAngleB, threePhaseSineModel.phaseAngleC]
    }

//Settings

    GroupBox {
        id: settings
        title: 'Settings'
        anchors.left: parent.left
        anchors.top: phase_chart.bottom
        anchors.leftMargin: 10

        GridLayout {
            id: grid_settings
            columns: 4

            RowLayout {
                id: toprow
                Layout.columnSpan : 4
                height: 40
                
                Label {
                    Layout.fillWidth: true
                }

                CButton {
                    id: reset
                    icon.name: 'Reset'
                    implicitWidth: 40
                    implicitHeight: 40
                    tooltip_text: "Reset"

                    onClicked: {
                        threePhaseSineModel.reset()
                        freqSlider.value = 50
                        ampSliderA.value = 230
                        ampSliderB.value = 230
                        ampSliderC.value = 230
                        phaseSliderA.value = 0
                        phaseSliderB.value = 120
                        phaseSliderC.value = 240
                        updateSeries()
                    }  
                }

                // CButton {
                //     id: graph_settings
                //     icon.name: 'Setting'
                //     implicitWidth: 40
                //     implicitHeight: 40
                //     tooltip_text: "Graph settings"

                //     onClicked: {
                //         if (graphPanel.visible == false) {
                //         graphPanel.show()
                //         }
                //         else graphPanel.close()
                //     } 
                // }
            }
            
            Label { 
                text: "Frequency: "
                Layout.alignment: Qt.AlignLeft
                }
            Slider {
                id: freqSlider
                from: 1; to: 100.0; value: 50
                stepSize: 1
                onValueChanged: {
                    threePhaseSineModel.setFrequency(value)
                    updateSeries()
                }
                WheelHandler {
                    property: "value"
                    margin: 0
                    rotationScale: 1 / 15
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

            Label { 
                    text: "RMSA: "
                    }

            Slider {
                    id: ampSliderA
                    from: 100; to: 280.0; value: 230
                    stepSize: 1.0
                    onValueChanged: {
                        threePhaseSineModel.setAmplitudeA(value * Math.sqrt(2))
                        updateSeries()
                    }

                    WheelHandler {
                        property: "value"
                        margin: 0
                        rotationScale: 2 / 15
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

            Label { 
                text: "RMSB: "
                }

            Slider {
                    id: ampSliderB
                    from: 100; to: 280.0; value: 230
                    stepSize: 1.0
                    onValueChanged: {
                        threePhaseSineModel.setAmplitudeB(value * Math.sqrt(2))
                        updateSeries()
                    }

                    WheelHandler {
                        property: "value"
                        margin: 0
                        rotationScale: 2 / 15
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

            Label { 
                text: "RMSC: "
                }

            Slider {
                id: ampSliderC
                from: 100; to: 280.0; value: 230
                stepSize: 1.0
                onValueChanged: {
                    threePhaseSineModel.setAmplitudeC(value * Math.sqrt(2))
                    updateSeries()
                }
                WheelHandler {
                    property: "value"
                    margin: 0
                    rotationScale: 2 / 15
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
                WheelHandler {
                    property: "value"
                    margin: 0
                    rotationScale: 5 / 15
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
                WheelHandler {
                    property: "value"
                    margin: 0
                    rotationScale: 5 / 15
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
                WheelHandler {
                    property: "value"
                    margin: 0
                    rotationScale: 5 / 15
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
//Values

    GroupBox {
        id: value_all
        title: 'Values'
        anchors.left: settings.right
        anchors.top: phase_chart.bottom
        anchors.leftMargin: 10

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

            Label {
                id: currentxyposition
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            }
        }
    }
}