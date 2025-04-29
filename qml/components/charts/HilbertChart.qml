import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import QtQuick.Controls.Universal
import Qt.labs.platform

Item {
    id: root

    property var calculator: null
    property var timeDomain: []
    property var transformResult: []  // Will contain envelope or combined envelope+signal data
    property var phaseResult: []      // Contains phase data
    property var frequencies: []      // Time values for consistent interface with TransformChart
    property string displayMode: "Envelope" // "Envelope", "Phase", or "Envelope & Phase"
    
    property color signalColor: "#2196F3"      // Blue for original signal
    property color envelopeColor: "#FF5722"    // Orange-red for envelope
    property color phaseColor: "#4CAF50"       // Green for phase
    property color envelopeAreaColor: Qt.rgba(0.98, 0.35, 0.13, 0.25)  // Semi-transparent orange-red
    property color gridColor: "#303030"
    property color textColor: "#e0e0e0"
    property color backgroundColor: "#1e1e1e"
    
    property bool darkMode: Universal.theme === Universal.Dark
    property bool highPerformanceMode: performanceModeCheckbox.checked
    
    property real animationDuration: 300
    property bool useOpenGL: false  // Disabled by default to prevent framebuffer errors

    readonly property bool isLinux: Qt.platform.os === "linux"
    readonly property bool isWindows: Qt.platform.os === "windows"
    readonly property bool isMacos: Qt.platform.os === "darwin"

    // Ensure series are initialized properly
    property var timeSeries: null
    property var envelopeSeries: null
    property var phaseSeries: null
    property var originalHilbertSeries: null
    property var lowerEnvelopeSeries: null
    property var envelopeAreaSeries: null
    
    // Help popup component
    property Popup helpPopup: Popup {
        id: hilbertChartHelpPopup
        width: Math.min(600, parent.width * 0.8)
        height: Math.min(400, parent.height * 0.7)
        anchors.centerIn: parent
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            Label {
                text: "Hilbert Transform Visualization"
                font.pixelSize: 18
                font.bold: true
                Layout.fillWidth: true
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                TextArea {
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.RichText
                    text: "<p><b>About the Hilbert Transform Visualization:</b></p>" +
                          "<p>This chart displays the Hilbert transform components of the signal:</p>" +
                          "<ul>" +
                          "<li><font color='" + root.signalColor + "'>Blue line</font>: Original signal</li>" +
                          "<li><font color='" + root.envelopeColor + "'>Orange line</font>: Envelope (magnitude of analytic signal)</li>" +
                          "<li><font color='" + root.phaseColor + "'>Green line</font>: Phase information</li>" +
                          "<li><font color='" + root.envelopeAreaColor + "'>Shaded area</font>: Region between positive and negative envelope</li>" +
                          "</ul>" +
                          "<p><b>Shading:</b> The orange shaded area represents the symmetric envelope around the original signal. This shading helps visualize the amplitude modulation of the signal. You can adjust the opacity of this shading using the slider.</p>" +
                          "<p><b>Display Modes:</b></p>" +
                          "<ul>" +
                          "<li><b>Envelope:</b> Shows only the amplitude envelope</li>" +
                          "<li><b>Phase:</b> Shows only the instantaneous phase</li>" +
                          "<li><b>Envelope & Phase:</b> Shows both envelope and phase along with the original signal</li>" +
                          "</ul>" +
                          "<p><b>Tips:</b></p>" +
                          "<ul>" +
                          "<li>Try the <b>Chirp</b> or <b>Sinusoidal</b> signal types for the most informative visualization</li>" +
                          "<li>Use a sampling rate between 10-100 Hz for more pronounced features</li>" +
                          "<li>The shading helps identify the envelope boundaries around the original signal</li>" +
                          "</ul>"
                    
                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
            
            Button {
                text: "Close"
                Layout.alignment: Qt.AlignRight
                onClicked: hilbertChartHelpPopup.close()
            }
        }
    }

    onDarkModeChanged: updateThemeColors()
    onTimeDomainChanged: Qt.callLater(updateCharts)
    onTransformResultChanged: Qt.callLater(updateCharts)
    onPhaseResultChanged: Qt.callLater(updateCharts)
    onDisplayModeChanged: {
        Qt.callLater(updateCharts)
        updateSeriesVisibility()
    }

    // Component initialization
    Component.onCompleted: {
        // Initialize charts and series
        initializeCharts();
        updateThemeColors();
        // Schedule chart update after a slight delay to ensure components are ready
        Qt.callLater(updateCharts);
    }

    ColumnLayout {
        anchors.fill: parent

        // Time Domain Chart (Original Signal)
        ChartView {
            id: timeDomainChart
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: parent.height / 2
            antialiasing: !highPerformanceMode
            animationOptions: ChartView.NoAnimation
            legend.visible: legendCheckBox.checked
            backgroundColor: root.backgroundColor
            theme: root.darkMode ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
            
            ValueAxis {
                id: timeAxisX
                min: 0
                max: 5
                labelFormat: "%.1f"
                labelsColor: root.textColor
                gridLineColor: root.gridColor
                titleText: "Time (s)"
                titleVisible: true
                titleFont.pixelSize: 12
                titleFont.bold: true
                tickCount: highPerformanceMode ? 6 : 11
            }
            
            ValueAxis {
                id: timeAxisY
                min: -2
                max: 2
                labelFormat: "%.1f"
                labelsColor: root.textColor
                gridLineColor: root.gridColor
                titleText: "Amplitude"
                titleVisible: true
                titleFont.pixelSize: 12
                titleFont.bold: true
                tickCount: highPerformanceMode ? 6 : 11
            }
        }

        // Hilbert Transform Chart
        ChartView {
            id: hilbertChart
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: parent.height / 2
            antialiasing: !highPerformanceMode
            animationOptions: ChartView.NoAnimation
            legend.visible: legendCheckBox.checked
            backgroundColor: root.backgroundColor
            theme: root.darkMode ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
            
            ValueAxis {
                id: hilbertAxisX
                min: 0
                max: 5
                labelFormat: "%.1f"
                labelsColor: root.textColor
                gridLineColor: root.gridColor
                titleText: "Time (s)"
                titleVisible: true
                titleFont.pixelSize: 12
                titleFont.bold: true
                tickCount: highPerformanceMode ? 6 : 11
            }
            
            ValueAxis {
                id: hilbertAxisY
                min: -2
                max: 2
                labelFormat: "%.1f"
                labelsColor: root.textColor
                gridLineColor: root.gridColor
                titleText: displayMode.includes("Phase") && !displayMode.includes("Envelope") ? "Phase (rad)" : "Amplitude"
                titleVisible: true
                titleFont.pixelSize: 12
                titleFont.bold: true
                tickCount: highPerformanceMode ? 6 : 11
            }
        }

        RowLayout {
            Layout.fillWidth: true
            
            Label { 
                text: "Display Mode:" 
                font.pixelSize: 12
            }
            
            ComboBox {
                id: displayModeCombo
                model: ["Envelope", "Phase", "Envelope & Phase"]
                implicitWidth: 150
                currentIndex: {
                    if (root.displayMode === "Envelope") return 0;
                    if (root.displayMode === "Phase") return 1;
                    return 2;
                }
                
                onCurrentTextChanged: {
                    root.displayMode = currentText;
                }
            }
            
            Label { 
                text: "Legend:" 
                font.pixelSize: 12
            }
            
            CheckBox {
                id: legendCheckBox
                checked: true
                
                ToolTip.text: "Show/hide legend"
                ToolTip.visible: hovered
                ToolTip.delay: 500
            }
            
            Label { 
                text: "Performance:" 
                font.pixelSize: 12
            }
            
            CheckBox {
                id: performanceModeCheckbox
                checked: false
                
                ToolTip.text: "Optimize rendering for better performance"
                ToolTip.visible: hovered
                ToolTip.delay: 500
                
                onCheckedChanged: {
                    Qt.callLater(updateCharts);
                }
            }
            
            Label { 
                text: "Shading:" 
                font.pixelSize: 12
            }
            
            Slider {
                id: shadingOpacitySlider
                from: 0
                to: 50
                value: 25
                stepSize: 1
                implicitWidth: 100
                
                ToolTip {
                    parent: shadingOpacitySlider.handle
                    visible: shadingOpacitySlider.pressed
                    text: shadingOpacitySlider.value.toFixed(0) + "%"
                }
                
                onValueChanged: {
                    // Update opacity of envelope area shading
                    root.envelopeAreaColor = Qt.rgba(0.98, 0.35, 0.13, value / 100);
                    updateThemeColors();
                }
            }
            
            Label { Layout.fillWidth: true }
            
            Button {
                id: helpButton
                icon.source: "../../../icons/rounded/help.svg"
                text: "Help"
                
                ToolTip.text: "Hilbert chart visualization guide"
                ToolTip.visible: hovered
                ToolTip.delay: 500
                
                onClicked: {
                    helpPopup.open()
                }
            }
            
            Button {
                text: "Refresh"
                icon.source: "../../../icons/rounded/refresh.svg"
                
                ToolTip.text: "Refresh chart data"
                ToolTip.visible: hovered
                ToolTip.delay: 500
                
                onClicked: {
                    if (calculator) {
                        calculator.calculate();
                    }
                }
            }
        }
    }

    // Initialize charts and series
    function initializeCharts() {
        try {
            // Create time domain series
            if (!timeSeries) {
                timeSeries = timeDomainChart.createSeries(ChartView.SeriesTypeLine, "Original Signal", timeAxisX, timeAxisY);
                timeSeries.color = root.signalColor;
                timeSeries.width = highPerformanceMode ? 1 : 2;
                timeSeries.useOpenGL = false; // Disable OpenGL to avoid framebuffer issues
            }

            // Create Hilbert transform series
            if (!envelopeSeries) {
                envelopeSeries = hilbertChart.createSeries(ChartView.SeriesTypeLine, "Envelope", hilbertAxisX, hilbertAxisY);
                envelopeSeries.color = root.envelopeColor;
                envelopeSeries.width = highPerformanceMode ? 1 : 2.5;
                envelopeSeries.useOpenGL = false;
                envelopeSeries.visible = displayMode.includes("Envelope");
            }

            if (!phaseSeries) {
                phaseSeries = hilbertChart.createSeries(ChartView.SeriesTypeLine, "Phase", hilbertAxisX, hilbertAxisY);
                phaseSeries.color = root.phaseColor;
                phaseSeries.width = highPerformanceMode ? 1 : 2;
                phaseSeries.useOpenGL = false;
                phaseSeries.visible = displayMode.includes("Phase");
            }

            if (!originalHilbertSeries) {
                originalHilbertSeries = hilbertChart.createSeries(ChartView.SeriesTypeLine, "Original Signal", hilbertAxisX, hilbertAxisY);
                originalHilbertSeries.color = root.signalColor;
                originalHilbertSeries.width = highPerformanceMode ? 1 : 2;
                originalHilbertSeries.useOpenGL = false;
                originalHilbertSeries.visible = displayMode === "Envelope & Phase";
            }

            if (!lowerEnvelopeSeries) {
                lowerEnvelopeSeries = hilbertChart.createSeries(ChartView.SeriesTypeLine, "Lower Bound", hilbertAxisX, hilbertAxisY);
                lowerEnvelopeSeries.color = "transparent";
                lowerEnvelopeSeries.width = 0;
                lowerEnvelopeSeries.useOpenGL = false;
                lowerEnvelopeSeries.visible = false;
            }

            // Create area series for envelope visualization in a safe way
            if (displayMode.includes("Envelope") && !envelopeAreaSeries) {
                try {
                    envelopeAreaSeries = hilbertChart.createSeries(ChartView.SeriesTypeArea, "Envelope Area", hilbertAxisX, hilbertAxisY);
                    envelopeAreaSeries.upperSeries = envelopeSeries;
                    envelopeAreaSeries.lowerSeries = lowerEnvelopeSeries;
                    envelopeAreaSeries.color = root.envelopeAreaColor;
                    envelopeAreaSeries.borderColor = "transparent";
                    envelopeAreaSeries.borderWidth = 0;
                    envelopeAreaSeries.opacity = 1.0;
                    envelopeAreaSeries.visible = displayMode.includes("Envelope");
                } catch (e) {
                    console.error("Could not create area series:", e);
                }
            }
            
            // Ensure proper visibility of series based on display mode
            updateSeriesVisibility();
            
        } catch (e) {
            console.error("Error initializing charts:", e);
        }
    }

    function updateCharts() {
        try {
            updateTimeDomainChart();
            updateHilbertChart();
            
            // Ensure proper visibility of series based on display mode
            updateSeriesVisibility();
            
            // Update axis title based on display mode
            if (hilbertAxisY) {
                hilbertAxisY.titleText = displayMode.includes("Phase") && !displayMode.includes("Envelope") ? 
                                        "Phase (rad)" : "Amplitude";
            }
        } catch (e) {
            console.error("Error updating charts:", e);
        }
    }

    function updateTimeDomainChart() {
        try {
            if (!timeSeries || !timeDomain || timeDomain.length === 0) return;
            
            // Clear series
            timeSeries.clear();
            
            let minY = Number.MAX_VALUE;
            let maxY = -Number.MAX_VALUE;
            let maxX = 0;
            
            // Determine stride for performance mode
            let stride = 1;
            if (highPerformanceMode) {
                if (timeDomain.length > 10000) stride = Math.max(1, Math.floor(timeDomain.length / 1000));
                else if (timeDomain.length > 5000) stride = Math.max(1, Math.floor(timeDomain.length / 750));
                else if (timeDomain.length > 1000) stride = Math.max(1, Math.floor(timeDomain.length / 500));
            }
            
            // Process time domain data based on its format
            if (timeDomain.length > 0) {
                if (typeof timeDomain[0] === 'object' && 'x' in timeDomain[0] && 'y' in timeDomain[0]) {
                    for (let i = 0; i < timeDomain.length; i += stride) {
                        let point = timeDomain[i];
                        if (point && isFinite(point.x) && isFinite(point.y)) {
                            timeSeries.append(point.x, point.y);
                            minY = Math.min(minY, point.y);
                            maxY = Math.max(maxY, point.y);
                            maxX = Math.max(maxX, point.x);
                        }
                    }
                } else if (Array.isArray(timeDomain[0])) {
                    // Other array formats
                    for (let i = 0; i < timeDomain.length; i += stride) {
                        if (timeDomain[i] && timeDomain[i].length >= 2 && 
                            isFinite(timeDomain[i][0]) && isFinite(timeDomain[i][1])) {
                            timeSeries.append(timeDomain[i][0], timeDomain[i][1]);
                            minY = Math.min(minY, timeDomain[i][1]);
                            maxY = Math.max(maxY, timeDomain[i][1]);
                            maxX = Math.max(maxX, timeDomain[i][0]);
                        }
                    }
                } else if (typeof timeDomain[0] === 'number') {
                    for (let i = 0; i < timeDomain.length; i += stride) {
                        if (isFinite(timeDomain[i])) {
                            timeSeries.append(i / 20, timeDomain[i]);
                            minY = Math.min(minY, timeDomain[i]);
                            maxY = Math.max(maxY, timeDomain[i]);
                        }
                    }
                    maxX = (timeDomain.length - 1) / 20;
                }
            }
            
            // Update axis limits for better visualization
            if (minY !== Number.MAX_VALUE) {
                timeAxisX.min = 0;
                timeAxisX.max = maxX > 0 ? maxX : 5;
                
                const yRange = Math.max(Math.abs(minY), Math.abs(maxY)) * 1.2;
                timeAxisY.min = -yRange || -2;
                timeAxisY.max = yRange || 2;
            }
        } catch (e) {
            console.error("Error updating time domain chart:", e);
        }
    }

    function updateHilbertChart() {
        try {
            // Check if series are initialized
            if (!envelopeSeries || !phaseSeries || !originalHilbertSeries || !lowerEnvelopeSeries) {
                console.log("Series not initialized, reinitializing...");
                initializeCharts();
                return;
            }
            
            // Clear existing data
            envelopeSeries.clear();
            phaseSeries.clear();
            originalHilbertSeries.clear();
            lowerEnvelopeSeries.clear();
            
            if (!transformResult || transformResult.length === 0) return;
            
            let minY = Number.MAX_VALUE;
            let maxY = -Number.MAX_VALUE;
            let maxX = 0;
            
            // Determine stride for performance mode
            let stride = 1;
            if (highPerformanceMode) {
                if (transformResult.length > 5000) stride = Math.max(1, Math.floor(transformResult.length / 750));
                else if (transformResult.length > 1000) stride = Math.max(1, Math.floor(transformResult.length / 500));
            }
            
            // Process the data based on display mode
            if (displayMode.includes("Envelope")) {
                // Check if data is interleaved format (envelope, original, envelope, original...)
                let isInterleaved = transformResult.length >= 2 * (frequencies ? frequencies.length : 0);
                
                if (isInterleaved) {
                    // Process interleaved envelope and original signal
                    for (let i = 0; i < transformResult.length; i += 2 * stride) {
                        if (i/2 < frequencies.length) {
                            let x = frequencies[i/2] || i/2;
                            let envelope = transformResult[i];
                            let original = (i+1 < transformResult.length) ? transformResult[i+1] : 0;
                            
                            if (isFinite(x) && isFinite(envelope)) {
                                envelopeSeries.append(x, envelope);
                                lowerEnvelopeSeries.append(x, -envelope);  // Negative envelope for AreaSeries
                                
                                // For combined view
                                if (displayMode === "Envelope & Phase" && isFinite(original)) {
                                    originalHilbertSeries.append(x, original);
                                }
                                
                                minY = Math.min(minY, -envelope, original);
                                maxY = Math.max(maxY, envelope, original);
                                maxX = Math.max(maxX, x);
                            }
                        }
                    }
                } else {
                    // If data is not interleaved, use standard approach
                    for (let i = 0; i < transformResult.length; i += stride) {
                        if (i < frequencies.length) {
                            let x = frequencies[i] || i/20;
                            let y = transformResult[i];
                            
                            if (isFinite(x) && isFinite(y)) {
                                envelopeSeries.append(x, y);
                                lowerEnvelopeSeries.append(x, -y);  // Negative envelope for AreaSeries
                                
                                // If we're showing both, get original signal from timeDomain
                                if (displayMode === "Envelope & Phase" && i < timeDomain.length) {
                                    let original = 0;
                                    
                                    if (typeof timeDomain[i] === 'object' && 'y' in timeDomain[i]) {
                                        original = timeDomain[i].y; 
                                    } else if (Array.isArray(timeDomain[i])) {
                                        original = timeDomain[i][1];
                                    } else if (typeof timeDomain[i] === 'number') {
                                        original = timeDomain[i];
                                    }
                                    
                                    if (isFinite(original)) {
                                        originalHilbertSeries.append(x, original);
                                    }
                                }
                                
                                minY = Math.min(minY, -y);
                                maxY = Math.max(maxY, y);
                                maxX = Math.max(maxX, x);
                            }
                        }
                    }
                }
            }
            
            // Add phase data if needed
            if (displayMode.includes("Phase") && phaseResult && phaseResult.length > 0) {
                let phaseScalingFactor = 1.0;
                
                // If showing both envelope and phase, scale the phase data
                if (displayMode === "Envelope & Phase") {
                    // Scale phase data to be less prominent than envelope
                    phaseScalingFactor = 0.7;
                }
                
                for (let i = 0; i < phaseResult.length; i += stride) {
                    if (i < frequencies.length) {
                        let x = frequencies[i] || i/20;
                        let phase = phaseResult[i] * phaseScalingFactor;
                        
                        if (isFinite(x) && isFinite(phase)) {
                            phaseSeries.append(x, phase);
                            
                            minY = Math.min(minY, phase);
                            maxY = Math.max(maxY, phase);
                            maxX = Math.max(maxX, x);
                        }
                    }
                }
            }
            
            // Update area series for better visualization
            if (displayMode.includes("Envelope") && !envelopeAreaSeries) {
                try {
                    // Try to create the area series if it doesn't exist
                    envelopeAreaSeries = hilbertChart.createSeries(ChartView.SeriesTypeArea, "Envelope Area", hilbertAxisX, hilbertAxisY);
                    envelopeAreaSeries.upperSeries = envelopeSeries;
                    envelopeAreaSeries.lowerSeries = lowerEnvelopeSeries;
                    envelopeAreaSeries.color = root.envelopeAreaColor;
                    envelopeAreaSeries.borderColor = "transparent";
                    envelopeAreaSeries.borderWidth = 0;
                    envelopeAreaSeries.visible = displayMode.includes("Envelope");
                } catch (e) {
                    console.log("Could not create area series:", e);
                }
            } else if (envelopeAreaSeries) {
                // Update area series properties
                envelopeAreaSeries.color = root.envelopeAreaColor;
                envelopeAreaSeries.visible = displayMode.includes("Envelope");
            }
            
            // Update axis limits for better visualization
            if (minY !== Number.MAX_VALUE) {
                hilbertAxisX.min = 0;
                hilbertAxisX.max = maxX > 0 ? maxX : 5;
                
                // Adjust limits based on display mode
                if (displayMode.includes("Phase") && !displayMode.includes("Envelope")) {
                    // For phase only, adjust range to typical phase values
                    hilbertAxisY.min = Math.min(-3.5, minY * 1.1);
                    hilbertAxisY.max = Math.max(3.5, maxY * 1.1);
                } else {
                    let yRange = Math.max(Math.abs(minY), Math.abs(maxY)) * 1.2;
                    hilbertAxisY.min = -yRange || -2;
                    hilbertAxisY.max = yRange || 2;
                }
            }
        } catch (e) {
            console.error("Error updating Hilbert chart:", e);
        }
    }

    function updateSeriesVisibility() {
        if (!envelopeSeries || !phaseSeries || !originalHilbertSeries) {
            return;
        }
        
        try {
            // Set visibility based on display mode
            envelopeSeries.visible = displayMode.includes("Envelope");
            phaseSeries.visible = displayMode.includes("Phase");
            originalHilbertSeries.visible = displayMode === "Envelope & Phase";
            
            // Update area series visibility
            if (envelopeAreaSeries) {
                envelopeAreaSeries.visible = displayMode.includes("Envelope");
            }
            
            // If showing both envelope and phase, adjust phase line width and color
            if (displayMode === "Envelope & Phase") {
                phaseSeries.width = 1.5;  // Thinner line for phase when showing both
                phaseSeries.color = root.phaseColor.darker(1.2);  // Slightly darker green
            } else {
                phaseSeries.width = highPerformanceMode ? 1 : 2;
                phaseSeries.color = root.phaseColor;
            }
        } catch (e) {
            console.error("Error updating series visibility:", e);
        }
    }

    function updateThemeColors() {
        if (darkMode) {
            backgroundColor = "#1e1e1e";
            textColor = "#e0e0e0";
            gridColor = "#303030";
            signalColor = "#2196F3";     // Blue
            envelopeColor = "#FF5722";   // Orange-red
            phaseColor = "#4CAF50";      // Green
            
            // Area color with custom opacity
            let opacity = shadingOpacitySlider.value / 100;
            envelopeAreaColor = Qt.rgba(0.98, 0.35, 0.13, opacity);  // Semi-transparent orange-red
        } else {
            backgroundColor = "#ffffff";
            textColor = "#333333";
            gridColor = "#cccccc";
            signalColor = "#1976D2";     // Darker blue for light theme
            envelopeColor = "#E64A19";   // Darker orange-red
            phaseColor = "#388E3C";      // Darker green
            
            // Area color with custom opacity for light theme
            let opacity = shadingOpacitySlider.value / 100;
            envelopeAreaColor = Qt.rgba(0.90, 0.27, 0.10, opacity);  // Semi-transparent orange-red
        }
        
        // Update series colors if they exist
        try {
            if (timeSeries) timeSeries.color = signalColor;
            if (envelopeSeries) envelopeSeries.color = envelopeColor;
            if (phaseSeries) {
                if (displayMode === "Envelope & Phase") {
                    phaseSeries.color = phaseColor.darker(1.2);
                } else {
                    phaseSeries.color = phaseColor;
                }
            }
            if (originalHilbertSeries) originalHilbertSeries.color = signalColor;
            
            // Update area series color
            if (envelopeAreaSeries) {
                envelopeAreaSeries.color = envelopeAreaColor;
            }
        } catch (e) {
            console.error("Error updating series colors:", e);
        }
    }
}
