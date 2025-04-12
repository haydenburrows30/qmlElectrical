import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

ChartView {
    title: "Time-Current Curves"
    antialiasing: true
    legend.visible: true
    theme: ChartView.ChartThemeDark
    
    LogValueAxis {
        id: axisY
        titleText: "Time (s)"
        min: 0.01
        max: 100
        base: 10
        minorGridVisible: true
    }
    
    LogValueAxis {
        id: axisX
        titleText: "Current (A)"
        min: 10
        max: 10000
        base: 10
        minorGridVisible: true
    }
    
    LineSeries {
        id: deviceCurve
        name: "This Device"
        axisX: axisX
        axisY: axisY
    }
    
    LineSeries {
        id: upstreamCurve
        name: "Upstream"
        axisX: axisX
        axisY: axisY
    }
    
    LineSeries {
        id: downstreamCurve
        name: "Downstream"
        axisX: axisX
        axisY: axisY
    }
    
    function updateCurves(calculator) {
        const points = calculator.getCurvePoints()
        deviceCurve.clear()
        points[0].forEach((current, i) => {
            if (points[1][i] !== null) {
                deviceCurve.append(current, points[1][i])
            }
        })
    }
}
