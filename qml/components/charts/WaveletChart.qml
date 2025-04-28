import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import Qt.labs.platform

Item {
    id: root
    
    property var timeDomain: []
    property var scaleData: []
    property var magnitudeData: []
    property var phaseData: []
    property color textColor: "#e0e0e0"
    property color backgroundColor: "#1e1e1e"
    property color lineColor1: "#2196f3"
    property color lineColor2: "#4caf50"
    property color gridColor: "#303030"
    property bool darkMode: true
    property bool highPerformanceMode: false
    property string waveletType: "db1"
    
    // For the heatmap/scalogram visualization
    property var colorGradient: [
        "#000033", // Dark blue (lowest value)
        "#0000FF", // Blue
        "#00FFFF", // Cyan
        "#00FF00", // Green
        "#FFFF00", // Yellow
        "#FF0000", // Red
        "#FF00FF"  // Magenta (highest value)
    ]
    
    onTimeDomainChanged: {
        updateTimeDomainChart()
    }
    
    onMagnitudeDataChanged: {
        console.log("Magnitude data changed, length:", magnitudeData ? magnitudeData.length : 0)
        if (magnitudeData && magnitudeData.length > 0) {
            console.log("First element type:", typeof magnitudeData[0])
            if (Array.isArray(magnitudeData[0])) {
                console.log("Subelement length:", magnitudeData[0].length)
                console.log("Data format: 2D array structure")
            } else {
                console.log("Data format: not a 2D array")
                // Try to log more details about the data structure
                if (typeof magnitudeData[0] === 'object') {
                    console.log("First element keys:", Object.keys(magnitudeData[0]))
                }
            }
        }
        updateWaveletVisualization()
    }
    
    onDarkModeChanged: {
        updateThemeColors()
    }
    
    // Debug button to help troubleshoot
    Button {
        id: debugButton
        text: "Debug Wavelet Data"
        anchors.top: parent.top
        anchors.right: parent.right
        z: 10
        
        onClicked: {
            console.log("Wavelet Data Debug:")
            console.log("- Time domain length:", timeDomain ? timeDomain.length : 0)
            console.log("- Scale data length:", scaleData ? scaleData.length : 0)
            console.log("- Magnitude data:", magnitudeData ? (magnitudeData.length + " x " + 
                       (magnitudeData.length > 0 && Array.isArray(magnitudeData[0]) ? 
                       magnitudeData[0].length : "not array")) : "null")
            if (magnitudeData && magnitudeData.length > 0) {
                // Try to figure out the data structure
                console.log("Data structure check:")
                console.log("- First element type:", typeof magnitudeData[0])
                if (Array.isArray(magnitudeData[0])) {
                    console.log("- First subelement type:", typeof magnitudeData[0][0])
                } else if (typeof magnitudeData[0] === 'object') {
                    console.log("- Object keys:", Object.keys(magnitudeData[0]))
                }
            }
            // Force a repaint
            waveletCanvas.requestPaint()
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        // Time Domain Chart
        ChartView {
            id: timeDomainChart
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height * 0.3
            antialiasing: !highPerformanceMode
            animationOptions: ChartView.NoAnimation
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
            }
            
            LineSeries {
                id: timeSeries
                name: "Time Domain"
                axisX: timeAxisX
                axisY: timeAxisY
                color: root.lineColor1
                width: 2
            }
        }
        
        // Wavelet Visualization - Scalogram as an image
        Rectangle {
            id: waveletContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: root.backgroundColor
            border.color: root.gridColor
            border.width: 1
            
            // Canvas for the wavelet scalogram
            Canvas {
                id: waveletCanvas
                anchors.fill: parent
                anchors.margins: 30 // Margin for axes
                
                // Trigger paint when data changes
                onPaint: {
                    var ctx = getContext("2d");
                    drawWaveletScalogram(ctx);
                }
                
                // Draw axes labels
                Text {
                    id: yAxisTitle
                    text: "Scales"
                    color: root.textColor
                    font.pixelSize: 12
                    font.bold: true
                    anchors.left: parent.left
                    anchors.leftMargin: -25
                    anchors.verticalCenter: parent.verticalCenter
                    rotation: -90
                }
                
                Text {
                    id: xAxisTitle
                    text: "Time"
                    color: root.textColor
                    font.pixelSize: 12
                    font.bold: true
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -25
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            
            // Error message to show when data can't be visualized
            Rectangle {
                id: errorMessage
                anchors.centerIn: parent
                color: "#80000000"
                radius: 8
                width: errorText.width + 40
                height: errorText.height + 20
                visible: false
                
                Text {
                    id: errorText
                    anchors.centerIn: parent
                    text: "Unable to visualize wavelet data. Check console for details."
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                }
            }
            
            // Color legend
            Rectangle {
                id: colorLegend
                width: 20
                height: parent.height * 0.7
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                
                // Draw the gradient using a canvas
                Canvas {
                    id: legendCanvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        var gradient = ctx.createLinearGradient(0, height, 0, 0);
                        
                        // Create gradient stops from our color array
                        for (var i = 0; i < root.colorGradient.length; i++) {
                            gradient.addColorStop(i / (root.colorGradient.length - 1), root.colorGradient[i]);
                        }
                        
                        ctx.fillStyle = gradient;
                        ctx.fillRect(0, 0, width, height);
                        
                        // Add border
                        ctx.strokeStyle = root.gridColor;
                        ctx.lineWidth = 1;
                        ctx.strokeRect(0, 0, width, height);
                    }
                }
                
                // Labels for color scale
                Text {
                    text: "High"
                    color: root.textColor
                    font.pixelSize: 10
                    anchors.bottom: colorLegend.top
                    anchors.horizontalCenter: colorLegend.horizontalCenter
                }
                
                Text {
                    text: "Low"
                    color: root.textColor
                    font.pixelSize: 10
                    anchors.top: colorLegend.bottom
                    anchors.horizontalCenter: colorLegend.horizontalCenter
                }
            }
            
            // Wavelet Type Label
            Rectangle {
                color: Qt.rgba(0, 0, 0, 0.5)
                radius: 5
                width: waveletTypeLabel.width + 20
                height: waveletTypeLabel.height + 10
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 10
                
                Text {
                    id: waveletTypeLabel
                    text: "Wavelet: " + root.waveletType
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    anchors.centerIn: parent
                }
            }
        }
    }
    
    // Method to draw the wavelet scalogram
    function drawWaveletScalogram(ctx) {
        errorMessage.visible = false;
        
        // Check if we have valid data
        if (!magnitudeData || magnitudeData.length === 0) {
            console.error("No magnitude data available");
            errorMessage.visible = true;
            return;
        }
        
        // Clear the canvas
        ctx.clearRect(0, 0, waveletCanvas.width, waveletCanvas.height);
        
        // Get dimensions
        var width = waveletCanvas.width;
        var height = waveletCanvas.height;
        
        try {
            // Debug the exact data structure 
            console.log("Wavelet data visualization - data type:", typeof magnitudeData);
            if (magnitudeData.length > 0) {
                console.log("First element type:", typeof magnitudeData[0]);
                if (typeof magnitudeData[0] === 'object') {
                    // Check if this is a special case where objects have numeric keys 0-99
                    if (Object.keys(magnitudeData[0]).every(key => !isNaN(parseInt(key)))) {
                        console.log("Special case: Array of objects with numeric keys");
                    }
                    
                    // Don't try to stringify potentially large arrays
                    console.log("First element keys:", Array.isArray(magnitudeData[0]) ? 
                               "Array of length " + magnitudeData[0].length : 
                               Object.keys(magnitudeData[0]));
                } else {
                    console.log("First element value:", magnitudeData[0]);
                }
            }
            
            // Check data structure - handle different array formats
            var is2DArray = Array.isArray(magnitudeData[0]);
            var isObjectWithNumericKeys = !is2DArray && typeof magnitudeData[0] === 'object' && 
                                         Object.keys(magnitudeData[0]).every(key => !isNaN(parseInt(key)));
            var numScales, numTimePoints;
            
            // Create a standard 2D array from the data regardless of its format
            var standardizedData = [];
            
            // Case 1: Standard 2D array
            if (is2DArray) {
                standardizedData = magnitudeData;
                numScales = magnitudeData.length;
                numTimePoints = magnitudeData[0].length;
                console.log("Processing as standard 2D array:", numScales, "x", numTimePoints);
            }
            // Case 2: Array of objects with numeric keys (special case we're seeing)
            else if (isObjectWithNumericKeys) {
                numScales = magnitudeData.length;
                // Determine the number of timepoints from the keys of the first object
                var keys = Object.keys(magnitudeData[0]);
                numTimePoints = keys.length;
                
                console.log("Processing as array of objects with numeric keys:", numScales, "x", numTimePoints);
                
                // Convert to standard 2D array
                for (var i = 0; i < numScales; i++) {
                    var row = [];
                    // Need to convert string keys to integers and sort
                    var sortedKeys = Object.keys(magnitudeData[i])
                        .map(key => parseInt(key))
                        .sort((a, b) => a - b);
                    
                    for (var j = 0; j < sortedKeys.length; j++) {
                        var key = sortedKeys[j];
                        row.push(magnitudeData[i][key]);
                    }
                    standardizedData.push(row);
                }
            }
            // Case 3: Try to reconstruct from flattened data
            else {
                if (timeDomain && timeDomain.length > 0 && scaleData && scaleData.length > 0) {
                    numScales = scaleData.length;
                    numTimePoints = Math.floor(magnitudeData.length / numScales);
                    
                    if (numTimePoints < 1) {
                        throw new Error("Invalid time points calculated: " + numTimePoints);
                    }
                    
                    // Convert flattened data to 2D array
                    for (var i = 0; i < numScales; i++) {
                        var row = [];
                        for (var j = 0; j < numTimePoints; j++) {
                            var index = i * numTimePoints + j;
                            if (index < magnitudeData.length) {
                                row.push(magnitudeData[index]);
                            } else {
                                row.push(0); // Fill with zeros if we run out of data
                            }
                        }
                        standardizedData.push(row);
                    }
                    
                    console.log("Reconstructed from flattened array:", numScales, "x", numTimePoints);
                } else {
                    // Create a simple visualization indicating data was received but can't be properly visualized
                    ctx.fillStyle = "#808080";
                    ctx.fillRect(0, 0, width, height);
                    
                    ctx.fillStyle = root.textColor;
                    ctx.font = "16px Arial";
                    ctx.textAlign = "center";
                    ctx.fillText("Wavelet data received but not in recognized format", width/2, height/2);
                    console.error("Cannot visualize wavelet data - not in expected format");
                    return;
                }
            }
            
            // Now draw the wavelet scalogram using the standardizedData
            // Find maximum magnitude value
            var maxMagnitude = 0;
            for (var i = 0; i < standardizedData.length; i++) {
                for (var j = 0; j < standardizedData[i].length; j++) {
                    if (isFinite(standardizedData[i][j])) {
                        maxMagnitude = Math.max(maxMagnitude, standardizedData[i][j]);
                    }
                }
            }
            
            // Scale factors for fitting data to canvas
            var scaleX = width / numTimePoints;
            var scaleY = height / numScales;
            
            // Draw the scalogram
            for (var y = 0; y < numScales; y++) {
                for (var x = 0; x < numTimePoints; x++) {
                    if (y < standardizedData.length && 
                        x < standardizedData[y].length && 
                        isFinite(standardizedData[y][x])) {
                        
                        // Normalize value between 0 and 1
                        var normalizedValue = standardizedData[y][x] / maxMagnitude;
                        
                        // Determine color based on normalized value
                        var color = getColorForValue(normalizedValue);
                        
                        // Draw a rectangle for this value (invert y to put lower scales at the bottom)
                        ctx.fillStyle = color;
                        ctx.fillRect(x * scaleX, (numScales - y - 1) * scaleY, scaleX + 1, scaleY + 1);
                    }
                }
            }
            
            // Draw scale markers
            ctx.fillStyle = root.textColor;
            ctx.font = "10px Arial";
            var scaleStep = Math.max(1, Math.floor(numScales / 5));
            for (var i = 0; i < numScales; i += scaleStep) {
                var yPos = (numScales - i - 1) * scaleY;
                if (scaleData && i < scaleData.length) {
                    var scaleValue = typeof scaleData[i] === 'number' ? 
                                    scaleData[i].toFixed(1) : i.toString();
                    ctx.fillText(scaleValue, -25, yPos + 4);
                } else {
                    ctx.fillText(i.toString(), -25, yPos + 4);
                }
            }
            
            // Draw time markers
            var timeStep = Math.max(1, Math.floor(numTimePoints / 8));
            for (var i = 0; i < numTimePoints; i += timeStep) {
                var xPos = i * scaleX;
                var timeValue;
                
                // Try to get real time value from timeDomain if possible
                if (timeDomain && timeDomain.length > 0 && i < timeDomain.length) {
                    timeValue = timeDomain[i].x.toFixed(1);
                } else {
                    // Default fallback
                    timeValue = (i / numTimePoints * 5).toFixed(1);
                }
                
                ctx.fillText(timeValue, xPos, height + 20);
            }
            
        } catch (error) {
            console.error("Error drawing wavelet scalogram:", error);
            errorMessage.visible = true;
            errorText.text = "Error: " + error.message;
            
            // Draw error message directly on canvas as well
            ctx.fillStyle = "#808080";
            ctx.fillRect(0, 0, width, height);
            
            ctx.fillStyle = root.textColor;
            ctx.font = "14px Arial";
            ctx.textAlign = "center";
            ctx.fillText("Error visualizing wavelet data: " + error.message, width/2, height/2);
        }
    }
    
    // Get color for a normalized value (0-1)
    function getColorForValue(normalizedValue) {
        // Ensure value is between 0 and 1
        normalizedValue = Math.max(0, Math.min(1, normalizedValue));
        
        // Map to gradient
        var position = normalizedValue * (colorGradient.length - 1);
        var index = Math.floor(position);
        var fraction = position - index;
        
        if (index >= colorGradient.length - 1) {
            return colorGradient[colorGradient.length - 1];
        }
        
        // Interpolate between two colors
        var color1 = colorGradient[index];
        var color2 = colorGradient[index + 1];
        
        return interpolateColor(color1, color2, fraction);
    }
    
    // Interpolate between two colors
    function interpolateColor(color1, color2, fraction) {
        try {
            // Validate color format - ensure colors are strings and properly formatted
            if (typeof color1 !== 'string' || typeof color2 !== 'string' || 
                !color1.startsWith('#') || !color2.startsWith('#')) {
                console.error("Invalid color format:", color1, color2);
                return "#FF00FF"; // Fallback to magenta for error indication
            }
            
            // Handle potential format issues by ensuring proper hex format
            color1 = ensureValidHexColor(color1);
            color2 = ensureValidHexColor(color2);
            
            // Extract RGB components
            var r1 = parseInt(color1.substr(1, 2), 16);
            var g1 = parseInt(color1.substr(3, 2), 16);
            var b1 = parseInt(color1.substr(5, 2), 16);
            
            var r2 = parseInt(color2.substr(1, 2), 16);
            var g2 = parseInt(color2.substr(3, 2), 16);
            var b2 = parseInt(color2.substr(5, 2), 16);
            
            // Interpolate
            var r = Math.round(r1 + (r2 - r1) * fraction);
            var g = Math.round(g1 + (g2 - g1) * fraction);
            var b = Math.round(b1 + (b2 - b1) * fraction);
            
            // Convert back to hex
            return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
        } catch (error) {
            console.error("Error in color interpolation:", error, "for colors", color1, color2);
            return "#FF00FF"; // Fallback to magenta to indicate error
        }
    }
    
    // Helper to ensure a valid hex color
    function ensureValidHexColor(color) {
        // Check if it's a valid hex color
        if (typeof color !== 'string') {
            return "#000000";
        }
        
        // If it doesn't start with #, add it
        if (!color.startsWith('#')) {
            color = '#' + color;
        }
        
        // Ensure it's the right length (either #RGB or #RRGGBB)
        if (color.length === 4) {
            // Convert #RGB to #RRGGBB
            var r = color.charAt(1);
            var g = color.charAt(2);
            var b = color.charAt(3);
            color = '#' + r + r + g + g + b + b;
        }
        
        // If it's still not valid, return black
        if (color.length !== 7) {
            return "#000000";
        }
        
        return color;
    }
    
    // Update the time domain chart
    function updateTimeDomainChart() {
        if (!timeDomain || timeDomain.length === 0) {
            return;
        }
        
        // Clear existing series
        timeSeries.clear();
        
        // Update axes ranges
        var minY = Number.MAX_VALUE;
        var maxY = -Number.MAX_VALUE;
        var maxX = 0;
        
        // Add points to series
        for (var i = 0; i < timeDomain.length; i++) {
            var point = timeDomain[i];
            if (point && isFinite(point.x) && isFinite(point.y)) {
                timeSeries.append(point.x, point.y);
                
                // Track min/max for axis scaling
                minY = Math.min(minY, point.y);
                maxY = Math.max(maxY, point.y);
                maxX = Math.max(maxX, point.x);
            }
        }
        
        // Update axes
        if (isFinite(minY) && isFinite(maxY) && minY !== Number.MAX_VALUE) {
            timeAxisX.min = 0;
            timeAxisX.max = maxX > 0 ? maxX : 5;
            
            // Ensure symmetric y-axis
            var yRange = Math.max(Math.abs(minY), Math.abs(maxY)) * 1.2;
            timeAxisY.min = -yRange || -2;
            timeAxisY.max = yRange || 2;
        }
    }
    
    // Update wavelet visualization
    function updateWaveletVisualization() {
        // Request a repaint of the canvas
        legendCanvas.requestPaint();
        waveletCanvas.requestPaint();
    }
    
    // Update colors based on theme
    function updateThemeColors() {
        if (darkMode) {
            backgroundColor = "#1e1e1e";
            textColor = "#e0e0e0";
            gridColor = "#303030";
        } else {
            backgroundColor = "#ffffff";
            textColor = "#333333";
            gridColor = "#cccccc";
        }
        
        // Request repaint of canvases
        waveletCanvas.requestPaint();
        legendCanvas.requestPaint();
    }
    
    // Force refresh method that can be called externally
    function refresh() {
        updateTimeDomainChart();
        updateWaveletVisualization();
    }
    
    // Component initialization
    Component.onCompleted: {
        Qt.callLater(function() {
            updateTimeDomainChart();
            updateWaveletVisualization();
        });
    }
}
