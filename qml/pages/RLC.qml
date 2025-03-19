import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts
import QtCore

import '../components'

Page {
    id: phasor

    background: Rectangle {
        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
    }

    Popup {
        id: tipsPopup
        width: 500
        height: 300
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: results.open

        onAboutToHide: {
            results.open = false
        }
        Text {
            anchors.fill: parent
            text: {"<h3>RLC Circuit</h3><br>"
                + "This page simulates the response of a series or parallel RLC circuit to an input frequency. "
                + "The circuit consists of a resistor (R), inductor (L), and capacitor (C) in series or parallel. "
                + "The circuit parameters can be adjusted to see how they affect the impedance and gain of the circuit. "
                + "The resonant frequency and quality factor (Q) are also calculated based on the circuit parameters. "
                + "The circuit response is displayed in a chart showing the gain or impedance vs. frequency. "
                + "The phase vector diagram shows the phase angle of the impedance and the current in the circuit. " }
            wrapMode: Text.WordWrap
        }
    }

    property int currentMode: 0 // 0 for series, 1 for parallel

    Connections {
        target: rlcChart
        function onFormattedDataChanged(data) {
            var gainSeries = rlcChartView.series(0)
            var resonantSeries = rlcChartView.series(1)
            
            gainSeries.clear()
            resonantSeries.clear()
            
            // Use Python fill_series for gain data
            rlcChart.fill_series(gainSeries)
            
            // Fill resonant line directly since it's just 2 points
            resonantSeries.append(data[1][0].x, data[1][0].y)
            resonantSeries.append(data[1][1].x, data[1][1].y)
        }

        function onAxisRangeChanged() {
            axisX.min = rlcChart.axisXMin
            axisX.max = rlcChart.axisXMax
            axisY.min = rlcChart.axisYMin
            axisY.max = rlcChart.axisYMax
        }
        
        function onCircuitModeChanged(mode) {
            circuitModeTabs.currentIndex = mode
            currentMode = mode
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentHeight: mainLayout.height
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            ColumnLayout {
                id: mainLayout
                anchors.fill: parent
                spacing: 5

                TabBar {
                    id: circuitModeTabs
                    Layout.fillWidth: true
                    
                    TabButton {
                        text: "Series RLC"
                        onClicked: {
                            rlcChart.setCircuitMode(0)
                        }
                    }
                    
                    TabButton {
                        text: "Parallel RLC"
                        onClicked: {
                            rlcChart.setCircuitMode(1)
                        }
                    }
                }

                RowLayout {
                    spacing: 5
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    WaveCard {
                        title: currentMode === 0 ? 'Series RLC Parameters' : 'Parallel RLC Parameters'
                        Layout.minimumHeight: 800
                        Layout.minimumWidth: 350
                        Layout.fillHeight: true

                        id: results
                        showSettings: true
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 5
                            
                            // Circuit diagram
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 160
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: sideBar.toggle1 ? "#2a2a2a" : "#f0f0f0"
                                    border.color: sideBar.toggle1 ? "#3a3a3a" : "#d0d0d0"
                                    border.width: 1
                                    radius: 4
                                }
                                
                                CircuitDiagram {
                                    id: circuitDiagram
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    circuitType: currentMode
                                    darkMode: sideBar.toggle1
                                    
                                    // Add component highlighting when editing relevant fields
                                    highlightR: resistanceInput.activeFocus
                                    highlightL: inductanceInput.activeFocus
                                    highlightC: capacitanceInput.activeFocus
                                    
                                    // Enable current animation
                                    animateCurrent: enableAnimationCheckbox.checked
                                    frequency: frequencySlider.value
                                }
                            }
                            
                            // Phase vector diagram
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 220
                                
                                Rectangle {
                                    anchors.fill: parent
                                    color: sideBar.toggle1 ? "#2a2a2a" : "#f0f0f0"
                                    border.color: sideBar.toggle1 ? "#3a3a3a" : "#d0d0d0"
                                    border.width: 1
                                    radius: 4
                                }
                                
                                PhaseVector {
                                    id: phaseVector
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    circuitType: currentMode
                                    darkMode: sideBar.toggle1
                                    resistance: Number(resistanceInput.text)
                                    inductance: Number(inductanceInput.text)
                                    capacitance: Number(capacitanceInput.text)
                                    frequency: frequencySlider.value
                                    isAnimating: enableAnimationCheckbox.checked
                                    showComponents: showComponentsCheckbox.checked
                                }
                            }
                            
                            // Animation controls
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                
                                CheckBox {
                                    id: enableAnimationCheckbox
                                    text: "Enable Animation"
                                    checked: false
                                    Layout.alignment: Qt.AlignLeft
                                }
                                
                                CheckBox {
                                    id: showComponentsCheckbox
                                    text: "Show Components"
                                    checked: true
                                    Layout.alignment: Qt.AlignLeft
                                }
                            }
                            
                            // Frequency slider for animation
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Label {
                                    text: "Animation Frequency: " + frequencySlider.value.toFixed(1) + " Hz"
                                }
                                
                                Slider {
                                    id: frequencySlider
                                    from: 1
                                    to: 100
                                    value: 50
                                    stepSize: 1
                                    Layout.fillWidth: true
                                    
                                    background: Rectangle {
                                        x: frequencySlider.leftPadding
                                        y: frequencySlider.topPadding + frequencySlider.availableHeight / 2 - height / 2
                                        width: frequencySlider.availableWidth
                                        height: 4
                                        radius: 2
                                        color: sideBar.toggle1 ? "#555555" : "#cccccc"
                                        
                                        Rectangle {
                                            width: frequencySlider.visualPosition * parent.width
                                            height: parent.height
                                            color: sideBar.toggle1 ? "#aaaaaa" : "#666666"
                                            radius: 2
                                        }
                                    }
                                    
                                    handle: Rectangle {
                                        x: frequencySlider.leftPadding + frequencySlider.visualPosition * frequencySlider.availableWidth - width / 2
                                        y: frequencySlider.topPadding + frequencySlider.availableHeight / 2 - height / 2
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: frequencySlider.pressed ? "#f0f0f0" : "#ffffff"
                                        border.color: "#999999"
                                    }
                                }
                            }
                            
                            GridLayout {
                                columns: 2
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Label {
                                    text: "Resistance (Ω):"
                                    Layout.preferredWidth: 150
                                }

                                TextField {
                                    id: resistanceInput
                                    placeholderText: "Enter Resistance"
                                    text: "10"  // Default value
                                    validator: DoubleValidator {
                                        bottom: 0.0001
                                        decimals: 4
                                        notation: DoubleValidator.ScientificNotation
                                    }
                                    
                                    property bool userEditing: false
                                    
                                    onTextChanged: {
                                        if (userEditing) {
                                            // Only do basic format validation while editing
                                            if (!acceptableInput && text !== "" && text !== "." && text !== "0." && 
                                                !text.endsWith('e') && !text.endsWith('-') && !text.endsWith('+')) {
                                                messagePopup.showError("Invalid resistance format")
                                            }
                                        }
                                    }
                                    
                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            userEditing = true
                                        } else {
                                            userEditing = false
                                            if (!acceptableInput) {
                                                messagePopup.showError("Invalid resistance value")
                                                text = "10"
                                                return
                                            }
                                            
                                            // Now apply the value
                                            var value = parseFloat(text)
                                            if (value < 0.0001) {
                                                messagePopup.showError("Resistance must be at least 0.0001 Ω")
                                                text = "0.0001"
                                                value = 0.0001
                                            }
                                            rlcChart.setResistance(value)
                                        }
                                    }
                                    
                                    Keys.onReturnPressed: { focus = false }
                                    Keys.onEnterPressed: { focus = false }
                                    
                                    Layout.preferredWidth: 150
                                    Layout.alignment: Qt.AlignRight
                                }

                                Label {
                                    text: "Inductance (H):"
                                    Layout.preferredWidth: 150
                                }

                                TextField {
                                    id: inductanceInput
                                    placeholderText: "Enter Inductance"
                                    text: "0.1"  // Default value
                                    validator: DoubleValidator {
                                        bottom: 0.0001
                                        decimals: 4
                                        notation: DoubleValidator.ScientificNotation
                                    }
                                    
                                    property bool userEditing: false
                                    
                                    onTextChanged: {
                                        if (userEditing) {
                                            // Only do basic format validation while editing
                                            if (!acceptableInput && text !== "" && text !== "." && text !== "0." && 
                                                !text.endsWith('e') && !text.endsWith('-') && !text.endsWith('+')) {
                                                messagePopup.showError("Invalid inductance format")
                                            }
                                        }
                                    }
                                    
                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            userEditing = true
                                        } else {
                                            userEditing = false
                                            if (!acceptableInput) {
                                                messagePopup.showError("Invalid inductance value")
                                                text = "0.1"
                                                return
                                            }
                                            
                                            // Now apply the value
                                            var value = parseFloat(text)
                                            if (value < 0.0001) {
                                                messagePopup.showError("Inductance must be at least 0.0001 H")
                                                text = "0.0001"
                                                value = 0.0001
                                            }
                                            rlcChart.setInductance(value)
                                        }
                                    }
                                    
                                    Keys.onReturnPressed: { focus = false }
                                    Keys.onEnterPressed: { focus = false }
                                    
                                    Layout.preferredWidth: 150
                                    Layout.alignment: Qt.AlignRight
                                }

                                Label {
                                    text: "Capacitance (F):"
                                    Layout.preferredWidth: 150
                                }

                                TextField {
                                    id: capacitanceInput
                                    placeholderText: "Enter Capacitance"
                                    text: "0.0001013"  // 101.3µF
                                    validator: DoubleValidator {
                                        bottom: 0.0001
                                        decimals: 6
                                        notation: DoubleValidator.ScientificNotation
                                    }
                                    
                                    property bool userEditing: false
                                    
                                    onTextChanged: {
                                        if (userEditing) {
                                            // Only do basic format validation while editing
                                            if (!acceptableInput && text !== "" && text !== "." && text !== "0." && 
                                                !text.endsWith('e') && !text.endsWith('-') && !text.endsWith('+')) {
                                                messagePopup.showError("Invalid capacitance format")
                                            }
                                        }
                                    }
                                    
                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            userEditing = true
                                        } else {
                                            userEditing = false
                                            if (!acceptableInput) {
                                                messagePopup.showError("Invalid capacitance value")
                                                text = "0.0001013"
                                                return
                                            }
                                            
                                            // Now apply the value
                                            var value = parseFloat(text)
                                            if (value < 0.0001) {
                                                messagePopup.showError("Capacitance must be at least 0.0001 F")
                                                text = "0.0001"
                                                value = 0.0001
                                            }
                                            rlcChart.setCapacitance(value)
                                        }
                                    }
                                    
                                    Keys.onReturnPressed: { focus = false }
                                    Keys.onEnterPressed: { focus = false }
                                    
                                    Layout.preferredWidth: 150
                                    Layout.alignment: Qt.AlignRight
                                }

                                Label {
                                    text: "Frequency (Hz):"
                                    Layout.preferredWidth: 150
                                }

                                RowLayout {
                                    Layout.fillWidth: true

                                    TextField {
                                        id: minFreqInput
                                        placeholderText: "Min"
                                        text: "0"
                                        validator: DoubleValidator {
                                            bottom: 0
                                            decimals: 1
                                        }
                                        onTextChanged: {
                                            if (!acceptableInput) {
                                                messagePopup.showError("Invalid minimum frequency")
                                                return
                                            }
                                            var min = Number(text)
                                            var max = Number(maxFreqInput.text)
                                            if (!isNaN(min) && !isNaN(max)) {
                                                if (min < 0) {
                                                    messagePopup.showError("Minimum frequency cannot be negative")
                                                    return
                                                }
                                                if (max <= min) {
                                                    messagePopup.showError("Maximum frequency must be greater than minimum")
                                                    return
                                                }
                                                rlcChart.setFrequencyRange(min, max)
                                            }
                                        }
                                    }

                                    Label {
                                        text: "to"
                                    }

                                    TextField {
                                        id: maxFreqInput
                                        placeholderText: "Max"
                                        text: "100"
                                        validator: DoubleValidator {
                                            bottom: 0
                                            decimals: 1
                                        }
                                        onTextChanged: {
                                            var min = Number(minFreqInput.text)
                                            var max = Number(text)
                                            if (!isNaN(min) && !isNaN(max) && min >= 0 && max > min) {
                                                rlcChart.setFrequencyRange(min, max)
                                            }
                                        }
                                    }
                                }

                                Label {
                                    text: "Resonant Frequency:"
                                    Layout.preferredWidth: 150
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: rlcChart.resonantFreq.toFixed(2) + " Hz"
                                    Layout.preferredWidth: 150
                                    Layout.alignment: Qt.AlignHCenter
                                    color: "red"
                                    font.bold: isAtResonance()
                                    font.pixelSize: isAtResonance() ? 14 : 12
                                    
                                    // Add visual feedback when near resonance
                                    function isAtResonance() {
                                        var minF = Number(minFreqInput.text)
                                        var maxF = Number(maxFreqInput.text)
                                        var resonantF = rlcChart.resonantFreq
                                        return resonantF >= minF && resonantF <= maxF
                                    }
                                }

                                Label {
                                    text: "Quality Factor (Q):"
                                    Layout.preferredWidth: 150
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: rlcChart.qualityFactor.toFixed(2)
                                    Layout.preferredWidth: 150
                                    Layout.alignment: Qt.AlignHCenter
                                    color: "blue"
                                }

                                Button {
                                    text: "Reset All Values"
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    onClicked: {
                                        rlcChart.resetValues()
                                        resistanceInput.text = "10"
                                        inductanceInput.text = "0.1"
                                        capacitanceInput.text = "0.0001013"
                                        minFreqInput.text = "0"
                                        maxFreqInput.text = "100"
                                    }
                                }
                            }
                        }
                    }

                    WaveCard {
                        title: currentMode === 0 ? 'Series RLC Response' : 'Parallel RLC Response'
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent

                            ChartView {
                                id: rlcChartView
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                antialiasing: true
                                theme: Universal.theme

                                MouseArea {
                                    anchors.fill: parent
                                    drag.target: dragTarget
                                    drag.axis: Drag.XAxis
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    hoverEnabled: true

                                    onDoubleClicked: {
                                        rlcChartView.zoomReset()
                                    }

                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            contextMenu.popup()
                                        }
                                    }

                                    onWheel: (wheel)=> {
                                        if (wheel.angleDelta.y > 0) {
                                            rlcChartView.zoom(0.9)
                                        } else {
                                            rlcChartView.zoom(1.1)
                                        }
                                    }
                                }

                                Menu {
                                    id: contextMenu
                                    title: "Chart Options"
                                    
                                    Menu {
                                        title: "Save Chart"
                                        MenuItem {
                                            text: "Standard Quality (1x)"
                                            onTriggered: {
                                                saveDialog.currentScale = 1.0
                                                saveDialog.open()
                                            }
                                        }
                                        MenuItem {
                                            text: "High Quality (2x)"
                                            onTriggered: {
                                                saveDialog.currentScale = 2.0
                                                saveDialog.open()
                                            }
                                        }
                                        MenuItem {
                                            text: "Ultra Quality (4x)"
                                            onTriggered: {
                                                saveDialog.currentScale = 4.0
                                                saveDialog.open()
                                            }
                                        }
                                    }
                                    MenuSeparator {}
                                    MenuItem {
                                        text: "Reset Zoom"
                                        onTriggered: rlcChartView.zoomReset()
                                    }
                                }

                                Item {
                                    id: dragTarget
                                    property real oldX : x
                                    property real oldY : y

                                    onXChanged: {
                                        rlcChartView.scrollLeft( x - oldX );
                                        oldX = x;
                                    }

                                    onYChanged: {
                                        rlcChartView.scrollUp( y - oldY );
                                        oldY = y;
                                    }
                                }

                                Component.onCompleted: {
                                    var gainSeries = createSeries(ChartView.SeriesTypeLine, "Gain", axisX, axisY)
                                    gainSeries.color = "blue"
                                    gainSeries.width = 2

                                    var resonantSeries = createSeries(ChartView.SeriesTypeLine, "Resonant Frequency", axisX, axisY)
                                    resonantSeries.color = "red"
                                    resonantSeries.width = 2
                                    resonantSeries.style = Qt.DashLine

                                    // Initialize with default values
                                    rlcChart.setResistance(10.0)
                                    rlcChart.setInductance(0.1)
                                    rlcChart.setCapacitance(0.0001013)
                                    rlcChart.setFrequencyRange(0, 100)
                                }

                                ValueAxis {
                                    id: axisX
                                    min: 0
                                    max: 1000
                                    tickCount: 10
                                    labelFormat: "\u00B0"
                                    titleText: "Frequency (Hz)"
                                }

                                ValueAxis {
                                    id: axisY
                                    min: 0
                                    max: 100
                                    tickCount: 10
                                    labelFormat: "%.3f"
                                    titleText: currentMode === 0 ? "Gain (ratio)" : "Impedance (Ω)"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: saveDialog
        title: "Save Chart"
        nameFilters: ["PNG files (*.png)", "All files (*)"]
        fileMode: FileDialog.SaveFile
        defaultSuffix: "png"
        currentFolder: Qt.platform.os === "windows" ? "file:///C:" : "file:///home"
        
        // Add property to track the selected scale
        property real currentScale: 2.0

        // Generate default filename with timestamp
        currentFile: {
            let timestamp = new Date().toISOString().replace(/[:.]/g, '-')
            return "rlc_chart_" + timestamp + ".png"
        }

        onAccepted: {
            // Use the selected scale factor
            rlcChart.saveChart(selectedFile, currentScale)
        }
    }

    Connections {
        target: rlcChart
        function onGrabRequested(filepath, scale) {
            loadingIndicator.visible = true
            console.log("Grabbing image to:", filepath, "with scale:", scale)
            rlcChartView.grabToImage(function(result) {
                loadingIndicator.visible = false
                if (result) {
                    var saved = result.saveToFile(filepath)
                    if (saved) {
                        messagePopup.showSuccess("Chart saved successfully")
                    } else {
                        messagePopup.showError("Failed to save chart")
                    }
                } else {
                    messagePopup.showError("Failed to grab chart image")
                }
            }, Qt.size(rlcChartView.width * scale, rlcChartView.height * scale))
        }
    }

    // Add message popup for feedback
    Popup {
        id: messagePopup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 400
        height: 200
        
        property string messageText: ""
        property bool isError: false
        
        function showSuccess(message) {
            messageText = message
            isError = false
            open()
        }
        
        function showError(message) {
            messageText = message
            isError = true
            open()
        }
        
        contentItem: ColumnLayout {
            Label {
                text: messagePopup.messageText
                wrapMode: Text.WordWrap
                color: messagePopup.isError ? "red" : (sideBar.toggle1 ? "#ffffff" : "#000000")
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                onClicked: messagePopup.close()
            }
        }
    }

    // Add loading indicator
    BusyIndicator {
        id: loadingIndicator
        anchors.centerIn: parent
        visible: false
        running: visible
        z: 999
        
        Rectangle {
            anchors.fill: parent
            color: "#80000000"
            visible: parent.visible
        }
    }
}