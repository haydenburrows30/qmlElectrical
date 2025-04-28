import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import Qt.labs.platform

import "../visualizers/"
import "../buttons/"

Item {
    id: root

    property var calculator: null
    property var timeDomain: []
    property var transformResult: []
    property var phaseResult: []
    property var frequencies: []
    property string transformType: "Fourier"
    property color lineColor1: "#2196f3"
    property color lineColor2: "#4caf50"
    property color gridColor: "#303030"
    property color textColor: "#e0e0e0"
    property color backgroundColor: "#1e1e1e"
    property bool darkMode: true
    property bool isCalculating: false
    property bool highPerformanceMode: performanceModeCheckbox.checked
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

    property string windowType: "None"
    property bool showWindowInfo: transformType === "Fourier" && windowType !== "None"

    property bool isCustomWaveform: transformType === "Fourier" && false
    property var harmonicFrequencies: []
    property bool showHarmonics: true

    property bool showHilbertEnvelope: false
    property bool showHilbertPhase: false
    property bool isHilbertTransform: transformType === "Hilbert"

    Component.onCompleted: {
        updateThemeColors()
        Qt.callLater(updateCharts)
    }

    onDarkModeChanged: {
        updateThemeColors()
    }
    onResonantFrequencyChanged: updateTransformSeries()
    onTimeDomainChanged: {
        Qt.callLater(updateCharts)
        detectHarmonics()
    }
    onTransformResultChanged: {
        Qt.callLater(updateCharts)
        if (isHilbertTransform) {
            processHilbertData()
        }
    }
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

    onWindowTypeChanged: {
        showWindowInfo = (transformType === "Fourier" && windowType !== "None")
    }

    ColumnLayout {
        anchors.fill: parent

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
            animationOptions: ChartView.NoAnimation
            legend.visible: legendCheckBox.checked
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
                visible: showPhaseCheckbox.checked
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
                visible: showPhaseCheckbox.checked
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

        RowLayout {

            Label { 
                text: "Phase:" 
            }

            CheckBox {
                id: showPhaseCheckbox
                checked: false

                Layout.alignment: Qt.AlignLeft
                ToolTip.text: "Turn phase on/off"
                ToolTip.visible: hovered
                ToolTip.delay: 500

                onToggled: updateCharts()
            }

            Label { 
                text: "Performance:"
            }

            CheckBox {
                id: performanceModeCheckbox
                // text: performanceModeCheckbox.checked ? "High" : "Normal"
                checked: false

                ToolTip.text: "Optimizes rendering for better performance"
                ToolTip.visible: hovered
                ToolTip.delay: 500
            }

            Label { 
                text: "Legend:"
            }

            CheckBox {
                id: legendCheckBox
                // text: legendCheckBox.checked ? "On" : "Off"
                checked: true

                ToolTip.text: "Turns legend on/off"
                ToolTip.visible: hovered
                ToolTip.delay: 500
            }

            Label {Layout.fillWidth: true}

            StyledButton {
                icon.source: "../../../icons/rounded/refresh.svg"
                ToolTip.text: "Refresh charts"
                ToolTip.visible: hovered
                ToolTip.delay: 500
                Layout.alignment: Qt.AlignRight

                onClicked: {
                    calculator.calculate()
                }
            }
        }

        // Pole-Zero Plot (only for Z-Transform)
        PoleZeroViz{
            id: poleZeroPlot
            visible: showPoleZero
        }

        TransformViz {
            id: wavelet3DPlot
            visible: show3D && transformType === "Wavelet"
        }
    }

    function updateTimeDomainChart() {
        let timePoints = [];

        if (!timeDomain || timeDomain.length === 0) {
            return;
        }

        let minY = Number.MAX_VALUE;
        let maxY = -Number.MAX_VALUE;
        let maxX = 0;
        let pointsAdded = 0;
        
        try {
            let stride = 1;
            if (highPerformanceMode) {
                if (timeDomain.length > 10000) {
                    stride = Math.max(1, Math.floor(timeDomain.length / 1000));
                } else if (timeDomain.length > 5000) {
                    stride = Math.max(1, Math.floor(timeDomain.length / 750));
                } else if (timeDomain.length > 1000) {
                    stride = Math.max(1, Math.floor(timeDomain.length / 500));
                }
            }
            
            if (timeDomain.length > 0) {
                if (typeof timeDomain[0] === 'object' && 'x' in timeDomain[0] && 'y' in timeDomain[0]) {
                    for (let i = 0; i < timeDomain.length; i += stride) {
                        let point = timeDomain[i];
                        
                        if (point && isFinite(point.x) && isFinite(point.y)) {
                            timePoints.push({ x: point.x, y: point.y });
                            minY = Math.min(minY, point.y);
                            maxY = Math.max(maxY, point.y);
                            maxX = Math.max(maxX, point.x);
                            pointsAdded++;
                        }
                    }
                } 
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

            if (isFinite(minY) && isFinite(maxY) && minY !== Number.MAX_VALUE && pointsAdded > 0) {
                timeAxisX.min = 0;
                timeAxisX.max = maxX > 0 ? maxX : 5;

                const yRange = Math.max(Math.abs(minY), Math.abs(maxY)) * 1.2;
                timeAxisY.min = -yRange || -2;
                timeAxisY.max = yRange || 2;

                timeSeries.clear();

                for (let i = 0; i < timePoints.length; i++) {
                    timeSeries.append(timePoints[i].x, timePoints[i].y);
                }
            }
        } catch (e) {
        }
    }
    
    function updateTransformChart() {
        let magnitudePoints = [];
        let phasePoints = [];
        let resonancePoints = [];

        if (!transformResult || transformResult.length === 0) return;

        let maxMagnitude = 0;
        let maxFreq = 0;

        let stride = highPerformanceMode && transformResult.length > 1000 ? Math.floor(transformResult.length / 500) : 1;

        for (let i = 0; i < transformResult.length; i += stride) {
            if (i < frequencies.length) {
                let freq = frequencies[i];
                let magnitude = transformResult[i];

                if (isFinite(freq) && isFinite(magnitude)) {
                    magnitudePoints.push({ x: freq, y: magnitude });
                    maxMagnitude = Math.max(maxMagnitude, magnitude);
                    maxFreq = Math.max(maxFreq, freq);
                }

                if (phaseResult && i < phaseResult.length) {
                    let phase = phaseResult[i];
                    if (isFinite(freq) && isFinite(phase)) {
                        phasePoints.push({ x: freq, y: phase });
                    }
                }
            }
        }

        if (isFinite(maxMagnitude) && isFinite(maxFreq)) {
            freqAxisX.min = 0;

            if (transformType === "Fourier") {
                let expectedFrequency = -1;

                if (frequencies && frequencies.length > 0) {
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

                if (expectedFrequency > 0) {
                    if (isCustomWaveform && harmonicFrequencies.length > 0) {
                        let maxHarmonic = harmonicFrequencies[harmonicFrequencies.length - 1];
                        freqAxisX.max = Math.max(maxHarmonic * 1.2, expectedFrequency * 5);
                    } else {
                        freqAxisX.max = Math.max(expectedFrequency * 3, 10);
                    }
                } else {
                    freqAxisX.max = maxFreq > 0 ? Math.min(Math.max(maxFreq * 1.2, 5), 100) : 100;
                }
                
                freqAxisX.labelFormat = "%.1f";
            } else {
                let significantFreq = maxFreq;
                let threshold = maxMagnitude * 0.1;
                let foundCutoff = false;

                for (let i = magnitudePoints.length - 1; i > 0; i--) {
                    if (magnitudePoints[i].y > threshold) {
                        significantFreq = magnitudePoints[i].x;
                        foundCutoff = true;
                        break;
                    }
                }

                if (!foundCutoff) {
                    significantFreq = maxFreq;
                }

                freqAxisX.max = Math.max(significantFreq * 1.2, 100);

                if ((resonantFrequency > 0) || 
                    (transformResult.length > 200 && maxFreq > 50)) {
                    let significantFreq = findSignificantFrequency(magnitudePoints, maxMagnitude);
                    if (significantFreq > 0) {
                        freqAxisX.max = Math.max(freqAxisX.max, significantFreq * 3);
                    }
                    
                    freqAxisX.max = Math.min(freqAxisX.max, 200);
                }

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

                if (windowType !== "None") {
                    harmonicsText.text = "Harmonics" + (windowType !== "None" ? " (attenuated)" : "");
                } else {
                    harmonicsText.text = "Harmonics";
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
        poleZeroPlot.pzCanvas.requestPaint();
    }
    
    function updateTransformSeries() {
        magnitudeSeries.clear();
        phaseSeries.clear();
        
        if (frequencies.length > 0 && transformResult.length > 0) {
            for (let i = 0; i < Math.min(frequencies.length, transformResult.length); i++) {
                magnitudeSeries.append(frequencies[i], transformResult[i]);
                
                if (phaseResult.length > i && (showPhaseCheckbox.checked)) {
                    phaseSeries.append(frequencies[i], phaseResult[i]);
                }
            }
        } else {
            magnitudeSeries.append(0, 0);
            magnitudeSeries.append(10, 0);
            
            if (showPhaseCheckbox.checked) {
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

    function updateCharts() {
        updateTimeDomainChart()
        updateTransformChart()
    }

    function detectHarmonics() {
        if (transformType !== "Fourier" || !transformResult || transformResult.length < 10) {
            isCustomWaveform = false
            harmonicFrequencies = []
            return
        }

        let peakThreshold = 0.10

        if (windowType !== "None") {
            switch(windowType) {
                case "Hann":
                case "Hamming":
                    peakThreshold = 0.05;
                    break;
                case "Blackman":
                case "Kaiser":
                    peakThreshold = 0.03;
                    break;
                case "Flattop":
                    peakThreshold = 0.02;
                    break;
                default:
                    peakThreshold = 0.07;
            }
        }
        
        let peaks = []
        let maxValue = 0

        for (let i = 0; i < transformResult.length; i++) {
            if (transformResult[i] > maxValue) {
                maxValue = transformResult[i]
            }
        }

        for (let i = 5; i < transformResult.length - 5; i++) {
            if (transformResult[i] > peakThreshold * maxValue) {
                if (transformResult[i] > transformResult[i-1] && 
                    transformResult[i] > transformResult[i+1]) {
                    peaks.push({
                        frequency: frequencies[i],
                        magnitude: transformResult[i]
                    })
                }
            }
        }

        if (peaks.length >= 2) {
            peaks.sort((a, b) => a.frequency - b.frequency)

            harmonicFrequencies = peaks.map(p => p.frequency)

            isCustomWaveform = true
        } else {
            isCustomWaveform = false
            harmonicFrequencies = []
        }
    }

    function processHilbertData() {
        // Ensure we have adequate data scaling for Hilbert transform
        if (isHilbertTransform && transformResult && transformResult.length > 0) {
            // Find min/max values for better scaling
            let minVal = Number.MAX_VALUE;
            let maxVal = Number.MIN_VALUE;
            
            for (let i = 0; i < transformResult.length; i++) {
                minVal = Math.min(minVal, transformResult[i]);
                maxVal = Math.max(maxVal, transformResult[i]);
            }
            
            // Adjust the scale to show at least 40rad/s instead of 5rad/s
            // This might involve setting your Y-axis range explicitly
            if (transformChart && transformChart.axes) {
                // If you have a ValueAxis for Y values on your bottom chart
                let yAxis = transformChart.axes[1]; // Adjust index if needed
                if (yAxis) {
                    // Expand the range to ensure data is visible
                    yAxis.min = minVal - (maxVal - minVal) * 0.1;
                    yAxis.max = maxVal + (maxVal - minVal) * 0.1;
                    
                    // Ensure there's a minimum height for visibility
                    if (yAxis.max - yAxis.min < 40) {
                        let midpoint = (yAxis.max + yAxis.min) / 2;
                        yAxis.min = midpoint - 20;
                        yAxis.max = midpoint + 20;
                    }
                }
            }
        }
    }
}
