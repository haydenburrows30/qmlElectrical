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
    property string transformType: "Fourier" // "Fourier", "Laplace", "Z-Transform", "Wavelet", "Hilbert"
    property color lineColor1: "#2196f3"
    property color lineColor2: "#4caf50"
    property color gridColor: "#303030"
    property color textColor: "#e0e0e0"
    property color backgroundColor: "#1e1e1e"
    property bool darkMode: true
    property bool isCalculating: false // Added property for BusyIndicator
    property bool highPerformanceMode: true // Add a high performance mode property
    property real resonantFrequency: -1 // Add property for resonant frequency
    
    // New properties for Z-transform and wavelet
    property bool showPoleZero: false
    property var poleLocations: []
    property var zeroLocations: []
    property bool show3D: false
    
    // Animation properties
    property real animationDuration: 300
    
    // Constants for the chart
    property real axisYMin: -1.2
    property real axisYMax: 1.2
    property real axisPhaseMin: -180
    property real axisPhaseMax: 180
    
    // Colors
    property color signalColor: "#2196F3"
    property color envelopeColor: "#4CAF50"
    property color phaseColor: "#FFA726"
    property color resonanceColor: "#FF5722"
    property color poleColor: "#E91E63"
    property color zeroColor: "#00BCD4"
    
    // Detect operating system
    readonly property bool isLinux: Qt.platform.os === "linux"
    readonly property bool isWindows: Qt.platform.os === "windows"
    
    // Handle theme changes more effectively for better visibility
    onDarkModeChanged: {
        // Update colors based on dark/light mode
        updateThemeColors()
    }
    
    function updateThemeColors() {
        // Set appropriate colors based on theme
        if (darkMode) {
            backgroundColor = "#1e1e1e"
            textColor = "#e0e0e0"
            gridColor = "#303030"
            poleColor = "#E91E63"    // Bright pink for poles
            zeroColor = "#00BCD4"    // Bright cyan for zeros
        } else {
            backgroundColor = "#ffffff"
            textColor = "#333333"
            gridColor = "#cccccc"
            poleColor = "#d81b60"    // Darker pink for poles
            zeroColor = "#0097a7"    // Darker cyan for zeros
        }
        
        // Force repaint of the canvas elements
        if (showPoleZero) {
            updatePoleZeroPlot()
        }
        if (show3D && transformType === "Wavelet") {
            wavelet3DCanvas.requestPaint()
        }
    }

    // Update charts when data changes or component completes
    Component.onCompleted: {
        // Initialize colors and then call update charts
        updateThemeColors()
        Qt.callLater(updateCharts)
    }
    
    onTimeDomainChanged: Qt.callLater(updateCharts)
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
    onResonantFrequencyChanged: updateTransformSeries()
    
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
                wavelet3DCanvas.requestPaint();
            }
        }
    }

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
                color: "#ff5722"  // Orange color for visibility
                width: 2
                visible: resonantFrequency > 0 && (transformType === "Laplace" || transformType === "Z-Transform")
                useOpenGL: isLinux // Enable OpenGL only on Linux
                
                XYPoint { x: resonantFrequency/(2*Math.PI); y: 0 }
                XYPoint { x: resonantFrequency/(2*Math.PI); y: magnitudeAxisY.max }
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
        
        // 3D visualization for wavelet transform
        Rectangle {
            id: wavelet3DPlot
            width: parent.width
            height: parent.height * 0.45
            visible: show3D && transformType === "Wavelet"
            color: root.backgroundColor
            border.color: root.gridColor
            border.width: 1
            radius: 5
            
            // Add a simple 3D-like visualization for wavelet transform
            Canvas {
                id: wavelet3DCanvas
                anchors.fill: parent
                anchors.margins: 10
                
                // Handle the array structure properly
                property real xScale: width / (transformResult.length > 0 ? transformResult[0].length || 100 : 100)
                property real yScale: height / (transformResult.length || 10)
                property real zScale: 50 // Scale factor for the magnitude
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    // Background color matching the theme
                    ctx.fillStyle = root.backgroundColor
                    ctx.fillRect(0, 0, width, height)
                    
                    // Check if we have data
                    if (!transformResult || transformResult.length === 0) {
                        // Draw a "No Data" message
                        ctx.fillStyle = root.textColor
                        ctx.font = "14px sans-serif";
                        ctx.textAlign = "center";
                        ctx.fillText("Wavelet visualization will appear here", width/2, height/2);
                        return;
                    }
                    
                    console.log("Rendering 3D plot with data size: " + transformResult.length);
                    console.log("First item type: " + (transformResult.length > 0 ? typeof transformResult[0] : "none"));
                    
                    if (transformResult.length > 0 && typeof transformResult[0] === 'number') {
                        console.log("Sample values: " + transformResult.slice(0, 5).join(", "));
                    } else if (transformResult.length > 0) {
                        console.log("Sample item keys: " + Object.keys(transformResult[0]).join(", "));
                    }
                    
                    try {
                        // Draw background grid
                        ctx.strokeStyle = root.gridColor;
                        ctx.lineWidth = 0.5;
                        
                        // Draw grid lines
                        for (let i = 0; i <= 10; i++) {
                            let x = i * width / 10;
                            let y = i * height / 10;
                            ctx.beginPath();
                            ctx.moveTo(x, 0);
                            ctx.lineTo(x, height);
                            ctx.moveTo(0, y);
                            ctx.lineTo(width, y);
                            ctx.stroke();
                        }
                        
                        // Data type investigation with improved array detection
                        let dataType = "unknown";
                        let isArray = Array.isArray(transformResult);
                        let isArrayLike = false;
                        
                        // Check if we have an array-like object with numeric indices
                        if (!isArray && typeof transformResult === 'object' && transformResult !== null) {
                            let keys = Object.keys(transformResult);
                            // Check if keys are all numeric indices
                            isArrayLike = keys.length > 0 && 
                                keys.every(key => !isNaN(parseInt(key)) && parseInt(key).toString() === key);
                            
                            if (isArrayLike) {
                                console.log("Detected array-like object with numeric indices");
                                // Find the length
                                let maxIndex = Math.max(...keys.map(k => parseInt(k)));
                                console.log("Max index: " + maxIndex);
                            }
                        }
                        
                        let is2DArray = isArray && transformResult.length > 0 && Array.isArray(transformResult[0]);
                        let isNestedObject = isArray && transformResult.length > 0 && 
                                        typeof transformResult[0] === 'object' &&
                                        !Array.isArray(transformResult[0]);
                        let isNumericArray = isArray && transformResult.length > 0 && 
                                           typeof transformResult[0] === 'number';
                        
                        if (is2DArray) dataType = "2D array";
                        else if (isNestedObject) dataType = "object array";
                        else if (isNumericArray) dataType = "numeric array";
                        else if (isArrayLike) dataType = "array-like object";
                        
                        console.log("Data structure analysis: " + dataType);
                        console.log("2D array: " + is2DArray + ", Nested object: " + isNestedObject + 
                                    ", Numeric array: " + isNumericArray + ", Array-like: " + isArrayLike);
                        
                        // Prepare data for visualization based on the type
                        let processedData;
                        let numScales = 10;
                        let maxValue = 0;
                        
                        // Convert array-like object to actual array if needed
                        let actualData = transformResult;
                        if (isArrayLike) {
                            actualData = [];
                            let keys = Object.keys(transformResult).sort((a, b) => parseInt(a) - parseInt(b));
                            for (const key of keys) {
                                actualData.push(transformResult[key]);
                            }
                            console.log("Converted array-like object to array with length: " + actualData.length);
                            
                            // Check what data types are in the converted array
                            let sampleType = typeof actualData[0];
                            console.log("Sample element type after conversion: " + sampleType);
                            
                            // For array of objects with numeric properties, try to use the object itself as a row
                            // This is a common format for wavelet coefficients
                            if (actualData.length > 0 && typeof actualData[0] === 'object') {
                                // Get example of first object to see its structure
                                let sampleObj = actualData[0];
                                let objKeys = Object.keys(sampleObj);
                                
                                // Check if object keys are numerical and sequential
                                let allNumericKeys = objKeys.length > 0 && 
                                                    objKeys.every(key => !isNaN(parseInt(key)));
                                                    
                                if (allNumericKeys) {
                                    // Each array element is likely a row of coefficients
                                    console.log("Detected wavelet coefficient matrix structure");
                                    
                                    // Use each object as a row directly
                                    is2DArray = true;
                                    
                                    // Restructure data: create proper 2D array from objects with numeric keys
                                    let maxCols = 0;
                                    // Find the maximum number of columns in any row
                                    for (let i = 0; i < actualData.length; i++) {
                                        maxCols = Math.max(maxCols, Object.keys(actualData[i]).length);
                                    }
                                    
                                    // Create restructured 2D array
                                    let restructured = [];
                                    for (let i = 0; i < actualData.length; i++) {
                                        let row = [];
                                        let obj = actualData[i];
                                        
                                        // Convert object numeric keys to array
                                        let objKeys = Object.keys(obj).sort((a, b) => parseInt(a) - parseInt(b));
                                        for (let j = 0; j < objKeys.length; j++) {
                                            let value = obj[objKeys[j]];
                                            if (typeof value === 'number') {
                                                row.push(value);
                                            } else {
                                                row.push(0); // Default for non-numeric values
                                            }
                                        }
                                        
                                        // Ensure all rows have same length by padding with zeros
                                        while (row.length < maxCols) {
                                            row.push(0);
                                        }
                                        
                                        restructured.push(row);
                                    }
                                    
                                    // Use the restructured data
                                    actualData = restructured;
                                    console.log("Restructured data to proper 2D array: " + 
                                              actualData.length + "x" + 
                                              (actualData.length > 0 ? actualData[0].length : 0));
                                    
                                    // For wavelet transform, we want to actually use this directly as our processed data
                                    // since it's already in the right format
                                    processedData = actualData;
                                    
                                    // Calculate max value for color scaling
                                    for (let i = 0; i < actualData.length; i++) {
                                        for (let j = 0; j < actualData[i].length; j++) {
                                            maxValue = Math.max(maxValue, Math.abs(actualData[i][j]));
                                        }
                                    }
                                    
                                    // Skip further processing since we already have the data in the right format
                                    is2DArray = true;
                                    isNumericArray = false;
                                    isNestedObject = false;
                                }
                            }
                            
                            // Re-detect data type after possible restructuring
                            isNumericArray = actualData.length > 0 && typeof actualData[0] === 'number';
                            isNestedObject = actualData.length > 0 && typeof actualData[0] === 'object' && 
                                            !Array.isArray(actualData[0]);
                            is2DArray = actualData.length > 0 && Array.isArray(actualData[0]);
                        }
                        
                        if (isNumericArray) {
                            // Convert flat numeric array to 2D visualization grid
                            let dataPoints = actualData.length;
                            let pointsPerScale = Math.ceil(dataPoints / numScales);
                            
                            processedData = new Array(numScales);
                            for (let i = 0; i < numScales; i++) {
                                processedData[i] = new Array(pointsPerScale).fill(0);
                            }
                            
                            // Fill with numerical data
                            for (let i = 0; i < dataPoints; i++) {
                                let scale = Math.floor(i / pointsPerScale);
                                let timeIdx = i % pointsPerScale;
                                if (scale < numScales) {
                                    let value = actualData[i];
                                    // Handle non-numeric values by converting if possible
                                    if (typeof value !== 'number') {
                                        if (value !== null && value !== undefined) {
                                            // Try to get a numeric value from the object
                                            if (typeof value === 'object') {
                                                // Try common property names that might contain values
                                                const possibleProps = ['value', 'coefficient', 'intensity', 'magnitude'];
                                                for (const prop of possibleProps) {
                                                    if (prop in value && typeof value[prop] === 'number') {
                                                        value = value[prop];
                                                        break;
                                                    }
                                                }
                                                
                                                // If still not a number, try the first numeric property
                                                if (typeof value !== 'number') {
                                                    for (const prop in value) {
                                                        if (typeof value[prop] === 'number') {
                                                            value = value[prop];
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            // If still not a number, try to parse it
                                            if (typeof value !== 'number') {
                                                value = parseFloat(value);
                                            }
                                        }
                                        
                                        // If conversion failed, use 0
                                        if (isNaN(value) || value === null || value === undefined) {
                                            value = 0;
                                        }
                                    }
                                    
                                    processedData[scale][timeIdx] = value;
                                    maxValue = Math.max(maxValue, Math.abs(value));
                                }
                            }
                        } else if (isNestedObject) {
                            // Handle objects with different properties
                            let dataPoints = actualData.length;
                            let pointsPerScale = Math.ceil(dataPoints / numScales);
                            
                            processedData = new Array(numScales);
                            for (let i = 0; i < numScales; i++) {
                                processedData[i] = new Array(pointsPerScale).fill(0);
                            }
                            
                            // Determine which property to use
                            let valueProperty = "";
                            if (actualData.length > 0) {
                                const sampleObj = actualData[0];
                                // Try common property names
                                const possibleProps = ['y', 'value', 'magnitude', 'amplitude', 'coefficient'];
                                for (const prop of possibleProps) {
                                    if (prop in sampleObj && typeof sampleObj[prop] === 'number') {
                                        valueProperty = prop;
                                        break;
                                    }
                                }
                                
                                // If no matching prop found, use the first numeric property
                                if (!valueProperty) {
                                    for (const prop in sampleObj) {
                                        if (typeof sampleObj[prop] === 'number') {
                                            valueProperty = prop;
                                            break;
                                        }
                                    }
                                }
                            }
                            
                            console.log("Using object property: " + valueProperty);
                            
                            // Fill with object data
                            for (let i = 0; i < dataPoints; i++) {
                                let scale = Math.floor(i / pointsPerScale);
                                let timeIdx = i % pointsPerScale;
                                if (scale < numScales && valueProperty) {
                                    let value = actualData[i][valueProperty] || 0;
                                    processedData[scale][timeIdx] = value;
                                    maxValue = Math.max(maxValue, Math.abs(value));
                                }
                            }
                        } else if (is2DArray) {
                            // Direct 2D array - use as is
                            processedData = actualData;
                            
                            // Find maximum value
                            for (let i = 0; i < actualData.length; i++) {
                                for (let j = 0; j < actualData[i].length; j++) {
                                    maxValue = Math.max(maxValue, Math.abs(actualData[i][j]));
                                }
                            }
                        } else {
                            // Fallback for unknown data structure - use flat array with dummy data
                            // Create a better visualization by using any numerical data we can find
                            let dummyData = [];
                            
                            // If transformResult is an object with any structure, try to extract numbers
                            if (typeof transformResult === 'object' && transformResult !== null) {
                                // Function to recursively extract numbers from any object
                                function extractNumbers(obj, path = "", result = []) {
                                    if (typeof obj === 'number') {
                                        result.push({path: path, value: obj});
                                    } else if (Array.isArray(obj)) {
                                        for (let i = 0; i < obj.length; i++) {
                                            extractNumbers(obj[i], path + "[" + i + "]", result);
                                        }
                                    } else if (typeof obj === 'object' && obj !== null) {
                                        for (const key in obj) {
                                            extractNumbers(obj[key], path ? path + "." + key : key, result);
                                        }
                                    }
                                    return result;
                                }
                                
                                // Extract all numbers from the object
                                let allNumbers = extractNumbers(transformResult);
                                
                                if (allNumbers.length > 0) {
                                    console.log("Found " + allNumbers.length + " numeric values in the data");
                                    // Use these values as our data
                                    dummyData = allNumbers.map(item => item.value);
                                    
                                    // Now convert this to our visualization grid
                                    let dataPoints = dummyData.length;
                                    let pointsPerScale = Math.ceil(dataPoints / numScales);
                                    
                                    processedData = new Array(numScales);
                                    for (let i = 0; i < numScales; i++) {
                                        processedData[i] = new Array(pointsPerScale).fill(0);
                                    }
                                    
                                    // Fill with the extracted numerical data
                                    for (let i = 0; i < dataPoints; i++) {
                                        let scale = Math.floor(i / pointsPerScale);
                                        let timeIdx = i % pointsPerScale;
                                        if (scale < numScales) {
                                            let value = dummyData[i];
                                            processedData[scale][timeIdx] = value;
                                            maxValue = Math.max(maxValue, Math.abs(value));
                                        }
                                    }
                                } else {
                                    // No numeric values found, create dummy data
                                    processedData = new Array(numScales);
                                    for (let i = 0; i < numScales; i++) {
                                        processedData[i] = new Array(20).fill(0);
                                    }
                                    console.log("No numeric values found, using empty grid");
                                }
                            } else {
                                // Truly unknown data type - use empty grid
                                processedData = new Array(numScales);
                                for (let i = 0; i < numScales; i++) {
                                    processedData[i] = new Array(20).fill(0);
                                }
                                console.log("Unknown data structure, using empty grid");
                            }
                        }
                        
                        console.log("Max value: " + maxValue);
                        console.log("Processed data dimensions: " + processedData.length + " x " + 
                                   (processedData.length > 0 ? processedData[0].length : 0));
                        
                        // If maxValue is too small or zero, use a default value for visualization
                        if (maxValue < 0.001) {
                            maxValue = 1.0;
                            console.log("Using default maxValue = 1.0 for better visualization");
                        }
                        
                        // Define color gradient
                        let colorStops = [
                            { pos: 0.0, color: darkMode ? "#004080" : "#0d47a1" }, // Blue
                            { pos: 0.2, color: darkMode ? "#008080" : "#00695c" }, // Teal
                            { pos: 0.4, color: darkMode ? "#008000" : "#2e7d32" }, // Green
                            { pos: 0.6, color: darkMode ? "#808000" : "#827717" }, // Yellow-Green
                            { pos: 0.8, color: darkMode ? "#800000" : "#b71c1c" }, // Red-Brown
                            { pos: 1.0, color: darkMode ? "#800080" : "#6a1b9a" }  // Purple
                        ];
                        
                        function getColorForValue(value, max) {
                            let normalizedValue = Math.abs(value) / max;
                            
                            for (let i = 0; i < colorStops.length - 1; i++) {
                                if (normalizedValue >= colorStops[i].pos && normalizedValue <= colorStops[i+1].pos) {
                                    let ratio = (normalizedValue - colorStops[i].pos) / (colorStops[i+1].pos - colorStops[i].pos);
                                    return interpolateColor(colorStops[i].color, colorStops[i+1].color, ratio);
                                }
                            }
                            return colorStops[colorStops.length-1].color;
                        }
                        
                        function interpolateColor(color1, color2, ratio) {
                            function hexToRgb(hex) {
                                let r = parseInt(hex.substring(1, 3), 16);
                                let g = parseInt(hex.substring(3, 5), 16);
                                let b = parseInt(hex.substring(5, 7), 16);
                                return [r, g, b];
                            }
                            
                            let rgb1 = hexToRgb(color1);
                            let rgb2 = hexToRgb(color2);
                            
                            let r = Math.round(rgb1[0] + (rgb2[0] - rgb1[0]) * ratio);
                            let g = Math.round(rgb1[1] + (rgb2[1] - rgb1[1]) * ratio);
                            let b = Math.round(rgb1[2] + (rgb2[2] - rgb1[2]) * ratio);
                            
                            return `rgb(${r},${g},${b})`;
                        }
                        
                        // Draw the heatmap visualization
                        const scaleCount = processedData.length;
                        const timeCount = processedData.length > 0 ? processedData[0].length : 0;
                        
                        // Define gradient dimensions early so they can be referenced throughout the function
                        const gradWidth = 20;
                        const gradHeight = height * 0.8;
                        const gradX = width - gradWidth - 10;
                        const gradY = height * 0.1;
                        
                        if (scaleCount > 0 && timeCount > 0) {
                            const cellWidth = width / timeCount;
                            const cellHeight = height / scaleCount;
                            
                            // Draw scale/time grid for reference
                            ctx.strokeStyle = root.gridColor;
                            ctx.lineWidth = 0.25;
                            
                            // Draw horizontal scale dividers
                            for (let i = 0; i <= scaleCount; i++) {
                                let y = i * cellHeight;
                                ctx.beginPath();
                                ctx.moveTo(0, y);
                                ctx.lineTo(width, y);
                                ctx.stroke();
                            }
                            
                            // Draw vertical time dividers
                            for (let i = 0; i <= timeCount; i++) {
                                let x = i * cellWidth;
                                ctx.beginPath();
                                ctx.moveTo(x, 0);
                                ctx.lineTo(x, height);
                                ctx.stroke();
                            }
                            
                            // Draw colored rectangles for the heatmap with better styling
                            for (let scaleIdx = 0; scaleIdx < scaleCount; scaleIdx++) {
                                let row = processedData[scaleIdx];
                                if (!row) continue;
                                
                                for (let timeIdx = 0; timeIdx < row.length; timeIdx++) {
                                    let value = row[timeIdx] || 0;
                                    let x = timeIdx * cellWidth;
                                    let y = height - (scaleIdx + 1) * cellHeight; // flip vertically
                                    
                                    // Color based on value
                                    ctx.fillStyle = getColorForValue(value, maxValue);
                                    
                                    // Draw cells with slight padding for better visualization
                                    let padding = Math.min(1, Math.min(cellWidth, cellHeight) * 0.05);
                                    ctx.fillRect(x + padding, y + padding, 
                                                cellWidth - padding*2, cellHeight - padding*2);
                                    
                                    // Add coefficient value text for larger cells
                                    if (cellWidth > 35 && cellHeight > 20 && Math.abs(value) > maxValue * 0.1) {
                                        let textColor = darkMode ? "#ffffff" : "#000000";
                                        let displayValue = value.toFixed(2);
                                        
                                        ctx.fillStyle = textColor;
                                        ctx.font = "10px sans-serif";
                                        ctx.textAlign = "center";
                                        ctx.textBaseline = "middle";
                                        ctx.fillText(displayValue, x + cellWidth/2, y + cellHeight/2);
                                    }
                                }
                            }
                            
                            // Add informative title about the data detected
                            ctx.textAlign = "center";
                            ctx.font = "12px sans-serif";
                            ctx.fillStyle = "#4CAF50"; // Green color for success message
                            
                            if (is2DArray || isArrayLike) {
                                ctx.fillText(`Successfully visualized ${scaleCount}×${timeCount} wavelet coefficients`, 
                                            width/2, 15);
                                
                                // Add a more detailed explanation for wavelet transform visualization
                                ctx.font = "11px sans-serif";
                                ctx.fillStyle = root.textColor;
                                ctx.fillText("Vertical axis: scale (low to high frequency)", width/2, 30);
                                ctx.fillText("Horizontal axis: time/position", width/2, 45);
                                ctx.fillText("Color intensity: coefficient magnitude", width/2, 60);
                            }
                            
                            // Add scale axis labels with scale values
                            ctx.font = "10px sans-serif";
                            ctx.textAlign = "right";
                            
                            // Show frequency scale labels
                            for (let i = 0; i < Math.min(10, scaleCount); i++) {
                                let y = height - (i * (height / Math.min(10, scaleCount))) - (height / (2 * Math.min(10, scaleCount)));
                                let labelText = i === 0 ? "Low freq" : (i === 9 ? "High freq" : "Scale " + i);
                                ctx.fillText(labelText, width - gradWidth - 15, y);
                            }
                            
                            // Add time axis labels
                            ctx.textAlign = "center";
                            for (let i = 0; i < Math.min(5, timeCount); i++) {
                                let x = i * (width - gradWidth - 20) / Math.min(5, timeCount) + (width - gradWidth - 20) / (2 * Math.min(5, timeCount));
                                ctx.fillText("t" + i, x, height - 5);
                            }
                        }
                        
                        // Draw the color scale/legend
                        let gradient = ctx.createLinearGradient(gradX, gradY + gradHeight, gradX, gradY);
                        for (let stop of colorStops) {
                            gradient.addColorStop(stop.pos, stop.color);
                        }
                        
                        ctx.fillStyle = gradient;
                        ctx.fillRect(gradX, gradY, gradWidth, gradHeight);
                        ctx.strokeStyle = root.textColor;
                        ctx.lineWidth = 1;
                        ctx.strokeRect(gradX, gradY, gradWidth, gradHeight);
                        
                        ctx.fillStyle = root.textColor;
                        ctx.font = "12px sans-serif";
                        ctx.textAlign = "right";
                        ctx.fillText(maxValue.toFixed(2), gradX - 5, gradY + 12);
                        ctx.fillText("0", gradX - 5, gradY + gradHeight);
                        
                        ctx.textAlign = "center";
                        ctx.fillText("Time", width/2, height - 5);
                        
                        ctx.save();
                        ctx.translate(10, height/2);
                        ctx.rotate(-Math.PI/2);
                        ctx.fillText("Scale", 0, 0);
                        ctx.restore();
                        
                        ctx.save();
                        ctx.translate(width - 40, height/2);
                        ctx.rotate(-Math.PI/2);
                        ctx.fillText("Coefficient Magnitude", 0, 0);
                        ctx.restore();
                        
                    } catch (e) {
                        // Handle errors with better reporting
                        console.error("Error in wavelet visualization:", e, "Stack: ", e.stack);
                        ctx.fillStyle = darkMode ? "#ff5252" : "#d32f2f";
                        ctx.font = "14px sans-serif";
                        ctx.textAlign = "center";
                        ctx.fillText("Error rendering wavelet visualization", width/2, height/2);
                        ctx.font = "12px sans-serif";
                        ctx.fillText(e.toString(), width/2, height/2 + 20);
                    }
                }
                
                Component.onCompleted: requestPaint()
                onVisibleChanged: if (visible) requestPaint()
            }
            
            MouseArea {
                anchors.fill: parent
                property real lastX: 0
                property real lastY: 0
                
                onPressed: {
                    lastX = mouseX
                    lastY = mouseY
                }
                
                onPositionChanged: {
                    if (pressed) {
                        var deltaY = mouseY - lastY
                        wavelet3DCanvas.zScale = Math.max(5, Math.min(200, wavelet3DCanvas.zScale - deltaY))
                        
                        lastX = mouseX
                        lastY = mouseY
                        
                        wavelet3DCanvas.requestPaint()
                    }
                }
                
                hoverEnabled: true
                ToolTip.visible: containsMouse
                ToolTip.text: "Drag vertically to adjust visualization scale"
            }
            
            Text {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 5
                text: "3D Wavelet Transform Visualization"
                color: root.textColor
                font.pixelSize: 14
                font.bold: true
            }
            
            Text {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 5
                text: "Showing time-scale representation of signal energy (drag to adjust scale)"
                color: root.textColor
                font.pixelSize: 12
                opacity: 0.8
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
                // For Laplace, automatically adjust the range to show the peak or full response
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
                    // Scale the axis to show 3x the peak frequency
                    freqAxisX.max = Math.max(peakFreq * 3, 100);
                } else {
                    // Fallback - ensure we show at least 100 rad/s range
                    freqAxisX.max = Math.max(maxFreq > 0 ? maxFreq * 1.5 : 100, 100);
                }
                
                // For damped sine or impulse waves specifically, ensure we show enough range
                if ((resonantFrequency > 0) || 
                    (transformResult.length > 200 && maxFreq > 50)) { // Likely impulse or other wide-spectrum function
                    
                    // For wide-spectrum functions, ensure we show a reasonable range
                    // Show at least 3x the frequency where we find the majority of energy
                    let significantFreq = findSignificantFrequency(magnitudePoints, maxMagnitude);
                    if (significantFreq > 0) {
                        freqAxisX.max = Math.max(freqAxisX.max, significantFreq * 3);
                    }
                    
                    // But cap it for readability
                    freqAxisX.max = Math.min(freqAxisX.max, 200);
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
    
    // Helper function to find a significant frequency for proper scaling
    function findSignificantFrequency(points, maxMagnitude) {
        if (!points || points.length === 0) return 0;
        
        // Find the frequency where the magnitude drops to 50% of the max
        // This is a good heuristic to set the display range
        let threshold = maxMagnitude * 0.5;
        
        for (let i = 0; i < points.length; i++) {
            if (points[i].y < threshold) {
                return points[i].x;
            }
        }
        
        // If we didn't find a cutoff point, return the last frequency
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
            // Default empty chart state
            magnitudeSeries.append(0, 0);
            magnitudeSeries.append(10, 0);
            
            if (showPhase) {
                phaseSeries.append(0, 0);
                phaseSeries.append(10, 0);
            }
        }
    }
}
