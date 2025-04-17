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

    // Add a signal to communicate with Python
    signal svgContentReady(string svgContent, string filename)

    // Revised approach using signals to bridge to Python
    function saveChartAsSVG(filename) {
        console.log(`Preparing SVG content for ${filename}`)
        
        // Temporarily increase line widths for better visibility in SVG
        let originalWidths = []
        relaySeries.forEach((series, index) => {
            originalWidths[index] = series.width
            series.width = series.width * 2.0  // Even thicker for SVG
        })
        
        // Save margin line width if visible
        let originalMarginWidth = 0
        if (marginLine && marginLine.visible) {
            originalMarginWidth = marginLine.width
            marginLine.width = originalMarginWidth * 2.0
        }
        
        // Generate SVG content
        let svgContent = generateSVG()
        console.log("Generated SVG content with length:", svgContent.length)
        
        // Emit signal to let Python handle the file writing
        svgContentReady(svgContent, filename)
        
        // Also save as PNG as fallback
        let pngFilename = filename.replace(".svg", ".png")
        saveHighResImage(pngFilename)
        
        // Restore original line widths
        relaySeries.forEach((series, index) => {
            series.width = originalWidths[index]
        })
        
        // Restore margin line width if it was changed
        if (marginLine && marginLine.visible) {
            marginLine.width = originalMarginWidth
        }
        
        // Always return true since we're delegating the actual file writing to Python
        return true
    }

    // Legacy function for backward compatibility
    function saveChartImage(filename) {
        console.log("saveChartImage called with: " + filename)
        
        // Always try to save as SVG first
        let svgFilename = filename
        if (!svgFilename.endsWith(".svg")) {
            svgFilename = filename.replace(/\.[^/.]+$/, "") + ".svg"
        }
        
        // Try SVG through Python, also save PNG as fallback
        return saveChartAsSVG(svgFilename)
    }

    // Generate SVG content for the chart with proper point data
    function generateSVG() {
        // Get chart dimensions
        let width = chart.width
        let height = chart.height
        
        // Create SVG header with exact dimensions
        let svg = `<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">
<style>
    .axis text { font-family: Arial, sans-serif; font-size: 12px; }
    .axis-title { font-family: Arial, sans-serif; font-size: 14px; font-weight: bold; }
    .line { stroke-width: 2px; fill: none; }
    .scatter { stroke-width: 1px; }
    .grid { stroke: #ccc; stroke-width: 0.5px; stroke-dasharray: 2,2; }
    .legend text { font-family: Arial, sans-serif; font-size: 12px; }
</style>
<rect width="100%" height="100%" fill="${Universal.theme === Universal.Dark ? '#1e1e1e' : 'white'}"/>
`
        
        // Generate real data paths instead of placeholders
        svg += generateRealAxes()
        
        // Add real data series
        relaySeries.forEach((series, index) => {
            svg += generateRealSeriesPath(series, index)
        })
        
        // Add real scatter points
        if (scatterSeries && scatterSeries.count > 0) {
            svg += generateRealScatterPoints(scatterSeries, "discrimination-margins")
        }
        
        // Add real margin line
        if (marginLine && marginLine.visible) {
            svg += generateRealMarginLine()
        }
        
        // Add real fault points
        faultPointsSeries.forEach((series, index) => {
            svg += generateRealScatterPoints(series, "fault-points-" + index)
        })
        
        // Add real legend
        svg += generateRealLegend()
        
        // Close SVG
        svg += "</svg>"
        
        return svg
    }
    
    // Generate real axes based on actual chart with scale labels
    function generateRealAxes() {
        // First create the main axes
        let axesGroup = `<g class="axis">
    <!-- X-Axis -->
    <line x1="50" y1="${chart.height - 50}" x2="${chart.width - 50}" y2="${chart.height - 50}" stroke="black" stroke-width="1.5" />
    <!-- Y-Axis -->
    <line x1="50" y1="50" x2="50" y2="${chart.height - 50}" stroke="black" stroke-width="1.5" />
    <!-- Axis Titles -->
    <text x="${chart.width / 2}" y="${chart.height - 20}" text-anchor="middle" class="axis-title">${axisX.titleText}</text>
    <text x="15" y="${chart.height / 2}" text-anchor="middle" transform="rotate(-90, 15, ${chart.height / 2})" class="axis-title">${axisY.titleText}</text>`
        
        // Add X-axis tick marks and labels
        // For log scale, use logarithmically spaced ticks
        let xTicks = getLogTicks(axisX.min, axisX.max)
        xTicks.forEach(tick => {
            let x = logXToSvg(tick)
            axesGroup += `
    <!-- X-axis tick at ${tick} -->
    <line x1="${x}" y1="${chart.height - 50}" x2="${x}" y2="${chart.height - 45}" stroke="black" stroke-width="1" />
    <text x="${x}" y="${chart.height - 35}" text-anchor="middle" font-size="10">${formatTickLabel(tick)}</text>`
        })
        
        // Add Y-axis tick marks and labels
        let yTicks = getLogTicks(axisY.min, axisY.max)
        yTicks.forEach(tick => {
            let y = logYToSvg(tick)
            axesGroup += `
    <!-- Y-axis tick at ${tick} -->
    <line x1="50" y1="${y}" x2="45" y2="${y}" stroke="black" stroke-width="1" />
    <text x="35" y="${y + 4}" text-anchor="end" font-size="10">${formatTickLabel(tick)}</text>`
        })
        
        // Add grid lines
        xTicks.forEach(tick => {
            let x = logXToSvg(tick)
            axesGroup += `
    <line x1="${x}" y1="50" x2="${x}" y2="${chart.height - 50}" stroke="#cccccc" stroke-width="0.5" stroke-dasharray="4,4" />`
        })
        
        yTicks.forEach(tick => {
            let y = logYToSvg(tick)
            axesGroup += `
    <line x1="50" y1="${y}" x2="${chart.width - 50}" y2="${y}" stroke="#cccccc" stroke-width="0.5" stroke-dasharray="4,4" />`
        })
        
        axesGroup += `
</g>`
        return axesGroup
    }
    
    // Generate evenly spaced logarithmic ticks
    function getLogTicks(min, max) {
        let ticks = []
        
        // For a log scale, we want powers of 10 and some intermediate values
        let minExp = Math.floor(Math.log10(min))
        let maxExp = Math.ceil(Math.log10(max))
        
        for (let exp = minExp; exp <= maxExp; exp++) {
            let base = Math.pow(10, exp)
            
            // Add major ticks at powers of 10
            if (base >= min && base <= max) {
                ticks.push(base)
            }
            
            // Add intermediate ticks at 2x and 5x for more detail
            if (exp < maxExp) {
                let tick2 = 2 * base
                let tick5 = 5 * base
                if (tick2 >= min && tick2 <= max) ticks.push(tick2)
                if (tick5 >= min && tick5 <= max) ticks.push(tick5)
            }
        }
        
        return ticks
    }
    
    // Format tick label for readable display
    function formatTickLabel(value) {
        // For small values, show more decimals
        if (value < 0.1) return value.toFixed(3)
        if (value < 1) return value.toFixed(2)
        if (value < 10) return value.toFixed(1)
        
        // For large values, use k/M suffixes
        if (value >= 1000000) return (value / 1000000).toFixed(0) + "M"
        if (value >= 1000) return (value / 1000).toFixed(0) + "k"
        
        // Otherwise return as integer
        return value.toFixed(0)
    }
    
    // Convert log scale value to SVG coordinate
    function logXToSvg(value) {
        let logMin = Math.log10(axisX.min)
        let logMax = Math.log10(axisX.max)
        let logValue = Math.log10(value)
        
        // Convert log scale to linear percentage
        let percentage = (logValue - logMin) / (logMax - logMin)
        // Map to SVG coordinates with margins
        return 50 + percentage * (chart.width - 100)
    }
    
    function logYToSvg(value) {
        let logMin = Math.log10(axisY.min)
        let logMax = Math.log10(axisY.max)
        let logValue = Math.log10(value)
        
        // Convert log scale to linear percentage (inverted for Y axis)
        let percentage = 1 - ((logValue - logMin) / (logMax - logMin))
        // Map to SVG coordinates with margins
        return 50 + percentage * (chart.height - 100)
    }
    
    // Generate a real path from series data
    function generateRealSeriesPath(series, index) {
        if (!series || series.count === 0) return ""
        
        let color = series.color.toString()
        let path = `<path class="line" stroke="${color}" stroke-width="${series.width}" fill="none" d="`
        
        // Build the SVG path data
        for (let i = 0; i < series.count; i++) {
            let point = series.at(i)
            if (point && point.x > 0 && point.y > 0) {
                let svgX = logXToSvg(point.x)
                let svgY = logYToSvg(point.y)
                
                if (i === 0) {
                    path += `M${svgX},${svgY} `
                } else {
                    path += `L${svgX},${svgY} `
                }
            }
        }
        
        path += `" />`
        return path
    }
    
    // Generate real scatter points
    function generateRealScatterPoints(series, className) {
        if (!series || series.count === 0) return ""
        
        let points = `<g class="${className}">`
        
        for (let i = 0; i < series.count; i++) {
            let point = series.at(i)
            if (point && point.x > 0 && point.y > 0) {
                let svgX = logXToSvg(point.x)
                let svgY = logYToSvg(point.y)
                
                points += `<circle cx="${svgX}" cy="${svgY}" r="${series.markerSize / 2}" fill="${series.color}" stroke="${series.borderColor || 'none'}" stroke-width="${series.borderWidth || 0}" />`
            }
        }
        
        points += `</g>`
        return points
    }
    
    // Generate real margin line
    function generateRealMarginLine() {
        if (!marginLine || !marginLine.visible) return ""
        
        let y = logYToSvg(discriminationAnalyzerCard.calculator.minimumMargin)
        let style = marginLine.style === Qt.DashLine ? "5,5" : "none"
        
        return `<path class="margin-line" stroke="${marginLine.color}" stroke-width="${marginLine.width}" stroke-dasharray="${style}" d="M50,${y} L${chart.width - 50},${y}" />`
    }
    
    // Generate real legend
    function generateRealLegend() {
        let legend = `<g class="legend" transform="translate(${chart.width - 180}, 20)">`
        let y = 0
        
        // Add relay series to legend
        relaySeries.forEach((series, index) => {
            legend += `
    <rect x="0" y="${y}" width="15" height="15" fill="${series.color}" />
    <text x="20" y="${y + 12}" font-family="Arial" font-size="12">${series.name}</text>`
            y += 20
        })
        
        // Add margin line to legend if visible
        if (marginLine && marginLine.visible) {
            legend += `
    <line x1="0" y1="${y + 7}" x2="15" y2="${y + 7}" stroke="${marginLine.color}" stroke-width="${marginLine.width}" stroke-dasharray="5,5" />
    <text x="20" y="${y + 12}" font-family="Arial" font-size="12">${marginLine.name}</text>`
            y += 20
        }
        
        // Add scatter series to legend
        if (scatterSeries && scatterSeries.count > 0) {
            legend += `
    <circle cx="7" cy="${y + 7}" r="${scatterSeries.markerSize / 2}" fill="${scatterSeries.color}" />
    <text x="20" y="${y + 12}" font-family="Arial" font-size="12">${scatterSeries.name}</text>`
            y += 20
        }
        
        legend += `</g>`
        return legend
    }

    // High resolution image backup function
    function saveHighResImage(filename) {
        // Save current antialiasing state
        let originalAntialiasing = chart.antialiasing
        
        // Apply maximum quality settings for export
        chart.antialiasing = true
        
        // Calculate proper aspect ratio based on current chart dimensions
        let originalWidth = chart.width
        let originalHeight = chart.height
        let aspectRatio = originalHeight / originalWidth
        
        // Use extremely high resolution for vector-like quality
        let targetWidth = 8000  // Much higher resolution
        let targetHeight = Math.round(targetWidth * aspectRatio)
        
        console.log(`Capturing fallback PNG at resolution ${targetWidth}x${targetHeight}`)
        
        return chart.grabToImage(function(result) {
            // Restore original settings
            chart.antialiasing = originalAntialiasing
            
            // Save with maximum quality
            let success = result.saveToFile(filename)
            console.log("Fallback PNG save result:", success ? "success" : "failed")
        }, Qt.size(targetWidth, targetHeight))
    }
}