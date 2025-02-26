import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

ChartView {
    id: lineChart
    anchors.leftMargin: 20

    property int currentrow
    property var axisx: axisX
    property var axisy: axisY
    property bool pointy: false 
    property var pointhovered
    
    title: "% Voltage Drop vs Cable Type"
    antialiasing: true
    legend.alignment: Qt.AlignBottom

    theme: Universal.theme

    titleFont {
        pointSize: 13
        bold: true
    }

    ValueAxis {
        id: axisX
        titleText: "Cable Type"
        
        min: 0
        max: 4
    }

    ValueAxis {
        id: axisY
        titleText: "Voltage Drop (%)"
        min: 0
        max: 10
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
        border.width: 5
        color: "red"
    }

    Rectangle{
        id: linemarkery
        x: parent.plotArea.x
        width: parent.plotArea.width
        height: 1
        visible: false
        border.width: 5
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

        HoverHandler {
            id: stylus
            acceptedPointerTypes: PointerDevice.AllPointerTypes
        }

        Rectangle {
            Text {
                id: legend
                visible: stylus.hovered && pointy == true
            }
        }

        onClicked:{
            lineChart.series(0).clicked
            lineChart.series(0).color = "red"
        }

        onMouseXChanged: {
            const betweenx = (x, min, max) => {
            return x >= min && x <= max;
            }
            const betweeny = (x, min, max) => {
            return x >= min && x <= max;
            }

            var point = Qt.point(mouseX, mouseY)

            if (lineChart.count > 0) {
                rectang.width = point.x - rectang.x
                linemarkerx.visible = true
                linemarkerx.x = mouseX - linemarkerx.width/2
            }

            if (currentrow >= 0 && lineChart.count > 0) {
                var cp = lineChart.mapToValue(point,lineChart.series(currentrow))
                var values = lineChart.series(currentrow).at(cp.x)

                pointhovered = ([values.x,values.y])

                if (betweenx(values.x, cp.x - 0.1, cp.x + 0.1) && betweeny(values.y, cp.y - 0.1, cp.y + 0.1) == true) {
                    pointy = true
                    var text = values.y.toFixed(2) + " %"
                    legend.x = point.x
                    legend.y = point.y - legend.height
                    legend.text = text
                } else {
                    pointy = false
                }
            }
        }

        onMouseYChanged: {
            var point = Qt.point(mouseX, mouseY)

            if (lineChart.count > 0) {
                
                rectang.height = point.y - rectang.y

                linemarkery.visible = true
                linemarkery.y = mouseY - linemarkery.height/2
            }
        }

        onReleased: {
            lineChart.zoomIn(Qt.rect(rectang.x, rectang.y, rectang.width, rectang.height))
            rectang.visible = false
        }

        onDoubleClicked: { lineChart.zoomReset() }

        onPositionChanged: {
        }

        onExited: {
            linemarkery.visible = false
            linemarkerx.visible = false
        }
    }
}