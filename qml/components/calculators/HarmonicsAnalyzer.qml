import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../../components"
import HarmonicAnalysis 1.0
import SeriesHelper 1.0  // Import our new helper

Item {
    id: harmonicsCard

    property HarmonicAnalysisCalculator calculator: HarmonicAnalysisCalculator {}
    property SeriesHelper seriesHelper: SeriesHelper {}

    RowLayout {
        spacing: 10
        anchors.margins: 10
        anchors.fill: parent

        ColumnLayout {
            Layout.maximumWidth: 400
            Layout.alignment: Qt.AlignTop
            spacing: 10

            WaveCard {
                title: "Harmonic Components"
                Layout.fillWidth: true
                Layout.minimumHeight: 550

                ColumnLayout {
                    spacing: 10
                    
                    // Header row for magnitude and phase
                    RowLayout {
                        spacing: 10
                        Label { text: "Harmonic"; Layout.preferredWidth: 120; font.bold: true }
                        Label { text: "Magnitude"; Layout.preferredWidth: 120; font.bold: true }
                        Label { text: "Phase"; Layout.preferredWidth: 120; font.bold: true }
                    }
                    
                    Repeater {
                        model: [1, 3, 5, 7, 11, 13]
                        delegate: RowLayout {
                            spacing: 10
                            Label { 
                                text: `${modelData}${modelData === 1 ? "st" : modelData === 3 ? "rd" : "th"} Harmonic:` 
                                Layout.preferredWidth: 120 
                                ToolTip.text: "Component frequency = " + modelData + " × fundamental frequency"
                                ToolTip.visible: harmonicMouseArea.containsMouse
                                ToolTip.delay: 500
                                
                                MouseArea {
                                    id: harmonicMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                            
                            TextField {
                                id: magnitudeField
                                placeholderText: modelData === 1 ? "100%" : "0%"
                                enabled: modelData !== 1
                                validator: DoubleValidator { bottom: 0; top: 100 }
                                
                                // Add throttling to avoid excessive updates
                                property bool updatePending: false
                                onTextChanged: {
                                    if(text) {
                                        updatePending = true
                                        updateTimer.restart()
                                    }
                                }
                                
                                Timer {
                                    id: updateTimer
                                    interval: 300 // 300ms throttle
                                    running: false
                                    repeat: false
                                    onTriggered: {
                                        if (magnitudeField.text) {
                                            calculator.setHarmonic(
                                                modelData, 
                                                parseFloat(magnitudeField.text), 
                                                phaseField.text ? parseFloat(phaseField.text) : 0
                                            )
                                        }
                                        magnitudeField.updatePending = false
                                    }
                                }
                                
                                Layout.preferredWidth: 120
                                
                                ToolTip.text: "Enter magnitude as percentage of fundamental"
                                ToolTip.visible: magnitudeMouseArea.containsMouse
                                ToolTip.delay: 500
                                
                                MouseArea {
                                    id: magnitudeMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    propagateComposedEvents: true
                                    onPressed: function(mouse) { mouse.accepted = false }
                                }
                            }
                            
                            TextField {
                                id: phaseField
                                placeholderText: "0°"
                                enabled: modelData !== 1
                                validator: DoubleValidator { bottom: -180; top: 180 }
                                
                                // Add throttling to avoid excessive updates
                                property bool updatePending: false
                                onTextChanged: {
                                    if(text) {
                                        updatePending = true
                                        phaseUpdateTimer.restart()
                                    }
                                }
                                
                                Timer {
                                    id: phaseUpdateTimer
                                    interval: 300 // 300ms throttle
                                    running: false
                                    repeat: false
                                    onTriggered: {
                                        if (phaseField.text) {
                                            calculator.setHarmonic(
                                                modelData, 
                                                magnitudeField.text ? parseFloat(magnitudeField.text) : 0,
                                                parseFloat(phaseField.text)
                                            )
                                        }
                                        phaseField.updatePending = false
                                    }
                                }
                                
                                Layout.preferredWidth: 120
                                
                                ToolTip.text: "Enter phase angle in degrees (-180° to 180°)"
                                ToolTip.visible: phaseMouseArea.containsMouse
                                ToolTip.delay: 500
                                
                                MouseArea {
                                    id: phaseMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    propagateComposedEvents: true
                                    onPressed: function(mouse) { mouse.accepted = false }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.margins: 10
                        height: 1
                        color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
                    }

                    // Reset button
                    Button {
                        text: "Reset to Defaults"
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: {
                            // Reset all harmonics to default values
                            calculator.resetHarmonics()
                            
                            // Clear all text fields - using recursive function to find all TextFields
                            function clearTextFields(parent) {
                                // Check all children of this component
                                for (let i = 0; i < parent.children.length; i++) {
                                    let child = parent.children[i]
                                    
                                    // If it's a TextField, clear its text
                                    if (child instanceof TextField) {
                                        child.text = ""
                                    }
                                    
                                    // If it has children, recursively search its children too
                                    if (child.children && child.children.length > 0) {
                                        clearTextFields(child)
                                    }
                                }
                            }
                            
                            // Start the recursive search from the root item
                            clearTextFields(harmonicsCard)
                        }
                    }

                    GridLayout {
                        columns: 2
                        rowSpacing: 10
                        columnSpacing: 10

                        Label { text: "Results:" ; Layout.columnSpan: 2 ; font.bold: true ; font.pixelSize: 16}

                        Label { 
                            text: "THD:" 
                            Layout.preferredWidth: 120 
                            ToolTip.text: "Total Harmonic Distortion - measures the amount of harmonic content"
                            ToolTip.visible: thdMouseArea.containsMouse
                            ToolTip.delay: 500
                            
                            MouseArea {
                                id: thdMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                        Label { text: calculator.thd.toFixed(2) + "%" }

                        Label { 
                            text: "Crest Factor:" 
                            Layout.preferredWidth: 120 
                            ToolTip.text: "Ratio of peak to RMS value - indicates waveform distortion"
                            ToolTip.visible: crestMouseArea.containsMouse
                            ToolTip.delay: 500
                            
                            MouseArea {
                                id: crestMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                        Label { text: calculator.crestFactor.toFixed(2) }
                        
                        Label { text: "Form Factor:" ; Layout.preferredWidth: 120 }
                        Label { text: calculator.formFactor ? calculator.formFactor.toFixed(2) : "1.11" }
                    }
                }
            }
            
            // Export buttons
            Button {
                text: "Export Data"
                Layout.fillWidth: true
                onClicked: {
                    // Call a method in your calculator to export data
                    calculator.exportData()
                }
                ToolTip.text: "Export harmonic data to CSV"
                ToolTip.visible: exportMouseArea.containsMouse
                ToolTip.delay: 500
                
                MouseArea {
                    id: exportMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onPressed: function(mouse) { mouse.accepted = false }
                }
            }
            
            // Profiling controls
            GroupBox {
                title: "Performance Analysis"
                Layout.fillWidth: true
                
                ColumnLayout {
                    width: parent.width
                    
                    CheckBox {
                        id: profilingCheckbox
                        text: "Enable Performance Profiling"
                        checked: calculator.profilingEnabled
                        onCheckedChanged: {
                            calculator.enableProfiling(checked)
                            
                            // Start frame profiling timer when enabled
                            if (checked) {
                                frameTimer.start()
                            } else {
                                frameTimer.stop()
                            }
                        }
                    }
                    
                    // Timer to measure frame times
                    Timer {
                        id: frameTimer
                        interval: 200  // 5x per second is enough
                        repeat: true
                        running: false
                        onTriggered: {
                            if (calculator.profilingEnabled) {
                                // Fix: Call the method directly on calculator instead of using getProfiler()
                                calculator.recordFrameTime()
                            }
                        }
                    }
                    
                    // Remove the separate getProfiler function since we'll access directly
                    
                    RowLayout {
                        Button {
                            text: "Clear Data"
                            enabled: calculator.profilingEnabled
                            onClicked: calculator.clearProfilingData()
                            Layout.fillWidth: true
                        }
                        
                        Button {
                            text: "Show Report"
                            enabled: calculator.profilingEnabled
                            onClicked: calculator.printProfilingSummary()
                            Layout.fillWidth: true
                        }
                    }
                    
                    CheckBox {
                        id: detailedLoggingCheckbox
                        text: "Detailed Performance Logging"
                        checked: false
                        onCheckedChanged: {
                            calculator.setDetailedLogging(checked)
                        }
                    }
                    
                    Label {
                        text: "Performance data will be printed to console"
                        font.italic: true
                        font.pixelSize: 10
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        // Right Panel - Visualizations
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Waveform Chart
            WaveCard {
                id: waveformCard // Add ID for reference
                title: "Waveform"
                Layout.fillHeight: true
                Layout.fillWidth: true

                // Define the function at this level so it can be accessed from anywhere
                function updateWaveform() {
                    // Skip updates if not visible for better performance
                    if (!waveformCard.visible) {
                        return;
                    }
                    
                    var points = calculator.waveform;
                    var fundamentalData = calculator.fundamentalWaveform;
                    
                    // Skip update if data hasn't changed
                    if (!points || points.length === 0) {
                        return;
                    }
                    
                    var maxY = 0;
                    
                    // Find maximum magnitude for scaling with validation
                    if (points && points.length > 0) {
                        for (var i = 0; i < points.length; i++) {
                            // Check for valid numeric values
                            if (isFinite(points[i])) {
                                maxY = Math.max(maxY, Math.abs(points[i]));
                            }
                            
                            if (fundamentalData && i < fundamentalData.length && isFinite(fundamentalData[i])) {
                                maxY = Math.max(maxY, Math.abs(fundamentalData[i]));
                            }
                        }
                    }
                    
                    // Ensure maxY is a valid value before setting axis range
                    if (!isFinite(maxY) || maxY <= 0) {
                        maxY = 100;  // Set a reasonable default if invalid
                    }
                    
                    // Set axis range with 20% padding
                    var paddedMax = Math.ceil(maxY * 1.2);
                    waveformChart.axisY.min = -paddedMax;
                    waveformChart.axisY.max = paddedMax;
                    
                    // Adjust point density based on available width
                    var chartWidth = waveformChart.width;
                    
                    // Use a safe minimum width
                    chartWidth = Math.max(100, chartWidth);
                    
                    // More aggressive downsampling for better performance
                    // Target 1 point every 3-4 pixels for good visual quality without lag
                    var maxPoints = Math.min(Math.floor(chartWidth / 3), 100);
                    var pointSpacing = Math.max(1, Math.floor(points.length / maxPoints));
                    
                    // Use the efficient series filling methods
                    var xValues = [];
                    var yValues = [];
                    var fundValues = [];
                    
                    // Add null check to avoid errors
                    if (points && points.length > 0) {
                        for (var i = 0; i < points.length; i += pointSpacing) {
                            if (isFinite(points[i])) {  // Only add valid points
                                xValues.push(i * (360/points.length));
                                yValues.push(points[i]);
                            }
                            
                            if (fundamentalData && i < fundamentalData.length && isFinite(fundamentalData[i])) {
                                fundValues.push(fundamentalData[i]);
                            }
                        }
                        
                        // Fill both series efficiently with the reduced dataset
                        if (xValues.length > 0 && yValues.length > 0) {
                            seriesHelper.fillSeriesFromArrays(waveformSeries, xValues, yValues);
                            
                            if (fundValues.length === xValues.length) {
                                seriesHelper.fillSeriesFromArrays(fundamentalSeries, xValues, fundValues);
                            }
                        }
                    }
                }

                // Use a timer to batch UI updates and defer them slightly
                Timer {
                    id: updateWaveformTimer
                    interval: 50  // Increase from 5ms to 50ms for smoother performance
                    running: false
                    repeat: false
                    onTriggered: {
                        waveformCard.updateWaveform(); // Use proper reference
                    }
                }

                ChartView {
                    id: waveformChart // Add ID for reference
                    anchors.fill: parent
                    antialiasing: false  // Disable antialiasing for better performance
                    legend.visible: true
                    legend.alignment: Qt.AlignBottom

                    theme: Universal.theme
                    
                    // Remove invalid renderStrategy property
                    // renderStrategy: ChartView.RenderStrategy.OpenGL
                    
                    // Add animation options control
                    property bool animationsEnabled: false
                    
                    ValueAxis {
                        id: axisX
                        min: 0
                        max: 360
                        titleText: "Angle (degrees)"
                        gridVisible: true
                        labelsAngle: 0
                        labelFormat: "%d"
                    }
                    
                    // Add visibility control
                    CheckBox {
                        id: showLabels
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 5
                        text: "Show degree labels"
                        checked: true
                        z: 10
                    }

                    ValueAxis {
                        id: axisY
                        min: -200
                        max: 200
                        titleText: "Magnitude (pu)"
                        gridVisible: true
                    }

                    LineSeries {
                        id: waveformSeries
                        name: "Combined Waveform"
                        axisX: axisX
                        axisY: axisY
                        width: 2
                        useOpenGL: true  // Enable OpenGL for series
                        
                        // Disable animations for better performance
                        pointsVisible: false
                    }
                    
                    LineSeries {
                        id: fundamentalSeries
                        name: "Fundamental"
                        axisX: axisX
                        axisY: axisY
                        color: "lightblue"
                        width: 1.5
                        visible: fundamentalCheckbox.checked  // Fix reference to checkbox
                        useOpenGL: true  // Enable OpenGL for series
                        
                        // Disable animations for better performance
                        pointsVisible: false
                    }

                    // Add resolution control 
                    ComboBox {
                        id: resolutionSelector
                        anchors {
                            left: parent.left
                            top: parent.top
                            margins: 10
                        }
                        width: 150
                        model: ["High (500 points)", "Medium (250 points)", "Low (100 points)"]
                        currentIndex: 0
                        
                        onCurrentIndexChanged: {
                            // Set resolution based on selection
                            let resolutions = [500, 250, 100];
                            calculator.updateResolution(resolutions[currentIndex]);
                        }
                        
                        ToolTip.text: "Adjust resolution for performance"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                    }

                    // Control UI performance with more granularity - moved below resolution control
                    ComboBox {
                        id: performanceMode
                        anchors {
                            left: parent.left
                            top: resolutionSelector.bottom
                            margins: 10
                        }
                        width: 150
                        model: ["Maximum Performance", "Balanced", "Maximum Quality"]
                        currentIndex: 0
                        
                        onCurrentIndexChanged: {
                            // Adjust app behavior based on performance mode
                            if (currentIndex === 0) { // Maximum Performance
                                useAntialiasing.checked = false;
                                updateWaveformTimer.interval = 50;
                                updateHarmonicsTimer.interval = 50;
                                resolutionSelector.currentIndex = 2; // Low resolution
                                waveformChart.updateAxes();
                            }
                            else if (currentIndex === 1) { // Balanced
                                useAntialiasing.checked = false;
                                updateWaveformTimer.interval = 25;
                                updateHarmonicsTimer.interval = 25;
                                resolutionSelector.currentIndex = 1; // Medium resolution
                                waveformChart.updateAxes();
                            }
                            else { // Maximum Quality
                                useAntialiasing.checked = true;
                                updateWaveformTimer.interval = 5;
                                updateHarmonicsTimer.interval = 5;
                                resolutionSelector.currentIndex = 0; // High resolution
                                waveformChart.updateAxes();
                            }
                        }
                        
                        ToolTip.text: "Select overall performance mode"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                    }

                    // Control for showing fundamental component - fix ID
                    CheckBox {
                        id: fundamentalCheckbox // Changed from showFundamentalCheckbox
                        text: "Show Fundamental"
                        checked: false
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: 10
                        }
                        
                        onCheckedChanged: {
                            fundamentalSeries.visible = checked
                        }
                    }

                    // Add performance controls
                    Row {
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                            margins: 10
                        }
                        spacing: 5
                        
                        CheckBox {
                            id: useAntialiasing
                            text: "Antialiasing"
                            checked: false
                            onCheckedChanged: {
                                waveformChart.antialiasing = checked
                                harmonicChart.antialiasing = checked
                            }
                        }
                        
                        CheckBox {
                            id: useAnimations
                            text: "Animations"
                            checked: false
                            onCheckedChanged: {
                                waveformChart.animationsEnabled = checked
                            }
                        }
                    }

                    // Add visibility binding for performance
                    visible: parent.visible && waveformCard.visible
                    
                    // Use timer-based axis updates instead of direct binding for performance
                    function updateAxes() {
                        // Only update when visible
                        if (!visible) return;
                        
                        // Skip non-essential visual updates for better performance
                        axisX.labelsVisible = showLabels.checked && useAntialiasing.checked;
                        axisX.minorGridVisible = useAntialiasing.checked;
                        axisY.minorGridVisible = useAntialiasing.checked;
                    }
                    
                    // Apply axis updates on visibility change
                    onVisibleChanged: {
                        if (visible) updateAxes();
                    }

                    // Update waveform when it changes - optimize updates using the helper
                    Connections {
                        target: calculator
                        
                        // Use a combined connection for calculationsComplete
                        function onCalculationsComplete() {
                            // Use a single shot timer to defer the update slightly
                            // This allows the UI thread to process other events first
                            updateWaveformTimer.start();
                            // Fix reference to timer in harmonicCard
                            if (harmonicCard && harmonicCard.updateHarmonicsTimer) {
                                harmonicCard.updateHarmonicsTimer.start();
                            }
                        }
                        
                        function onWaveformChanged() {
                            // Only update waveform, not harmonics
                            updateWaveformTimer.start();
                        }
                    }
                }
            }

            WaveCard {
                id: harmonicCard // Add ID for reference
                Layout.fillHeight: true
                Layout.fillWidth: true
                title: "Harmonic Spectrum"

                // Define function at this level
                function updateHarmonics() {
                    var data = calculator.individualDistortion;
                    var phaseData = calculator.harmonicPhases;
                    var maxY = 0;
                    
                    harmonicChart.harmonicSeries.clear();
                    harmonicChart.phaseAngleSeries.clear();
                    
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
                    harmonicChart.spectrumAxisY.max = isFinite(paddedMax) ? paddedMax : 120;
                    
                    // Update bar series with validation
                    if (data && data.length > 0) {
                        // Make a filtered copy of the data with only valid values
                        var validData = [];
                        for (var i = 0; i < data.length; i++) {
                            validData.push(isFinite(data[i]) ? data[i] : 0);
                        }
                        harmonicChart.harmonicSeries.append("Magnitude", validData);
                    }
                    
                    // Update phase series with validation
                    if (phaseData && phaseData.length > 0) {
                        var harmOrder = [1, 3, 5, 7, 11, 13];
                        
                        for (var i = 0; i < harmOrder.length && i < phaseData.length; i++) {
                            // Only add valid phase values
                            if (isFinite(phaseData[i])) {
                                harmonicChart.phaseAngleSeries.append(i + 0.5, phaseData[i]);
                            } else {
                                harmonicChart.phaseAngleSeries.append(i + 0.5, 0);  // Use 0 for invalid values
                            }
                        }
                    }
                }

                // Use timer to batch harmonics UI updates too
                Timer {
                    id: updateHarmonicsTimer // This is the timer we'll keep
                    interval: 50  // Increase to 50ms for less frequent updates
                    running: false
                    repeat: false
                    onTriggered: {
                        // Add a slight delay effect for animation when animations are enabled
                        if (useAnimations && useAnimations.checked) {
                            // Create a subtle animated effect by updating in stages
                            harmonicCard.opacity = 0.9;
                            harmonicCard.updateHarmonics(); 
                            harmonicCard.opacity = 1.0;
                        } else {
                            harmonicCard.updateHarmonics();
                        }
                    }
                }

                // Harmonic Spectrum
                ChartView {
                    id: harmonicChart
                    anchors.fill: parent
                    antialiasing: false  // Disable antialiasing for better performance
                    legend.visible: true
                    legend.alignment: Qt.AlignBottom
                    theme: Universal.theme
                    
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
                        // Remove non-existent property
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
                            visible: showPhaseCheckbox.checked
                            gridVisible: false
                        }
                        
                        axisY: phaseAxisY
                        visible: showPhaseCheckbox.checked
                        color: "red"
                        width: 2
                        pointsVisible: false  // Disable point rendering for better performance
                    }

                    // Optimize spectrum updates
                    Connections {
                        target: calculator
                        function onHarmonicsChanged() {
                            // Use the timer to defer the update
                            harmonicCard.updateHarmonicsTimer.start(); // Updated reference
                        }
                    }

                    // Initialize with default values
                    Component.onCompleted: {
                        harmonicSeries.append("Magnitude", calculator.individualDistortion)
                    }
                    
                    // Control for showing phase angles
                    CheckBox {
                        id: showPhaseCheckbox
                        text: "Show Phase Angles"
                        checked: false
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: 10
                        }
                        
                        onCheckedChanged: {
                            phaseAngleSeries.visible = checked
                            phaseAxisY.visible = checked
                        }
                    }

                    // Control performance settings globally - replace with alternative approach
                    Connections {
                        target: useAnimations
                        function onCheckedChanged() {
                            // Instead of setting an animation duration, we'll update the chart in other ways
                            // For example, we might trigger a full refresh of the chart when animations are enabled
                            if (useAnimations.checked) {
                                // For enhanced display when animations are on, we might add a slight delay
                                // to simulate an animated effect
                                harmonicChart.opacity = 0.9;
                                harmonicChart.opacity = 1.0;
                            }
                        }
                    }
                }
            }
        }
    }
}
