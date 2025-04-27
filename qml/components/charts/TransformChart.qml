import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import Qt.labs.platform

import "../visualizers/"

Item {
    id: root

    property var timeDomain: []
    property var transformResult: []
    property var phaseResult: []
    property var frequencies: []
    property bool showPhase: true
    property string transformType: "Fourier" // "Fourier", "Laplace", "Z-Transform", "Wavelet", "Hilbert"
    property color lineColor1: "#2196f3"
    property color lineColor2: "#4caf50"
    property color gridColor: "#303030"
    property color textColor: "#e0e0e0"
    property color backgroundColor: "#1e1e1e"
    property bool darkMode: true
    property bool isCalculating: false
    property bool highPerformanceMode: true
    property real resonantFrequency: -1

    property bool showPoleZero: false
    property var poleLocations: []
    property var zeroLocations: []
    property bool show3D: false

    property real animationDuration: 300

    property real axisYMin: -1.2
    property real axisYMax: 1.2
    property real axisPhaseMin: -180
    property real axisPhaseMax: 180

    property color signalColor: "#2196F3"
    property color envelopeColor: "#4CAF50"
    property color phaseColor: "#FFA726"
    property color resonanceColor: "#FF5722"
    property color poleColor: "#E91E63"
    property color zeroColor: "#00BCD4"

    readonly property bool isLinux: Qt.platform.os === "linux"
    readonly property bool isWindows: Qt.platform.os === "windows"

    // Update window visualization properties
    property string windowType: "None"  // Window function type to display in labels
    property bool showWindowInfo: transformType === "Fourier" && windowType !== "None"

    property bool isCustomWaveform: transformType === "Fourier" && false  // Will be set based on data
    property var harmonicFrequencies: []  // To store detected harmonic frequencies
    property bool showHarmonics: true     // Allow toggling harmonic markers

    Component.onCompleted: {
        // Initialize colors and then call update charts
        updateThemeColors()
        Qt.callLater(updateCharts)
    }

    onDarkModeChanged: {
        // Update colors based on dark/light mode
        updateThemeColors()
    }
    onResonantFrequencyChanged: updateTransformSeries()
    onTimeDomainChanged: {
        Qt.callLater(updateCharts)
        // Check if this looks like a custom waveform with harmonics
        detectHarmonics()
    }
    onTransformResultChanged: Qt.callLater(updateCharts)
    onShowPhaseChanged: Qt.callLater(updateCharts)
    onHighPerformanceModeChanged: Qt.callLater(updateCharts)

    onPoleLocationsChanged: {
        if (showPoleZero) {
            updatePoleZeroPlot()
        }
    }

    onZeroLocationsChanged: {
        if (showPoleZero) {
            updatePoleZeroPlot() 
        }
    }

    onShowPoleZeroChanged: {
        // Use one code block to handle visibility toggling
        if (showPoleZero) {
            transformChart.visible = false
            poleZeroPlot.visible = true
            updatePoleZeroPlot()
        } else {
            transformChart.visible = true
            poleZeroPlot.visible = false
        }
    }

    onShow3DChanged: {
        if (transformType === "Wavelet") {
            // Toggle visibility of the 3D wavelet plot
            wavelet3DPlot.visible = show3D;
            transformChart.visible = !show3D;
            
            // Force a repaint of the 3D canvas when shown
            if (show3D) {
                wavelet3DPlot.threeDcanvas.requestPaint();
            }
        }
    }

    // Update both charts together
    function updateCharts() {
        updateTimeDomainChart()
        updateTransformChart()
    }
    
    // Detect harmonics in the spectrum
    function detectHarmonics() {
        // Only detect harmonics for Fourier transforms
        if (transformType !== "Fourier" || !transformResult || transformResult.length < 10) {
            isCustomWaveform = false
            harmonicFrequencies = []
            return
        }
        
        // Look for multiple peaks in the spectrum that could be harmonics
        let peakThreshold = 0.10  // Peaks must be at least 10% of max value
        let peaks = []
        let maxValue = 0
        
        // First find the maximum value
        for (let i = 0; i < transformResult.length; i++) {
            if (transformResult[i] > maxValue) {
                maxValue = transformResult[i]
            }
        }
        
        // Then find all peaks above the threshold
        for (let i = 5; i < transformResult.length - 5; i++) {
            if (transformResult[i] > peakThreshold * maxValue) {
                // Check if this is a local maximum
                if (transformResult[i] > transformResult[i-1] && 
                    transformResult[i] > transformResult[i+1]) {
                    // Add this peak
                    peaks.push({
                        frequency: frequencies[i],
                        magnitude: transformResult[i]
                    })
                }
            }
        }
        
        // Need at least 2 peaks to consider as having harmonics
        if (peaks.length >= 2) {
            // Sort peaks by frequency
            peaks.sort((a, b) => a.frequency - b.frequency)
            
            // Store the harmonic frequencies
            harmonicFrequencies = peaks.map(p => p.frequency)
            
            // Mark as custom waveform if we have multiple frequency components
            isCustomWaveform = true
        } else {
            isCustomWaveform = false
            harmonicFrequencies = []
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        // Window function explanation when used
        Rectangle {
            id: windowInfoRect
            visible: showWindowInfo
            color: Qt.rgba(root.lineColor2.r, root.lineColor2.g, root.lineColor2.b, 0.2)
            border.color: root.lineColor2
            border.width: 1
            radius: 5
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: windowInfoText.width + 20
            Layout.preferredHeight: windowInfoText.height + 10
            Layout.topMargin: 5
            
            Label {
                id: windowInfoText
                text: "Window: " + windowType
                color: root.textColor
                font.pixelSize: 12
                font.bold: true
                anchors.centerIn: parent
            }
        }
        
        // explanation for Laplace transforms
        Label {
            id: laplaceExplanation
            text: {
                if (root.transformType === "Laplace" && resonantFrequency > 0) {
                    return "Resonant frequency: " + resonantFrequency.toFixed(1) + " rad/s (" + 
                           (resonantFrequency/(2*Math.PI)).toFixed(1) + " Hz)";
                }
                return "";
            }
            color: root.textColor
            font.pixelSize: 14
            font.bold: true
            visible: transformType === "Laplace" && resonantFrequency > 0
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 5
            Layout.preferredWidth: parent.width * 0.9
            Layout.maximumWidth: parent.width
            horizontalAlignment: Text.AlignHCenter
            z: 10
        }

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
            legend.visible: root.showPhase
            backgroundColor: root.backgroundColor
            theme: root.darkMode ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
            
            ValueAxis {
                id: freqAxisX
                min: 0
                // Adjust max based on the transform type
                max: transformType === "Fourier" ? 100 : 200  // Increased from 1000 to provide better visualization
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
                color: "#ff5722"
                width: 2
                visible: resonantFrequency > 0 && (transformType === "Laplace" || transformType === "Z-Transform")
                useOpenGL: isLinux // Enable OpenGL only on Linux
                
                XYPoint { x: resonantFrequency/(2*Math.PI); y: 0 }
                XYPoint { x: resonantFrequency/(2*Math.PI); y: magnitudeAxisY.max }
            }

            LineSeries {
                id: harmonicsSeries
                name: "Harmonics"
                axisX: freqAxisX
                axisY: magnitudeAxisY
                color: "#E91E63"  // Pink color for harmonics
                width: 1
                style: Qt.DashLine
                useOpenGL: isLinux
                visible: isCustomWaveform && showHarmonics
            }

            Rectangle {
                id: harmonicsLegend
                visible: isCustomWaveform && showHarmonics
                color: "#80E91E63"  // Semi-transparent pink
                border.color: "#E91E63"
                border.width: 1
                radius: 5
                width: harmonicsText.width + 12
                height: harmonicsText.height + 8
                x: parent.width - width - 10
                y: 10

                Text {
                    id: harmonicsText
                    text: "Harmonics"
                    anchors.centerIn: parent
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            Rectangle {
                id: resonanceLabel
                visible: transformType === "Laplace" && resonantFrequency > 0
                color: "#80ff5722"
                border.color: "#ff5722"
                border.width: 1
                radius: 5
                width: resonanceText.width + 12
                height: resonanceText.height + 8

                Text {
                    id: resonanceText
                    text: resonantFrequency > 0 ? "ω = " + resonantFrequency.toFixed(1) : ""
                    anchors.centerIn: parent
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        // Pole-Zero Plot (only for Z-Transform)
        Rectangle {
            id: poleZeroPlot
            width: parent.width
            height: parent.height * 0.45
            visible: showPoleZero
            color: root.backgroundColor
            border.color: root.gridColor
            border.width: 1
            radius: 5
            
            Canvas {
                id: pzCanvas
                anchors.fill: parent
                anchors.margins: 10
                
                property real centerX: width / 2
                property real centerY: height / 2
                property real radius: Math.min(width, height) * 0.4
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    // Draw coordinate system
                    ctx.strokeStyle = root.gridColor;
                    ctx.lineWidth = 1;
                    
                    // Draw unit circle
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                    ctx.stroke();
                    
                    // Draw coordinate axes
                    ctx.beginPath();
                    ctx.moveTo(0, centerY);
                    ctx.lineTo(width, centerY);
                    ctx.moveTo(centerX, 0);
                    ctx.lineTo(centerX, height);
                    ctx.stroke();
                    
                    // Draw poles
                    ctx.fillStyle = root.poleColor;
                    ctx.strokeStyle = root.poleColor;
                    ctx.lineWidth = 2;
                    
                    for (var i = 0; i < poleLocations.length; i++) {
                        var pole = poleLocations[i];
                        var poleX = centerX + pole.x * radius;
                        var poleY = centerY - pole.y * radius; // Note the negative sign for y coordinates
                        
                        // Draw cross for pole
                        ctx.beginPath();
                        ctx.moveTo(poleX - 7, poleY - 7);
                        ctx.lineTo(poleX + 7, poleY + 7);
                        ctx.moveTo(poleX + 7, poleY - 7);
                        ctx.lineTo(poleX - 7, poleY + 7);
                        ctx.stroke();
                    }
                    
                    // Draw zeros
                    ctx.fillStyle = root.zeroColor;
                    ctx.strokeStyle = root.zeroColor;
                    ctx.lineWidth = 2;
                    
                    for (var j = 0; j < zeroLocations.length; j++) {
                        var zero = zeroLocations[j];
                        var zeroX = centerX + zero.x * radius;
                        var zeroY = centerY - zero.y * radius; // Note the negative sign for y coordinates
                        
                        // Draw circle for zero
                        ctx.beginPath();
                        ctx.arc(zeroX, zeroY, 7, 0, 2 * Math.PI);
                        ctx.stroke();
                    }
                    
                    // Add grid lines for better readability
                    ctx.strokeStyle = root.gridColor;
                    ctx.lineWidth = 0.5;
                    ctx.setLineDash([3, 3]); // Dotted line
                    
                    // Draw horizontal grid lines
                    for (var k = -2; k <= 2; k++) {
                        if (k === 0) continue; // Skip center line, already drawn
                        var gridY = centerY + k * radius/2;
                        ctx.beginPath();
                        ctx.moveTo(0, gridY);
                        ctx.lineTo(width, gridY);
                        ctx.stroke();
                    }
                    
                    // Draw vertical grid lines
                    for (var l = -2; l <= 2; l++) {
                        if (l === 0) continue; // Skip center line, already drawn
                        var gridX = centerX + l * radius/2;
                        ctx.beginPath();
                        ctx.moveTo(gridX, 0);
                        ctx.lineTo(gridX, height);
                        ctx.stroke();
                    }
                    
                    // Reset line dash
                    ctx.setLineDash([]);
                    
                    // Draw labels
                    ctx.fillStyle = root.textColor;
                    ctx.font = "12px sans-serif";
                    ctx.textAlign = "center";
                    
                    ctx.fillText("Re(z)", width - 20, centerY - 5);
                    ctx.fillText("Im(z)", centerX + 5, 15);
                    ctx.fillText("|z| = 1", centerX, centerY - radius - 5);
                    
                    // Draw +/- 0.5 markers
                    ctx.fillText("0.5", centerX + radius/2, centerY - 5);
                    ctx.fillText("-0.5", centerX - radius/2, centerY - 5);
                    ctx.fillText("0.5j", centerX + 5, centerY - radius/2);
                    ctx.fillText("-0.5j", centerX + 5, centerY + radius/2);
                    
                    // Draw legend
                    var legendX = 60;
                    var legendY = height - 30;
                    
                    // Pole legend
                    ctx.strokeStyle = root.poleColor;
                    ctx.beginPath();
                    ctx.moveTo(legendX - 5, legendY - 5);
                    ctx.lineTo(legendX + 5, legendY + 5);
                    ctx.moveTo(legendX + 5, legendY - 5);
                    ctx.lineTo(legendX - 5, legendY + 5);
                    ctx.stroke();
                    
                    ctx.fillStyle = root.textColor;
                    ctx.textAlign = "left";
                    ctx.fillText("Pole", legendX + 10, legendY + 5);
                    
                    // Zero legend
                    legendX += 80;
                    ctx.strokeStyle = root.zeroColor;
                    ctx.beginPath();
                    ctx.arc(legendX, legendY, 5, 0, 2 * Math.PI);
                    ctx.stroke();
                    
                    ctx.fillStyle = root.textColor;
                    ctx.fillText("Zero", legendX + 10, legendY + 5);
                }
            }
            
            Text {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Pole-Zero Plot"
                color: root.textColor
                font.pixelSize: 14
                font.bold: true
            }
            
            Component.onCompleted: {
                updatePoleZeroPlot();
            }
        }

        TransformViz {
            id: wavelet3DPlot
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
                    // For custom waveforms with harmonics, show a wider frequency range
                    if (isCustomWaveform && harmonicFrequencies.length > 0) {
                        // Find the highest harmonic frequency
                        let maxHarmonic = harmonicFrequencies[harmonicFrequencies.length - 1];
                        // Show range up to the highest harmonic plus some margin
                        freqAxisX.max = Math.max(maxHarmonic * 1.2, expectedFrequency * 5);
                    } else {
                        // Show 2-3x the main frequency to include harmonics
                        freqAxisX.max = Math.max(expectedFrequency * 3, 10);
                    }
                } else {
                    // Fallback to the previous calculation
                    freqAxisX.max = maxFreq > 0 ? Math.min(Math.max(maxFreq * 1.2, 5), 100) : 100;
                }
                
                freqAxisX.labelFormat = "%.1f";
            } else {
                // For Laplace, ensure we use the full range of data
                // Start by finding the maximum frequency that has meaningful data
                let significantFreq = maxFreq;
                
                // Find the frequency where the magnitude drops below a threshold
                let threshold = maxMagnitude * 0.1; // 10% of max value
                let foundCutoff = false;
                
                // Scan from high to low frequencies to find where signal becomes significant
                for (let i = magnitudePoints.length - 1; i > 0; i--) {
                    if (magnitudePoints[i].y > threshold) {
                        significantFreq = magnitudePoints[i].x;
                        foundCutoff = true;
                        break;
                    }
                }
                
                // If we couldn't find a cutoff, use the maximum frequency
                if (!foundCutoff) {
                    significantFreq = maxFreq;
                }
                
                // Ensure the x-axis range is always sufficient, at least 100 rad/s or higher if data warrants
                freqAxisX.max = Math.max(significantFreq * 1.2, 100);
                
                // For resonant peaks, expand range further
                if ((resonantFrequency > 0) || 
                    (transformResult.length > 200 && maxFreq > 50)) {
                    let significantFreq = findSignificantFrequency(magnitudePoints, maxMagnitude);
                    if (significantFreq > 0) {
                        freqAxisX.max = Math.max(freqAxisX.max, significantFreq * 3);
                    }
                    
                    freqAxisX.max = Math.min(freqAxisX.max, 200);
                }
                
                // Cap the maximum for readability
                freqAxisX.max = Math.min(Math.max(freqAxisX.max, 200), 300);
                
                freqAxisX.labelFormat = freqAxisX.max > 100 ? "%.0f" : "%.1f";
            }
            
            magnitudeAxisY.min = 0;
            magnitudeAxisY.max = maxMagnitude > 0 ? maxMagnitude * 1.2 : 2;
            
            if (transformType === "Laplace" && resonantFrequency > 0) {
                if (resonantFrequency > freqAxisX.max) {
                    freqAxisX.max = resonantFrequency * 1.5;
                }
            }
            
            magnitudeSeries.clear();
            for (let i = 0; i < magnitudePoints.length; i++) {
                magnitudeSeries.append(magnitudePoints[i].x, magnitudePoints[i].y);
            }
            
            phaseSeries.clear();
            for (let i = 0; i < phasePoints.length; i++) {
                phaseSeries.append(phasePoints[i].x, phasePoints[i].y);
            }
            
            if (isCustomWaveform && harmonicFrequencies.length > 0 && transformType === "Fourier") {
                harmonicsSeries.clear();
                
                for (let i = 0; i < harmonicFrequencies.length; i++) {
                    let freq = harmonicFrequencies[i];
                    harmonicsSeries.append(freq, 0);
                    harmonicsSeries.append(freq, maxMagnitude * 0.9);
                    
                    if (i < harmonicFrequencies.length - 1) {
                        harmonicsSeries.append(freq, 0);
                    }
                }
            }
            
            if (transformType === "Laplace" && resonantFrequency > 0) {
                let maxMag = maxMagnitude;
                
                resonanceMarker.clear();
                
                resonanceMarker.append(resonantFrequency, 0);
                resonanceMarker.append(resonantFrequency, maxMag * 1.1);
                
                let xPos = transformChart.mapToPosition(Qt.point(resonantFrequency, maxMag), magnitudeSeries).x;
                let yPos = transformChart.mapToPosition(Qt.point(resonantFrequency, maxMag * 0.8), magnitudeSeries).y;
                
                resonanceLabel.x = xPos - resonanceLabel.width / 2;
                resonanceLabel.y = yPos - resonanceLabel.height - 5;
            }
        }
    }
    
    function findSignificantFrequency(points, maxMagnitude) {
        if (!points || points.length === 0) return 0;
        
        let threshold = maxMagnitude * 0.5;
        
        for (let i = 0; i < points.length; i++) {
            if (points[i].y < threshold) {
                return points[i].x;
            }
        }
        
        return points[points.length - 1].x;
    }
    
    function updatePoleZeroPlot() {
        pzCanvas.requestPaint();
    }
    
    function updateTransformSeries() {
        magnitudeSeries.clear();
        phaseSeries.clear();
        
        if (frequencies.length > 0 && transformResult.length > 0) {
            for (let i = 0; i < Math.min(frequencies.length, transformResult.length); i++) {
                magnitudeSeries.append(frequencies[i], transformResult[i]);
                
                if (phaseResult.length > i && showPhase) {
                    phaseSeries.append(frequencies[i], phaseResult[i]);
                }
            }
        } else {
            magnitudeSeries.append(0, 0);
            magnitudeSeries.append(10, 0);
            
            if (showPhase) {
                phaseSeries.append(0, 0);
                phaseSeries.append(10, 0);
            }
        }
    }

    function updateThemeColors() {
        if (darkMode) {
            backgroundColor = "#1e1e1e"
            textColor = "#e0e0e0"
            gridColor = "#303030"
            poleColor = "#E91E63"
            zeroColor = "#00BCD4"
        } else {
            backgroundColor = "#ffffff"
            textColor = "#333333"
            gridColor = "#cccccc"
            poleColor = "#d81b60"
            zeroColor = "#0097a7"
        }
        
        if (showPoleZero) {
            updatePoleZeroPlot()
        }
        if (show3D && transformType === "Wavelet") {
            wavelet3DPlot.threeDcanvas.requestPaint()
        }
    }

    onWindowTypeChanged: {
        showWindowInfo = (transformType === "Fourier" && windowType !== "None")
    }
}
