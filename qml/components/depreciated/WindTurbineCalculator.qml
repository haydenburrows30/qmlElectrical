import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../"
import "../../components"

import WindTurbine 1.0

Item {
    id: root
    anchors.fill: parent
    
    property WindTurbineCalculator calculator: WindTurbineCalculator {}

    property bool calculatorReady: calculator !== null

    function initializeInputs() {
        if (calculatorReady) {
            bladeRadiusSpinBox.value = calculator.bladeRadius
            windSpeedSpinBox.value = calculator.windSpeed
            airDensitySpinBox.value = Math.round(calculator.airDensity * 100)
            powerCoefficientSpinBox.value = Math.round(calculator.powerCoefficient * 100)
            cutInSpinBox.value = calculator.cutInSpeed
            cutOutSpinBox.value = calculator.cutOutSpeed
            efficiencySpinBox.value = Math.round(calculator.efficiency * 100)
        }
    }

    function safeValue(value, defaultVal) {
        if (value === undefined || value === null) {
            return defaultVal;
        }
        
        if (typeof value !== 'number' || isNaN(value) || !isFinite(value)) {
            return defaultVal;
        }
        
        return value;
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: Style.spacing

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Wind Turbine Power Calculator"
            font.pixelSize: 24
            font.bold: true
            color: "#2c3e50"
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Calculate power output and performance of wind turbines"
            font.pixelSize: 16
            color: "#7f8c8d"
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ColumnLayout {
                width: parent.width
                spacing: Style.spacing

                // Input parameters section
                GroupBox {
                    title: "Input Parameters"
                    Layout.fillWidth: true
                    
                    GridLayout {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 10
                        Layout.fillWidth: true
                        
                        Label { text: "Blade Radius (m):" }
                        SpinBox {
                            id: bladeRadiusSpinBox
                            from: 1
                            to: 100
                            value: 25
                            stepSize: 1
                            editable: true
                            Layout.fillWidth: true
                            onValueModified: if (calculatorReady) calculator.setBladeRadius(value)
                        }
                        
                        Label { text: "Wind Speed (m/s):" }
                        SpinBox {
                            id: windSpeedSpinBox
                            from: 1
                            to: 30
                            value: 8  
                            stepSize: 1
                            editable: true
                            Layout.fillWidth: true
                            onValueModified: if (calculatorReady) calculator.setWindSpeed(value)
                        }
                        
                        Label { text: "Air Density (kg/m³):" }
                        SpinBox {
                            id: airDensitySpinBox
                            from: 100
                            to: 150
                            value: 122   (1.22 kg/m³)
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
                        
                        Label { text: "Power Coefficient (Cp):" }
                        SpinBox {
                            id: powerCoefficientSpinBox
                            from: 0
                            to: 60
                            value: 40   (0.40)
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
                            
                            onValueModified: if (calculatorReady) calculator.setPowerCoefficient(realValue)
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
                        
                        Label { text: "Generator Efficiency (%):" }
                        SpinBox {
                            id: efficiencySpinBox
                            from: 50
                            to: 100
                            value: 90   (90%)
                            stepSize: 1
                            editable: true
                            Layout.fillWidth: true
                            onValueModified: if (calculatorReady) calculator.setEfficiency(value / 100)
                        }
                    }
                }
                
                // Results section
                GroupBox {
                    title: "Calculated Results"
                    Layout.fillWidth: true
                    
                    GridLayout {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 10
                        Layout.fillWidth: true
                        
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
                            text: safeValue(calculator.actualPower, 0).toFixed(2)
                            background: Rectangle {
                                color: "#e8f6ff"
                                border.color: "#0078d7"
                                radius: 2
                            }
                        }
                        
                        Label { text: "Estimated Annual Energy (MWh/year):" }
                        TextField {
                            id: annualEnergyText
                            readOnly: true
                            Layout.fillWidth: true
                            text: safeValue(calculator.annualEnergy, 0).toFixed(2)
                            background: Rectangle {
                                color: "#e8f6ff"
                                border.color: "#0078d7"
                                radius: 2
                            }
                        }
                        
                        Button {
                            text: "Calculate"
                            Layout.columnSpan: 2
                            Layout.alignment: Qt.AlignHCenter
                            onClicked: calculator.refreshCalculations()
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
                
                // Power curve chart
                GroupBox {
                    title: "Power Curve"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    
                    ChartView {
                        id: powerCurveChart
                        anchors.fill: parent
                        antialiasing: true
                        legend.visible: true
                        
                        ValueAxis {
                            id: axisX
                            min: 0
                            max: safeValue(calculator.cutOutSpeed, 25) + 5
                            titleText: "Wind Speed (m/s)"
                        }
                        
                        ValueAxis {
                            id: axisY
                            min: 0
                            max: 10
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
                
                // Information section
                GroupBox {
                    title: "Information"
                    Layout.fillWidth: true
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: Style.spacing
                        
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
        }
    }

    Connections {
        target: calculator
        
        function onCalculationCompleted() {
            sweptAreaText.text = safeValue(calculator.sweptArea, 0).toFixed(2)
            theoreticalPowerText.text = safeValue(calculator.theoreticalPower, 0).toFixed(2)
            actualPowerText.text = safeValue(calculator.actualPower, 0).toFixed(2)
            powerKWText.text = safeValue(calculator.actualPower, 0).toFixed(2)
            annualEnergyText.text = safeValue(calculator.annualEnergy, 0).toFixed(2)
        }
        
        function onPowerCurveChanged() {
            updatePowerCurve()
        }
    }

    function updatePowerCurve() {
        console.log("Updating power curve...")

        powerSeries.clear()

        if (!calculatorReady) {
            console.error("Calculator instance not ready")
            return
        }
        
        try {
            var powerCurveData = calculator.powerCurve || []

            var maxPower = 0.1
            var totalPower = 0
            var nonZeroPoints = 0

            for (var i = 0; i < powerCurveData.length; i++) {
                var point = powerCurveData[i]

                var x, y;
                if (typeof point === 'object') {
                    if ('x' in point && 'y' in point) {
                        x = safeValue(point.x, 0)
                        y = safeValue(point.y, 0)
                    } else if (Array.isArray(point) && point.length >= 2) {
                        x = safeValue(point[0], 0)
                        y = safeValue(point[1], 0)
                    } else {
                        continue
                    }
                } else {
                    continue
                }

                powerSeries.append(x, y)
                
                if (y > 0) {
                    nonZeroPoints++
                    totalPower += y
                }
                
                if (y > maxPower) {
                    maxPower = y
                }
            }

            var avgPower = nonZeroPoints > 0 ? totalPower / nonZeroPoints : 0

            var yAxisMax;
            if (maxPower < 1) {
                yAxisMax = 1;
            } else if (maxPower < 10) {
                yAxisMax = Math.ceil(maxPower * 1.5);
            } else {
                yAxisMax = Math.ceil(maxPower * 1.2);
            }

            if (maxPower > 50) {
                yAxisMax = Math.max(yAxisMax, 100);
            }

            axisY.max = yAxisMax;

            axisX.max = Math.max(calculator.cutOutSpeed + 5, 30);

            powerCurveChart.update()
        } catch (e) {
            console.error("Error updating power curve:", e)
            console.error("Error stack:", e.stack)
        }
    }

    Component.onCompleted: {
        initTimer.start()
    }

    Timer {
        id: initTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (calculatorReady) {
                console.log("Calculator instance is available, initializing")
                initializeInputs()

                calculator.refreshCalculations()

                updateTimer.start()
            } else {
                console.error("Calculator instance is not available - check main.py registration")
            }
        }
    }

    Timer {
        id: updateTimer
        interval: 200
        repeat: false
        onTriggered: {
            updatePowerCurve()
        }
    }
}
