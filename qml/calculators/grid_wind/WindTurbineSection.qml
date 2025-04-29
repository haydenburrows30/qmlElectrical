import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import QtQuick.Controls.Universal
import QtQuick.Dialogs

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"

Item {
    id: windTurbineSection

    property var calculator
    property bool calculatorReady
    property var safeValueFunction
    property string applicationDirPath: Qt.application.directoryPath || "."

    property bool saveSuccess: false
    
    property bool isUpdatingValues: false
    property bool isUpdatingAEP: false

    signal calculate()

    PopUpText {
        id: lVPopup
        parentCard: infoButton
        widthFactor: 0.5
        heightFactor: 0.7
        popupText: "<b>400V Generator Protection Requirements:</b><br>" +
                "• Over/Under Voltage Protection (27/59)<br>" +
                "• Over/Under Frequency Protection (81O/81U)<br>" +
                "• Overcurrent Protection (50/51)<br>" +
                "• Earth Fault Protection (50N/51N)<br>" +
                "• Reverse Power Protection (32)<br>" +
                "• Loss of Excitation Protection (40)<br>" +
                "• Stator Earth Fault Protection<br>" +
                "• Anti-Islanding Protection<br><br>" +
                "<b>Wind Turbine Power Formula:</b><br>" +
                "P = ½ × ρ × A × Cp × v³ × η<br>" +
                "Where:<br>" +
                "P = Power output (W)<br>" +
                "ρ = Air density (kg/m³)<br>" +
                "A = Swept area (m²) = π × r²<br>" +
                "Cp = Power coefficient<br>" +
                "v = Wind speed (m/s)<br>" +
                "η = Generator efficiency<br><br>" +
                "<b>Notes:</b><br>" +
                "• The Betz limit sets the maximum theoretical Cp at 0.593<br>" +
                "• Air density varies with altitude and temperature<br>" +
                "• Modern large wind turbines typically operate with power coefficient around 0.35-0.45<br>" +
                "• The cut-in speed is when the turbine starts generating power<br>" +
                "• The cut-out speed is when the turbine shuts down to prevent damage"
    }

    WindPopup {
        id: v27StatsPopup
    }

    MessagePopup {
        id: messagePopup
        anchors.centerIn: parent

        // Custom property to manage visibility
        property bool autoOpen: false
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
                    Layout.minimumHeight: 60
                    Layout.maximumWidth: topLayout.width
                    Layout.alignment: Qt.AlignHCenter

                    Label {
                            text: "Wind Turbine"
                            font.pixelSize: 20
                            font.bold: true
                    }

                    Label {Layout.fillWidth: true}

                    StyledButton {
                        ToolTip.text: "Export report to PDF"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500

                        Layout.alignment: Qt.AlignRight
                        icon.source: "../../../icons/rounded/download.svg"

                        onClicked: {
                            if (calculatorReady) {
                                // Create a temporary file path for the chart image
                                var tempImagePath = applicationDirPath + (Qt.platform.os === "windows" ? "\\temp_wind_chart.png" : "/temp_wind_chart.png")
                                
                                // Capture the chart image and save it to the temporary file
                                powerCurveChart.grabToImage(function(result) {
                                    if (result) {
                                        result.saveToFile(tempImagePath)
                                        
                                        // Export the PDF with the saved image path
                                        calculator.exportWindTurbineReport(tempImagePath)
                                    } else {
                                        // Export without image if grabToImage fails
                                        calculator.exportWindTurbineReport("")
                                    }
                                })
                            }
                        }
                    }

                    StyledButton {
                        ToolTip.text: "Reset to default values"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500

                        Layout.alignment: Qt.AlignRight
                        icon.source: "../../../icons/rounded/restart_alt.svg"

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
                    }

                    StyledButton {
                        id: infoButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Information"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                    
                        onClicked: {
                            lVPopup.open()
                        }
                    }
                }
                
                RowLayout {
                    id: topLayout
                    Layout.alignment: Qt.AlignHCenter

                    WaveCard {
                        id: windTurbineCard
                        title: "Wind Turbine Parameters"
                        Layout.minimumHeight: windTurbineOutputCard.height
                        Layout.minimumWidth: 350

                        GridLayout {
                            columns: 2
                            anchors.fill: parent
                            
                            Label { text: "Blade Radius (m):" }
                            SpinBoxRound {
                                id: bladeRadiusSpinBox
                                from: 1
                                to: 100
                                value: calculatorReady ? calculator.bladeRadius : 40
                                stepSize: 1
                                readOnly: true
                                Layout.fillWidth: true
                                onValueModified: {
                                    if (calculatorReady) {
                                        calculator.setBladeRadius(value)
                                    }
                                }
                            }
                            
                            Label { text: "Wind Speed (m/s):" }
                            SpinBoxRound {
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
                            SpinBoxRound {
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
                            SpinBoxRound {
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
                            SpinBoxRound {
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
                            SpinBoxRound {
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
                            SpinBoxRound {
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
                                color: window.modeToggled ? "#404040" : "#e0e0e0"
                            }

                            Label { 
                                text: "Profiles"
                                Layout.columnSpan: 2
                                font.bold: true
                            }

                            RowLayout {
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignHCenter

                                StyledButton {
                                    text: "Vestas V27"
                                    ToolTip.text: "Set to Vestas V27 parameters"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500

                                    Layout.alignment: Qt.AlignRight
                                    
                                    onClicked: {
                                        if (calculatorReady) {
                                            calculator.loadVestasV27Parameters()
                                            bladeRadiusSpinBox.value = calculator.bladeRadius
                                            windSpeedSpinBox.value = calculator.windSpeed  // Will be set to rated wind speed
                                            cutInSpinBox.value = calculator.cutInSpeed
                                            cutOutSpinBox.value = calculator.cutOutSpeed
                                            powerCoefficientSpinBox.value = calculator.powerCoefficient * 100
                                            efficiencySpinBox.value = calculator.efficiency * 100
                                            
                                            // Force immediate recalculation and update
                                            updatePowerCurve()
                                        }
                                    }
                                }
                                
                                StyledButton {
                                    text: "V27 Info"
                                    Layout.alignment: Qt.AlignRight
                                    
                                    onClicked: v27StatsPopup.open()
                                    ToolTip.text: "View Vestas V27 statistics"
                                    ToolTip.delay: 500
                                    ToolTip.visible: hovered
                                }
                            }
                        }
                    }
                    
                    WaveCard {
                        id: windTurbineOutputCard
                        title: "Wind Turbine Output"
                        Layout.minimumHeight: 530
                        Layout.minimumWidth: 430
                        Layout.alignment: Qt.AlignTop
                        
                        GridLayout {
                            columns: 2
                            anchors.fill: parent

                            Label { text: "Swept Area (m²):" }
                            TextFieldBlue {
                                id: sweptAreaText
                                text: "0.00" // Set default value, will be updated by timer
                                hoverEnabled: true
                                ToolTip.visible: hovered
                                ToolTip.delay: 500
                                ToolTip.text: "self._swept_area = math.pi * self._blade_radius * self._blade_radius"
                            }

                            Label { text: "Theoretical Power (kW):" }
                            TextFieldBlue {
                                id: theoreticalPowerText
                                text: "0.00" // Set default value, will be updated by timer
                                hoverEnabled: true
                                ToolTip.visible: hovered
                                ToolTip.delay: 500
                                ToolTip.text: "self._theoretical_power = 0.5 * self._air_density * self._swept_area * math.pow(self._wind_speed, 3)"
                            }

                            Label { text: "Actual Power Output (kW):" }
                            TextFieldBlue {
                                id: actualPowerText
                                text: "0.00" // Set default value, will be updated by timer
                                hoverEnabled: true
                                ToolTip.visible: hovered
                                ToolTip.delay: 500
                                ToolTip.text: "self._actual_power = self._theoretical_power * self._power_coefficient * self._efficiency"
                            }
                            
                            Label { text: "Generator Rated Capacity (kVA):" }
                            TextFieldBlue {
                                id: genCapacityText
                                text: "0.00" // Set default value, will be updated by timer
                                hoverEnabled: true
                                ToolTip.visible: hovered
                                ToolTip.delay: 500
                                ToolTip.text: "self._rated_capacity =  self._actual_power * 1.2 / 1000"
                            }
                            
                            Label { text: "Generator Output Current (A):" }
                            TextFieldBlue {
                                id: genCurrentText
                                text: "0.00" // Set default value, will be updated by timer
                                hoverEnabled: true
                                ToolTip.visible: hovered
                                ToolTip.delay: 500
                                ToolTip.text: "self._output_current =  (self._actual_power / 1000) / (math.sqrt(3) * 0.4)"
                            }
                            
                            Label { text: "Annual Energy Production (MWh/year):" }
                            TextFieldBlue {
                                id: annualEnergyText
                                text: "0.00" // Set default value, will be updated by timer
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.columnSpan: 2
                                Layout.margins: 10
                                height: 1
                                color: window.modeToggled ? "#404040" : "#e0e0e0"
                            }

                            Label { 
                                text: "Advanced Analysis:"
                                Layout.columnSpan: 2
                                font.bold: true
                            }

                            Label { text: "Average Wind Speed (m/s):" }
                            SpinBoxRound {
                                id: avgWindSpeedSpinBox
                                from: 1
                                to: 20
                                value: 7
                                stepSize: 1
                                editable: true
                                Layout.fillWidth: true
                            }
                            
                            Label { text: "Weibull Shape Parameter:" }
                            SpinBoxRound {
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
                            }
                            
                            Label { text: "Estimated AEP (MWh/year):" }
                            TextFieldBlue {
                                id: advancedAepText
                                text: "0.00"
                            }
                            
                            StyledButton {
                                text: "Calculate AEP"

                                ToolTip.text: "Calculate AEP"
                                ToolTip.visible: hovered
                                ToolTip.delay: 500

                                icon.source: "../../../icons/rounded/calculate.svg"
                                
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignRight
                                
                                onClicked: {
                                    calculateAdvancedAEP()
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

                        theme: Universal.theme
                                                                                
                        StyledButton {
                            text: "Update Power Curve"
                            icon.source: "../../../icons/rounded/restart_alt.svg"
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: -40
                            
                            ToolTip.text: "Update power curve"
                            ToolTip.delay: 500
                            ToolTip.visible: hovered

                            onClicked: {
                                calculate()
                                updatePowerCurve()
                            }
                        }
                        
                        ValueAxis {
                            id: axisX
                            min: 0
                            max: 30 // Default value
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

    // Function to update the power curve display
    function updatePowerCurve() {
        if (!calculatorReady) {
            console.error("Calculator instance not ready")
            return
        }
        
        try {
            powerSeries.clear()
            
            var powerCurveData = calculator.powerCurve || []
            
            var maxPower = 0.1
            
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
                
                if (y > maxPower) {
                    maxPower = y
                }
            }
            
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
            
            var cutOut = calculatorReady ? calculator.cutOutSpeed : 25;
            axisX.max = Math.max(cutOut + 5, 30);
            
            powerCurveChart.update()
        } catch (e) {
            console.error("Error updating power curve:", e)
            console.error("Error stack:", e.stack)
        }
    }

    function safeValue(value, defaultVal) {
        if (value === undefined || value === null || 
            typeof value !== 'number' || 
            isNaN(value) || !isFinite(value)) {
            return defaultVal;
        }
        return value;
    }

    function calculateAdvancedAEP() {
        if (!calculatorReady || isUpdatingAEP) return;
        
        try {
            isUpdatingAEP = true;
            
            var windSpeed = avgWindSpeedSpinBox.value;
            var weibullK = weibullKSpinBox.value / 10;
            
            var aep = calculator.estimateAEP(windSpeed, weibullK);
            
            advancedAepText.text = safeValue(aep, 0).toFixed(2);
        } catch (e) {
            console.error("Error calculating AEP:", e);
            advancedAepText.text = "Error";
        } finally {
            isUpdatingAEP = false;
        }
    }
    
    function updateDisplayValues() {
        if (!calculatorReady || isUpdatingValues) return;
        
        try {
            isUpdatingValues = true;
            
            sweptAreaText.text = safeValue(calculator.sweptArea, 0).toFixed(2);
            theoreticalPowerText.text = safeValue(calculator.theoreticalPower, 0).toFixed(2);
            actualPowerText.text = safeValue(calculator.actualPower, 0).toFixed(2);
            genCapacityText.text = safeValue(calculator.ratedCapacity, 0).toFixed(2);
            genCurrentText.text = safeValue(calculator.outputCurrent, 0).toFixed(2);
            annualEnergyText.text = safeValue(calculator.annualEnergy, 0).toFixed(2);
            
        } catch (e) {
            console.error("Error updating display values:", e);
        } finally {
            isUpdatingValues = false;
        }
    }

    Timer {
        id: updateTimer
        interval: 1000
        repeat: true
        running: calculatorReady
        onTriggered: {
            if(calculatorReady) {
                updateDisplayValues()
            }
        }
    }

    Connections {
        target: calculator
        function onPdfExportStatusChanged(success, message) {
            if (success) {
                messagePopup.showSuccess(message);
            } else {
                messagePopup.showError(message);
            }
        }
    }
    
    Component.onCompleted: {
        if (calculatorReady) {
            Qt.callLater(function() {
                updateDisplayValues();
                calculateAdvancedAEP();
                updatePowerCurve();
            });
        }

        // Check if the popup needs to be parented to the Overlay
        if (typeof Overlay !== 'undefined') {
            messagePopup.parent = Overlay.overlay;
        }
    }
}