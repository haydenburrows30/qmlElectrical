import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import Qt.labs.platform

Rectangle {
    id: wavelet3DPlot
    width: parent.width
    height: parent.height * 0.45
    visible: show3D && transformType === "Wavelet"

    property var threeDcanvas: wavelet3DCanvas
    // color: root.backgroundColor
    // border.color: root.gridColor
    // border.width: 1
    // radius: 5

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
                        // Find the length
                        let maxIndex = Math.max(...keys.map(k => parseInt(k)));
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

                    // Check what data types are in the converted array
                    let sampleType = typeof actualData[0];
                    
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
                        }
                    } else {
                        // Truly unknown data type - use empty grid
                        processedData = new Array(numScales);
                        for (let i = 0; i < numScales; i++) {
                            processedData[i] = new Array(20).fill(0);
                        }
                    }
                }
                
                // If maxValue is too small or zero, use a default value for visualization
                if (maxValue < 0.001) {
                    maxValue = 1.0;
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