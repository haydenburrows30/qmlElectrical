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
    property var currentLevelLine: null
    property var relaySeries: []
    property var faultPointsSeries: []
    property var fuseCurvesSeries: []

    // Tooltip properties
    property var tooltip: null
    property real tooltipThreshold: 20 // Pixel distance threshold for showing tooltip
    property var tooltipTimer: null
    property var lastMousePoint: null

    // Mouse handling for tooltips
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        
        Component.onCompleted: {
            // Create a timer for throttling tooltip updates
            tooltipTimer = Qt.createQmlObject(`
                import QtQuick
                Timer {
                    interval: 50
                    repeat: false
                    onTriggered: {
                        if (lastMousePoint) {
                            let screenPoint = chart.mapToPosition(lastMousePoint)
                            updateTooltip(lastMousePoint, screenPoint)
                        }
                    }
                }
            `, chart)
        }
        
        onPositionChanged: {
            if (containsMouse) {
                lastMousePoint = chart.mapToValue(Qt.point(mouseX, mouseY))
                if (tooltipTimer) {
                    tooltipTimer.restart()
                }
            }
        }
        
        onExited: {
            if (tooltipTimer) {
                tooltipTimer.stop()
            }
            lastMousePoint = null
            hideTooltip()
        }
    }

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

    LineSeries {
        id: currentLevelSeries
        name: "Current Level"
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
        currentLevelLine = currentLevelSeries
        
        // Create tooltip
        createTooltip()
        
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

    function updateCurrentLevelLine() {
        if (!discriminationAnalyzerCard?.calculator) return
        
        let level = discriminationAnalyzerCard.calculator.currentLevel

        currentLevelLine.clear()
        currentLevelLine.append(level, axisY.min)
        currentLevelLine.append(level, axisY.max)
    }

    function createRelaySeries() {
        // Only clear relay series, not all series (preserves fuse curves)
        clearRelaySeries()
        
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
            series.pointLabelsVisible = true
            series.pointLabelsFormat = "@xPoint, @yPoint"

            points.forEach(point => series.append(point.current, point.time))
            faultPointsSeries.push(series)
        })
        
        updateRanges(discriminationAnalyzerCard.calculator.chartRanges)
    }

    function updateFuseCurves() {
        clearFuseCurves()
        
        if (!discriminationAnalyzerCard?.calculator) return
        
        let loadedFuses = discriminationAnalyzerCard.calculator.getLoadedFuseCurves()
        if (!loadedFuses.length) return
        
        let fuseColors = ['orange', 'purple', 'brown', 'pink', 'gray', 'olive']
        
        loadedFuses.forEach((fuseInfo, index) => {
            let curveData = discriminationAnalyzerCard.calculator.getFuseCurveData(
                fuseInfo.type, 
                fuseInfo.rating, 
                fuseInfo.manufacturer
            )
            
            if (curveData && curveData.length > 0) {
                let series = chart.createSeries(ChartView.SeriesTypeLine, 
                                             "Fuse: " + fuseInfo.label, 
                                             axisX, axisY)
                series.width = 2
                series.color = fuseColors[index % fuseColors.length]
                
                curveData.forEach(point => {
                    if (point.current > 0 && point.melting_time > 0) {
                        series.append(point.current, point.melting_time)
                    }
                })
                
                fuseCurvesSeries.push(series)
            }
        })
        
        updateRanges(discriminationAnalyzerCard.calculator.chartRanges)
    }

    // Basic cleanup functions
    function clearRelaySeries() {
        relaySeries.forEach(series => chart.removeSeries(series))
        relaySeries = []
    }

    function clearFuseCurves() {
        fuseCurvesSeries.forEach(series => chart.removeSeries(series))
        fuseCurvesSeries = []
    }

    function clearFaultPoints() {
        faultPointsSeries.forEach(series => chart.removeSeries(series))
        faultPointsSeries = []
    }

    function clearAllSeries() {
        scatterSeries?.clear()
        clearRelaySeries()
        clearFaultPoints()
        clearFuseCurves()
    }

    function resetChart() {
        clearAllSeries()
        marginLine?.clear()
        marginLine.visible = false
        currentLevelLine?.clear()
        currentLevelLine.visible = false
        hideTooltip()
        updateRanges(discriminationAnalyzerCard.calculator.defaultRanges)
    }

    Component.onDestruction: {
        hideTooltip()
        if (tooltip) {
            tooltip.destroy()
            tooltip = null
        }
        if (tooltipTimer) {
            tooltipTimer.stop()
            tooltipTimer.destroy()
            tooltipTimer = null
        }
    }

    signal svgContentReady(string svgContent, string filename)

    // Tooltip functions
    function createTooltip() {
        if (tooltip) {
            tooltip.destroy()
        }
        
        // Create a simple tooltip using Rectangle
        tooltip = Qt.createQmlObject(`
            import QtQuick
            import QtQuick.Controls.Universal
            
            Rectangle {
                id: tooltipRect
                property alias text: tooltipText.text
                
                width: Math.max(140, tooltipText.implicitWidth + 20)
                height: tooltipText.implicitHeight + 16
                color: Universal.theme === Universal.Dark ? "#2D2D2D" : "#F0F0F0"
                border.color: Universal.theme === Universal.Dark ? "#555555" : "#CCCCCC"
                border.width: 1
                radius: 6
                visible: false
                
                // Drop shadow effect
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    color: "transparent"
                    border.color: Universal.theme === Universal.Dark ? "#111111" : "#DDDDDD"
                    border.width: 1
                    radius: 6
                    opacity: 0.3
                    z: -1
                }
                
                Text {
                    id: tooltipText
                    anchors.centerIn: parent
                    font.pixelSize: 11
                    font.family: "Segoe UI"
                    color: Universal.theme === Universal.Dark ? "#FFFFFF" : "#000000"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignLeft
                }
            }
        `, chart)
    }

    function updateTooltip(mousePoint, screenPoint) {
        if (!tooltip) return
        
        let nearestPoint = findNearestPoint(mousePoint)
        if (nearestPoint) {
            // Format the tooltip text based on curve type
            let tooltipText = `${nearestPoint.seriesName}\n`
            
            if (nearestPoint.seriesName.includes("Fault Points")) {
                tooltipText += `Current: ${nearestPoint.current.toFixed(1)} A\n`
                tooltipText += `Time: ${nearestPoint.time.toFixed(3)} s`
            } else if (nearestPoint.seriesName.includes("Fuse:")) {
                tooltipText += `Current: ${nearestPoint.current.toFixed(1)} A\n`
                tooltipText += `Melt Time: ${nearestPoint.time.toFixed(3)} s`
            } else {
                tooltipText += `Current: ${nearestPoint.current.toFixed(1)} A\n`
                tooltipText += `Trip Time: ${nearestPoint.time.toFixed(3)} s`
            }
            
            tooltip.text = tooltipText
            
            // Position tooltip with better logic
            let tooltipX = screenPoint.x + 15
            let tooltipY = screenPoint.y - tooltip.height - 15
            
            // Adjust if tooltip goes off-screen
            if (tooltipX + tooltip.width > chart.width - 10) {
                tooltipX = screenPoint.x - tooltip.width - 15
            }
            if (tooltipY < 10) {
                tooltipY = screenPoint.y + 15
            }
            if (tooltipY + tooltip.height > chart.height - 10) {
                tooltipY = chart.height - tooltip.height - 10
            }
            
            tooltip.x = Math.max(10, tooltipX)
            tooltip.y = Math.max(10, tooltipY)
            tooltip.visible = true
        } else {
            tooltip.visible = false
        }
    }

    function hideTooltip() {
        if (tooltip) {
            tooltip.visible = false
        }
    }

    function findNearestPoint(mousePoint) {
        let minDistance = Number.MAX_VALUE
        let nearestPoint = null
        
        // Function to check a series and update nearest point
        function checkSeries(series) {
            if (!series || series.count === 0) return
            
            let point = findNearestPointOnSeries(series, mousePoint)
            if (point && point.distance < minDistance) {
                minDistance = point.distance
                nearestPoint = {
                    seriesName: series.name,
                    current: point.current,
                    time: point.time,
                    distance: point.distance
                }
            }
        }
        
        // Check all series types
        relaySeries.forEach(checkSeries)
        fuseCurvesSeries.forEach(checkSeries)
        faultPointsSeries.forEach(checkSeries)
        
        // Check scatter series (discrimination margins)
        if (scatterSeries) {
            checkSeries(scatterSeries)
        }
        
        // Only return if within threshold (convert to screen coordinates for consistent threshold)
        let mouseScreenPoint = chart.mapToPosition(mousePoint)
        if (nearestPoint && minDistance < tooltipThreshold) {
            return nearestPoint
        }
        
        return null
    }

    function findNearestPointOnSeries(series, mousePoint) {
        if (!series || series.count === 0) return null
        
        let minDistance = Number.MAX_VALUE
        let nearestPoint = null
        let mouseScreenPoint = chart.mapToPosition(mousePoint)
        
        for (let i = 0; i < series.count; i++) {
            let point = series.at(i)
            let screenPoint = chart.mapToPosition(point)
            
            let distance = Math.sqrt(
                Math.pow(screenPoint.x - mouseScreenPoint.x, 2) +
                Math.pow(screenPoint.y - mouseScreenPoint.y, 2)
            )
            
            if (distance < minDistance) {
                minDistance = distance
                nearestPoint = {
                    current: point.x,
                    time: point.y,
                    distance: distance
                }
            }
        }
        
        return nearestPoint
    }

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