import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/displays"

Item {
    id: protectionSection

    property var transformerCalculator
    property var windTurbineCalculator
    property bool transformerReady
    property bool windTurbineReady
    property real totalGeneratedPower
    property var safeValueFunction

    signal calculate()

    // Add helper function for transformer ratings
    function calculateTransformerFullLoadCurrent() {
        if (!transformerReady) return 0.0;
        
        let transformerRating = safeValueFunction(transformerCalculator.transformerRating, 300); // kVA
        let transformerHvVoltage = 11000; // V
        
        return (transformerRating * 1000) / (Math.sqrt(3) * transformerHvVoltage);
    }

    // Add helper function to determine CT ratio
    function determineCtRatio(current) {
        let standardRatios = [50, 75, 100, 150, 200, 300, 400, 600, 800, 1000, 1200];
        let multipliedCurrent = current * 1.5; // 150% margin
        
        for (let i = 0; i < standardRatios.length; i++) {
            if (standardRatios[i] >= multipliedCurrent) {
                return standardRatios[i] + "/5";
            }
        }
        return "1000/5";
    }
                
    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height + 50
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5
            clip: true

            ColumnLayout {
                id: mainLayout
                anchors.centerIn: parent

                // Title and calculate button
                Item {
                    Layout.fillWidth: true
                    height: 50
                    
                    RowLayout {
                        anchors.fill: parent
                        
                        Label {
                            text: "Protection Requirements for Wind Turbine Connection"
                            font.bold: true
                            font.pixelSize: 16
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        StyledButton {
                            text: "Calculate System"
                            onClicked: calculate()
                        }
                        
                        StyledButton {
                            text: "Export Settings"
                            onClicked: exportDialog.open()
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter

                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        // Generator Protection Card
                        WaveCard {
                            title: "Generator Protection (400V)"
                            Layout.minimumWidth: 400
                            Layout.preferredHeight: 360

                            
                            GridLayout {
                                anchors.fill: parent
                                columns: 2
                                
                                Label { text: "Generator Rated Power:" }
                                TextFieldBlue { 
                                    text: windTurbineReady ? safeValueFunction(windTurbineCalculator.actualPower, 0).toFixed(2) + " kW" : "0.00 kW" 
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Generator Output Current:" }
                                TextFieldBlue { 
                                    text: windTurbineReady ? 
                                        safeValueFunction((windTurbineCalculator.actualPower * 1000) / (Math.sqrt(3) * 400), 0).toFixed(2) + " A" : 
                                        "0.00 A" 
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Overcurrent Pickup (150%):" }
                                TextFieldBlue { 
                                    text: windTurbineReady ? 
                                        safeValueFunction(1.5 * (windTurbineCalculator.actualPower * 1000) / (Math.sqrt(3) * 400), 0).toFixed(2) + " A" : 
                                        "0.00 A" 
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Recommended CT Ratio:" }
                                TextFieldBlue { 
                                    text: windTurbineReady ? 
                                        determineCtRatio((windTurbineCalculator.actualPower * 1000) / (Math.sqrt(3) * 400)) : 
                                        "100/5" 
                                    Layout.fillWidth: true
                                    
                                    function determineCtRatio(current) {
                                        let standardRatios = [50, 75, 100, 150, 200, 300, 400, 600, 800, 1000, 1200];
                                        let multipliedCurrent = current * 1.5; // 150% margin
                                        
                                        for (let i = 0; i < standardRatios.length; i++) {
                                            if (standardRatios[i] >= multipliedCurrent) {
                                                return standardRatios[i] + "/5";
                                            }
                                        }
                                        return "1000/5";
                                    }
                                }
                                
                                Label { text: "Under/Over Voltage:" }
                                TextFieldBlue { text: "±15% (340V - 460V)" }
                                
                                Label { text: "Under/Over Frequency:" }
                                TextFieldBlue { text: "±2% (49Hz - 51Hz)" }
                                
                                Label { text: "Earth Fault Setting:" }
                                TextFieldBlue { text: "30% of FLC" }
                                
                                Label { text: "Anti-Islanding Protection:" }
                                TextFieldBlue { text: "Required" }
                            }
                        }

                        // Transformer Protection Card - Important to be based on transformer rating
                        WaveCard {
                            title: "Transformer Protection (11kV)"
                            Layout.minimumWidth: 400
                            Layout.minimumHeight: 800  // Increased height for new fields
                            
                            GridLayout {
                                anchors.fill: parent
                                columns: 2
                                
                                Label { text: "Transformer Rating:" }
                                TextFieldBlue { 
                                    text: transformerReady ? 
                                        safeValueFunction(transformerCalculator.transformerRating, 300) + " kVA" : 
                                        "300 kVA" 
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Full Load Current (HV Side):" }
                                TextFieldBlue { 
                                    id: transformerFLCField
                                    text: transformerReady ? 
                                        calculateTransformerFullLoadCurrent().toFixed(2) + " A" : 
                                        "15.75 A" 
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Relay Pickup Current (125% FLC):" }
                                TextFieldBlue { 
                                    text: transformerReady ? 
                                        (safeValueFunction(calculateTransformerFullLoadCurrent(), 15.75) * 1.25).toFixed(2) + " A" : 
                                        "19.69 A" 
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "CT Ratio:" }
                                TextFieldBlue { 
                                    id: someField
                                    text: {
                                        if (!transformerReady || !transformerCalculator) return "Default Value";
                                        
                                        const propertyValue = transformerCalculator.relayCtRatio;
                                        return propertyValue !== undefined ? propertyValue.toString() : "Default Value";
                                    }
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Time-Current Curve:" }
                                ComboBox {
                                    model: ["Very Inverse", "Extremely Inverse", "Standard Inverse", "Long-Time Inverse"]
                                    currentIndex: 0
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Time Dial Setting:" }
                                SpinBoxRound {
                                    from: 10
                                    to: 100
                                    value: 30
                                    stepSize: 5
                                    editable: true
                                    Layout.fillWidth: true
                                    
                                    property real realValue: value / 100
                                    
                                    textFromValue: function(value) {
                                        return (value / 100).toFixed(2);
                                    }
                                    
                                    valueFromText: function(text) {
                                        return Math.round(parseFloat(text) * 100);
                                    }
                                }
                                
                                Label { text: "Ground Fault Current:" }
                                TextFieldBlue { 
                                    text: transformerReady && transformerCalculator ? 
                                        (typeof transformerCalculator.groundFaultCurrent === 'number' ? 
                                            transformerCalculator.groundFaultCurrent.toFixed(2) + " A" : "0.00 A") : 
                                        "0.00 A"
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Instantaneous Setting:" }
                                TextFieldBlue { 
                                    text: transformerReady ? 
                                        (safeValueFunction(calculateTransformerFullLoadCurrent(), 15.75) * 8).toFixed(2) + " A (8× FLC)" : 
                                        "126.00 A (8× FLC)" 
                                    Layout.fillWidth: true
                                }
                                
                                // Add differential protection section
                                Rectangle {
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 2
                                    color: "#e0e0e0"
                                }
                                
                                Label { 
                                    text: "Differential Protection:"
                                    font.bold: true
                                    Layout.columnSpan: 2
                                }
                                
                                Label { text: "HV CT Ratio:" }
                                TextFieldBlue { 
                                    text: transformerReady && transformerCalculator.differentialSettings ? 
                                        transformerCalculator.differentialSettings.hv_ct_ratio : "300/1"
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "LV CT Ratio:" }
                                TextFieldBlue { 
                                    text: transformerReady && transformerCalculator.differentialSettings ? 
                                        transformerCalculator.differentialSettings.lv_ct_ratio : "1000/1"
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Diff. Pickup Current:" }
                                TextFieldBlue { 
                                    text: transformerReady && transformerCalculator.differentialSettings ? 
                                        transformerCalculator.differentialSettings.pickup_current.toFixed(2) + " A" : "0.00 A"
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Slope 1/Slope 2:" }
                                TextFieldBlue { 
                                    text: transformerReady && transformerCalculator.differentialSettings ? 
                                        (transformerCalculator.differentialSettings.slope1 * 100).toFixed(0) + "% / " +
                                        (transformerCalculator.differentialSettings.slope2 * 100).toFixed(0) + "%" : 
                                        "25% / 50%"
                                    Layout.fillWidth: true
                                }
                                
                                // Add harmonics section
                                Rectangle {
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 2
                                    color: "#e0e0e0"
                                }
                                
                                Label { 
                                    text: "Harmonic Limits:"
                                    font.bold: true
                                    Layout.columnSpan: 2
                                }
                                
                                Label { text: "2nd/3rd Harmonic:" }
                                TextFieldBlue { 
                                    text: "2% / 5% of fundamental"
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "5th/7th Harmonic:" }
                                TextFieldBlue { 
                                    text: "6% / 5% of fundamental"
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "THD Limit:" }
                                TextFieldBlue { 
                                    text: "8% maximum"
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Line Protection Card
                        WaveCard {
                            title: "Line Protection Requirements"
                            Layout.minimumWidth: 400
                            Layout.preferredHeight: 300
                            
                            GridLayout {
                                anchors.fill: parent
                                columns: 2
                                
                                Label { text: "Fault Current at 11kV:" }
                                TextFieldBlue { 
                                    text: transformerReady ? 
                                        (safeValueFunction(transformerCalculator.faultCurrentHV, 0.5) * 1000).toFixed(2) + " A" : 
                                        "500.00 A" 
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Minimum Cable Size:" }
                                TextFieldBlue { 
                                    text: transformerReady ? 
                                        transformerCalculator.recommendedHVCable : "25mm²" 
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Line Length:" }
                                TextFieldBlue { 
                                    text: transformerReady ? 
                                        safeValueFunction(transformerCalculator.lineLength, 5).toFixed(1) + " km" : 
                                        "5.0 km" 
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Voltage Regulation:" }
                                TextFieldBlue { 
                                    text: transformerReady ? 
                                        safeValueFunction(transformerCalculator.voltageDrop, 0.5).toFixed(2) + "%" : 
                                        "0.50%" 
                                    Layout.fillWidth: true
                                }
                                
                                Label { text: "Distance Protection:" }
                                TextFieldBlue { text: "Required for lines > 10km" }
                                
                                Label { text: "Auto-Reclosure:" }
                                TextFieldBlue { text: "Single-shot" }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop

                        // Time-Overcurrent Curve Card
                        WaveCard {
                            title: "Time-Overcurrent Curve"
                            Layout.minimumWidth: 500
                            Layout.preferredHeight: 400
                            
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10
                                
                                // Curve type info
                                GridLayout {
                                    columns: 4
                                    Layout.fillWidth: true
                                    
                                    Label { text: "Curve Type:" }
                                    ComboBox {
                                        id: curveTypeCombo
                                        model: ["Standard Inverse", "Very Inverse", "Extremely Inverse", "Long-Time Inverse"]
                                        Layout.fillWidth: true
                                        onCurrentTextChanged: curveCanvas.requestPaint()
                                    }
                                    
                                    Label { text: "Time Dial:" }
                                    SpinBox {
                                        id: timeDialSpin
                                        from: 10
                                        to: 100
                                        value: 30
                                        stepSize: 5
                                        editable: true
                                        onValueChanged: curveCanvas.requestPaint()
                                    }
                                }
                                
                                // Curve canvas
                                Canvas {
                                    id: curveCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    
                                    property var curveParams: {
                                        "Standard Inverse": {a: 0.14, b: 0.02},
                                        "Very Inverse": {a: 13.5, b: 1.0},
                                        "Extremely Inverse": {a: 80.0, b: 2.0},
                                        "Long-Time Inverse": {a: 120.0, b: 1.0}
                                    }
                                    
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        var w = width
                                        var h = height
                                        
                                        ctx.clearRect(0, 0, w, h)
                                        
                                        // Draw grid
                                        ctx.strokeStyle = "#e0e0e0"
                                        ctx.beginPath()
                                        for(var i = 0; i < w; i += w/10) {
                                            ctx.moveTo(i, 0)
                                            ctx.lineTo(i, h)
                                        }
                                        for(var j = 0; j < h; j += h/10) {
                                            ctx.moveTo(0, j)
                                            ctx.lineTo(w, j)
                                        }
                                        ctx.stroke()
                                        
                                        // Draw curve
                                        ctx.strokeStyle = "#2196F3"
                                        ctx.lineWidth = 2
                                        ctx.beginPath()
                                        
                                        var params = curveParams[curveTypeCombo.currentText]
                                        var timeDial = timeDialSpin.value / 100
                                        
                                        for(var x = 1; x < 20; x += 0.1) {
                                            var t = (params.a * timeDial) / (Math.pow(x, params.b) - 1)
                                            t = Math.max(t, 0.025)  // Minimum 25ms
                                            
                                            // Scale for display
                                            var px = Math.log(x) * w/3 + w/4
                                            var py = h - (Math.log(t) * h/3 + h/4)
                                            
                                            if(x === 1) ctx.moveTo(px, py)
                                            else ctx.lineTo(px, py)
                                        }
                                        ctx.stroke()
                                        
                                        // Draw axes labels
                                        ctx.fillStyle = "#000000"
                                        ctx.font = "12px Arial"
                                        ctx.fillText("Current Multiple (×pickup)", w/2, h-5)
                                        ctx.save()
                                        ctx.translate(10, h/2)
                                        ctx.rotate(-Math.PI/2)
                                        ctx.fillText("Time (seconds)", 0, 0)
                                        ctx.restore()
                                    }
                                }
                                
                                // Trip times table
                                GridLayout {
                                    columns: 4
                                    Layout.fillWidth: true
                                    
                                    Label { text: "Trip Times:" ; font.bold: true; Layout.columnSpan: 4 }
                                    Label { text: "2× pickup:" }
                                    Label { 
                                        text: {
                                            if (!transformerReady || !transformerCalculator) return "0.00";
                                            
                                            try {
                                                // Try the new method first, fall back to hardcoded value
                                                if (typeof transformerCalculator.calculateTripTimeWithParams === 'function') {
                                                    return transformerCalculator.calculateTripTimeWithParams(2.0, 
                                                           safeValueFunction(transformerCalculator.relayTimeDial, 0.3), 
                                                           transformerCalculator.relayCurveType || "Very Inverse").toFixed(2);
                                                } else {
                                                    console.warn("Trip time calculation methods not available");
                                                    return "1.25"; // Sensible default for Very Inverse at 2x pickup
                                                }
                                            } catch (e) {
                                                console.error("Error calculating trip time:", e);
                                                return "1.25";
                                            }
                                        }
                                    }
                                    Label { text: "5× pickup:" }
                                    Label { 
                                        text: {
                                            if (!transformerReady || !transformerCalculator) return "0.00";
                                            
                                            try {
                                                // Try the new method first, fall back to hardcoded value
                                                if (typeof transformerCalculator.calculateTripTimeWithParams === 'function') {
                                                    return transformerCalculator.calculateTripTimeWithParams(5.0, 
                                                           safeValueFunction(transformerCalculator.relayTimeDial, 0.3), 
                                                           transformerCalculator.relayCurveType || "Very Inverse").toFixed(2);
                                                } else {
                                                    console.warn("Trip time calculation methods not available");
                                                    return "0.25"; // Sensible default for Very Inverse at 5x pickup
                                                }
                                            } catch (e) {
                                                console.error("Error calculating trip time:", e);
                                                return "0.25";
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // VR-32 Voltage Regulator Card
                        WaveCard {
                            title: "Eaton VR-32 Voltage Regulator Protection Specifications"
                            Layout.minimumWidth: 500
                            Layout.preferredHeight: 600

                            ColumnLayout {
                                anchors.fill: parent

                                Label {
                                    text: "<b>Key Components for 3× Eaton 185kVA Single-Phase Regulators:</b>"
                                    font.pixelSize: 14
                                }
                                
                                GridLayout {
                                    columns: 2
                                    Layout.fillWidth: true
                                    
                                    Label { text: "<b>Current Transformers:</b>" }
                                    Label { text: "<b>Specifications:</b>" }
                                    
                                    Label { text: "• Metering CTs:" }
                                    Label { text: "300/1A, Class 0.5, 5VA" }
                                    
                                    Label { text: "• Protection CTs:" }
                                    Label { text: "300/1A, 5P20, 10VA" }
                                    
                                    Label { text: "• Voltage Sensing Circuit Fuses:" }
                                    Label { text: "2A, Type D" }
                                    
                                    Label { text: "• Backup Battery:" }
                                    Label { text: "12V, 7Ah, sealed lead-acid" }
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: regConfigLayout.implicitHeight + 20
                                    color: window.modeToggled ? "black" : "#f7f0ff"
                                    border.color: "#8a4eef"
                                    radius: 5
                                    
                                    ColumnLayout {
                                        id: regConfigLayout
                                        anchors.fill: parent
                                        anchors.margins: 10

                                        Label {
                                            text: "<b>Controller Configuration:</b>"
                                            font.pixelSize: 13
                                        }
                                        
                                        GridLayout {
                                            columns: 2
                                            Layout.fillWidth: true

                                            Label { text: "• Voltage Regulation Range:" }
                                            Label { text: "±10% in 32 steps (0.625% per step)" }
                                            
                                            Label { text: "• Bandwidth:" }
                                            Label { text: safeValueFunction(transformerCalculator.voltageRegulatorBandwidth, 2.0).toFixed(1)}
                                            
                                            Label { text: "• Time Delay:" }
                                            Label { text: "30 seconds (adjustable 15-120s)" }
                                            
                                            Label { text: "• Line Drop Compensation:" }
                                            Label { text: "R=3Ω, X=6Ω (adjustable)" }
                                        }
                                        
                                        Label {
                                            text: "<b>Protection & Monitoring Features:</b>"
                                            font.pixelSize: 13
                                            Layout.topMargin: 10
                                        }
                                        
                                        Label {
                                            text: "• Overvoltage cutout: 130% of nominal\n" + 
                                                    "• Tap position monitoring and reporting\n" + 
                                                    "• Operations counter with maintenance alerts\n" + 
                                                    "• Temperature monitoring with automatic shutdown\n" + 
                                                    "• Voltage quality recording with event logs\n" + 
                                                    "• Automatic bypass on controller failure"
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                                
                                Label {
                                    text: "<b>SCADA Integration:</b>\n" +
                                            "• DNP3.0 protocol support\n" +
                                            "• Remote tap position monitoring\n" +
                                            "• Remote voltage setpoint adjustment\n" +
                                            "• Operations count and status monitoring\n" +
                                            "• Maintenance alerts via SCADA\n" +
                                            "• Event logs with timestamping"
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Grid Connection Requirements Card
                        WaveCard {
                            title: "Grid Connection Requirements"
                            Layout.minimumWidth: 500
                            Layout.preferredHeight: 470
                            
                            ColumnLayout {
                                anchors.fill: parent
                                
                                Label {
                                    text: "<b>G99 Connection Requirements:</b>"
                                    font.pixelSize: 14
                                }
                                
                                Label {
                                    text: "• Frequency range: 47.5Hz - 52Hz\n" +
                                        "• Voltage range: -10% to +10% of nominal\n" +
                                        "• Power factor control: 0.95 lagging to 0.95 leading\n" +
                                        "• Harmonic limits per EN 50160\n" +
                                        "• Low Voltage Ride Through (LVRT) capability\n" +
                                        "• Rate of Change of Frequency (RoCoF) protection: 1Hz/s\n" +
                                        "• Vector shift protection: 12 degrees"
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Label {
                                    text: "<b>Protection Requirements:</b>"
                                    font.pixelSize: 14
                                    Layout.topMargin: 10
                                }
                                
                                Column {
                                    id: protectionTableColumn
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 230
                                    
                                    property var columnWidths: [0.33, 0.22, 0.28, 0.17]
                                    property var columnNames: ["Protection", "Stage", "Setting", "Time"]
                                    
                                    function getWidth(index) {
                                        return width * columnWidths[index]
                                    }
                                    
                                    // Header
                                    Row {
                                        width: parent.width
                                        height: 30
                                        
                                        Repeater {
                                            model: protectionTableColumn.columnNames
                                            
                                            Rectangle {
                                                width: protectionTableColumn.getWidth(index)
                                                height: 30
                                                color: "#e0e0e0"
                                                border.width: 1
                                                border.color: "#c0c0c0"
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    font.bold: true
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Data rows
                                    ListView {
                                        width: parent.width
                                        height: 200
                                        clip: true
                                        
                                        model: ListModel {
                                            ListElement { protection: "Under Voltage"; stage: "Stage 1"; setting: "V < 0.8pu"; time: "2.5s" }
                                            ListElement { protection: "Under Voltage"; stage: "Stage 2"; setting: "V < 0.87pu"; time: "5.0s" }
                                            ListElement { protection: "Over Voltage"; stage: "Stage 1"; setting: "V > 1.1pu"; time: "1.0s" }
                                            ListElement { protection: "Over Voltage"; stage: "Stage 2"; setting: "V > 1.14pu"; time: "0.5s" }
                                            ListElement { protection: "Under Frequency"; stage: "Stage 1"; setting: "f < 47.5Hz"; time: "20s" }
                                            ListElement { protection: "Over Frequency"; stage: "Stage 1"; setting: "f > 52Hz"; time: "0.5s" }
                                        }
                                        
                                        delegate: Rectangle {
                                            width: ListView.view.width
                                            height: 30
                                            color: index % 2 === 0 ? "#f0f0f0" : "#ffffff"
                                            
                                            Row {
                                                width: parent.width
                                                height: parent.height
                                                
                                                Rectangle {
                                                    width: protectionTableColumn.getWidth(0)
                                                    height: parent.height
                                                    color: "transparent"
                                                    border.width: 1
                                                    border.color: "#e0e0e0"
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: protection
                                                    }
                                                }
                                                Rectangle {
                                                    width: protectionTableColumn.getWidth(1)
                                                    height: parent.height
                                                    color: "transparent"
                                                    border.width: 1
                                                    border.color: "#e0e0e0"
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: stage
                                                    }
                                                }
                                                Rectangle {
                                                    width: protectionTableColumn.getWidth(2)
                                                    height: parent.height
                                                    color: "transparent"
                                                    border.width: 1
                                                    border.color: "#e0e0e0"
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: setting
                                                    }
                                                }
                                                Rectangle {
                                                    width: protectionTableColumn.getWidth(3)
                                                    height: parent.height
                                                    color: "transparent"
                                                    border.width: 1
                                                    border.color: "#e0e0e0"
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: time
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    FileDialog {
        id: exportDialog
        title: "Export Protection Settings"
        fileMode: FileDialog.SaveFile
        nameFilters: ["PDF files (*.pdf)"]
        defaultSuffix: "pdf"
        
        onAccepted: {
            if (transformerReady && windTurbineReady) {
                // Process file path
                let filePath = exportDialog.selectedFile.toString();
                if (filePath.startsWith("file:///")) {
                    filePath = filePath.substring(Qt.platform.os === "windows" ? 8 : 7);
                } else if (filePath.startsWith("file://")) {
                    filePath = filePath.substring(5);
                }
                
                // Calculate needed values
                let generatorCurrent = (windTurbineCalculator.actualPower * 1000) / (Math.sqrt(3) * 400);
                let transformerCurrent = calculateTransformerFullLoadCurrent();
                
                // Build complete data structure with all required values
                const exportData = {
                    "generator": {
                        "power": Number(windTurbineCalculator.actualPower),
                        "current": Number(generatorCurrent),
                        "capacity": Number(windTurbineCalculator.actualPower * 1.2),
                        "voltage_range": "±15% (340V - 460V)",
                        "frequency_range": "±2% (49Hz - 51Hz)",
                        "earth_fault": "30% of FLC",
                        "anti_islanding": "Required",
                        "overcurrent_pickup": Number(generatorCurrent * 1.5),
                        "time_delay": "0.5s",
                        "ct_ratio": determineCtRatio(generatorCurrent)
                    },
                    "transformer": {
                        "rating": Number(transformerCalculator.transformerRating),
                        "voltage": "11kV/400V",
                        "full_load_current": Number(transformerCurrent),
                        "fault_current": Number(transformerCalculator.faultCurrentHV),
                        "ground_fault": Number(transformerCalculator.groundFaultCurrent),
                        "ct_ratio": transformerCalculator.relayCtRatio,
                        "relay_pickup_current": Number(transformerCalculator.relayPickupCurrent),
                        "relay_curve_type": transformerCalculator.relayCurveType,
                        "time_dial": Number(transformerCalculator.relayTimeDial),
                        "differential_slope": Number(transformerCalculator.differentialRelaySlope),
                        "reverse_power": Number(transformerCalculator.reversePowerThreshold),
                        "instantaneous_pickup": Number(transformerCurrent * 8)
                    },
                    "line": {
                        "voltage": "11 kV",
                        "fault_current": Number(transformerCalculator.faultCurrentHV),
                        "cable_size": transformerCalculator.recommendedHVCable,
                        "length": Number(transformerCalculator.lineLength),
                        "voltage_drop": Number(transformerCalculator.voltageDrop)
                    },
                    "protection_settings": {
                        "voltage": [
                            {"type": "Under Voltage", "stage": "Stage 1", "setting": "V < 0.8pu", "time": "2.5s"},
                            {"type": "Under Voltage", "stage": "Stage 2", "setting": "V < 0.87pu", "time": "5.0s"},
                            {"type": "Over Voltage", "stage": "Stage 1", "setting": "V > 1.1pu", "time": "1.0s"},
                            {"type": "Over Voltage", "stage": "Stage 2", "setting": "V > 1.14pu", "time": "0.5s"}
                        ],
                        "frequency": [
                            {"type": "Under Frequency", "stage": "Stage 1", "setting": "f < 47.5Hz", "time": "20s"},
                            {"type": "Over Frequency", "stage": "Stage 1", "setting": "f > 52Hz", "time": "0.5s"}
                        ]
                    }
                };
                
                transformerCalculator.exportProtectionReport(exportData, filePath);
            }
        }
    }
}