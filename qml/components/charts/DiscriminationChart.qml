import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

ChartView {
    id: marginChart
    width: parent.width
    height: parent.height - parent.spacing - parent.children[0].height
    antialiasing: true
    legend.alignment: Qt.AlignBottom

    property var scatterSeries: marginPoints

    theme: Universal.theme

    ValueAxis {
        id: marginAxis
        min: 0
        max: 10
        titleText: "Time (s)"
    }
    
    LogValueAxis {
        id: faultAxis
        min: 100
        max: 20000
        titleText: "Fault Current (A)"
        base: 10
        labelFormat: "%.0f"
    }

    LineSeries {
        id: marginLine
        name: "Minimum Margin"
        axisX: faultAxis
        axisY: marginAxis
        width: 2
    }

    ScatterSeries {
        id: marginPoints
        name: "Margin Points"
        axisX: faultAxis
        axisY: marginAxis
        markerSize: 10
    }

    function updateMarginLine() {
        marginLine.clear()
        marginLine.append(faultAxis.min, calculator.minimumMargin)
        marginLine.append(faultAxis.max, calculator.minimumMargin)
    }

    function createRelaySeries() {
        console.log("Creating relay series...")
        // Remove existing relay series
        let seriesToRemove = []
        for (let i = 0; i < marginChart.count; i++) {
            let series = marginChart.series(i)
            if (series !== marginLine && series !== marginPoints) {
                seriesToRemove.push(series)
            }
        }
        seriesToRemove.forEach(series => marginChart.removeSeries(series))

        // Add new series for each relay
        calculator.relayList.forEach(function(relay) {
            console.log("Creating series for relay:", relay.name)
            let series = marginChart.createSeries(ChartView.SeriesTypeLine, relay.name, faultAxis, marginAxis)
            series.width = 2

            // Generate curve points
            const numPoints = 100
            const minCurrent = Math.max(100, relay.pickup)
            const maxCurrent = 20000
            const step = (Math.log10(maxCurrent) - Math.log10(minCurrent)) / numPoints

            for (let i = 0; i <= numPoints; i++) {
                const current = Math.pow(10, Math.log10(minCurrent) + i * step)
                const multiple = current / relay.pickup
                if (multiple <= 1) continue
                
                const time = (relay.curve_constants.a * relay.tds) / 
                        (Math.pow(multiple, relay.curve_constants.b) - 1)
                if (isFinite(time) && time > 0 && time < 10) {
                    series.append(current, time)
                }
            }
        })
    }

    Component.onCompleted: {
        createRelaySeries()
        updateMarginLine()
    }
}