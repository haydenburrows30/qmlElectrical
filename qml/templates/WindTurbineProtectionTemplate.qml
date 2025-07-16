import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCharts
import WindTurbineProtection 1.0

Page {
    id: windTurbineWindow
    
    property var templateEngine: windTurbineProtectionTemplate
    property var analysisResults: null
    
    title: "Wind Turbine Protection Coordination Template"
    
    // Create the template engine instance
    WindTurbineProtectionTemplate {
        id: windTurbineProtectionTemplate
        
        onAnalysisComplete: function(result) {
            console.log("Analysis complete:", result)
            analysisResults = JSON.parse(result)
            updateAnalysisDisplay()
        }
        
        onFuseDataReady: function(result) {
            console.log("Fuse data ready:", result)
        }
        
        onErrorOccurred: function(error) {
            console.error("Error occurred:", error)
        }
    }
    
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
                                                text: "Issue at " + modelData.current + "A: Time ratio " + modelData.time_ratio.toFixed(2) + " < " + modelData.required_ratio.toFixed(2)
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
                                            text: "Loading: " + fuse25AAnalysis.loading_factor.toFixed(2)
                                            font.family: "monospace"
                                        }
                                        
                                        Text {
                                            text: "Full Load: " + fuse25AAnalysis.full_load_time.toFixed(0) + "s"
                                            color: fuse25AAnalysis.full_load_ok ? "#27ae60" : "#e74c3c"
                                            font.family: "monospace"
                                        }
                                        
                                        Text {
                                            text: "Inrush: " + fuse25AAnalysis.inrush_time.toFixed(2) + "s"
                                            color: fuse25AAnalysis.inrush_ok ? "#27ae60" : "#e74c3c"
                                            font.family: "monospace"
                                        }
                                        
                                        Text {
                                            text: "Fault: " + fuse25AAnalysis.fault_time.toFixed(2) + "s"
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
                                            text: "Loading: " + fuse63AAnalysis.loading_factor.toFixed(2)
                                            font.family: "monospace"
                                        }
                                        
                                        Text {
                                            text: "Full Load: " + fuse63AAnalysis.full_load_time.toFixed(0) + "s"
                                            color: fuse63AAnalysis.full_load_ok ? "#27ae60" : "#e74c3c"
                                            font.family: "monospace"
                                        }
                                        
                                        Text {
                                            text: "System Fault: " + fuse63AAnalysis.system_fault_time.toFixed(2) + "s"
                                            color: fuse63AAnalysis.system_fault_ok ? "#27ae60" : "#e74c3c"
                                            font.family: "monospace"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Chart Display
                GroupBox {
                    title: "Time-Current Characteristic Curves"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10
                        
                        // Chart controls
                        RowLayout {
                            Layout.fillWidth: true
                            
                            CheckBox {
                                id: show25AFuse
                                text: "25A Fuse"
                                checked: true
                                onCheckedChanged: chartCanvas.updateChart()
                            }
                            
                            CheckBox {
                                id: show63AFuse
                                text: "63A Fuse"
                                checked: true
                                onCheckedChanged: chartCanvas.updateChart()
                            }
                            
                            CheckBox {
                                id: showOperatingPoints
                                text: "Operating Points"
                                checked: true
                                onCheckedChanged: chartCanvas.updateChart()
                            }
                            
                            Item { Layout.fillWidth: true }
                            
                            Button {
                                text: "Auto Scale"
                                onClicked: chartCanvas.autoScale()
                            }
                            
                            Button {
                                text: "Export Chart"
                                onClicked: exportChart()
                            }
                        }
                        
                        // Chart canvas
                        ChartView {
                            id: chartCanvas
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            backgroundColor: "white"
                            
                            title: "Time-Current Characteristic Curves"
                            
                            legend.alignment: Qt.AlignBottom
                            legend.font.pixelSize: 12
                            
                            animationOptions: ChartView.NoAnimation
                            
                            LogValueAxis {
                                id: xAxis
                                titleText: "Current (A)"
                                min: 1
                                max: 10000
                                base: 10
                                labelFormat: "%.0f"
                                gridVisible: true
                            }
                            
                            LogValueAxis {
                                id: yAxis
                                titleText: "Time (s)"
                                min: 0.01
                                max: 10000
                                base: 10
                                labelFormat: "%.2f"
                                gridVisible: true
                            }
                            
                            LineSeries {
                                id: fuse25ASeries
                                name: "25A Fuse"
                                color: "#e74c3c"
                                width: 2
                                visible: show25AFuse.checked
                                axisX: xAxis
                                axisY: yAxis
                            }
                            
                            LineSeries {
                                id: fuse63ASeries
                                name: "63A Fuse"
                                color: "#3498db"
                                width: 2
                                visible: show63AFuse.checked
                                axisX: xAxis
                                axisY: yAxis
                            }
                            
                            ScatterSeries {
                                id: operatingPointsSeries
                                name: "Operating Points"
                                color: "#27ae60"
                                markerSize: 8
                                visible: showOperatingPoints.checked
                                axisX: xAxis
                                axisY: yAxis
                            }
                            
                            ScatterSeries {
                                id: inrushPointSeries
                                name: "Inrush Current"
                                color: "#f39c12"
                                markerSize: 8
                                visible: showOperatingPoints.checked
                                axisX: xAxis
                                axisY: yAxis
                            }
                            
                            ScatterSeries {
                                id: faultPointSeries
                                name: "Wind Fault"
                                color: "#e74c3c"
                                markerSize: 8
                                visible: showOperatingPoints.checked
                                axisX: xAxis
                                axisY: yAxis
                            }
                            
                            function updateChart() {
                                // Clear existing data
                                fuse25ASeries.clear()
                                fuse63ASeries.clear()
                                operatingPointsSeries.clear()
                                inrushPointSeries.clear()
                                faultPointSeries.clear()
                                
                                // Generate 25A fuse curve
                                if (show25AFuse.checked) {
                                    generateFuseCurve(fuse25ASeries, 25)
                                }
                                
                                // Generate 63A fuse curve
                                if (show63AFuse.checked) {
                                    generateFuseCurve(fuse63ASeries, 63)
                                }
                                
                                // Add operating points
                                if (showOperatingPoints.checked) {
                                    addOperatingPoints()
                                }
                            }
                            
                            function generateFuseCurve(series, rating) {
                                // Use real CEF fuse curve data from database
                                if (templateEngine) {
                                    try {
                                        // Get real fuse curve data from database as JSON
                                        var curveDataJson = templateEngine.getFuseCurveDataJson(rating)
                                        var curveData = JSON.parse(curveDataJson)
                                        
                                        if (curveData && curveData.length > 0) {
                                            // Clear existing data
                                            series.clear()
                                            
                                            // Use actual database data
                                            for (var i = 0; i < curveData.length; i++) {
                                                var multiplier = curveData[i].current_multiplier
                                                var time = curveData[i].melting_time
                                                var current = rating * multiplier
                                                
                                                // Only add points within chart bounds
                                                if (current >= xAxis.min && current <= xAxis.max && 
                                                    time >= yAxis.min && time <= yAxis.max) {
                                                    series.append(current, time)
                                                }
                                            }
                                            
                                            console.log("Generated " + rating + "A fuse curve with " + curveData.length + " real data points")
                                        } else {
                                            // Fallback to simplified model if no database data
                                            generateFuseCurveSimplified(series, rating)
                                        }
                                    } catch (error) {
                                        console.log("Error getting fuse curve data: " + error)
                                        // Fallback to simplified model
                                        generateFuseCurveSimplified(series, rating)
                                    }
                                } else {
                                    // No template engine available, use simplified model
                                    generateFuseCurveSimplified(series, rating)
                                }
                            }
                            
                            function generateFuseCurveSimplified(series, rating) {
                                // Simplified fuse curve generation (fallback)
                                for (var mult = 1.1; mult <= 100; mult += 0.2) {
                                    var current = rating * mult
                                    if (current > xAxis.max) break
                                    
                                    var time = getFuseTime(mult, rating)
                                    if (time < yAxis.min || time > yAxis.max) continue
                                    
                                    series.append(current, time)
                                }
                            }
                            
                            function getFuseTime(multiplier, rating) {
                                // Simplified fuse time-current characteristic (fallback)
                                // This is a basic model - real fuse data is preferred
                                if (multiplier < 1.1) return 10000
                                if (multiplier < 2) return 3600 / Math.pow(multiplier - 1, 2)
                                if (multiplier < 10) return 100 / Math.pow(multiplier, 1.5)
                                return 10 / Math.pow(multiplier, 2)
                            }
                            
                            function addOperatingPoints() {
                                // Get current system values
                                var hvFullLoad = parseFloat(hvFullLoadCurrent.text.replace(" A", "")) || 0
                                var inrush = parseFloat(inrushCurrent.text.replace(" A", "")) || 0
                                var windFault = parseFloat(windFaultCurrent.text.replace(" A", "")) || 0
                                
                                // Add operating points if they're within chart bounds
                                if (hvFullLoad > 0 && hvFullLoad >= xAxis.min && hvFullLoad <= xAxis.max) {
                                    operatingPointsSeries.append(hvFullLoad, 3600)
                                }
                                
                                if (inrush > 0 && inrush >= xAxis.min && inrush <= xAxis.max) {
                                    inrushPointSeries.append(inrush, 0.1)
                                }
                                
                                if (windFault > 0 && windFault >= xAxis.min && windFault <= xAxis.max) {
                                    faultPointSeries.append(windFault, 1.0)
                                }
                            }
                            
                            function autoScale() {
                                // Auto-scale chart based on current values
                                var hvFullLoad = parseFloat(hvFullLoadCurrent.text.replace(" A", "")) || 100
                                var inrush = parseFloat(inrushCurrent.text.replace(" A", "")) || 100
                                var windFault = parseFloat(windFaultCurrent.text.replace(" A", "")) || 100
                                
                                var maxCurrent = Math.max(hvFullLoad, inrush, windFault) * 2
                                var minCurrent = Math.min(hvFullLoad, inrush, windFault) * 0.5
                                
                                xAxis.max = Math.max(1000, maxCurrent)
                                xAxis.min = Math.max(1, minCurrent)
                                
                                updateChart()
                            }
                            
                            Component.onCompleted: {
                                updateChart()
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
        fileMode: FileDialog.SaveFile
        nameFilters: ["JSON files (*.json)"]
        onAccepted: {
            // Save configuration to selected file
            console.log("Saving config to:", selectedFile)
        }
    }
    
    FileDialog {
        id: saveReportDialog
        title: "Save Report"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Markdown files (*.md)", "Text files (*.txt)"]
        onAccepted: {
            // Save report to selected file
            console.log("Saving report to:", selectedFile)
        }
    }
    
    // Functions
    function generateAnalysisReport() {
        console.log("Generating analysis report...")
        
        // Collect input values and update system configuration
        var config = {
            system_config: {
                turbine_voltage: turbineVoltage.value,
                turbine_power: turbinePower.value * 1000, // Convert to W
                transformer_rating: transformerRating.value * 1000, // Convert to VA
                transformer_voltage_hv: parseFloat(transformerHV.currentText) * 1000, // Convert to V
                transformer_impedance: transformerImpedance.value / 1000.0, // Convert to decimal
                wind_fault_factor: windFaultFactor.value / 100.0, // Convert to decimal
                hv_fuse_rating: parseInt(hvFuseRating.currentText),
                incomer_fuse_rating: parseInt(incomerFuseRating.currentText)
            },
            protection_settings: {
                discrimination_time: discriminationTime.value / 100.0, // Convert to seconds
                safety_margin: safetyMargin.value / 100.0, // Convert to decimal
                coordination_ratio: coordinationRatio.value / 100.0, // Convert to decimal
                max_fault_current: maxFaultCurrent.value
            }
        }
        
        // Update system configuration in Python backend
        if (templateEngine) {
            templateEngine.updateSystemConfiguration(JSON.stringify(config))
            // Run the analysis
            templateEngine.analyzeFuseCoordination()
        } else {
            // Simulate analysis results for demonstration
            simulateAnalysisResults(config.system_config)
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
        
        // Refresh the chart
        chartCanvas.updateChart()
    }
    
    function exportChart() {
        console.log("Exporting chart...")
        // In a real implementation, this would save the chart as an image
        // For now, we'll just show the export dialog
        var timestamp = new Date().toISOString().replace(/[:.]/g, '-')
        console.log("Chart would be saved as: wind_turbine_protection_chart_" + timestamp + ".png")
    }
    
    function saveConfiguration() {
        saveConfigDialog.open()
    }
    
    function updateAnalysisDisplay() {
        if (!analysisResults) {
            console.log("No analysis results to display")
            return
        }
        
        try {
            // Update system currents display
            if (analysisResults.system_currents) {
                var currents = analysisResults.system_currents
                lvFullLoadCurrent.text = (currents.lv_full_load || 0).toFixed(1) + " A"
                hvFullLoadCurrent.text = (currents.hv_full_load || 0).toFixed(1) + " A"
                transformerSCCurrent.text = (currents.transformer_sc_current || 0).toFixed(0) + " A"
                windFaultCurrent.text = (currents.hv_fault_current || 0).toFixed(1) + " A"
                inrushCurrent.text = (currents.inrush_current || 0).toFixed(0) + " A"
            }
            
            // Update fuse analysis
            if (analysisResults.fuse_25a_analysis) {
                var fuse25a = analysisResults.fuse_25a_analysis
                fuse25AAnalysis.loading_factor = fuse25a.loading_factor || 0
                fuse25AAnalysis.full_load_time = fuse25a.full_load_time || 0
                fuse25AAnalysis.full_load_ok = fuse25a.full_load_ok || false
                fuse25AAnalysis.inrush_time = fuse25a.inrush_time || 0
                fuse25AAnalysis.inrush_ok = fuse25a.inrush_ok || false
                fuse25AAnalysis.fault_time = fuse25a.fault_time || 0
                fuse25AAnalysis.fault_ok = fuse25a.fault_ok || false
            }
            
            if (analysisResults.fuse_63a_analysis) {
                var fuse63a = analysisResults.fuse_63a_analysis
                fuse63AAnalysis.loading_factor = fuse63a.loading_factor || 0
                fuse63AAnalysis.full_load_time = fuse63a.full_load_time || 0
                fuse63AAnalysis.full_load_ok = fuse63a.full_load_ok || false
                fuse63AAnalysis.system_fault_time = fuse63a.system_fault_time || 0
                fuse63AAnalysis.system_fault_ok = fuse63a.system_fault_ok || false
            }
            
            // Update coordination status
            if (analysisResults.coordination_results) {
                var coord = analysisResults.coordination_results
                coordinationStatus.coordinated = coord.coordinated || false
                coordinationStatus.issues = coord.issues || []
            }
            
            // Update chart
            if (chartCanvas && chartCanvas.updateChart) {
                chartCanvas.updateChart()
            }
            
            console.log("Analysis display updated successfully")
            
        } catch (error) {
            console.error("Error updating analysis display:", error)
        }
    }
    
    function openDiscriminationChart() {
        // Auto-scale chart based on current values
        console.log("Auto-scaling chart...")
        chartCanvas.autoScale()
    }
    
    Component.onCompleted: {
        // Initialize with default analysis
        generateAnalysisReport()
    }
}
