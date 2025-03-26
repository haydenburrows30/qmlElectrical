import QtQuick
import QtCharts
import QtQuick.Controls

ChartView {
    id: chartView
    antialiasing: true
    legend.visible: false

    theme: Universal.theme

    property bool showRmsA: false
    property bool showRmsB: false
    property bool showRmsC: false

    property bool showTracker: true

    property real trackerX: 0
    property var trackerValues: []

    Component.onCompleted: {
        if (sineModel) {
            sineModel.fill_series(seriesA, seriesB, seriesC)
        }
    }

    Connections {
        target: sineModel
        function onDataChanged() {
            sineModel.fill_series(seriesA, seriesB, seriesC)
        }
    }

    function autoScale() {
        let maxA = 0, maxB = 0, maxC = 0;
        
        for(let i = 0; i < seriesA.count; i++) {
            maxA = Math.max(maxA, Math.abs(seriesA.at(i).y));
            maxB = Math.max(maxB, Math.abs(seriesB.at(i).y));
            maxC = Math.max(maxC, Math.abs(seriesC.at(i).y));
        }
        
        let maxVal = Math.max(maxA, maxB, maxC);
        maxVal = maxVal * 1.1;
        axisY.min = -maxVal;
        axisY.max = maxVal;
    }

    ValueAxis {
        id: axisY
        min: -400
        max: 400
        titleText: "Voltage (V)"
    }

    ValueAxis {
        id: axisX
        min: 0
        max: 1000
        titleText: "Time (ms)"
    }

    LineSeries {
        id: seriesA
        axisX: axisX
        axisY: axisY
        color: "#f44336"
        width: 2
        name: "Phase A" + (chartView.showRmsA ? " (RMS: " + sineModel.rmsA.toFixed(1) + "V)" : "")
    }

    LineSeries {
        id: seriesB
        axisX: axisX
        axisY: axisY
        color: "#4caf50"
        width: 2
        name: "Phase B" + (chartView.showRmsB ? " (RMS: " + sineModel.rmsB.toFixed(1) + "V)" : "")
    }

    LineSeries {
        id: seriesC
        axisX: axisX
        axisY: axisY
        color: "#2196f3"
        width: 2
        name: "Phase C" + (chartView.showRmsC ? " (RMS: " + sineModel.rmsC.toFixed(1) + "V)" : "")
    }


    Rectangle {
        id: trackerLine
        visible: showTracker
        x: trackerX
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
            spacing: Style.spacing

            Repeater {
                model: trackerValues
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
        visible: showTracker
        z: 1001
    }

    Rectangle {
        id: dotB
        width: 8
        height: 8
        radius: 4
        color: "#00cc00"
        visible: showTracker
        z: 1001
    }

    Rectangle {
        id: dotC
        width: 8
        height: 8
        radius: 4
        color: "#0000ff"
        visible: showTracker
        z: 1001
    }

    PinchArea {
        id: pa
        anchors.fill: parent
        property real currentPinchScaleX: 1
        property real currentPinchScaleY: 1
        property real pinchStartX: 0
        property real pinchStartY: 0

        onPinchStarted: function(event) {
            pinchStartX = event.center.x
            pinchStartY = event.center.y
        }

        onPinchUpdated: function(event) {
            chartView.zoomReset()

            var center_x = pinchStartX + (pinchStartX - event.center.x)
            var center_y = pinchStartY + (pinchStartY - event.center.y)

            var scaleX = currentPinchScaleX * (1 + (event.scale - 1) * Math.abs(Math.cos(event.angle * Math.PI / 180)))
            var scaleY = currentPinchScaleY * (1 + (event.scale - 1) * Math.abs(Math.sin(event.angle * Math.PI / 180)))

            var width_zoom = height / scaleX
            var height_zoom = width / scaleY

            var r = Qt.rect(center_x - width_zoom / 2, center_y - height_zoom / 2, width_zoom, height_zoom)
            chartView.zoomIn(r)
        }

        onPinchFinished: function(event) {
            currentPinchScaleX = currentPinchScaleX * (1 + (event.scale - 1) * Math.abs(Math.cos(event.angle * Math.PI / 180)))
            currentPinchScaleY = currentPinchScaleY * (1 + (event.scale - 1) * Math.abs(Math.sin(event.angle * Math.PI / 180)))
        }

        MouseArea{
            anchors.fill: parent
            drag.target: dragTarget
            drag.axis: Drag.XAndYAxis
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true

            onExited: hideTracker()

            onDoubleClicked: {                   
                chartView.zoomReset();
                parent.currentPinchScaleX = 1;
                parent.currentPinchScaleY = 1;
            }

            onWheel: (wheel)=> {
                if (wheel.angleDelta.y > 0) {
                    chartView.zoom(0.9)
                } else {
                    chartView.zoom(1.1)
                }
            }

            onClicked: function(mouse) {
                if (mouse.button == Qt.RightButton) {
                    contextMenu.popup()
                }
            }

            function hideTracker() {
                trackerValues = []
                dotA.visible = false
                dotB.visible = false
                dotC.visible = false
            }

            onPositionChanged: (mouse) => {
            if (!mouse || !sineModel) {
                hideTracker();
                return;
            }

            let chartPoint = mouse.x - chartView.plotArea.x
            if (chartPoint < 0 || chartPoint > chartView.plotArea.width) {
                hideTracker();
                return;
            }

            let xValue = axisX.min + (chartPoint / chartView.plotArea.width) * (axisX.max - axisX.min)
            trackerX = chartPoint + chartView.plotArea.x

            let values = sineModel.calculate_values_at(xValue)

            if (!values || values.length !== 3) {
                console.log("Invalid values returned from Python");
                hideTracker();
                return;
            }

            let valA = Number(values[0]);
            let valB = Number(values[1]);
            let valC = Number(values[2]);

            if (isNaN(valA) || isNaN(valB) || isNaN(valC)) {
                console.log("Invalid number conversion");
                hideTracker();
                return;
            }

            trackerValues = [
                { color: seriesA.color, value: valA },
                { color: seriesB.color, value: valB },
                { color: seriesC.color, value: valC }
            ]

            let posA = chartView.mapToPosition(Qt.point(xValue, valA), seriesA)
            let posB = chartView.mapToPosition(Qt.point(xValue, valB), seriesB)
            let posC = chartView.mapToPosition(Qt.point(xValue, valC), seriesC)

            if (!isNaN(posA.x) && !isNaN(posA.y)) {
                dotA.x = posA.x - dotA.width/2
                dotA.y = posA.y - dotA.height/2
                dotA.visible = true
            }

            if (!isNaN(posB.x) && !isNaN(posB.y)) {
                dotB.x = posB.x - dotB.width/2
                dotB.y = posB.y - dotB.height/2
                dotB.visible = true
            }

            if (!isNaN(posC.x) && !isNaN(posC.y)) {
                dotC.x = posC.x - dotC.width/2
                dotC.y = posC.y - dotC.height/2
                dotC.visible = true
            }
        }

        Menu {
            id: contextMenu
            title: "Display Options"

            MenuItem {
                text: "Show Phase A RMS"
                checkable: true
                checked: chartView.showRmsA
                onTriggered: {
                    chartView.showRmsA = !chartView.showRmsA
                    chartView.legend.visible = chartView.showRmsA || chartView.showRmsB || chartView.showRmsC
                }
            }
            MenuItem {
                text: "Show Phase B RMS"
                checkable: true
                checked: chartView.showRmsB
                onTriggered: {
                    chartView.showRmsB = !chartView.showRmsB
                    chartView.legend.visible = chartView.showRmsA || chartView.showRmsB || chartView.showRmsC
                }
            }
            MenuItem {
                text: "Show Phase C RMS"
                checkable: true
                checked: chartView.showRmsC
                onTriggered: {
                    chartView.showRmsC = !chartView.showRmsC
                    chartView.legend.visible = chartView.showRmsA || chartView.showRmsB || chartView.showRmsC
                }
            }
            MenuSeparator { }
            MenuItem {
                text: "Hide All RMS"
                onTriggered: {
                    chartView.showRmsA = false
                    chartView.showRmsB = false
                    chartView.showRmsC = false
                    chartView.legend.visible = false
                }
            }
            MenuItem {
                text: "Auto Scale Y-Axis"
                onTriggered: {
                    let maxA = 0, maxB = 0, maxC = 0;
                    
                    for(let i = 0; i < seriesA.count; i++) {
                        maxA = Math.max(maxA, Math.abs(seriesA.at(i).y));
                        maxB = Math.max(maxB, Math.abs(seriesB.at(i).y));
                        maxC = Math.max(maxC, Math.abs(seriesC.at(i).y));
                    }

                    let maxVal = Math.max(maxA, maxB, maxC);
                    
                    maxVal = maxVal * 1.1;
                    axisY.min = -maxVal;
                    axisY.max = maxVal;
                }
            }
            }
        }

        Item {
            id: dragTarget

            property real oldX : x
            property real oldY : y

            onXChanged: {
                chartView.scrollLeft( x - oldX );
                oldX = x;
            }
            onYChanged: {
                chartView.scrollUp( y - oldY );
                oldY = y;
            }
        }
    }
}
