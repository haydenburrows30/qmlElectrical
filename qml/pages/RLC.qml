import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts
import QtCore

import "../components"
import "../components/charts/"
import "../components/style"
import "../components/popups"
import "../components/backgrounds"
import "../components/charts"
import "../components/visualizers"

import RLC 1.0

Page {
    id: rlcPage

    // Create the calculator property with explicit type and id
    property RLCChart calculator: RLCChart {id: rlcChart}

    property int currentMode: changeMode.on ? 1 : 0

    background: Rectangle {
        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
    }

    Connections {
        target: calculator
    }

    // set current mode from the SwitchLabel{}
    function react() {
        currentMode ? calculator.setCircuitMode(1) : calculator.setCircuitMode(0)
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentHeight: mainLayout.height + 10
            contentWidth: parent.width
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            RowLayout {
                id: mainLayout
                width: scrollView.width
                

                ColumnLayout {

                    RowLayout {
                        //Buttons
                        SwitchLabel {
                            Layout.minimumHeight: 60
                            Layout.minimumWidth: 350
                            id: changeMode
                        }

                        ShadowRectangle {
                            Layout.alignment: Qt.AlignRight
                            implicitHeight: 52
                            implicitWidth: 52
                            radius: implicitHeight / 2
                            Layout.columnSpan: 2
                            
                            ImageButton {
                                id: resetButton
                                anchors.centerIn: parent
                                iconName: '\uf053'
                                iconWidth: 24
                                iconHeight: 24
                                color: Style.red
                                backgroundColor: Style.alphaColor(color,0.1)
                                ToolTip.text: "Reset Parameters"
                                ToolTip.visible: resetButton.hovered
                                ToolTip.delay: 500

                                onClicked: {
                                    calculator.resetValues()
                                    resistanceInput.text = "10"
                                    inductanceInput.text = "0.1"
                                    capacitanceInput.text = "0.0001013"
                                    minFreqInput.text = "0"
                                    maxFreqInput.text = "100"
                                }
                            }
                        }
                    }

                    //Visuals
                    WaveCard {
                        title: currentMode === 0 ? 'Series RLC Parameters' : 'Parallel RLC Parameters'
                        Layout.minimumHeight: 600
                        Layout.minimumWidth: 400
                        Layout.fillHeight: true

                        id: results
                        showSettings: true
                        
                        ColumnLayout {
                            anchors.fill: parent
                            
                            
                            // Circuit diagram
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 130
                                
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

                                    highlightR: resistanceInput.activeFocus
                                    highlightL: inductanceInput.activeFocus
                                    highlightC: capacitanceInput.activeFocus

                                    animateCurrent: enableAnimationCheckbox.checked
                                    frequency: frequencySlider.value
                                }
                            }
                            
                            // Phase vector diagram
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 260
                                
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

                            // Frequency slider for animation
                            Label {
                                text: "Animation Settings:"
                                Layout.columnSpan: 2
                                font.bold: true
                                Layout.topMargin: 10
                            }

                            RowLayout {
                                Label {
                                    text: "Freq:"
                                }

                                Slider {
                                    id: frequencySlider
                                    from: 1
                                    to: 100
                                    value: 50
                                    stepSize: 1
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: frequencySlider.value.toFixed(1) + " Hz"
                                    Layout.preferredWidth: 80
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
                        }
                    }

                    //Settings
                    WaveCard {
                        title: currentMode === 0 ? 'Series RLC Parameters' : 'Parallel RLC Parameters'
                        Layout.minimumHeight: 340
                        Layout.minimumWidth: 400
                        Layout.fillHeight: true
                            
                        GridLayout {
                            columns: 2
                            anchors.fill: parent
                            // uniformCellHeights: true
                            uniformCellWidths: true

                            Label {
                                text: "Resistance (Ω):"
                                Layout.fillWidth: true
                            }

                            TextField {
                                id: resistanceInput
                                placeholderText: "Enter Resistance"
                                text: "10"
                                Layout.fillWidth: true
                                                                    
                                Keys.onReturnPressed: { focus = false }
                                Keys.onEnterPressed: { focus = false }
                                Layout.alignment: Qt.AlignRight

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
                                        calculator.setResistance(value)
                                    }
                                }
                            }

                            Label {
                                text: "Inductance (H):"
                                Layout.fillWidth: true
                            }

                            TextField {
                                id: inductanceInput
                                placeholderText: "Enter Inductance"
                                text: "0.1"
                                Layout.fillWidth: true
                                                                    
                                Keys.onReturnPressed: { focus = false }
                                Keys.onEnterPressed: { focus = false }
                                Layout.alignment: Qt.AlignRight

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
                                        calculator.setInductance(value)
                                    }
                                }
                            }

                            Label {
                                text: "Capacitance (F):"
                                Layout.fillWidth: true
                            }

                            TextField {
                                id: capacitanceInput
                                placeholderText: "Enter Capacitance"
                                text: "0.0001013"  // 101.3µF
                                Layout.fillWidth: true
                                                                    
                                Keys.onReturnPressed: { focus = false }
                                Keys.onEnterPressed: { focus = false }
                                Layout.alignment: Qt.AlignRight
        
                                property bool userEditing: false

                                validator: DoubleValidator {
                                    bottom: 0.0001
                                    decimals: 6
                                    notation: DoubleValidator.ScientificNotation
                                }
                                
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
                                        calculator.setCapacitance(value)
                                    }
                                }
                            }

                            Label {
                                text: "Frequency (Hz):"
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                TextField {
                                    id: minFreqInput
                                    placeholderText: "Min"
                                    text: "0"
                                    Layout.fillWidth: true

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
                                            calculator.setFrequencyRange(min, max)
                                        }
                                    }
                                }

                                Label {
                                    text: "to"
                                    Layout.minimumWidth: 20
                                }

                                TextField {
                                    id: maxFreqInput
                                    placeholderText: "Max"
                                    text: "100"
                                    Layout.fillWidth: true
                                    validator: DoubleValidator {
                                        bottom: 0
                                        decimals: 1
                                    }
                                    onTextChanged: {
                                        var min = Number(minFreqInput.text)
                                        var max = Number(text)
                                        if (!isNaN(min) && !isNaN(max) && min >= 0 && max > min) {
                                            calculator.setFrequencyRange(min, max)
                                        }
                                    }
                                }
                            }

                            Label {
                                text: "Resonant Frequency:"
                                Layout.fillWidth: true
                            }

                            TextField {
                                text: calculator.resonantFreq.toFixed(2) + " Hz"
                                Layout.alignment: Qt.AlignHCenter
                                Layout.fillWidth: true
                                font.bold: isAtResonance()
                                font.pixelSize: isAtResonance() ? 14 : 12
                                background: ProtectionRectangle {}
                                readOnly: true

                                function isAtResonance() {
                                    var minF = Number(minFreqInput.text)
                                    var maxF = Number(maxFreqInput.text)
                                    var resonantF = calculator.resonantFreq
                                    return resonantF >= minF && resonantF <= maxF
                                }
                            }

                            Label {
                                text: "Quality Factor (Q):"
                                Layout.fillWidth: true
                            }

                            TextField {
                                text: calculator.qualityFactor.toFixed(2)
                                Layout.alignment: Qt.AlignHCenter
                                Layout.fillWidth: true
                                background: ProtectionRectangle {}
                                readOnly: true
                            }
                        }
                    }
                }

                //Chart
                WaveCard {
                    title: currentMode === 0 ? 'Series RLC Response' : 'Parallel RLC Response'
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    RLCChartView {
                        currentMode: currentMode
                        calculator: rlcChart
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

        property real currentScale: 2.0

        currentFile: {
            let timestamp = new Date().toISOString().replace(/[:.]/g, '-')
            return "rlc_chart_" + timestamp + ".png"
        }

        onAccepted: {
            calculator.saveChart(selectedFile, currentScale)
        }
    }

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

    RLCPopup {
        id: tipsPopup
    }
}