import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import "../"
import "../displays"
import "../style"
import "../buttons"

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

    ScrollView {
        id: scrollView
        anchors.fill: parent
        
        GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: 20
            rowSpacing: 20
            
            // Title and calculate button
            Item {
                Layout.columnSpan: 2
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
            
            // Generator Protection Card
            WaveCard {
                title: "Generator Protection (400V)"
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                
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
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                
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
                        text: transformerReady ? transformerCalculator.relayCtRatio : "200/1"
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
                        text: transformerReady ? 
                            safeValueFunction(transformerCalculator.groundFaultCurrent, 100).toFixed(2) + " A" : 
                            "100.00 A"
                        Layout.fillWidth: true
                    }
                    
                    Label { text: "Instantaneous Setting:" }
                    TextFieldBlue { 
                        text: transformerReady ? 
                            (safeValueFunction(calculateTransformerFullLoadCurrent(), 15.75) * 8).toFixed(2) + " A (8× FLC)" : 
                            "126.00 A (8× FLC)" 
                        Layout.fillWidth: true
                    }
                }
            }
            
            // Line Protection Card
            WaveCard {
                title: "Line Protection Requirements"
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                
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
            
            // Voltage Regulator Protection Card
            VoltageRegulatorProtectionInfo {
                Layout.columnSpan: 1
                Layout.fillWidth: true
                Layout.preferredHeight: 400
                
                calculator: transformerCalculator
                safeValueFunction: protectionSection.safeValueFunction
            }
            
            // Grid Connection Requirements Card
            WaveCard {
                title: "Grid Connection Requirements"
                Layout.columnSpan: 1
                Layout.fillWidth: true
                Layout.preferredHeight: 400
                
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
                    
                    TableView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
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
                            implicitWidth: 100
                            implicitHeight: 30
                            color: index % 2 === 0 ? "#f0f0f0" : "#ffffff"
                            
                            Label {
                                // Fix: Access the model properties directly using model.<propertyName>
                                text: {
                                    if (modelData) {
                                        // For array-based models using modelData
                                        return modelData[role] || ""
                                    } else {
                                        // For ListModel-based models
                                        switch(column) {
                                            case 0: return model.protection || "";
                                            case 1: return model.stage || "";
                                            case 2: return model.setting || "";
                                            case 3: return model.time || "";
                                            default: return "";
                                        }
                                    }
                                }
                                anchors.centerIn: parent
                                elide: Text.ElideRight
                            }
                        }
                        
                        columnWidthProvider: function(column) {
                            switch(column) {
                                case 0: return 120;
                                case 1: return 70;
                                case 2: return 100;
                                case 3: return 70;
                            }
                            return 100;
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
                // Create export data
                let exportData = {
                    "wind_power": windTurbineCalculator.actualPower,
                    "generator_current": (windTurbineCalculator.actualPower * 1000) / (Math.sqrt(3) * 400),
                    "generator_capacity": windTurbineCalculator.actualPower * 1.2,
                    "transformer_rating": transformerCalculator.transformerRating,
                    "voltage_protection": {
                        "under_voltage": "-15%",
                        "over_voltage": "+15%"
                    },
                    "frequency_protection": {
                        "under_frequency": "47.5Hz",
                        "over_frequency": "52Hz"
                    }
                };
                
                // Process file path for Python backend
                let filePath = exportDialog.selectedFile.toString();
                
                // Remove the "file://" prefix based on platform
                if (filePath.startsWith("file:///") && Qt.platform.os === "windows") {
                    filePath = filePath.substring(8);
                } else if (filePath.startsWith("file:///")) {
                    filePath = filePath.substring(7); 
                } else if (filePath.startsWith("file://")) {
                    filePath = filePath.substring(5);
                }
                
                transformerCalculator.exportProtectionReport(exportData, filePath);
            }
        }
    }
}