import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

ChartView {
    id: waveformChart
    antialiasing: Qt.platform.os !== "windows" // Disable on Windows for performance
    legend.visible: true
    legend.alignment: Qt.AlignBottom
    theme: Universal.theme
    
    // Added properties for performance tuning
    property bool useOpenGL: Qt.platform.os !== "windows"
    property bool animationsEnabled: false
    property bool showFundamental: false
    property var calculator
    property var seriesHelper
    property var onUpdateCompleted: null
    property bool throttleUpdates: true
    property int updateThrottleMs: 50  // Don't update more often than this
    property var lastUpdateTime: Date.now()

    // Add these properties to control quality based on interaction
    property bool isInteracting: false
    property bool lowQualityMode: false

    // Function to update the waveform visualization
    function updateWaveform() {
        // Skip updates if not visible for better performance
        if (!visible) {
            return;
        }
        
        // Throttle updates for better performance
        if (throttleUpdates) {
            var currentTime = Date.now();
            if (currentTime - lastUpdateTime < updateThrottleMs) {
                return;
            }
            lastUpdateTime = currentTime;
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

        if (!isFinite(maxY) || maxY <= 0) {
            maxY = 100;
        }

        var paddedMax = Math.ceil(maxY * 1.2);
        axisY.min = -paddedMax;
        axisY.max = paddedMax;

        var chartWidth = width;

        chartWidth = Math.max(100, chartWidth);

        var maxPoints = isWindows ? 
            Math.min(Math.floor(chartWidth / 4), 80) :
            Math.min(Math.floor(chartWidth / 3), 100);
            
        var pointSpacing = Math.max(1, Math.floor(points.length / maxPoints));

        var xValues = [];
        var yValues = [];
        var fundValues = [];
        
        if (points && points.length > 0) {
            for (var i = 0; i < points.length; i += pointSpacing) {
                if (isFinite(points[i])) {
                    xValues.push(i * (360/points.length));
                    yValues.push(points[i]);
                }
                
                if (fundamentalData && i < fundamentalData.length && isFinite(fundamentalData[i])) {
                    fundValues.push(fundamentalData[i]);
                }
            }

            if (isWindows && forceUpdate) {
                waveformSeries.clear();
                fundamentalSeries.clear();
            }

            if (xValues.length > 0 && yValues.length > 0) {
                seriesHelper.fillSeriesFromArrays(waveformSeries, xValues, yValues);
                
                if (fundValues.length === xValues.length) {
                    seriesHelper.fillSeriesFromArrays(fundamentalSeries, xValues, fundValues);
                }

                if (isWindows) {
                    update();
                }
            }
        }

        if (lowQualityMode) {
            // Use lower resolution data or simpler rendering
            // ...
        } else {
            // Use full quality rendering
            // ...
        }

        if (onUpdateCompleted) {
            onUpdateCompleted();
        }
    }

    Component.onCompleted: {
        initTimer.start();
    }
    
    Timer {
        id: initTimer
        interval: 300
        repeat: false
        onTriggered: {
            updateWaveform();
            if (Qt.platform.os === "windows") {
                refreshTimer.start();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 700
        repeat: false
        onTriggered: {
            updateWaveform();
        }
    }
    
    Timer {
        id: lowQualityTimer
        interval: 300
        onTriggered: {
            lowQualityMode = false;
            // Request high quality update
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

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onPressed: {
            isInteracting = true;
            lowQualityMode = true;
        }
        
        onReleased: {
            isInteracting = false;
            lowQualityTimer.restart();
        }
        
        onPositionChanged: {
            if (pressed) {
                // If user is dragging, extend low quality mode
                lowQualityTimer.restart();
            }
        }
    }

    function setLabelsVisible(visible) {
        axisX.labelsVisible = visible;
    }

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
