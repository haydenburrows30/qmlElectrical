import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

ApplicationWindow {
    id: windTurbineWindow
    width: 1200
    height: 800
    title: "Wind Turbine Protection Coordination Template"
    
    property var templateEngine: null
    property var analysisResults: null
    
    // Main layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#2c3e50"
            radius: 5
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                
                Text {
                    text: "🌪️ Wind Turbine Protection Coordination Template"
                    font.pixelSize: 20
                    font.bold: true
                    color: "white"
                    Layout.fillWidth: true
                }
                
                Button {
                    text: "Generate Report"
                    onClicked: generateAnalysisReport()
                    background: Rectangle {
                        color: "#3498db"
                        radius: 5
                    }
                }
                
                Button {
                    text: "Save Config"
                    onClicked: saveConfiguration()
                    background: Rectangle {
                        color: "#27ae60"
                        radius: 5
                    }
                }
            }
        }
        
        // Main content area
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ColumnLayout {
                width: parent.width
                spacing: 15
                
                // System Configuration Card
                GroupBox {
                    title: "System Configuration"
                    Layout.fillWidth: true
                    
                    GridLayout {
                        columns: 4
                        columnSpacing: 15
                        rowSpacing: 10
                        anchors.fill: parent
                        
                        // Turbine Parameters
                        Label { text: "Turbine Voltage (V):" }
                        SpinBox {
                            id: turbineVoltage
                            from: 230
                            to: 690
                            value: 400
                            editable: true
                        }
                        
                        Label { text: "Turbine Power (kW):" }
                        SpinBox {
                            id: turbinePower
                            from: 100
                            to: 5000
                            value: 300
                            editable: true
                        }
                        
                        // Transformer Parameters
                        Label { text: "Transformer Rating (kVA):" }
                        SpinBox {
                            id: transformerRating
                            from: 100
                            to: 5000
                            value: 300
                            editable: true
                        }
                        
                        Label { text: "Transformer HV (kV):" }
                        ComboBox {
                            id: transformerHV
                            model: ["11.0", "22.0", "33.0"]
                            currentIndex: 0
                            editable: true
                        }
                        
                        Label { text: "Transformer Impedance (%):" }
                        SpinBox {
                            id: transformerImpedance
                            from: 30
                            to: 100
                            value: 60
                            editable: true
                            textFromValue: function(value) {
                                return (value / 10.0).toFixed(1) + "%"
                            }
                            valueFromText: function(text) {
                                return parseFloat(text) * 10
                            }
                        }
                        
                        Label { text: "Wind Fault Factor:" }
                        SpinBox {
                            id: windFaultFactor
                            from: 100
                            to: 150
                            value: 115
                            editable: true
                            textFromValue: function(value) {
                                return (value / 100.0).toFixed(2)
                            }
                            valueFromText: function(text) {
                                return parseFloat(text) * 100
                            }
                        }
                        
                        // Fuse Parameters
                        Label { text: "HV Fuse Rating (A):" }
                        ComboBox {
                            id: hvFuseRating
                            model: ["16", "25", "40", "63", "100"]
                            currentIndex: 1
                            editable: true
                        }
                        
                        Label { text: "Incomer Fuse Rating (A):" }
                        ComboBox {
                            id: incomerFuseRating
                            model: ["40", "63", "100", "125", "160"]
                            currentIndex: 1
                            editable: true
                        }
                    }
                }
                
                // Protection Settings Card
                GroupBox {
                    title: "Protection Settings"
                    Layout.fillWidth: true
                    
                    GridLayout {
                        columns: 4
                        columnSpacing: 15
                        rowSpacing: 10
                        anchors.fill: parent
                        
                        Label { text: "Discrimination Time (s):" }
                        SpinBox {
                            id: discriminationTime
                            from: 10
                            to: 100
                            value: 30
                            editable: true
                            textFromValue: function(value) {
                                return (value / 100.0).toFixed(2)
                            }
                            valueFromText: function(text) {
                                return parseFloat(text) * 100
                            }
                        }
                        
                        Label { text: "Safety Margin:" }
                        SpinBox {
                            id: safetyMargin
                            from: 100
                            to: 300
                            value: 150
                            editable: true
                            textFromValue: function(value) {
                                return (value / 100.0).toFixed(1)
                            }
                            valueFromText: function(text) {
                                return parseFloat(text) * 100
                            }
                        }
                        
                        Label { text: "Coordination Ratio:" }
                        SpinBox {
                            id: coordinationRatio
                            from: 150
                            to: 400
                            value: 200
                            editable: true
                            textFromValue: function(value) {
                                return (value / 100.0).toFixed(1)
                            }
                            valueFromText: function(text) {
                                return parseFloat(text) * 100
                            }
                        }
                        
                        Label { text: "Max Fault Current (A):" }
                        SpinBox {
                            id: maxFaultCurrent
                            from: 1000
                            to: 10000
                            value: 2500
                            editable: true
                            stepSize: 100
                        }
                    }
                }
                
                // Analysis Results Card
                GroupBox {
                    title: "Analysis Results"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    
                    ScrollView {
                        anchors.fill: parent
                        
                        ColumnLayout {
                            width: parent.width
                            
                            // System Currents
                            GroupBox {
                                title: "Calculated System Currents"
                                Layout.fillWidth: true
                                
                                GridLayout {
                                    columns: 2
                                    columnSpacing: 20
                                    rowSpacing: 5
                                    anchors.fill: parent
                                    
                                    Label { text: "LV Full Load Current:" }
                                    Label { 
                                        id: lvFullLoadCurrent
                                        text: "-- A"
                                        font.family: "monospace"
                                    }
                                    
                                    Label { text: "HV Full Load Current:" }
                                    Label { 
                                        id: hvFullLoadCurrent
                                        text: "-- A"
                                        font.family: "monospace"
                                    }
                                    
                                    Label { text: "Transformer SC Current:" }
                                    Label { 
                                        id: transformerSCCurrent
                                        text: "-- A"
                                        font.family: "monospace"
                                    }
                                    
                                    Label { text: "Wind Fault Current (HV):" }
                                    Label { 
                                        id: windFaultCurrent
                                        text: "-- A"
                                        font.family: "monospace"
                                    }
                                    
                                    Label { text: "Inrush Current:" }
                                    Label { 
                                        id: inrushCurrent
                                        text: "-- A"
                                        font.family: "monospace"
                                    }
                                }
                            }
                            
                            // Coordination Status
                            GroupBox {
                                title: "Coordination Status"
                                Layout.fillWidth: true
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40
                                        color: coordinationStatus.coordinated ? "#27ae60" : "#e74c3c"
                                        radius: 5
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: coordinationStatus.coordinated ? "✓ COORDINATED" : "⚠ COORDINATION ISSUES"
                                            color: "white"
                                            font.bold: true
                                            font.pixelSize: 16
                                        }
                                    }
                                    
                                    ListView {
                                        id: coordinationIssues
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 100
                                        model: coordinationStatus.issues
                                        visible: coordinationStatus.issues.length > 0
                                        
                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 25
                                            color: index % 2 ? "#ecf0f1" : "transparent"
                                            
                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: `Issue at ${modelData.current}A: Time ratio ${modelData.time_ratio.toFixed(2)} < ${modelData.required_ratio.toFixed(2)}`
                                                font.pixelSize: 12
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Fuse Analysis
                            Row {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                GroupBox {
                                    title: "25A Fuse Analysis"
                                    width: parent.width / 2 - 5
                                    
                                    ColumnLayout {
                                        anchors.fill: parent
                                        
                                        Text {
                                            text: `Loading: ${fuse25AAnalysis.loading_factor.toFixed(2)}`
                                            font.family: "monospace"
                                        }
                                        
                                        Text {
                                            text: `Full Load: ${fuse25AAnalysis.full_load_time.toFixed(0)}s`
                                            color: fuse25AAnalysis.full_load_ok ? "#27ae60" : "#e74c3c"
                                            font.family: "monospace"
                                        }
                                        
                                        Text {
                                            text: `Inrush: ${fuse25AAnalysis.inrush_time.toFixed(2)}s`
                                            color: fuse25AAnalysis.inrush_ok ? "#27ae60" : "#e74c3c"
                                            font.family: "monospace"
                                        }
                                        
                                        Text {
                                            text: `Fault: ${fuse25AAnalysis.fault_time.toFixed(2)}s`
                                            color: fuse25AAnalysis.fault_ok ? "#27ae60" : "#e74c3c"
                                            font.family: "monospace"
                                        }
                                    }
                                }
                                
                                GroupBox {
                                    title: "63A Fuse Analysis"
                                    width: parent.width / 2 - 5
                                    
                                    ColumnLayout {
                                        anchors.fill: parent
                                        
                                        Text {
                                            text: `Loading: ${fuse63AAnalysis.loading_factor.toFixed(2)}`
                                            font.family: "monospace"
                                        }
                                        
                                        Text {
                                            text: `Full Load: ${fuse63AAnalysis.full_load_time.toFixed(0)}s`
                                            color: fuse63AAnalysis.full_load_ok ? "#27ae60" : "#e74c3c"
                                            font.family: "monospace"
                                        }
                                        
                                        Text {
                                            text: `System Fault: ${fuse63AAnalysis.system_fault_time.toFixed(2)}s`
                                            color: fuse63AAnalysis.system_fault_ok ? "#27ae60" : "#e74c3c"
                                            font.family: "monospace"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Chart Display (placeholder)
                GroupBox {
                    title: "Time-Current Characteristic Curves"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    
                    Rectangle {
                        anchors.fill: parent
                        color: "#ecf0f1"
                        radius: 5
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            
                            Text {
                                text: "📊"
                                font.pixelSize: 48
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Text {
                                text: "Time-Current Curves"
                                font.pixelSize: 16
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Button {
                                text: "Open Discrimination Chart"
                                onClicked: openDiscriminationChart()
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Data models for analysis results
    property var coordinationStatus: ({
        coordinated: true,
        issues: []
    })
    
    property var fuse25AAnalysis: ({
        loading_factor: 0.0,
        full_load_time: 3600,
        full_load_ok: true,
        inrush_time: 1.0,
        inrush_ok: true,
        fault_time: 1.0,
        fault_ok: true
    })
    
    property var fuse63AAnalysis: ({
        loading_factor: 0.0,
        full_load_time: 3600,
        full_load_ok: true,
        system_fault_time: 1.0,
        system_fault_ok: true
    })
    
    // File dialogs
    FileDialog {
        id: saveConfigDialog
        title: "Save Configuration"
        selectExisting: false
        nameFilters: ["JSON files (*.json)"]
        onAccepted: {
            // Save configuration to selected file
            console.log("Saving config to:", fileUrl)
        }
    }
    
    FileDialog {
        id: saveReportDialog
        title: "Save Report"
        selectExisting: false
        nameFilters: ["Markdown files (*.md)", "Text files (*.txt)"]
        onAccepted: {
            // Save report to selected file
            console.log("Saving report to:", fileUrl)
        }
    }
    
    // Functions
    function generateAnalysisReport() {
        console.log("Generating analysis report...")
        
        // Collect input values
        var config = {
            turbine_voltage: turbineVoltage.value,
            turbine_power: turbinePower.value * 1000, // Convert to W
            transformer_rating: transformerRating.value * 1000, // Convert to VA
            transformer_voltage_hv: parseFloat(transformerHV.currentText) * 1000, // Convert to V
            transformer_impedance: transformerImpedance.value / 1000.0, // Convert to decimal
            wind_fault_factor: windFaultFactor.value / 100.0, // Convert to decimal
            hv_fuse_rating: parseInt(hvFuseRating.currentText),
            incomer_fuse_rating: parseInt(incomerFuseRating.currentText),
            discrimination_time: discriminationTime.value / 100.0, // Convert to seconds
            safety_margin: safetyMargin.value / 100.0, // Convert to decimal
            coordination_ratio: coordinationRatio.value / 100.0, // Convert to decimal
            max_fault_current: maxFaultCurrent.value
        }
        
        // Call Python backend to generate analysis
        if (templateEngine) {
            templateEngine.generateAnalysis(config)
        } else {
            // Simulate analysis results for demonstration
            simulateAnalysisResults(config)
        }
    }
    
    function simulateAnalysisResults(config) {
        // Simulate calculated currents
        var lvFullLoad = config.turbine_power / (Math.sqrt(3) * config.turbine_voltage)
        var hvFullLoad = config.transformer_rating / (Math.sqrt(3) * config.transformer_voltage_hv)
        var transformerSC = hvFullLoad / config.transformer_impedance
        var windFault = lvFullLoad * config.wind_fault_factor
        var hvFault = windFault * (config.turbine_voltage / config.transformer_voltage_hv)
        var inrush = hvFullLoad * 8.0 // Typical inrush factor
        
        // Update display
        lvFullLoadCurrent.text = lvFullLoad.toFixed(1) + " A"
        hvFullLoadCurrent.text = hvFullLoad.toFixed(1) + " A"
        transformerSCCurrent.text = transformerSC.toFixed(0) + " A"
        windFaultCurrent.text = hvFault.toFixed(1) + " A"
        inrushCurrent.text = inrush.toFixed(0) + " A"
        
        // Update fuse analysis
        fuse25AAnalysis.loading_factor = hvFullLoad / config.hv_fuse_rating
        fuse25AAnalysis.full_load_ok = fuse25AAnalysis.loading_factor < 0.8
        fuse25AAnalysis.inrush_ok = inrush / config.hv_fuse_rating < 10
        fuse25AAnalysis.fault_ok = true // Assume adequate for demo
        
        fuse63AAnalysis.loading_factor = hvFullLoad / config.incomer_fuse_rating
        fuse63AAnalysis.full_load_ok = fuse63AAnalysis.loading_factor < 0.8
        fuse63AAnalysis.system_fault_ok = true // Assume adequate for demo
        
        // Update coordination status
        coordinationStatus.coordinated = fuse25AAnalysis.full_load_ok && fuse25AAnalysis.inrush_ok && 
                                       fuse63AAnalysis.full_load_ok
        coordinationStatus.issues = coordinationStatus.coordinated ? [] : [
            {current: 200, time_ratio: 1.5, required_ratio: 2.0}
        ]
    }
    
    function saveConfiguration() {
        saveConfigDialog.open()
    }
    
    function openDiscriminationChart() {
        // Open the main discrimination analyzer with current configuration
        console.log("Opening discrimination chart...")
        
        // This would typically open the main discrimination analyzer
        // with the current fuse configuration pre-loaded
    }
    
    Component.onCompleted: {
        // Initialize with default analysis
        generateAnalysisReport()
    }
}
