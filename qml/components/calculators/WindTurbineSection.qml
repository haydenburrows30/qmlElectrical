import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"  // Import for WaveCard component

Item {
    id: windTurbineSection
    
    // Properties passed from parent
    property var calculator
    property bool calculatorReady
    property real totalGeneratedPower
    property var safeValueFunction
    
    // Signal for when calculation is requested
    signal calculate()
        
    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height + 40
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            ColumnLayout {
                id: mainLayout
                width: scrollView.width

                RowLayout {
                    WaveCard {
                        title: "Wind Turbine Parameters"
                        // Layout.fillWidth: true
                        Layout.preferredHeight: 550
                        Layout.minimumWidth: 350
                        Layout.alignment: Qt.AlignTop
                        
                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 10
                            
                            Label { text: "Blade Radius (m):" }
                            SpinBox {
                                id: bladeRadiusSpinBox
                                from: 1
                                to: 100
                                value: calculatorReady ? calculator.bladeRadius : 40
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: {
                                    if (calculatorReady) {
                                        calculator.setBladeRadius(value)
                                    }
                                }
                            }
                            
                            Label { text: "Wind Speed (m/s):" }
                            SpinBox {
                                id: windSpeedSpinBox
                                from: 1
                                to: 30
                                value: calculatorReady ? calculator.windSpeed : 8
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: {
                                    if (calculatorReady) {
                                        calculator.setWindSpeed(value)
                                    }
                                }
                            }

                            Label { text: "Air Density (kg/m³):" }
                            SpinBox {
                                id: airDensitySpinBox
                                from: 100
                                to: 150
                                value: 122  // Set a default value (1.22 kg/m³)
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                
                                property real realValue: value / 100
                                
                                textFromValue: function(value) {
                                    return (value / 100).toFixed(2);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 100);
                                }
                                
                                onValueModified: if (calculatorReady) calculator.setAirDensity(realValue)
                            }

                            Label { text: "Cut-in Wind Speed (m/s):" }
                            SpinBox {
                                id: cutInSpinBox
                                from: 1
                                to: 10
                                value: 3  // Set a default value
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: if (calculatorReady) calculator.setCutInSpeed(value)
                            }
                            
                            Label { text: "Cut-out Wind Speed (m/s):" }
                            SpinBox {
                                id: cutOutSpinBox
                                from: 15
                                to: 35
                                value: 25  // Set a default value
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: if (calculatorReady) calculator.setCutOutSpeed(value)
                            }
                            
                            Label { text: "Power Coefficient (Cp):" }
                            SpinBox {
                                id: powerCoefficientSpinBox
                                from: 0
                                to: 60
                                value: calculatorReady ? calculator.powerCoefficient * 100 : 40
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                property real realValue: value / 100
                                
                                textFromValue: function(value) {
                                    return (value / 100).toFixed(2);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 100);
                                }
                                
                                onValueModified: {
                                    if (calculatorReady) {
                                        calculator.setPowerCoefficient(realValue)
                                    }
                                }
                            }
                            
                            Label { text: "Generator Efficiency (%):" }
                            SpinBox {
                                id: efficiencySpinBox
                                from: 50
                                to: 100
                                value: calculatorReady ? calculator.efficiency * 100 : 90
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                onValueModified: {
                                    if (calculatorReady) {
                                        calculator.setEfficiency(value / 100)
                                    }
                                }
                            }
                        }
                    }
                    
                    WaveCard {
                        title: "Wind Turbine Output"
                        // Layout.fillWidth: true
                        Layout.preferredHeight: 550
                        Layout.minimumWidth: 500
                        Layout.alignment: Qt.AlignTop
                        
                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 10

                            Label { text: "Swept Area (m²):" }
                            TextField {
                                id: sweptAreaText
                                readOnly: true
                                Layout.fillWidth: true
                                text: safeValue(calculator.sweptArea, 0).toFixed(2)
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }

                            Label { text: "Theoretical Power (W):" }
                            TextField {
                                id: theoreticalPowerText
                                readOnly: true
                                Layout.fillWidth: true
                                text: safeValue(calculator.theoreticalPower, 0).toFixed(2)
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }

                            Label { text: "Actual Power Output (W):" }
                            TextField {
                                id: actualPowerText
                                readOnly: true
                                Layout.fillWidth: true
                                text: safeValue(calculator.actualPower, 0).toFixed(2)
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }
                            
                            Label { text: "Power Output (kW):" }
                            TextField {
                                id: powerKWText
                                readOnly: true
                                Layout.fillWidth: true
                                text: calculatorReady ? safeValueFunction(calculator.powerInKW, 0).toFixed(2) : "0.00"
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }
                            
                            Label { text: "Generator Rated Capacity (kVA):" }
                            TextField {
                                id: genCapacityText
                                readOnly: true
                                Layout.fillWidth: true
                                text: (totalGeneratedPower * 1.2).toFixed(2)
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }
                            
                            Label { text: "Generator Output Current (A):" }
                            TextField {
                                id: genCurrentText
                                readOnly: true
                                Layout.fillWidth: true
                                // I = S/(√3 × V) for three-phase systems
                                text: totalGeneratedPower > 0 
                                    ? ((totalGeneratedPower * 1000) / (Math.sqrt(3) * 400)).toFixed(2)
                                    : "0.00"
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }
                            
                            Label { text: "Annual Energy Production (MWh/year):" }
                            TextField {
                                id: annualEnergyText
                                readOnly: true
                                Layout.fillWidth: true
                                text: calculatorReady ? safeValueFunction(calculator.annualEnergy, 0).toFixed(2) : "0.00"
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }
                            
                            Button {
                                text: "Update Power Curve"
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignHCenter
                                onClicked: {
                                    calculate()
                                    updatePowerCurve()
                                }
                            }

                            // Add advanced analysis section
                            Label { 
                                text: "Advanced Analysis:"
                                Layout.columnSpan: 2
                                font.bold: true
                            }
                            
                            Label { text: "Average Wind Speed (m/s):" }
                            SpinBox {
                                id: avgWindSpeedSpinBox
                                from: 1
                                to: 20
                                value: 7
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                            }
                            
                            Label { text: "Estimated AEP (MWh/year):" }
                            TextField {
                                id: advancedAepText
                                readOnly: true
                                Layout.fillWidth: true
                                text: "0.00"
                                background: Rectangle {
                                    color: "#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }
                            
                            Button {
                                text: "Run Advanced Analysis"
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignHCenter
                                onClicked: {
                                    try {
                                        // Safely call the estimateAEP function with proper arguments
                                        var windSpeed = safeValue(avgWindSpeedSpinBox.value, 7);
                                        var weibullK = 2.0; // Default Weibull shape parameter
                                        
                                        // Make sure both required arguments are provided
                                        var aep = calculator.estimateAEP(windSpeed, weibullK);
                                        advancedAepText.text = safeValue(aep, 0).toFixed(2);
                                    } catch (e) {
                                        console.error("Error calculating AEP:", e);
                                        advancedAepText.text = "Error";
                                    }
                                }
                            }
                        }
                    }
                    
                    WaveCard {
                        title: "Wind Turbine Generator Protection Requirements"
                        Layout.alignment: Qt.AlignTop
                        Layout.minimumHeight: 550
                        Layout.minimumWidth: 500
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            
                            Text {
                                text: "<b>400V Generator Protection Requirements:</b><br>" +
                                    "• Over/Under Voltage Protection (27/59)<br>" +
                                    "• Over/Under Frequency Protection (81O/81U)<br>" +
                                    "• Overcurrent Protection (50/51)<br>" +
                                    "• Earth Fault Protection (50N/51N)<br>" +
                                    "• Reverse Power Protection (32)<br>" +
                                    "• Loss of Excitation Protection (40)<br>" +
                                    "• Stator Earth Fault Protection<br>" +
                                    "• Anti-Islanding Protection"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "<b>Wind Turbine Power Formula:</b><br>" +
                                    "P = ½ × ρ × A × Cp × v³ × η<br>" +
                                    "Where:<br>" +
                                    "P = Power output (W)<br>" +
                                    "ρ = Air density (kg/m³)<br>" +
                                    "A = Swept area (m²) = π × r²<br>" +
                                    "Cp = Power coefficient<br>" +
                                    "v = Wind speed (m/s)<br>" +
                                    "η = Generator efficiency"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            
                            Text {
                                text: "<b>Notes:</b><br>" +
                                    "• The Betz limit sets the maximum theoretical Cp at 0.593<br>" +
                                    "• Air density varies with altitude and temperature<br>" +
                                    "• Modern large wind turbines typically operate with power coefficient around 0.35-0.45<br>" +
                                    "• The cut-in speed is when the turbine starts generating power<br>" +
                                    "• The cut-out speed is when the turbine shuts down to prevent damage"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                RowLayout {

                    // Power curve chart
                    WaveCard {
                        title: "Power Curve"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 350
                        Layout.minimumWidth:700
                        Layout.alignment: Qt.AlignTop
                        
                        ChartView {
                            id: powerCurveChart
                            anchors.fill: parent
                            antialiasing: true
                            legend.visible: true
                            
                            ValueAxis {
                                id: axisX
                                min: 0
                                max: safeValue(calculator.cutOutSpeed, 25) + 5  // Use safeValue to prevent NaN
                                titleText: "Wind Speed (m/s)"
                            }
                            
                            ValueAxis {
                                id: axisY
                                min: 0
                                max: 10  // Will be updated dynamically
                                titleText: "Power Output (kW)"
                            }
                            
                            LineSeries {
                                id: powerSeries
                                name: "Power Output"
                                axisX: axisX
                                axisY: axisY
                            }
                        }
                    }

                }
            }
        }
    }

    function updatePowerCurve() {
        
        // Clear existing data
        powerSeries.clear()
        
        // Safety check for calculator and data
        if (!calculatorReady) {
            console.error("Calculator instance not ready")
            return
        }
        
        try {
            // Get power curve data from backend with null check
            var powerCurveData = calculator.powerCurve || []
            
            // Additional debugging for received data points
            if (powerCurveData.length > 0) {
            }
            
            // Find maximum power for Y axis scaling
            var maxPower = 0.1 // Minimum default
            var totalPower = 0
            var nonZeroPoints = 0
            
            // Add all points to the series and calculate stats
            for (var i = 0; i < powerCurveData.length; i++) {
                var point = powerCurveData[i]
                
                // Support both array format and dictionary format
                var x, y;
                if (typeof point === 'object') {
                    if ('x' in point && 'y' in point) {
                        // Dictionary format with named keys
                        x = safeValue(point.x, 0)
                        y = safeValue(point.y, 0)
                    } else if (Array.isArray(point) && point.length >= 2) {
                        // Array format [x, y]
                        x = safeValue(point[0], 0)
                        y = safeValue(point[1], 0)
                    } else {
                        // Skip invalid points
                        continue
                    }
                } else {
                    // Skip non-object points
                    continue
                }
                
                // Debug more individual points to see what's being processed
                if (i % 10 === 0 || y > maxPower) {
                }
                
                // Add point to chart
                powerSeries.append(x, y)
                
                if (y > 0) {
                    nonZeroPoints++
                    totalPower += y
                }
                
                if (y > maxPower) {
                    maxPower = y
                }
            }

            // Calculate average power (excluding zero points)
            var avgPower = nonZeroPoints > 0 ? totalPower / nonZeroPoints : 0

            // Ensure a reasonable Y-axis max based on actual data
            var yAxisMax;
            if (maxPower < 1) {
                yAxisMax = 1; // Minimum 1 kW
            } else if (maxPower < 10) {
                yAxisMax = Math.ceil(maxPower * 1.5); // Add 50% margin for small values
            } else {
                yAxisMax = Math.ceil(maxPower * 1.2); // Add 20% margin for larger values
            }
            
            // Force minimum of 100 kW if maxPower is high
            if (maxPower > 50) {
                yAxisMax = Math.max(yAxisMax, 100);
            }
            
            // Update axes
            axisY.max = yAxisMax;
            
            // Also dynamically adjust the X-axis
            axisX.max = Math.max(calculator.cutOutSpeed + 5, 30);
            
            // Force chart update
            powerCurveChart.update()
        } catch (e) {
            console.error("Error updating power curve:", e)
            console.error("Error stack:", e.stack)
        }
    }
    
    Timer {
        id: updateTimer
        interval: 250
        repeat: true
        running: calculatorReady
        onTriggered: {
            if(calculatorReady) {
                updateDisplayValues()
            }
        }
        
        function updateDisplayValues() {
            powerKWText.text = safeValueFunction(calculator.powerInKW, 0).toFixed(2)
            genCapacityText.text = (calculator.powerInKW * 1.2).toFixed(2)
            
            // Calculate generator current at 400V
            var genCurrent = (calculator.powerInKW * 1000) / (Math.sqrt(3) * 400)
            genCurrentText.text = safeValueFunction(genCurrent, 0).toFixed(2)
            
            annualEnergyText.text = safeValueFunction(calculator.annualEnergy, 0).toFixed(2)
        }
    }
}