import QtQuick
import QtCharts
import QtQuick.Controls.Universal
import QtQuick.Layouts

ChartView {
    id: chart
    antialiasing: true
    legend.visible: true
    theme: Universal.theme === Universal.Dark ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
    animationOptions: ChartView.NoAnimation
    margins.top: 0
    margins.bottom: 0
    margins.left: 0
    margins.right: 0
    axes: []

    // We only need these properties as they're directly used by QML
    property var scatterSeries: null
    property var marginLine: null
    property var relaySeries: []
    property var faultPointsSeries: []

    LogValueAxis {
        id: axisX
        titleText: "Current (A)"
        min: 10
        max: 10000
        labelFormat: "%g"
        base: 10.0
        gridVisible: true
        labelsVisible: true
        minorGridVisible: true
        minorTickCount: 9
        minorGridLineColor: Universal.theme === Universal.Dark ? Qt.rgba(0.3, 0.3, 0.3, 0.3) : Qt.rgba(0.7, 0.7, 0.7, 0.3)
    }

    LogValueAxis {
        id: axisY
        titleText: "Time (s)"
        min: 0.01
        max: 10
        labelFormat: "%.2f"
        base: 10.0
        gridVisible: true
        labelsVisible: true
        minorGridVisible: true
        minorTickCount: 9
    }

    LineSeries {
        id: marginLineSeries
        name: "Min Margin"
        visible: false
        color: Universal.theme === Universal.Dark ? "#90EE90" : "green" 
        width: 2
        style: Qt.DashLine
        axisX: axisX
        axisY: axisY
    }

    Component.onCompleted: {
        // Initialize chart
        setAxisX(axisX, null)
        setAxisY(axisY, null)
        
        // Create scatter series for margin points
        scatterSeries = createSeries(ChartView.SeriesTypeScatter, "Discrimination Margins", axisX, axisY)
        scatterSeries.markerSize = 10
        scatterSeries.color = Universal.accent
        
        marginLine = marginLineSeries
        
        // Apply initial ranges from Python
        let ranges = discriminationAnalyzerCard.calculator.defaultRanges
        updateRanges(ranges)
    }

    // Simplified functions that rely on Python calculations
    function updateRanges(ranges) {
        if (!ranges) return
        axisX.min = ranges.xMin
        axisX.max = ranges.xMax
        axisY.min = ranges.yMin
        axisY.max = ranges.yMax
    }

    function updateMarginLine() {
        if (!discriminationAnalyzerCard?.calculator) return
        
        let margin = discriminationAnalyzerCard.calculator.minimumMargin
        marginLine.clear()
        marginLine.visible = relaySeries.length >= 2
        if (marginLine.visible) {
            marginLine.append(axisX.min, margin)
            marginLine.append(axisX.max, margin)
        }
    }

    function createRelaySeries() {
        clearAllSeries()
        
        let curvePoints = discriminationAnalyzerCard.calculator.curvePoints
        if (!curvePoints) return
        
        curvePoints.forEach(relayData => {
            if (!relayData?.points) return
            let series = chart.createSeries(ChartView.SeriesTypeLine, relayData.name, axisX, axisY)
            series.width = 2
            relayData.points.forEach(point => {
                if (point?.current > 0 && point?.time > 0) {
                    series.append(point.current, point.time)
                }
            })
            relaySeries.push(series)
        })
        
        updateRanges(discriminationAnalyzerCard.calculator.chartRanges)
    }

    function updateFaultPoints(points, visible) {
        clearFaultPoints()
        if (!visible || !points?.length) return
        
        let relayPoints = points.reduce((acc, point) => {
            if (!acc[point.relay]) acc[point.relay] = []
            acc[point.relay].push(point)
            return acc
        }, {})
        
        Object.entries(relayPoints).forEach(([name, points]) => {
            let series = chart.createSeries(ChartView.SeriesTypeScatter, 
                                         "Fault Points - " + name, 
                                         axisX, axisY)
            series.markerSize = 12
            series.color = "red"
            series.borderColor = "white"
            series.borderWidth = 1
            
            points.forEach(point => series.append(point.current, point.time))
            faultPointsSeries.push(series)
        })
        
        updateRanges(discriminationAnalyzerCard.calculator.chartRanges)
    }

    // Basic cleanup functions
    function clearFaultPoints() {
        faultPointsSeries.forEach(series => chart.removeSeries(series))
        faultPointsSeries = []
    }

    function clearAllSeries() {
        scatterSeries?.clear()
        relaySeries.forEach(series => chart.removeSeries(series))
        relaySeries = []
        clearFaultPoints()
    }

    function resetChart() {
        clearAllSeries()
        marginLine?.clear()
        marginLine.visible = false
        updateRanges(discriminationAnalyzerCard.calculator.defaultRanges)
    }

    signal svgContentReady(string svgContent, string filename)

    function saveChartImage(filename) {

        chart.grabToImage(function(result) {
            if (result) {
                var success = result.saveToFile(filename)
            } else {
                console.error("Failed to grab chart image")
            }
        })
    }

    function saveHighResImage(filename) {
        let originalAntialiasing = chart.antialiasing

        chart.antialiasing = true

        let originalWidth = chart.width
        let originalHeight = chart.height
        let aspectRatio = originalHeight / originalWidth

        let targetWidth = 8000
        let targetHeight = Math.round(targetWidth * aspectRatio)
        
        return chart.grabToImage(function(result) {
            chart.antialiasing = originalAntialiasing

            result.saveToFile(filename)
        }, Qt.size(targetWidth, targetHeight))
    }
}