import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"
import "../../components/charts"

import SequenceComponentCalculator 1.0

Page {
    id: root
    
    property color textColorPhase: window.modeToggled ? "#ffffff" : "#000000"
    property SequenceComponentCalculator calculator: SequenceComponentCalculator {}
    
    PopUpText {
        id: popUpText
        parentCard: topHeader
        popupText: "<h3>Sequence Component Calculator</h3><br>Sequence components are a mathematical technique used to analyze unbalanced three-phase systems." +
        " The method transforms the original three-phase system into three balanced systems: positive, negative, and zero sequence components.<br><br>" +
        "<b>Positive Sequence</b>: Represents the normal balanced three-phase component with positive phase rotation (A-B-C).<br>" +
        "<b>Negative Sequence</b>: Represents unbalanced components with negative phase rotation (A-C-B).<br>" +
        "<b>Zero Sequence</b>: Represents the in-phase component that exists only when there is current flow through neutral or ground.<br><br>" +
        "The voltage unbalance factor (VUF) is calculated as the ratio of negative sequence voltage to positive sequence voltage, expressed as a percentage."
        widthFactor: 0.6
        heightFactor: 0.6
    }
    
    // Add educational popup for fault types and sequence components
    PopUpText {
        id: faultInfoPopup
        parentCard: inputsCard
        popupText: "<h3>Fault Types and Sequence Components</h3><br>" +
                   "<p>Different fault types produce distinctive sequence component patterns that can be used for fault diagnosis:</p>" +
                   
                   "<h4>Balanced System (No Fault)</h4>" +
                   "<ul>" +
                   "<li><b>Positive Sequence:</b> Normal values</li>" +
                   "<li><b>Negative Sequence:</b> Nearly zero (< 1-2%)</li>" +
                   "<li><b>Zero Sequence:</b> Nearly zero in ungrounded systems</li>" +
                   "</ul>" +
                   
                   "<h4>Single Line-to-Ground Fault</h4>" +
                   "<ul>" +
                   "<li><b>Positive Sequence:</b> Reduced from normal</li>" +
                   "<li><b>Negative Sequence:</b> Present (typically 30-70% of positive)</li>" +
                   "<li><b>Zero Sequence:</b> Present and significant (typically equal to negative)</li>" +
                   "<li><b>Key Indicator:</b> All three sequence currents are approximately equal</li>" +
                   "</ul>" +
                   
                   "<h4>Line-to-Line Fault</h4>" +
                   "<ul>" +
                   "<li><b>Positive Sequence:</b> Reduced from normal</li>" +
                   "<li><b>Negative Sequence:</b> Present and significant (equal to positive)</li>" +
                   "<li><b>Zero Sequence:</b> Nearly zero (no ground path)</li>" +
                   "<li><b>Key Indicator:</b> Negative sequence approximately equals positive sequence, zero sequence is minimal</li>" +
                   "</ul>" +
                   
                   "<h4>Double Line-to-Ground Fault</h4>" +
                   "<ul>" +
                   "<li><b>Positive Sequence:</b> Reduced from normal</li>" +
                   "<li><b>Negative Sequence:</b> Present (typically 40-80% of positive)</li>" +
                   "<li><b>Zero Sequence:</b> Present (typically 40-80% of positive)</li>" +
                   "<li><b>Key Indicator:</b> All three sequences present with significant values</li>" +
                   "</ul>" +
                   
                   "<h4>Three-Phase Fault</h4>" +
                   "<ul>" +
                   "<li><b>Positive Sequence:</b> High value (depending on fault impedance)</li>" +
                   "<li><b>Negative Sequence:</b> Nearly zero (balanced fault)</li>" +
                   "<li><b>Zero Sequence:</b> Nearly zero (balanced fault)</li>" +
                   "<li><b>Key Indicator:</b> Only positive sequence present, others minimal</li>" +
                   "</ul>" +
                   
                   "<h4>Interpreting Phase Angles</h4>" +
                   "<p>Phase angle relationships between sequence components can provide additional diagnostic information. For example, in a single line-to-ground fault, the angles between positive, negative and zero sequence currents are theoretically equal.</p>"
        widthFactor: 0.7
        heightFactor: 0.7
    }
    
    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            id: flickableContainer
            contentWidth: parent.width
            contentHeight: mainLayout.height
            bottomMargin: 5
            leftMargin: 5
            
            ColumnLayout {
                id: mainLayout
                anchors.centerIn: parent
                
                // Header with title and help button
                RowLayout {
                    id: topHeader
                    Layout.fillWidth: true
                    Layout.bottomMargin: 5
                    
                    Label {
                        text: "Sequence Component Calculator"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Help"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: popUpText.open()
                    }
                    
                    // Add fault information button
                    StyledButton {
                        id: faultInfoButton
                        icon.source: "../../../icons/rounded/lightbulb.svg" 
                        ToolTip.text: "Fault Type Reference"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: faultInfoPopup.open()
                    }
                    
                    StyledButton {
                        id: resetButton
                        icon.source: "../../../icons/rounded/refresh.svg"
                        ToolTip.text: "Reset to balanced system"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: calculator.resetToBalanced()
                    }
                }
                
                // Main calculator interface
                RowLayout {
                    Layout.fillWidth: true
                    
                    // Input values card
                    WaveCard {
                        id: inputsCard
                        title: "Three-Phase Values"
                        Layout.minimumWidth: 670
                        Layout.minimumHeight: 260
                        
                        ColumnLayout {
                            anchors.fill: parent
                            
                            // Example presets
                            RowLayout {
                                Layout.maximumWidth:400
                                spacing: 10
                                
                                Label {
                                    text: "Preset examples:"
                                    font.bold: true
                                }
                                
                                ComboBoxRound {
                                    id: presetSelector
                                    model: ["Custom", "Balanced System", "Unbalanced System", "Single Line-to-Ground Fault", "Line-to-Line Fault", "Double Line-to-Ground Fault", "Three-Phase Fault"]
                                    Layout.fillWidth: true
                                    
                                    onCurrentTextChanged: {
                                        if (currentText === "Balanced System") {
                                            calculator.resetToBalanced()
                                        } else if (currentText === "Unbalanced System") {
                                            calculator.createUnbalancedExample()
                                        } else if (currentText.indexOf("Fault") !== -1) {
                                            calculator.createFaultExample(currentText.replace(" Fault", ""))
                                        }
                                    }
                                }
                            }
                            
                            // Phase inputs
                            ColumnLayout {
                                Layout.fillWidth: true
                                
                                // Headers
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Label {
                                        text: ""
                                        Layout.preferredWidth: 80
                                    }
                                    
                                    Label {
                                        text: "Voltage (V)"
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.preferredWidth: 120
                                    }
                                    
                                    Label {
                                        text: "Angle (°)"
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.preferredWidth: 120
                                    }
                                    
                                    Label {
                                        text: "Current (A)"
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.preferredWidth: 120
                                    }
                                    
                                    Label {
                                        text: "Angle (°)"
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.preferredWidth: 120
                                    }
                                }
                                
                                // Phase A inputs
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Label {
                                        text: "Phase A"
                                        color: "#f44336"
                                        font.bold: true
                                        Layout.preferredWidth: 120
                                    }
                                    
                                    SpinBoxRound {
                                        id: voltageAInput
                                        from: 0
                                        to: 20000
                                        stepSize: 1
                                        value: calculator.voltageA
                                        Layout.preferredWidth: 120
                                        editable: true
                                        
                                        onValueModified: calculator.setVoltageA(value)
                                        
                                        textFromValue: function(value, locale) {
                                            return Number(value).toLocaleString(locale, 'f', 1)
                                        }
                                        
                                        valueFromText: function(text, locale) {
                                            return Number.fromLocaleString(locale, text)
                                        }
                                    }
                                    
                                    SpinBoxRound {
                                        id: voltageAngleAInput
                                        from: -360
                                        to: 360
                                        stepSize: 1
                                        value: calculator.voltageAngleA
                                        Layout.preferredWidth: 120
                                        editable: true
                                        
                                        onValueModified: calculator.setVoltageAngleA(value)
                                    }
                                    
                                    SpinBoxRound {
                                        id: currentAInput
                                        from: 0
                                        to: 10000
                                        stepSize: 1
                                        value: calculator.currentA
                                        Layout.preferredWidth: 120
                                        editable: true
                                        
                                        onValueModified: calculator.setCurrentA(value)
                                        
                                        textFromValue: function(value, locale) {
                                            return Number(value).toLocaleString(locale, 'f', 1)
                                        }
                                        
                                        valueFromText: function(text, locale) {
                                            return Number.fromLocaleString(locale, text)
                                        }
                                    }
                                    
                                    SpinBoxRound {
                                        id: currentAngleAInput
                                        from: -360
                                        to: 360
                                        stepSize: 1
                                        value: calculator.currentAngleA
                                        Layout.preferredWidth: 120
                                        editable: true
                                        
                                        onValueModified: calculator.setCurrentAngleA(value)
                                    }
                                }
                                
                                // Phase B inputs
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Label {
                                        text: "Phase B"
                                        color: "#4caf50"
                                        font.bold: true
                                        Layout.preferredWidth: 120
                                    }
                                    
                                    SpinBoxRound {
                                        id: voltageBInput
                                        from: 0
                                        to: 20000
                                        stepSize: 1
                                        value: calculator.voltageB
                                        Layout.preferredWidth: 120
                                        editable: true
                                        
                                        onValueModified: calculator.setVoltageB(value)
                                        
                                        textFromValue: function(value, locale) {
                                            return Number(value).toLocaleString(locale, 'f', 1)
                                        }
                                        
                                        valueFromText: function(text, locale) {
                                            return Number.fromLocaleString(locale, text)
                                        }
                                    }
                                    
                                    SpinBoxRound {
                                        id: voltageAngleBInput
                                        from: -360
                                        to: 360
                                        stepSize: 1
                                        value: calculator.voltageAngleB
                                        Layout.preferredWidth: 120
                                        editable: true
                                        
                                        onValueModified: calculator.setVoltageAngleB(value)
                                    }
                                    
                                    SpinBoxRound {
                                        id: currentBInput
                                        from: 0
                                        to: 10000
                                        stepSize: 1
                                        value: calculator.currentB
                                        Layout.preferredWidth: 120
                                        editable: true
                                        
                                        onValueModified: calculator.setCurrentB(value)
                                        
                                        textFromValue: function(value, locale) {
                                            return Number(value).toLocaleString(locale, 'f', 1)
                                        }
                                        
                                        valueFromText: function(text, locale) {
                                            return Number.fromLocaleString(locale, text)
                                        }
                                    }
                                    
                                    SpinBoxRound {
                                        id: currentAngleBInput
                                        from: -360
                                        to: 360
                                        stepSize: 1
                                        value: calculator.currentAngleB
                                        Layout.preferredWidth: 120
                                        editable: true
                                        
                                        onValueModified: calculator.setCurrentAngleB(value)
                                    }
                                }
                                
                                // Phase C inputs
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Label {
                                        text: "Phase C"
                                        color: "#2196f3"
                                        font.bold: true
                                        Layout.preferredWidth: 120
                                    }
                                    
                                    SpinBoxRound {
                                        id: voltageCInput
                                        from: 0
                                        to: 20000
                                        stepSize: 1
                                        value: calculator.voltageC
                                        Layout.preferredWidth: 120
                                        editable: true
                                        
                                        onValueModified: calculator.setVoltageC(value)
                                        
                                        textFromValue: function(value, locale) {
                                            return Number(value).toLocaleString(locale, 'f', 1)
                                        }
                                        
                                        valueFromText: function(text, locale) {
                                            return Number.fromLocaleString(locale, text)
                                        }
                                    }
                                    
                                    SpinBoxRound {
                                        id: voltageAngleCInput
                                        from: -360
                                        to: 360
                                        stepSize: 1
                                        value: calculator.voltageAngleC
                                        Layout.preferredWidth: 120
                                        editable: true
                                        
                                        onValueModified: calculator.setVoltageAngleC(value)
                                    }
                                    
                                    SpinBoxRound {
                                        id: currentCInput
                                        from: 0
                                        to: 10000
                                        stepSize: 1
                                        value: calculator.currentC
                                        Layout.preferredWidth: 120
                                        editable: true
                                        
                                        onValueModified: calculator.setCurrentC(value)
                                        
                                        textFromValue: function(value, locale) {
                                            return Number(value).toLocaleString(locale, 'f', 1)
                                        }
                                        
                                        valueFromText: function(text, locale) {
                                            return Number.fromLocaleString(locale, text)
                                        }
                                    }
                                    
                                    SpinBoxRound {
                                        id: currentAngleCInput
                                        from: -360
                                        to: 360
                                        stepSize: 1
                                        value: calculator.currentAngleC
                                        Layout.preferredWidth: 120
                                        editable: true
                                        
                                        onValueModified: calculator.setCurrentAngleC(value)
                                    }
                                }
                            }
                        }
                    }

                    // Visual representation
                    WaveCard {
                        id: phaseVectorCard
                        title: "Vector Diagram"
                        Layout.fillHeight: true
                        Layout.minimumWidth: unbalanceResults.width

                        PhaseVector {
                            id: phaseVectorDiagram
                            anchors.fill: parent
                            // Voltage phasors
                            property var vA: Qt.vector2d(
                                calculator.voltageA * Math.cos(calculator.voltageAngleA * Math.PI/180),
                                calculator.voltageA * Math.sin(calculator.voltageAngleA * Math.PI/180)
                            )
                            property var vB: Qt.vector2d(
                                calculator.voltageB * Math.cos(calculator.voltageAngleB * Math.PI/180),
                                calculator.voltageB * Math.sin(calculator.voltageAngleB * Math.PI/180)
                            )
                            property var vC: Qt.vector2d(
                                calculator.voltageC * Math.cos(calculator.voltageAngleC * Math.PI/180),
                                calculator.voltageC * Math.sin(calculator.voltageAngleC * Math.PI/180)
                            )
                            
                            // Custom phasor rendering with vector properties
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                
                                // Draw background
                                ctx.fillStyle = "transparent"
                                ctx.fillRect(0, 0, width, height)
                                
                                var centerX = width / 2
                                var centerY = height / 2
                                var radius = Math.min(width, height) * 0.4
                                
                                // Draw coordinate grid
                                ctx.strokeStyle = "#888888"
                                ctx.lineWidth = 1
                                
                                // Draw horizontal and vertical axes
                                ctx.beginPath()
                                ctx.moveTo(0, centerY)
                                ctx.lineTo(width, centerY)
                                ctx.moveTo(centerX, 0)
                                ctx.lineTo(centerX, height)
                                ctx.stroke()
                                
                                // Draw circle
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
                                ctx.stroke()
                                
                                // Calculate scale factor
                                var maxVoltage = Math.max(calculator.voltageA, calculator.voltageB, calculator.voltageC)
                                var scale = radius / maxVoltage
                                
                                // Draw voltage phasors
                                // Phase A (red)
                                ctx.beginPath()
                                ctx.strokeStyle = "#f44336"
                                ctx.lineWidth = 2
                                ctx.moveTo(centerX, centerY)
                                var vaMag = calculator.voltageA * scale
                                var vaAngle = calculator.voltageAngleA * Math.PI / 180
                                var vaEndX = centerX + vaMag * Math.cos(vaAngle)
                                var vaEndY = centerY - vaMag * Math.sin(vaAngle)  // y is inverted in canvas
                                ctx.lineTo(vaEndX, vaEndY)
                                ctx.stroke()
                                
                                // Arrow head
                                ctx.fillStyle = "#f44336"
                                var arrowSize = 8
                                var angle = Math.atan2(centerY - vaEndY, vaEndX - centerX)
                                ctx.beginPath()
                                ctx.moveTo(vaEndX, vaEndY)
                                ctx.lineTo(
                                    vaEndX - arrowSize * Math.cos(angle - Math.PI/6),
                                    vaEndY - arrowSize * Math.sin(angle - Math.PI/6)
                                )
                                ctx.lineTo(
                                    vaEndX - arrowSize * Math.cos(angle + Math.PI/6),
                                    vaEndY - arrowSize * Math.sin(angle + Math.PI/6)
                                )
                                ctx.closePath()
                                ctx.fill()
                                ctx.fillText("Va", vaEndX + 10, vaEndY)
                                
                                // Phase B (green)
                                ctx.beginPath()
                                ctx.strokeStyle = "#4caf50"
                                ctx.lineWidth = 2
                                ctx.moveTo(centerX, centerY)
                                var vbMag = calculator.voltageB * scale
                                var vbAngle = calculator.voltageAngleB * Math.PI / 180
                                var vbEndX = centerX + vbMag * Math.cos(vbAngle)
                                var vbEndY = centerY - vbMag * Math.sin(vbAngle)
                                ctx.lineTo(vbEndX, vbEndY)
                                ctx.stroke()
                                
                                // Arrow head
                                ctx.fillStyle = "#4caf50"
                                angle = Math.atan2(centerY - vbEndY, vbEndX - centerX)
                                ctx.beginPath()
                                ctx.moveTo(vbEndX, vbEndY)
                                ctx.lineTo(
                                    vbEndX - arrowSize * Math.cos(angle - Math.PI/6),
                                    vbEndY - arrowSize * Math.sin(angle - Math.PI/6)
                                )
                                ctx.lineTo(
                                    vbEndX - arrowSize * Math.cos(angle + Math.PI/6),
                                    vbEndY - arrowSize * Math.sin(angle + Math.PI/6)
                                )
                                ctx.closePath()
                                ctx.fill()
                                ctx.fillText("Vb", vbEndX + 10, vbEndY)
                                
                                // Phase C (blue)
                                ctx.beginPath()
                                ctx.strokeStyle = "#2196f3"
                                ctx.lineWidth = 2
                                ctx.moveTo(centerX, centerY)
                                var vcMag = calculator.voltageC * scale
                                var vcAngle = calculator.voltageAngleC * Math.PI / 180
                                var vcEndX = centerX + vcMag * Math.cos(vcAngle)
                                var vcEndY = centerY - vcMag * Math.sin(vcAngle)
                                ctx.lineTo(vcEndX, vcEndY)
                                ctx.stroke()
                                
                                // Arrow head
                                ctx.fillStyle = "#2196f3"
                                angle = Math.atan2(centerY - vcEndY, vcEndX - centerX)
                                ctx.beginPath()
                                ctx.moveTo(vcEndX, vcEndY)
                                ctx.lineTo(
                                    vcEndX - arrowSize * Math.cos(angle - Math.PI/6),
                                    vcEndY - arrowSize * Math.sin(angle - Math.PI/6)
                                )
                                ctx.lineTo(
                                    vcEndX - arrowSize * Math.cos(angle + Math.PI/6),
                                    vcEndY - arrowSize * Math.sin(angle + Math.PI/6)
                                )
                                ctx.closePath()
                                ctx.fill()
                                ctx.fillText("Vc", vcEndX + 10, vcEndY)
                            }
                            
                            // Update diagram when values change
                            Connections {
                                target: calculator
                                function onDataChanged() {
                                    phaseVectorDiagram.requestPaint()
                                }
                            }
                        }
                    }
                }
                
                // Waveform visualization card
                WaveCard {
                    id: waveformCard
                    title: "Three-Phase Waveform Visualization"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 500
                    
                    ColumnLayout {
                        anchors.fill: parent
                        
                        RowLayout {
                            Layout.fillWidth: true
                            
                            Label {
                                text: "Waveform Type:"
                                font.bold: true
                            }
                            
                            RadioButton {
                                id: voltageRadio
                                text: "Voltage"
                                checked: !waveformChart.showCurrents
                                onCheckedChanged: {
                                    if (checked) {
                                        waveformChart.showCurrents = false
                                    }
                                }
                            }
                            
                            RadioButton {
                                id: currentRadio
                                text: "Current"
                                checked: waveformChart.showCurrents
                                onCheckedChanged: {
                                    if (checked) {
                                        waveformChart.showCurrents = true
                                    }
                                }
                            }
                            
                            Item { Layout.fillWidth: true } // Spacer
                            
                            Label {
                                text: "Selected Pattern: " + presetSelector.currentText
                                font.italic: true
                            }
                        }
                        
                        // Dynamic waveform chart
                        SequenceWaveformChart {
                            id: waveformChart
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            faultType: presetSelector.currentText
                            
                            // Bind to calculator values
                            voltageA: calculator.voltageA
                            voltageB: calculator.voltageB
                            voltageC: calculator.voltageC
                            angleA: calculator.voltageAngleA
                            angleB: calculator.voltageAngleB
                            angleC: calculator.voltageAngleC
                            currentA: calculator.currentA
                            currentB: calculator.currentB
                            currentC: calculator.currentC
                            currentAngleA: calculator.currentAngleA
                            currentAngleB: calculator.currentAngleB
                            currentAngleC: calculator.currentAngleC
                        }
                    }
                }

                // Results card
                RowLayout {
                    
                    // Sequence Component Results
                    WaveCard {
                        id: sequenceResults
                        title: "Sequence Components"
                        Layout.minimumWidth: inputsCard.width
                        Layout.minimumHeight: 210
                        
                        GridLayout {
                            anchors.fill: parent
                            columns: 5
                            
                            // Headers
                            Label { text: ""; Layout.columnSpan: 1 }
                            Label { text: "Voltage"; font.bold: true; horizontalAlignment: Text.AlignHCenter; Layout.columnSpan: 2 }
                            Label { text: "Current"; font.bold: true; horizontalAlignment: Text.AlignHCenter; Layout.columnSpan: 2 }
                            
                            Label { text: ""; Layout.columnSpan: 1 }
                            Label { text: "Magnitude"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                            Label { text: "Angle"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                            Label { text: "Magnitude"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                            Label { text: "Angle"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                            
                            // Positive Sequence
                            Label { 
                                text: "Positive"; 
                                font.bold: true; 
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Label { 
                                text: calculator.voltagePositiveMagnitude.toFixed(1) + " V";
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Label { 
                                text: calculator.voltagePositiveAngle.toFixed(1) + "°";
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Label { 
                                text: calculator.currentPositiveMagnitude.toFixed(1) + " A";
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Label { 
                                text: calculator.currentPositiveAngle.toFixed(1) + "°";
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            // Negative Sequence
                            Label { 
                                text: "Negative";
                                font.bold: true; 
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Label { 
                                text: calculator.voltageNegativeMagnitude.toFixed(1) + " V";
                                color: calculator.voltageNegativeMagnitude / calculator.voltagePositiveMagnitude > 0.05 ? "#ff4444" : textColorPhase;
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Label { 
                                text: calculator.voltageNegativeAngle.toFixed(1) + "°";
                                color: calculator.voltageNegativeMagnitude / calculator.voltagePositiveMagnitude > 0.05 ? "#ff4444" : textColorPhase;
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Label { 
                                text: calculator.currentNegativeMagnitude.toFixed(1) + " A";
                                color: calculator.currentNegativeMagnitude / calculator.currentPositiveMagnitude > 0.1 ? "#ff4444" : textColorPhase;
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Label { 
                                text: calculator.currentNegativeAngle.toFixed(1) + "°";
                                color: calculator.currentNegativeMagnitude / calculator.currentPositiveMagnitude > 0.1 ? "#ff4444" : textColorPhase;
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            // Zero Sequence
                            Label { 
                                text: "Zero";
                                font.bold: true; 
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Label { 
                                text: calculator.voltageZeroMagnitude.toFixed(1) + " V";
                                color: calculator.voltageZeroMagnitude / calculator.voltagePositiveMagnitude > 0.05 ? "#ff4444" : textColorPhase;
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Label { 
                                text: calculator.voltageZeroAngle.toFixed(1) + "°";
                                color: calculator.voltageZeroMagnitude / calculator.voltagePositiveMagnitude > 0.05 ? "#ff4444" : textColorPhase;
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Label { 
                                text: calculator.currentZeroMagnitude.toFixed(1) + " A";
                                color: calculator.currentZeroMagnitude / calculator.currentPositiveMagnitude > 0.1 ? "#ff4444" : textColorPhase;
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Label { 
                                text: calculator.currentZeroAngle.toFixed(1) + "°";
                                color: calculator.currentZeroMagnitude / calculator.currentPositiveMagnitude > 0.1 ? "#ff4444" : textColorPhase;
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    
                    // Unbalance Factor Card
                    WaveCard {
                        id: unbalanceResults
                        title: "System Analysis"
                        Layout.minimumWidth: 530
                        Layout.minimumHeight: sequenceResults.height
                        
                        GridLayout {
                            anchors.fill: parent
                            columns: 2
                            
                            // Unbalance factors
                            Label { 
                                text: "Voltage Unbalance Factor:"; 
                                font.bold: true 
                            }
                            Label { 
                                text: calculator.voltageUnbalanceFactor.toFixed(2) + "%";
                                color: calculator.voltageUnbalanceFactor > 2.0 ? "#ff4444" : 
                                        calculator.voltageUnbalanceFactor > 1.0 ? "#ff8800" : "#4caf50"
                            }
                            
                            Label { 
                                text: "Current Unbalance Factor:"; 
                                font.bold: true 
                            }
                            Label { 
                                text: calculator.currentUnbalanceFactor.toFixed(2) + "%";
                                color: calculator.currentUnbalanceFactor > 10.0 ? "#ff4444" : 
                                        calculator.currentUnbalanceFactor > 5.0 ? "#ff8800" : "#4caf50"
                            }
                            
                            // System health interpretation
                            Label { 
                                text: "System Status:"; 
                                font.bold: true 
                            }
                            Label { 
                                text: calculator.voltageUnbalanceFactor <= 1.0 && calculator.currentUnbalanceFactor <= 5.0 ? 
                                        "Balanced System" : 
                                        calculator.voltageUnbalanceFactor <= 2.0 && calculator.currentUnbalanceFactor <= 10.0 ? 
                                        "Minor Unbalance" : 
                                        calculator.voltageZeroMagnitude > 5.0 ? 
                                        "Ground Fault Likely" : 
                                        "Significant Unbalance";
                                
                                color: calculator.voltageUnbalanceFactor <= 1.0 && calculator.currentUnbalanceFactor <= 5.0 ? 
                                        "#4caf50" : 
                                        calculator.voltageUnbalanceFactor <= 2.0 && calculator.currentUnbalanceFactor <= 10.0 ? 
                                        "#ff8800" : "#ff4444"
                            }
                            
                            // Information about sequence components
                            Label { 
                                text: "Dominant Issue:"; 
                                font.bold: true; 
                                visible: calculator.voltageUnbalanceFactor > 1.0 || calculator.currentUnbalanceFactor > 5.0
                            }
                            Label { 
                                text: calculator.voltageZeroMagnitude / calculator.voltagePositiveMagnitude > 0.05 ? 
                                        "Ground Fault (Zero Sequence)" : 
                                        calculator.voltageNegativeMagnitude / calculator.voltagePositiveMagnitude > 0.05 ? 
                                        "Phase-Phase Unbalance (Negative Sequence)" : 
                                        "Minor Phase Imbalance";
                                
                                visible: calculator.voltageUnbalanceFactor > 1.0 || calculator.currentUnbalanceFactor > 5.0
                            }
                            
                            // Recommendations
                            Label { 
                                text: "Recommendation:"; 
                                font.bold: true;
                                visible: calculator.voltageUnbalanceFactor > 1.0 || calculator.currentUnbalanceFactor > 5.0
                            }
                            Label { 
                                text: calculator.voltageZeroMagnitude / calculator.voltagePositiveMagnitude > 0.05 ? 
                                        "Check for ground faults" : 
                                        calculator.voltageNegativeMagnitude / calculator.voltagePositiveMagnitude > 0.05 ? 
                                        "Redistribute single-phase loads" : 
                                        "Monitor for changes";
                                
                                visible: calculator.voltageUnbalanceFactor > 1.0 || calculator.currentUnbalanceFactor > 5.0
                            }
                        }
                    }
                }
            }
        }
    }
}
