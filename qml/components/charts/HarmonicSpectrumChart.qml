import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

ChartView {
    id: harmonicChart
    antialiasing: false  // Disable antialiasing for better performance
    legend.visible: true
    legend.alignment: Qt.AlignBottom
    theme: Universal.theme
    
    property var calculator
    property bool showPhaseAngles: false
    
    // Function to update the harmonic spectrum visualization
    function updateHarmonics() {
        var data = calculator.individualDistortion;
        var phaseData = calculator.harmonicPhases;
        var maxY = 0;
        
        harmonicSeries.clear();
        phaseAngleSeries.clear();
        
        // Find maximum magnitude for scaling with validation
        if (data && data.length > 0) {
            for (var i = 0; i < data.length; i++) {
                if (isFinite(data[i])) {
                    maxY = Math.max(maxY, data[i]);
                }
            }
        }
        
        // Ensure maxY is valid
        if (!isFinite(maxY) || maxY <= 0) {
            maxY = 100;  // Default to 100% if invalid
        }
        
        // Set axis range with 20% padding and validation
        var paddedMax = Math.ceil(maxY * 1.2);
        spectrumAxisY.max = isFinite(paddedMax) ? paddedMax : 120;
        
        // Update bar series with validation
        if (data && data.length > 0) {
            // Make a filtered copy of the data with only valid values
            var validData = [];
            for (var i = 0; i < data.length; i++) {
                validData.push(isFinite(data[i]) ? data[i] : 0);
            }
            harmonicSeries.append("Magnitude", validData);
        }
        
        // Update phase series with validation
        if (phaseData && phaseData.length > 0) {
            var harmOrder = [1, 3, 5, 7, 11, 13];
            
            for (var i = 0; i < harmOrder.length && i < phaseData.length; i++) {
                // Only add valid phase values
                if (isFinite(phaseData[i])) {
                    phaseAngleSeries.append(i + 0.5, phaseData[i]);
                } else {
                    phaseAngleSeries.append(i + 0.5, 0);  // Use 0 for invalid values
                }
            }
        }
    }
    
    // Initialize with default values
    Component.onCompleted: {
        updateHarmonics();
    }

    ValueAxis {
        id: spectrumAxisY
        min: 0
        max: 120  // Allow for harmonics up to 120% of fundamental
        titleText: "Magnitude (%)"
        gridVisible: true
    }

    BarCategoryAxis {
        id: spectrumAxisX
        categories: ["1st", "3rd", "5th", "7th", "11th", "13th"]
        titleText: "Harmonic Order"
        gridVisible: true
    }

    BarSeries {
        id: harmonicSeries
        axisX: spectrumAxisX
        axisY: spectrumAxisY
        name: "Magnitude (%)"
    }
    
    LineSeries {
        id: phaseAngleSeries
        name: "Phase Angle (°)"
        axisX: spectrumAxisX
        
        ValueAxis {
            id: phaseAxisY
            min: -180
            max: 180
            titleText: "Phase (degrees)"
            visible: harmonicChart.showPhaseAngles
            gridVisible: false
        }
        
        axisY: phaseAxisY
        visible: harmonicChart.showPhaseAngles
        color: "red"
        width: 2
        pointsVisible: false  // Disable point rendering for better performance
    }
    
    // Connect to calculator signals
    Connections {
        target: calculator
        function onHarmonicsChanged() {
            updateHarmonics();
        }
        
        function onCalculationsComplete() {
            updateHarmonics();
        }
    }
}
