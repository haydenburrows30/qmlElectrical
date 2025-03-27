import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import QtQuick.Controls.Universal

import "../"
import "../buttons"
import "../popups"
import "../backgrounds"

Item {
    id: windTurbineSection

    property var calculator
    property bool calculatorReady
    property real totalGeneratedPower
    property var safeValueFunction

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
    
    WindPopup {
        id: v27StatsPopup
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
                                value: 122
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
                            
                            RowLayout {
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignCenter
                                
                                Button {
                                    text: "Vestas V27"
                                    Layout.fillWidth: true
                                    onClicked: {
                                        if (calculatorReady) {
                                            calculator.loadVestasV27Parameters()
                                            bladeRadiusSpinBox.value = calculator.bladeRadius
                                            cutInSpinBox.value = calculator.cutInSpeed
                                            cutOutSpinBox.value = calculator.cutOutSpeed
                                            powerCoefficientSpinBox.value = calculator.powerCoefficient * 100
                                            efficiencySpinBox.value = calculator.efficiency * 100
                                            updatePowerCurve()
                                        }
                                    }
                                    
                                    background: Rectangle {
                                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                                        radius: 2
                                    }
                                }
                                
                                Button {
                                    text: "V27 Info"
                                    Layout.preferredWidth: 100
                                    onClicked: v27StatsPopup.open()
                                    
                                    background: Rectangle {
                                        color: sideBar.toggle1 ? "#404040" : "#d0e8ff"
                                        radius: 2
                                    }
                                }
                                
                                Button {
                                    text: "Reset"
                                    Layout.fillWidth: true
                                    onClicked: {
                                        if (calculatorReady) {
                                            calculator.resetToGenericTurbine()
                                            bladeRadiusSpinBox.value = calculator.bladeRadius
                                            cutInSpinBox.value = calculator.cutInSpeed
                                            cutOutSpinBox.value = calculator.cutOutSpeed
                                            powerCoefficientSpinBox.value = calculator.powerCoefficient * 100
                                            efficiencySpinBox.value = calculator.efficiency * 100
                                            updatePowerCurve()
                                        }
                                    }
                                    
                                    background: Rectangle {
                                        color: sideBar.toggle1 ? "black":"#e8f6ff"
                                        radius: 2
                                    }
                                }
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
                                background: ProtectionRectangle {}

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
                                background: ProtectionRectangle {}

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
                                background: ProtectionRectangle {}

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
                                background: ProtectionRectangle {}

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
                                background: ProtectionRectangle {}

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
                                background: ProtectionRectangle {}
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
                                background: ProtectionRectangle {}
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

                            background: Rectangle {
                                color: sideBar.toggle1 ? "black":"#e8f6ff"
                                radius: 2
                            }
                        }
                        
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
            }
        }
    }

    function updatePowerCurve() {

        powerSeries.clear()

        if (!calculatorReady) {
            console.error("Calculator instance not ready")
            return
        }
        
        try {
            var powerCurveData = calculator.powerCurve || []

            if (powerCurveData.length > 0) {
            }

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

                if (i % 10 === 0 || y > maxPower) {
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

            var genCurrent = (calculator.actualPower * 1000) / (Math.sqrt(3) * 400)
            genCurrentText.text = safeValueFunction(genCurrent, 0).toFixed(2)
            
            annualEnergyText.text = safeValueFunction(calculator.annualEnergy, 0).toFixed(2)
        }

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

    function updateAdvancedAEP() {
        if (!calculatorReady) return;
        
        try {
            var windSpeed = safeValue(avgWindSpeedSpinBox.value, 7);
            var weibullK = safeValue(weibullKSpinBox.value / 10, 2.0);
            
            var aep = calculator.estimateAEP(windSpeed, weibullK);
            advancedAepText.text = safeValue(aep, 0).toFixed(2);
        } catch (e) {
            console.error("Error calculating AEP:", e);
            advancedAepText.text = "Error";
        }
    }

    Component.onCompleted: {
        updateTimer.updateDisplayValuesTimer.start();
    }
}