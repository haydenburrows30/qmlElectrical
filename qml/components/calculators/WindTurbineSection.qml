import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../buttons"
import "../popups"

Item {
    id: windTurbineSection
    
    // Properties passed from parent
    property var calculator
    property bool calculatorReady
    property real totalGeneratedPower
    property var safeValueFunction
    
    // Signal for when calculation is requested
    signal calculate()

    Popup {
        id: lVPopup
        x: Math.round((windTurbineSection.width - width) / 2)
        y: Math.round((windTurbineSection.height - height) / 2)

        contentItem: Gen400VPopup {}

        visible: windTurbineCard.open
        onClosed: {
            windTurbineCard.open = false
        }
    }
        
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
                    id: topLayout
                    Layout.alignment: Qt.AlignHCenter

                    WaveCard {
                        id: windTurbineCard
                        title: "Wind Turbine Parameters"
                        Layout.fillHeight: true
                        Layout.minimumWidth: 350
                        Layout.alignment: Qt.AlignTop

                        showSettings: true

                        GridLayout {
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
                                value: 3
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
                                value: 25
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

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.columnSpan: 2
                                Layout.margins: 10
                                height: 1
                                color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
                            }

                            ExportButton {
                                Layout.alignment: Qt.AlignRight
                                Layout.columnSpan: 2
                                defaultFileName: "wind_turbine_report.pdf"
                                onExport: function(fileUrl) {
                                    if (calculatorReady) {
                                        let genCurrent = (calculator.actualPower) / (Math.sqrt(3) * 400)
                                        
                                        calculator.exportWindTurbineReport(fileUrl)
                                    }
                                }
                            }
                        }
                    }
                    
                    WaveCard {
                        title: "Wind Turbine Output"
                        Layout.minimumHeight: 460
                        Layout.minimumWidth: 400
                        Layout.alignment: Qt.AlignTop
                        
                        GridLayout {
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
                                    color: sideBar.toggle1 ? "black":"#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }

                                hoverEnabled: true
                                ToolTip.visible: hovered
                                ToolTip.delay: 500

                                ToolTip.text: "self._swept_area = math.pi * self._blade_radius * self._blade_radius"
                            }

                            Label { text: "Theoretical Power (kW):" }
                            TextField {
                                id: theoreticalPowerText
                                readOnly: true
                                Layout.fillWidth: true
                                text: safeValue(calculator.theoreticalPower, 0).toFixed(2)
                                background: Rectangle {
                                    color: sideBar.toggle1 ? "black":"#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }

                                hoverEnabled: true
                                ToolTip.visible: hovered
                                ToolTip.delay: 500

                                ToolTip.text: "self._theoretical_power = 0.5 * self._air_density * self._swept_area * math.pow(self._wind_speed, 3)"
                            }

                            Label { text: "Actual Power Output (kW):" }
                            TextField {
                                id: actualPowerText
                                readOnly: true
                                Layout.fillWidth: true
                                text: calculatorReady ? safeValueFunction(calculator.actualPower, 0).toFixed(2) : "0.00"
                                background: Rectangle {
                                    color: sideBar.toggle1 ? "black":"#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }

                                hoverEnabled: true
                                ToolTip.visible: hovered
                                ToolTip.delay: 500

                                ToolTip.text: "self._actual_power = self._theoretical_power * self._power_coefficient * self._efficiency"
                            }
                            
                            Label { text: "Generator Rated Capacity (kVA):" }
                            TextField {
                                id: genCapacityText
                                readOnly: true
                                Layout.fillWidth: true
                                text: calculatorReady ? safeValueFunction(calculator.ratedCapacity, 0).toFixed(2) : "0.00"
                                background: Rectangle {
                                    color: sideBar.toggle1 ? "black":"#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }

                                hoverEnabled: true
                                ToolTip.visible: hovered
                                ToolTip.delay: 500

                                ToolTip.text: "self._rated_capacity =  self._actual_power * 1.2 / 1000"
                            }
                            
                            Label { text: "Generator Output Current (A):" }
                            TextField {
                                id: genCurrentText
                                readOnly: true
                                Layout.fillWidth: true
                                text: calculatorReady ? safeValueFunction(calculator.outputCurrent, 0).toFixed(2) : "0.00"
                                background: Rectangle {
                                    color: sideBar.toggle1 ? "black":"#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }

                                hoverEnabled: true
                                ToolTip.visible: hovered
                                ToolTip.delay: 500

                                ToolTip.text: "self._output_current =  (self._actual_power / 1000) / (math.sqrt(3) * 0.4)"
                            }
                            
                            Label { text: "Annual Energy Production (MWh/year):" }
                            TextField {
                                id: annualEnergyText
                                readOnly: true
                                Layout.fillWidth: true
                                text: calculatorReady ? safeValueFunction(calculator.annualEnergy, 0).toFixed(2) : "0.00"
                                background: Rectangle {
                                    color: sideBar.toggle1 ? "black":"#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.columnSpan: 2
                                Layout.margins: 10
                                height: 1
                                color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
                            }

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
                                onValueModified: updateAdvancedAEP()
                            }
                            
                            Label { text: "Weibull Shape Parameter:" }
                            SpinBox {
                                id: weibullKSpinBox
                                from: 15
                                to: 30
                                value: 20
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                                
                                property real realValue: value / 10
                                
                                textFromValue: function(value) {
                                    return (value / 10).toFixed(1);
                                }
                                
                                valueFromText: function(text) {
                                    return Math.round(parseFloat(text) * 10);
                                }
                                
                                onValueModified: updateAdvancedAEP()
                            }
                            
                            Label { text: "Estimated AEP (MWh/year):" }
                            TextField {
                                id: advancedAepText
                                readOnly: true
                                Layout.fillWidth: true
                                text: "0.00"
                                background: Rectangle {
                                    color: sideBar.toggle1 ? "black":"#e8f6ff"
                                    border.color: "#0078d7"
                                    radius: 2
                                }
                            }
                        }
                    }
                }

                WaveCard {
                    title: "Power Curve"
                    Layout.minimumHeight: 350
                    Layout.minimumWidth: topLayout.width
                    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                    
                    ChartView {
                        id: powerCurveChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.visible: true

                                                                                                
                        Button {
                            text: "Update Power Curve"
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 10
                            onClicked: {
                                calculate()
                                updatePowerCurve()
                            }
                        }
                        
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
            actualPowerText.text = safeValueFunction(calculator.actualPower, 0).toFixed(2)
            genCapacityText.text = (calculator.actualPower * 1.2).toFixed(2)
            
            // Calculate generator current at 400V
            var genCurrent = (calculator.actualPower * 1000) / (Math.sqrt(3) * 400)
            genCurrentText.text = safeValueFunction(genCurrent, 0).toFixed(2)
            
            annualEnergyText.text = safeValueFunction(calculator.annualEnergy, 0).toFixed(2)
        }
        
        // Add a timer specifically for the initial update of advanced AEP
        property Timer updateDisplayValuesTimer: Timer {
            interval: 500
            repeat: false
            onTriggered: {
                if (calculatorReady) {
                    updateAdvancedAEP();
                }
            }
        }
    }

    // Add a function to update the advanced AEP calculation
    function updateAdvancedAEP() {
        if (!calculatorReady) return;
        
        try {
            // Get values from the spinboxes
            var windSpeed = safeValue(avgWindSpeedSpinBox.value, 7);
            var weibullK = safeValue(weibullKSpinBox.value / 10, 2.0);
            
            // Call the Python method with both parameters
            var aep = calculator.estimateAEP(windSpeed, weibullK);
            advancedAepText.text = safeValue(aep, 0).toFixed(2);
        } catch (e) {
            console.error("Error calculating AEP:", e);
            advancedAepText.text = "Error";
        }
    }
    
    // Component state management
    Component.onCompleted: {
        // Initial update after a small delay to ensure calculator is ready
        updateTimer.updateDisplayValuesTimer.start();
    }
}