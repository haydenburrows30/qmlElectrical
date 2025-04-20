import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import FaultCurrent 1.0

Item {
    id: root
    
    property FaultCurrentCalculator calculator: FaultCurrentCalculator {}
    property color textColor: Universal.foreground
    
    // Initialize fields with calculator values to ensure proper two-way binding
    Component.onCompleted: {
        initializeFields()
    }
    
    function initializeFields() {
        // System parameters
        systemVoltage.text = calculator.systemVoltage.toString()
        systemMva.text = calculator.systemMva.toString()
        systemXrRatio.text = calculator.systemXrRatio.toString()
        
        // Transformer parameters
        transformerMva.text = calculator.transformerMva.toString()
        transformerZ.text = calculator.transformerZ.toString()
        transformerXrRatio.text = calculator.transformerXrRatio.toString()
        
        // Cable parameters
        cableLength.text = calculator.cableLength.toString()
        cableR.text = calculator.cableR.toString()
        cableX.text = calculator.cableX.toString()
        
        // Fault parameters
        faultResistance.text = calculator.faultResistance.toString()
        
        // Motor parameters
        includeMotors.checked = calculator.includeMotors
        motorMva.text = calculator.motorMva.toString()
        motorContributionFactor.text = calculator.motorContributionFactor.toString()

        for (let i = 0; i < faultType.model.length; i++) {
            if (faultType.model[i] === calculator.faultType) {
                faultType.currentIndex = i
                break
            }
        }
        
        // Update advanced panel visibility
        advancedPanel.visible = advancedButton.checked
    }

    // Recalculate diagram when values change
    Connections {
        target: calculator
        function onCalculationComplete() {
            faultDiagram.requestPaint()
        }
    }

    PopUpText {
        id: popUpText
        parentCard: helpButton
        popupText: "<h3>Fault Current Calculator</h3><br>" +
                  "This calculator estimates fault currents in an electrical system based on:" +
                  "<ul>" +
                  "<li>System voltage and MVA</li>" +
                  "<li>Transformer impedance</li>" +
                  "<li>Cable resistance and reactance</li>" +
                  "<li>Fault location and type</li>" +
                  "<li>Motor contribution (optional)</li>" +
                  "</ul>" +
                  "Results include:<br>" +
                  "• Initial symmetrical fault current<br>" + 
                  "• Peak fault current<br>" +
                  "• Breaking current<br>" +
                  "• Thermal equivalent current<br><br>" +
                  "<b>Standards:</b> Calculations are based on IEC 60909 methods for fault current calculations in three-phase AC systems. " +
                  "The implementation follows standard industry practices for X/R ratio considerations, DC component decay, and thermal equivalence."
        widthFactor: 0.4
        heightFactor: 0.5
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        Flickable {
            id: flickableContainer
            contentWidth: parent.width
            contentHeight: mainLayout.height + 10
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            // Left side inputs and results
            ColumnLayout {
                id: mainLayout
                width: flickableContainer.width - 20

                RowLayout {
                    id: topHeader
                    Layout.maximumWidth: 800
                    Layout.bottomMargin: 5
                    Layout.leftMargin: 5
                    Layout.alignment: Qt.AlignHCenter

                    Label {
                        text: "Fault Current Calculator"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Information"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: popUpText.open()
                    }
                }

                RowLayout {
                    id: firstRow
                    Layout.maximumWidth: 800
                    Layout.alignment: Qt.AlignHCenter

                    // Inputs
                    WaveCard {
                        title: "System Parameters"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 500
                        Layout.minimumWidth: 350

                        GridLayout {
                            columns: 2
                            anchors.fill: parent

                            // System parameters
                            Label { text: "System Voltage (kV):" }
                            TextFieldRound {
                                id: systemVoltage
                                text: "11"
                                validator: DoubleValidator { bottom: 0.4; decimals: 1 }
                                onTextChanged: if(acceptableInput) calculator.setSystemVoltage(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label { text: "System MVA:" }
                            TextFieldRound {
                                id: systemMva
                                text: "500"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(acceptableInput) calculator.setSystemMva(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label { text: "System X/R Ratio:" }
                            TextFieldRound {
                                id: systemXrRatio
                                text: "15"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(acceptableInput) calculator.setSystemXrRatio(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            // Transformer parameters
                            Label { text: "Transformer Rating (MVA):" }
                            TextFieldRound {
                                id: transformerMva
                                text: "5"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(acceptableInput) calculator.setTransformerMva(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label { text: "Transformer Z%:" }
                            TextFieldRound {
                                id: transformerZ
                                text: "6"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(acceptableInput) calculator.setTransformerZ(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            // Cable parameters
                            Label { text: "Cable Length (km):" }
                            TextFieldRound {
                                id: cableLength
                                text: "0.5"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(acceptableInput) calculator.setCableLength(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label { text: "Cable R (Ω/km):" }
                            TextFieldRound {
                                id: cableR
                                text: "0.2"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(acceptableInput) calculator.setCableR(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label { text: "Cable X (Ω/km):" }
                            TextFieldRound {
                                id: cableX
                                text: "0.15"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(acceptableInput) calculator.setCableX(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            // Fault parameters
                            Label { text: "Fault Type:" }
                            ComboBoxRound {
                                id: faultType
                                model: ["3-Phase", "Line-Line", "Line-Ground", "Line-Line-Ground"]
                                onCurrentTextChanged: calculator.setFaultType(currentText)
                                Layout.fillWidth: true
                            }
                            StyledButton {
                                id: advancedButton
                                text: "Advanced Settings"
                                icon.source: "../../../icons/rounded/settings.svg"
                                checkable: true
                                Layout.alignment: Qt.AlignRight
                                Layout.columnSpan: 2

                                onClicked: {
                                    advancedPanel.visible = !advancedPanel.visible
                                    checked = advancedPanel.visible
                                }
                            }
                        }
                    }

                    // Results section
                    WaveCard {
                        title: "Results"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 500
                        Layout.minimumWidth: 350

                        GridLayout {
                            anchors.fill: parent
                            columns: 2

                            // Main results
                            Label { 
                                text: "Initial Sym. Current:" 
                                Layout.minimumWidth: 100
                            }
                            TextFieldBlue { 
                                text: calculator.initialSymCurrent.toFixed(1) + " kA"
                                Layout.minimumWidth: 100
                            }

                            Label { text: "Peak Fault Current:" }
                            TextFieldBlue { 
                                text: calculator.peakFaultCurrent.toFixed(1) + " kA"
                            }

                            Label { text: "Breaking Current:" }
                            TextFieldBlue { 
                                text: calculator.breakingCurrent.toFixed(1) + " kA"
                            }

                            Label { text: "Thermal Current:" }
                            TextFieldBlue { 
                                text: calculator.thermalCurrent.toFixed(1) + " kA"
                            }

                            // Impedance details
                            Rectangle {
                                color: "transparent"
                                height: 1
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                            }

                            Label { 
                                text: "Impedance Values" 
                                font.bold: true
                                Layout.columnSpan: 2
                            }

                            Label { text: "Total Impedance:" }
                            TextFieldBlue { 
                                text: calculator.totalImpedance.toFixed(3) + " Ω"
                            }
                            
                            Label { text: "R / X Components:" }
                            TextFieldBlue { 
                                text: calculator.totalR.toFixed(3) + " / " + calculator.totalX.toFixed(3) + " Ω"
                            }
                            
                            Label { text: "Effective X/R Ratio:" }
                            TextFieldBlue { 
                                text: calculator.effectiveXrRatio.toFixed(1)
                            }
                            
                            // Per-unit values 
                            Rectangle {
                                color: "transparent"
                                height: 1
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                            }

                            Label { 
                                text: "Per-Unit Values" 
                                font.bold: true
                                Layout.columnSpan: 2
                            }
                            
                            Label { text: "System Z (p.u.):" }
                            TextFieldBlue { 
                                text: calculator.systemPuZ.toFixed(3) 
                            }
                            
                            Label { text: "Transformer Z (p.u.):" }
                            TextFieldBlue { 
                                text: calculator.transformerPuZ.toFixed(3)
                            }
                            
                            Label { text: "Cable Z (p.u.):" }
                            TextFieldBlue { 
                                text: calculator.cablePuZ.toFixed(3)
                            }
                        }
                    }
                
                    // Advanced parameters
                    WaveCard {
                        id: advancedPanel
                        title: "Advanced Settings" 

                        Layout.minimumHeight: 500
                        Layout.minimumWidth: 300
                        visible: false

                        GridLayout {
                            columns: 2
                            anchors.fill: parent
                            anchors.top: parent.top

                            Rectangle {
                                height: 1
                                color: Universal.accent
                                opacity: 0.3
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                Layout.topMargin: 5
                                Layout.bottomMargin: 10
                            }
                            
                            Label { text: "Transformer X/R Ratio:" }
                            TextFieldRound {
                                id: transformerXrRatio
                                text: "10"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(acceptableInput) calculator.setTransformerXrRatio(parseFloat(text))
                                Layout.fillWidth: true
                            }
                            
                            Label { text: "Fault Resistance (Ω):" }
                            TextFieldRound {
                                id: faultResistance
                                text: "0"
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(acceptableInput) calculator.setFaultResistance(parseFloat(text))
                                Layout.fillWidth: true
                            }
                            
                            Label { text: "Include Motors:" }
                            CheckBox {
                                id: includeMotors
                                checked: false
                                onCheckedChanged: calculator.setIncludeMotors(checked)
                            }
                            
                            Label { 
                                text: "Motor Rating (MVA):" 
                                enabled: includeMotors.checked
                            }
                            TextFieldRound {
                                id: motorMva
                                text: "1"
                                enabled: includeMotors.checked
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(acceptableInput) calculator.setMotorMva(parseFloat(text))
                                Layout.fillWidth: true
                            }
                            
                            Label { 
                                text: "Motor Contribution Factor:" 
                                enabled: includeMotors.checked
                            }
                            TextFieldRound {
                                id: motorContributionFactor
                                text: "4"
                                enabled: includeMotors.checked
                                validator: DoubleValidator { bottom: 0 }
                                onTextChanged: if(acceptableInput) calculator.setMotorContributionFactor(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label{Layout.fillHeight: true}
                        }
                    }
                }

                WaveCard {
                    Layout.minimumWidth: firstRow.width
                    Layout.minimumHeight: 300
                    Layout.alignment: Qt.AlignHCenter

                    title: "Fault Current Diagram"

                    Canvas {
                        id: faultDiagram
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()

                            var lineColor = root.Universal.theme === Universal.Dark ? "#FFFFFF" : "#000000"
                            var accentColor = root.Universal.theme === Universal.Dark ? "#00B4FF" : "#0078D4"
                            var motorColor = root.Universal.theme === Universal.Dark ? "#C586C0" : "#9B4F96"
                            ctx.strokeStyle = lineColor
                            ctx.fillStyle = lineColor
                            ctx.lineWidth = 2
                            
                            // Draw system source
                            var startX = 50
                            var centerY = height/2
                            drawSource(ctx, startX, centerY - 50, accentColor)
                            
                            // Draw busbar
                            ctx.lineWidth = 3
                            ctx.beginPath()
                            ctx.moveTo(startX, centerY - 20)
                            ctx.lineTo(width - 50, centerY - 20)
                            ctx.stroke()
                            
                            // Draw transformer
                            drawTransformer(ctx, startX + 100, centerY, accentColor)
                            
                            // Draw cable with R and X annotation
                            drawCable(ctx, startX + 200, centerY, lineColor)
                            
                            // Draw motor contribution if enabled
                            if (calculator.includeMotors) {
                                drawMotor(ctx, startX + 300, centerY + 70, motorColor)
                            }
                            
                            // Draw fault location with lightning bolt and fault resistance if any
                            drawFault(ctx, width - 100, centerY + 20, "#FFB900")
                            
                            ctx.fillStyle = lineColor
                            ctx.font = "bold 12px sans-serif"
                            ctx.textAlign = "center"
                            ctx.fillText(systemVoltage.text + " kV", startX, centerY - 90)
                            ctx.font = "11px sans-serif"
                            ctx.fillText("System MVA: " + systemMva.text, startX, centerY - 75)
                            ctx.fillText("X/R: " + systemXrRatio.text, startX, centerY - 60)
                            
                            ctx.font = "11px sans-serif"
                            ctx.fillText("Z = " + transformerZ.text + "%", startX + 115, centerY + 50)
                            ctx.fillText("X/R = " + transformerXrRatio.text, startX + 115, centerY + 65)
                            
                            // Update cable annotation to show R and X
                            ctx.fillText(cableLength.text + " km (R=" + cableR.text + ", X=" + cableX.text + " Ω/km)", 
                                        startX + 300, centerY - 40)
                            
                            // Show motor contribution if enabled
                            if (calculator.includeMotors) {
                                ctx.fillStyle = motorColor
                                ctx.fillText(motorMva.text + " MVA", startX + 300, centerY + 110)
                            }
                            
                            // Show fault resistance if non-zero
                            if (parseFloat(faultResistance.text) > 0) {
                                ctx.fillStyle = "#FFB900"
                                ctx.fillText("Rf = " + faultResistance.text + " Ω", width - 100, centerY + 80)
                            }
                            
                            // Draw fault current with highlight
                            ctx.font = "bold 13px sans-serif"
                            ctx.fillStyle = "#FFB900"
                            ctx.fillText("If = " + calculator.initialSymCurrent.toFixed(1) + " kA", width - 100, centerY + 60)
                            ctx.font = "11px sans-serif"
                            ctx.fillText(faultType.currentText + " Fault", width - 100, centerY + 40)
                        }
                        
                        // Existing drawing functions...
                        function drawSource(ctx, x, y, accentColor) {
                            // Outer circle
                            ctx.beginPath()
                            ctx.strokeStyle = accentColor
                            ctx.lineWidth = 2.5
                            ctx.arc(x, y, 22, 0, 2 * Math.PI)
                            ctx.stroke()
                            
                            // Inner symbol
                            ctx.beginPath()
                            ctx.strokeStyle = ctx.fillStyle
                            ctx.lineWidth = 2
                            ctx.moveTo(x-12, y)
                            ctx.lineTo(x+12, y)
                            ctx.moveTo(x, y-12)
                            ctx.lineTo(x, y+12)
                            ctx.stroke()
                        }
                        
                        function drawTransformer(ctx, x, y, accentColor) {
                            ctx.strokeStyle = accentColor
                            ctx.lineWidth = 2.5
                            
                            // Primary winding
                            ctx.beginPath()
                            drawRoundedLine(ctx, x, y-25, x, y+25, 4)
                            
                            // Secondary winding
                            ctx.beginPath()
                            drawRoundedLine(ctx, x+20, y-25, x+20, y+25, 4)
                            
                            // Core lines
                            ctx.lineWidth = 1.5
                            ctx.beginPath()
                            ctx.moveTo(x-5, y-20)
                            ctx.lineTo(x+25, y-20)
                            ctx.moveTo(x-5, y+20)
                            ctx.lineTo(x+25, y+20)
                            ctx.stroke()
                        }
                        
                        function drawRoundedLine(ctx, x1, y1, x2, y2, radius) {
                            ctx.moveTo(x1, y1 + radius)
                            ctx.arcTo(x1, y1, x1 + radius, y1, radius)
                            ctx.lineTo(x2, y1)
                            ctx.arcTo(x2, y1, x2, y1 + radius, radius)
                            ctx.lineTo(x2, y2 - radius)
                            ctx.arcTo(x2, y2, x2 - radius, y2, radius)
                            ctx.stroke()
                        }
                        
                        function drawCable(ctx, x, y, lineColor) {
                            ctx.strokeStyle = lineColor
                            ctx.lineWidth = 2.5
                            
                            // Main line
                            ctx.beginPath()
                            ctx.moveTo(x, y-20)
                            ctx.lineTo(x+200, y-20)
                            ctx.stroke()
                            
                            // Impedance symbol
                            ctx.lineWidth = 2
                            ctx.beginPath()
                            var amplitude = 12
                            var period = 15
                            ctx.moveTo(x + 20, y-20)
                            for(var i = 0; i <= 180; i++) {
                                var xPos = x + 20 + i
                                var yPos = y - 20 + Math.sin(i/period) * amplitude
                                ctx.lineTo(xPos, yPos)
                            }
                            ctx.stroke()
                        }
                        
                        function drawFault(ctx, x, y, faultColor) {
                            ctx.strokeStyle = faultColor
                            ctx.lineWidth = 3
                            ctx.beginPath()
                            ctx.moveTo(x, y-40)
                            ctx.lineTo(x-8, y-25)
                            ctx.lineTo(x+8, y-10)
                            ctx.lineTo(x-8, y+5)
                            ctx.lineTo(x+8, y+20)
                            ctx.lineTo(x, y+35)
                            ctx.stroke()

                            ctx.strokeStyle = faultColor + "40" // 40 = 25% opacity
                            ctx.lineWidth = 6
                            ctx.stroke()
                        }
                        
                        // New function to draw motor contribution
                        function drawMotor(ctx, x, y, motorColor) {
                            ctx.strokeStyle = motorColor
                            ctx.lineWidth = 2
                            
                            // Motor connection to busbar
                            ctx.beginPath()
                            ctx.moveTo(x, y - 40)
                            ctx.lineTo(x, y)
                            ctx.stroke()
                            
                            // Motor circle
                            ctx.beginPath()
                            ctx.arc(x, y + 20, 20, 0, 2 * Math.PI)
                            ctx.stroke()
                            
                            // Motor symbol (M)
                            ctx.fillStyle = motorColor
                            ctx.font = "bold 16px sans-serif"
                            ctx.textAlign = "center"
                            ctx.fillText("M", x, y + 25)
                        }
                    }
                }
            }
        }
    }
}
