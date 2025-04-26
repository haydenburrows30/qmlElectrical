import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import Qt.labs.platform

Item {
    id: root
    
    // Properties
    property var timeDomain: []
    property var transformResult: []
    property var phaseResult: []
    property var frequencies: []
    property bool showPhase: true
    property string transformType: "Fourier" // "Fourier" or "Laplace"
    property color lineColor1: "#2196f3"
    property color lineColor2: "#4caf50"
    property color gridColor: "#303030"
    property color textColor: "#e0e0e0"
    property color backgroundColor: "#1e1e1e"
    property bool darkMode: true
    property bool isCalculating: false // Added property for BusyIndicator
    property bool highPerformanceMode: true // Add a high performance mode property
    property real resonantFrequency: -1 // Add property for resonant frequency
    
    // Detect operating system
    readonly property bool isLinux: Qt.platform.os === "linux"
    readonly property bool isWindows: Qt.platform.os === "windows"
    
    // Update charts when data changes or component completes
    Component.onCompleted: {
        // Use callLater to make sure initialization is complete
        Qt.callLater(updateCharts)
    }
    
    onTimeDomainChanged: Qt.callLater(updateCharts)
    onTransformResultChanged: Qt.callLater(updateCharts)
    onShowPhaseChanged: Qt.callLater(updateCharts)
    onHighPerformanceModeChanged: Qt.callLater(updateCharts)
    
    // Update both charts together to ensure consistency
    function updateCharts() {
        updateTimeDomainChart()
        updateTransformChart()
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        // Update explanation for Laplace transforms with more specific resonant frequency value
        Text {
            id: laplaceExplanation
            text: {
                if (root.transformType === "Laplace" && resonantFrequency > 0) {
                    return "Resonant frequency: " + resonantFrequency.toFixed(1) + " rad/s (" + 
                           (resonantFrequency/(2*Math.PI)).toFixed(1) + " Hz)";
                }
                return "";
            }
            color: root.textColor
            font.pixelSize: 14  // Increased from 12 to 14
            font.bold: true
            visible: transformType === "Laplace" && resonantFrequency > 0
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 5
            Layout.preferredWidth: parent.width * 0.9
            Layout.maximumWidth: parent.width
            horizontalAlignment: Text.AlignHCenter
            z: 10
        }
        
        // Busy Indicator
        BusyIndicator {
            id: busyIndicator
            visible: root.isCalculating
            Layout.alignment: Qt.AlignCenter
        }
        
        // Time Domain Chart
        ChartView {
            id: timeDomainChart
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: parent.height / 2
            antialiasing: !highPerformanceMode // Disable antialiasing in high performance mode
            animationOptions: ChartView.NoAnimation // Always disable animations for better performance
            legend.visible: false
            backgroundColor: root.backgroundColor
            theme: root.darkMode ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
            
            ValueAxis {
                id: timeAxisX
                min: 0
                max: 5
                labelFormat: "%.1f"
                labelsColor: root.textColor
                gridLineColor: root.gridColor
                titleText: "Time (s)"
                titleVisible: true
                titleFont.pixelSize: 12
                titleFont.bold: true
                tickCount: highPerformanceMode ? 6 : 11 // Reduce ticks in high perf mode
            }
            
            ValueAxis {
                id: timeAxisY
                min: -2
                max: 2
                labelFormat: "%.1f"
                labelsColor: root.textColor
                gridLineColor: root.gridColor
                titleText: "Amplitude"
                titleVisible: true
                titleFont.pixelSize: 12
                titleFont.bold: true
                tickCount: highPerformanceMode ? 6 : 11 // Reduce ticks in high perf mode
            }
            
            LineSeries {
                id: timeSeries
                name: "Time Domain"
                axisX: timeAxisX
                axisY: timeAxisY
                color: root.lineColor1
                width: highPerformanceMode ? 1 : 2 // Thinner lines in high perf mode
                useOpenGL: isLinux // Enable OpenGL only on Linux
            }
        }
        
        // Transform Domain Chart
        ChartView {
            id: transformChart
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: parent.height / 2
            antialiasing: !highPerformanceMode
            animationOptions: ChartView.NoAnimation // Always disable animations for better performance
            legend.visible: true
            backgroundColor: root.backgroundColor
            theme: root.darkMode ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
            
            ValueAxis {
                id: freqAxisX
                min: 0
                // Adjust max based on the transform type
                max: transformType === "Fourier" ? 100 : 1000  // Much wider for Laplace to show resonance
                labelFormat: "%.1f"
                labelsColor: root.textColor
                gridLineColor: root.gridColor
                titleText: transformType === "Fourier" ? "Frequency (Hz)" : "jω (rad/s)"
                titleVisible: true
                titleFont.pixelSize: 12
                titleFont.bold: true
                tickCount: highPerformanceMode ? 6 : 11
            }
            
            ValueAxis {
                id: magnitudeAxisY
                min: 0
                max: 2
                labelFormat: "%.1f"
                labelsColor: root.textColor
                gridLineColor: root.gridColor
                titleText: "Magnitude"
                titleVisible: true
                titleFont.pixelSize: 12
                titleFont.bold: true
                tickCount: highPerformanceMode ? 6 : 11 // Reduce ticks in high perf mode
            }
            
            ValueAxis {
                id: phaseAxisY
                min: -180
                max: 180
                labelFormat: "%.0f"
                labelsColor: root.textColor
                gridLineColor: root.gridColor
                titleText: "Phase (°)"
                titleVisible: true
                titleFont.pixelSize: 12
                titleFont.bold: true
                tickCount: highPerformanceMode ? 6 : 11 // Reduce ticks in high perf mode
            }
            
            LineSeries {
                id: magnitudeSeries
                name: "Magnitude"
                axisX: freqAxisX
                axisY: magnitudeAxisY
                color: root.lineColor1
                width: highPerformanceMode ? 1 : 2
                useOpenGL: isLinux // Enable OpenGL only on Linux
            }
            
            LineSeries {
                id: phaseSeries
                name: "Phase"
                axisX: freqAxisX
                axisY: phaseAxisY
                color: root.lineColor2
                width: highPerformanceMode ? 1 : 2
                visible: root.showPhase
                useOpenGL: isLinux // Enable OpenGL only on Linux
            }
            
            // Add a vertical line to indicate resonant frequency for Laplace transforms
            LineSeries {
                id: resonanceMarker
                name: "Resonance"
                axisX: freqAxisX
                axisY: magnitudeAxisY
                color: "#ff5722"  // Orange color for visibility
                width: 2
                visible: transformType === "Laplace" && resonantFrequency > 0
                useOpenGL: isLinux // Enable OpenGL only on Linux
            }
            
            // Add a text annotation to label the resonant frequency
            Rectangle {
                id: resonanceLabel
                visible: transformType === "Laplace" && resonantFrequency > 0
                color: "#80ff5722"  // Semi-transparent orange
                border.color: "#ff5722"
                border.width: 1
                radius: 5  // Slightly increased radius
                width: resonanceText.width + 12  // More padding
                height: resonanceText.height + 8  // More padding
                // Position will be set in updateTransformChart
                
                Text {
                    id: resonanceText
                    text: resonantFrequency > 0 ? "ω = " + resonantFrequency.toFixed(1) : ""
                    anchors.centerIn: parent
                    color: "white"
                    font.pixelSize: 12  // Increased from 10 to 12
                    font.bold: true
                }
            }
        }
    }
    
    // Update functions
    function updateTimeDomainChart() {
        // Create temporary arrays for points
        let timePoints = [];
        
        // Check if we have data
        if (!timeDomain || timeDomain.length === 0) {
            return;
        }
        
        // Add the points to the series
        let minY = Number.MAX_VALUE;
        let maxY = -Number.MAX_VALUE;
        let maxX = 0;
        let pointsAdded = 0;
        
        try {
            // Calculate stride for sampling points
            let stride = 1;
            if (highPerformanceMode) {
                // Scale stride based on data size - larger datasets get more aggressive subsampling
                if (timeDomain.length > 10000) {
                    stride = Math.max(1, Math.floor(timeDomain.length / 1000));
                } else if (timeDomain.length > 5000) {
                    stride = Math.max(1, Math.floor(timeDomain.length / 750));
                } else if (timeDomain.length > 1000) {
                    stride = Math.max(1, Math.floor(timeDomain.length / 500));
                }
            }
            
            if (timeDomain.length > 0) {
                // Handle different data formats
                if (typeof timeDomain[0] === 'object' && 'x' in timeDomain[0] && 'y' in timeDomain[0]) {
                    // First collect points in array
                    for (let i = 0; i < timeDomain.length; i += stride) {
                        let point = timeDomain[i];
                        
                        if (point && isFinite(point.x) && isFinite(point.y)) {
                            timePoints.push({ x: point.x, y: point.y });
                            
                            // Track min/max for axis scaling
                            minY = Math.min(minY, point.y);
                            maxY = Math.max(maxY, point.y);
                            maxX = Math.max(maxX, point.x);
                            pointsAdded++;
                        }
                    }
                } 
                // Array of arrays format
                else if (Array.isArray(timeDomain[0])) {
                    for (let i = 0; i < timeDomain.length; i += stride) {
                        let point = timeDomain[i];
                        
                        if (point && point.length >= 2 && 
                            isFinite(point[0]) && isFinite(point[1])) {
                            
                            timePoints.push({ x: point[0], y: point[1] });
                            
                            minY = Math.min(minY, point[1]);
                            maxY = Math.max(maxY, point[1]);
                            maxX = Math.max(maxX, point[0]);
                            pointsAdded++;
                        }
                    }
                }
                // Direct array of y values
                else if (typeof timeDomain[0] === 'number') {
                    for (let i = 0; i < timeDomain.length; i += stride) {
                        let y = timeDomain[i];
                        
                        if (isFinite(y)) {
                            timePoints.push({ x: i / 20, y: y });
                            
                            minY = Math.min(minY, y);
                            maxY = Math.max(maxY, y);
                            pointsAdded++;
                        }
                    }
                    
                    maxX = (timeDomain.length - 1) / 20;
                }
            }
            
            // Only update axes if we have valid data
            if (isFinite(minY) && isFinite(maxY) && minY !== Number.MAX_VALUE && pointsAdded > 0) {
                // Update the axes with some padding
                timeAxisX.min = 0;
                timeAxisX.max = maxX > 0 ? maxX : 5;
                
                // Ensure symmetric y-axis for visual clarity
                const yRange = Math.max(Math.abs(minY), Math.abs(maxY)) * 1.2;
                timeAxisY.min = -yRange || -2;  // Default to -2 if yRange is 0 or NaN
                timeAxisY.max = yRange || 2;    // Default to 2 if yRange is 0 or NaN
                
                // Clear and replace all points at once to ensure Windows compatibility
                timeSeries.clear();
                
                // For Windows, use a more compatible approach to add points
                for (let i = 0; i < timePoints.length; i++) {
                    timeSeries.append(timePoints[i].x, timePoints[i].y);
                }
            }
        } catch (e) {
            // Silently handle errors
        }
    }
    
    function updateTransformChart() {
        // Temporary arrays for collecting points
        let magnitudePoints = [];
        let phasePoints = [];
        let resonancePoints = [];
        
        // Check if we have data
        if (!transformResult || transformResult.length === 0) return;
        
        // Add the points to the series
        let maxMagnitude = 0;
        let maxFreq = 0;
        
        // For large datasets, subsample in high performance mode
        let stride = highPerformanceMode && transformResult.length > 1000 ? Math.floor(transformResult.length / 500) : 1;
        
        // Collect points in arrays first
        for (let i = 0; i < transformResult.length; i += stride) {
            if (i < frequencies.length) {
                let freq = frequencies[i];
                let magnitude = transformResult[i];
                
                // Check for valid numbers
                if (isFinite(freq) && isFinite(magnitude)) {
                    magnitudePoints.push({ x: freq, y: magnitude });
                    maxMagnitude = Math.max(maxMagnitude, magnitude);
                    maxFreq = Math.max(maxFreq, freq);
                }
                
                // Add phase points if we have phase data
                if (phaseResult && i < phaseResult.length) {
                    let phase = phaseResult[i];
                    if (isFinite(freq) && isFinite(phase)) {
                        phasePoints.push({ x: freq, y: phase });
                    }
                }
            }
        }
        
        // Only update axes if we have valid data
        if (isFinite(maxMagnitude) && isFinite(maxFreq)) {
            // Update the magnitude axis with some padding
            freqAxisX.min = 0;
            
            // Different axis handling for Fourier vs Laplace
            if (transformType === "Fourier") {
                // Auto-adjust scale based on the data frequency content
                let expectedFrequency = -1;
                
                // Try to extract frequency from the data
                if (frequencies && frequencies.length > 0) {
                    // Find the frequency with the highest magnitude
                    let maxMagIndex = 0;
                    let maxMagValue = 0;
                    
                    for (let i = 0; i < transformResult.length && i < frequencies.length; i++) {
                        if (transformResult[i] > maxMagValue) {
                            maxMagValue = transformResult[i];
                            maxMagIndex = i;
                        }
                    }
                    
                    if (maxMagIndex > 0) {
                        expectedFrequency = frequencies[maxMagIndex];
                    }
                }
                
                // If we found a peak frequency, scale the axis around it
                if (expectedFrequency > 0) {
                    // Show 2-3x the main frequency to include harmonics
                    freqAxisX.max = Math.max(expectedFrequency * 3, 10);
                } else {
                    // Fallback to the previous calculation
                    freqAxisX.max = maxFreq > 0 ? Math.min(Math.max(maxFreq * 1.2, 5), 100) : 100;
                }
                
                freqAxisX.labelFormat = "%.1f";
            } else {
                // For Laplace, automatically adjust the range to show the peak
                // Find the location of the peak
                let peakIndex = -1;
                let peakValue = 0;
                
                for (let i = 0; i < transformResult.length && i < frequencies.length; i++) {
                    if (transformResult[i] > peakValue) {
                        peakValue = transformResult[i];
                        peakIndex = i;
                    }
                }
                
                // If we found a peak, center the view around it
                if (peakIndex >= 0) {
                    let peakFreq = frequencies[peakIndex];
                    // Scale the axis to show 1.5x the peak frequency on each side
                    freqAxisX.max = Math.max(peakFreq * 3, 100);
                } else {
                    // Fallback
                    freqAxisX.max = maxFreq > 0 ? Math.max(maxFreq * 1.5, 1000) : 1000;
                }
                
                freqAxisX.labelFormat = freqAxisX.max > 100 ? "%.0f" : "%.1f";
            }
            
            magnitudeAxisY.min = 0;
            magnitudeAxisY.max = maxMagnitude > 0 ? maxMagnitude * 1.2 : 2;
            
            // If we have a resonant frequency, make sure it's visible
            if (transformType === "Laplace" && resonantFrequency > 0) {
                // Ensure the x-axis range shows the resonant frequency
                if (resonantFrequency > freqAxisX.max) {
                    freqAxisX.max = resonantFrequency * 1.5;
                }
            }
            
            // Clear and add all points at once to ensure Windows compatibility
            magnitudeSeries.clear();
            for (let i = 0; i < magnitudePoints.length; i++) {
                magnitudeSeries.append(magnitudePoints[i].x, magnitudePoints[i].y);
            }
            
            phaseSeries.clear();
            for (let i = 0; i < phasePoints.length; i++) {
                phaseSeries.append(phasePoints[i].x, phasePoints[i].y);
            }
            
            // Update the resonance marker if applicable
            if (transformType === "Laplace" && resonantFrequency > 0) {
                // Create a vertical line at the resonant frequency
                // Get the max magnitude to scale the line height
                let maxMag = maxMagnitude;
                
                // Clear any existing points
                resonanceMarker.clear();
                
                // Draw vertical line from 0 to slightly above max magnitude
                resonanceMarker.append(resonantFrequency, 0);
                resonanceMarker.append(resonantFrequency, maxMag * 1.1);
                
                // Position the label near the resonant frequency peak
                // We need to convert from value to pixel position
                let xPos = transformChart.mapToPosition(Qt.point(resonantFrequency, maxMag), magnitudeSeries).x;
                let yPos = transformChart.mapToPosition(Qt.point(resonantFrequency, maxMag * 0.8), magnitudeSeries).y;
                
                // Set the position of the label
                resonanceLabel.x = xPos - resonanceLabel.width / 2;
                resonanceLabel.y = yPos - resonanceLabel.height - 5;
            }
        }
    }
}
