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
    // Remove any default margins that might cause double axes
    margins.top: 0
    margins.bottom: 0
    margins.left: 0
    margins.right: 0
    // Add this to avoid double axes
    axes: []

    property var scatterSeries: null
    property var marginLine: null
    property var relaySeries: []
    property var faultPointsSeries: []
    property var currentMarginValue: 0.3

    // Create a single set of axes for the chart
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
        // Extend the range to ensure all points are visible
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
        // Add these properties to improve appearance
        minorGridVisible: true
        minorTickCount: 9  // One minor tick between each major tick
    }

    // Set the axes explicitly for the chart
    Component.onCompleted: {
        // Set the axes for the chart
        setAxisX(axisX, null);
        setAxisY(axisY, null);
        
        // Create scatter series for margin points
        scatterSeries = createSeries(ChartView.SeriesTypeScatter, "Discrimination Margins", axisX, axisY);
        scatterSeries.markerSize = 10;
        scatterSeries.color = Universal.accent;
        
        // Create margin reference line
        marginLine = marginLineSeries;
        updateMarginLine();
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

    function updateMarginLine() {
        // Check if calculator is available
        if (!discriminationAnalyzerCard || !discriminationAnalyzerCard.calculator) {
            console.log("Calculator not available yet in updateMarginLine");
            return;
        }
        
        currentMarginValue = discriminationAnalyzerCard.calculator.minimumMargin;
        marginLine.visible = true;
        
        if (relaySeries.length > 0) {
            // Create a horizontal line at the current margin value
            marginLine.clear();
            
            // Get extreme points from the axes
            let xMin = axisX.min;
            let xMax = axisX.max;
            
            let count = 0;
            for(let i = 0; i < relaySeries.length; i++) {
                // Only consider relay series with points
                if (relaySeries[i] && relaySeries[i].count > 0) {
                    count++;
                }
            }
            
            if (count >= 2) {
                marginLine.append(xMin, currentMarginValue);
                marginLine.append(xMax, currentMarginValue);
            } else {
                marginLine.visible = false;
            }
        }
    }

    function createRelaySeries() {
        // Check if calculator is available
        if (!discriminationAnalyzerCard || !discriminationAnalyzerCard.calculator) {
            console.log("Calculator not available yet");
            return;
        }
        
        // Remove old series
        for (let i = 0; i < relaySeries.length; i++) {
            if (relaySeries[i]) {
                chart.removeSeries(relaySeries[i]);
            }
        }
        
        relaySeries = [];
        
        // Get relay list from calculator
        let relays = discriminationAnalyzerCard.calculator.relayList;
        
        // Create a new series for each relay with explicit axes
        for (let i = 0; i < relays.length; i++) {
            let relay = relays[i];
            let series = chart.createSeries(ChartView.SeriesTypeLine, relay.name, axisX, axisY);
            series.width = 2;
            
            // Generate curve points
            updateRelayCurve(series, relay);
            
            relaySeries.push(series);
        }
        
        updateMarginLine();
        adjustAxes();
    }
    
    function updateRelayCurve(series, relay) {
        series.clear();
        
        // Generate points for the curve
        let pickup = parseFloat(relay.pickup);
        if (!pickup || pickup <= 0) return;
        
        // Further expand the range of multiples to cover much higher currents
        // Start very close to 1.0 and go up to 10000x pickup
        let multiples = [];
        
        // Add points from 1.01 to 2.0 with fine steps
        for (let m = 1.01; m <= 2.0; m += 0.1) {
            multiples.push(m);
        }
        
        // Add points from 2.0 to 10.0 with medium steps
        for (let m = 2.0; m <= 10.0; m += 0.5) {
            multiples.push(m);
        }
        
        // Add points from 10 to 10000 with logarithmic steps
        for (let i = 1; i <= 4; i++) {
            let base = Math.pow(10, i);
            multiples.push(base);
            multiples.push(2 * base);
            multiples.push(5 * base);
        }
        
        let constants = relay.curve_constants;
        let tds = parseFloat(relay.tds);
        
        if (!constants || !tds) return;
        
        for (let i = 0; i < multiples.length; i++) {
            let current = pickup * multiples[i];
            
            // Calculate time using the standard formula
            let denominator = Math.pow(multiples[i], constants.b) - 1;
            if (denominator <= 0) continue;
            
            let time = (constants.a * tds) / denominator;
            
            // Only add valid points with an expanded range
            if (time > 0 && time < 100 && current > 0) {
                series.append(current, time);
            }
        }
        
        // Log the range of the curve
        if (series.count > 0) {
            let firstPoint = series.at(0);
            let lastPoint = series.at(series.count - 1);
            console.log(`Relay curve for ${relay.name}: ${firstPoint.x}A to ${lastPoint.x}A`);
        }
    }
    
    function adjustAxes() {
        // Find min/max values from all series
        let xMin = Number.MAX_VALUE;
        let xMax = Number.MIN_VALUE;
        let yMin = Number.MAX_VALUE;
        let yMax = Number.MIN_VALUE;
        
        // Process relay series
        for (let i = 0; i < relaySeries.length; i++) {
            if (!relaySeries[i] || relaySeries[i].count === 0) continue;
            
            for (let j = 0; j < relaySeries[i].count; j++) {
                let point = relaySeries[i].at(j);
                xMin = Math.min(xMin, point.x);
                xMax = Math.max(xMax, point.x);
                yMin = Math.min(yMin, point.y);
                yMax = Math.max(yMax, point.y);
            }
        }
        
        // Process scatter points for margins
        if (scatterSeries && scatterSeries.count > 0) {
            for (let i = 0; i < scatterSeries.count; i++) {
                let point = scatterSeries.at(i);
                xMin = Math.min(xMin, point.x);
                xMax = Math.max(xMax, point.x);
                yMin = Math.min(yMin, point.y);
                yMax = Math.max(yMax, point.y);
            }
        }
        
        // Process fault points
        for (let i = 0; i < faultPointsSeries.length; i++) {
            if (!faultPointsSeries[i] || faultPointsSeries[i].count === 0) continue;
            
            for (let j = 0; j < faultPointsSeries[i].count; j++) {
                let point = faultPointsSeries[i].at(j);
                xMin = Math.min(xMin, point.x);
                xMax = Math.max(xMax, point.x);
                yMin = Math.min(yMin, point.y);
                yMax = Math.max(yMax, point.y);
            }
        }
        
        // Set reasonable axis limits with more padding
        if (xMin < Number.MAX_VALUE && xMax > Number.MIN_VALUE) {
            axisX.min = Math.max(10, xMin * 0.5);  // More padding on lower end
            axisX.max = xMax * 2.0;  // More padding on upper end
        } else {
            // Default range if no valid points
            axisX.min = 10;
            axisX.max = 10000;
        }
        
        if (yMin < Number.MAX_VALUE && yMax > Number.MIN_VALUE) {
            axisY.min = Math.max(0.01, yMin * 0.5);  // More padding on lower end
            axisY.max = Math.min(100, yMax * 2.0);  // More padding on upper end
        } else {
            // Default range if no valid points
            axisY.min = 0.01;
            axisY.max = 10;
        }
        
        console.log(`Adjusted axis ranges: X(${axisX.min}-${axisX.max}), Y(${axisY.min}-${axisY.max})`);
    }
    
    function clearFaultPoints() {
        // Remove all existing fault point series
        for (let i = 0; i < faultPointsSeries.length; i++) {
            if (faultPointsSeries[i]) {
                chart.removeSeries(faultPointsSeries[i]);
            }
        }
        faultPointsSeries = [];
    }

    function addFaultPoints(relayIndex, faultCurrents) {
        console.log("Adding fault points for relay", relayIndex, "with currents:", 
                    JSON.stringify(faultCurrents), "Type:", typeof faultCurrents);
        
        if (relayIndex < 0 || relayIndex >= relaySeries.length) {
            console.log("Invalid relay index:", relayIndex);
            return null;
        }
        
        let series = relaySeries[relayIndex];
        if (!series) {
            console.log("Relay series not found");
            return null;
        }
        
        let relay = discriminationAnalyzerCard.calculator.relayList[relayIndex];
        if (!relay) {
            console.log("Relay data not found");
            return null;
        }
        
        // Handle different types of fault current inputs
        let currentsToUse = [];
        
        // Normal array
        if (Array.isArray(faultCurrents)) {
            currentsToUse = [...faultCurrents];
        } 
        // Single number
        else if (typeof faultCurrents === 'number') {
            currentsToUse = [faultCurrents];
        } 
        // QML ListModel or other object with length property
        else if (faultCurrents && typeof faultCurrents === 'object') {
            // Try to convert to array if it has length and indexing
            try {
                if ('length' in faultCurrents) {
                    for (let i = 0; i < faultCurrents.length; i++) {
                        if (faultCurrents[i] !== undefined) {
                            currentsToUse.push(faultCurrents[i]);
                        }
                    }
                } else {
                    // Try to extract values as a last resort
                    let values = Object.values(faultCurrents);
                    if (values.length > 0) {
                        currentsToUse = values;
                    }
                }
            } catch (e) {
                console.error("Error converting fault currents to array:", e);
            }
        }
        
        console.log("Converted currents:", currentsToUse);
        
        if (currentsToUse.length === 0) {
            console.log("No valid fault currents to plot");
            return null;
        }
        
        // Create a new scatter series with explicit axes
        let faultSeries = chart.createSeries(ChartView.SeriesTypeScatter, 
                                           "Fault Points - " + relay.name, 
                                           axisX, axisY);
        faultSeries.markerSize = 12;  // Larger markers for better visibility
        faultSeries.color = "red";
        faultSeries.borderColor = "white";  // Add border for better contrast
        faultSeries.borderWidth = 1;
        
        let added = false;
        
        // Process each fault current
        for (let i = 0; i < currentsToUse.length; i++) {
            let current = parseFloat(currentsToUse[i]);
            if (isNaN(current) || current <= 0) {
                console.log("Invalid current value:", currentsToUse[i]);
                continue;
            }
            
            let time = calculateTime(relay, current);
            console.log(`Calculating time for current ${current}A: ${time}s`);
            
            if (time && time > 0 && time < 100) {
                console.log("Adding fault point:", current, time);
                faultSeries.append(current, time);
                added = true;
            } else {
                console.log("Invalid time value:", time, "for current:", current);
            }
        }
        
        if (added) {
            faultPointsSeries.push(faultSeries);
            // Update axes after adding fault points to ensure they're visible
            adjustAxes();
            return faultSeries;
        } else {
            chart.removeSeries(faultSeries);
            return null;
        }
    }
    
    function calculateTime(relay, current) {
        try {
            let pickup = parseFloat(relay.pickup);
            if (!pickup || pickup <= 0) {
                return null;
            }
                
            let multiple = current / pickup;
            if (multiple <= 1.0) {
                return null;  // Current is below pickup threshold
            }
                
            let constants = relay.curve_constants;
            let tds = parseFloat(relay.tds);
            
            if (!constants || !tds) {
                return null;
            }
                
            // Calculation using the standard formula
            let denominator = (Math.pow(multiple, constants.b)) - 1;
            if (denominator <= 0) {
                return null;
            }
                
            let time = (constants.a * tds) / denominator;
            return time > 0 ? time : null;
        } catch (e) {
            console.error("Error calculating time:", e);
            return null;
        }
    }
    
    function clearAllSeries() {
        if (scatterSeries) {
            scatterSeries.clear();
        }
        
        for (let i = 0; i < relaySeries.length; i++) {
            if (relaySeries[i]) {
                chart.removeSeries(relaySeries[i]);
            }
        }
        
        relaySeries = [];
        
        // Also clear fault points
        clearFaultPoints();
    }
}