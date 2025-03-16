import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../../"

ChartView {
    id: waveformChart
    antialiasing: Qt.platform.os !== "windows" // Disable on Windows for performance
    legend.visible: true
    legend.alignment: Qt.AlignBottom
    theme: Universal.theme
    
    property bool useOpenGL: Qt.platform.os !== "windows"
    property bool animationsEnabled: false
    property bool showFundamental: false
    property var calculator
    property var seriesHelper
    property var onUpdateCompleted: null

    // Function to update the waveform visualization
    function updateWaveform() {
        // Skip updates if not visible for better performance
        if (!visible) {
            return;
        }
        
        // Explicitly check if QML is running on Windows
        var isWindows = Qt.platform.os === "windows";
        
        // Force full update on Windows to fix rendering issues
        var forceUpdate = isWindows || !waveformSeries.count;
        
        var points = calculator.waveform;
        var fundamentalData = calculator.fundamentalWaveform;
        
        // Skip update if data hasn't changed
        if (!points || points.length === 0) {
            return;
        }
        
        var maxY = 0;
        
        // Find maximum magnitude for scaling with validation
        if (points && points.length > 0) {
            for (var i = 0; i < points.length; i++) {
                // Check for valid numeric values
                if (isFinite(points[i])) {
                    maxY = Math.max(maxY, Math.abs(points[i]));
                }
                
                if (fundamentalData && i < fundamentalData.length && isFinite(fundamentalData[i])) {
                    maxY = Math.max(maxY, Math.abs(fundamentalData[i]));
                }
            }
        }
        
        // Ensure maxY is a valid value before setting axis range
        if (!isFinite(maxY) || maxY <= 0) {
            maxY = 100;  // Set a reasonable default if invalid
        }
        
        // Set axis range with 20% padding
        var paddedMax = Math.ceil(maxY * 1.2);
        axisY.min = -paddedMax;
        axisY.max = paddedMax;
        
        // Adjust point density based on available width
        var chartWidth = width;
        
        // Use a safe minimum width
        chartWidth = Math.max(100, chartWidth);
        
        // Windows optimization: use fewer points for better performance
        var maxPoints = isWindows ? 
            Math.min(Math.floor(chartWidth / 4), 80) : // Fewer points on Windows
            Math.min(Math.floor(chartWidth / 3), 100); // More points on other platforms
            
        var pointSpacing = Math.max(1, Math.floor(points.length / maxPoints));
        
        // Use the efficient series filling methods
        var xValues = [];
        var yValues = [];
        var fundValues = [];
        
        // Add null check to avoid errors
        if (points && points.length > 0) {
            for (var i = 0; i < points.length; i += pointSpacing) {
                if (isFinite(points[i])) {  // Only add valid points
                    xValues.push(i * (360/points.length));
                    yValues.push(points[i]);
                }
                
                if (fundamentalData && i < fundamentalData.length && isFinite(fundamentalData[i])) {
                    fundValues.push(fundamentalData[i]);
                }
            }
            
            // Clear series first on Windows to prevent rendering issues
            if (isWindows && forceUpdate) {
                waveformSeries.clear();
                fundamentalSeries.clear();
            }
            
            // Fill both series efficiently with the reduced dataset
            if (xValues.length > 0 && yValues.length > 0) {
                seriesHelper.fillSeriesFromArrays(waveformSeries, xValues, yValues);
                
                if (fundValues.length === xValues.length) {
                    seriesHelper.fillSeriesFromArrays(fundamentalSeries, xValues, fundValues);
                }
                
                // Force immediate update on Windows
                if (isWindows) {
                    update();
                }
            }
        }
        
        // Signal that the update is complete
        if (onUpdateCompleted) {
            onUpdateCompleted();
        }
    }
    
    // Force first update after component is created
    Component.onCompleted: {
        // Initial update, use a timer to ensure the chart is fully created
        initTimer.start();
    }
    
    Timer {
        id: initTimer
        interval: 300
        repeat: false
        onTriggered: {
            updateWaveform();
            // Try a second update for Windows
            if (Qt.platform.os === "windows") {
                refreshTimer.start();
            }
        }
    }
    
    // Extra update for Windows platforms
    Timer {
        id: refreshTimer
        interval: 700
        repeat: false
        onTriggered: {
            updateWaveform();
        }
    }
    
    ValueAxis {
        id: axisX
        min: 0
        max: 360
        titleText: "Angle (degrees)"
        gridVisible: true
        labelsAngle: 0
        labelFormat: "%d"
        labelsVisible: true
    }
    
    ValueAxis {
        id: axisY
        min: -200
        max: 200
        titleText: "Magnitude (pu)"
        gridVisible: true
    }

    LineSeries {
        id: waveformSeries
        name: "Combined Waveform"
        axisX: axisX
        axisY: axisY
        width: 2
        useOpenGL: waveformChart.useOpenGL
        pointsVisible: false
    }
    
    LineSeries {
        id: fundamentalSeries
        name: "Fundamental"
        axisX: axisX
        axisY: axisY
        color: "lightblue"
        width: 1.5
        visible: waveformChart.showFundamental
        useOpenGL: waveformChart.useOpenGL
        pointsVisible: false
    }
    
    // Expose functions to control axis labels
    function setLabelsVisible(visible) {
        axisX.labelsVisible = visible;
    }
    
    // Connect to calculator signals
    Connections {
        target: calculator
        
        function onWaveformChanged() {
            updateWaveform();
        }
        
        function onCalculationsComplete() {
            updateWaveform();
        }
    }
}
