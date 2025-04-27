import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import Calculus 1.0

Item {
    id: root

    property CalculusCalculator calculator: CalculusCalculator {}
    property color textColor: Universal.foreground
    
    // Function to update the Y-axis range based on visible series
    function updateYAxisRange() {
        // Get all values from visible series
        var allValues = []
        
        if (functionSeries && functionSeries.visible) {
            for (var i = 0; i < functionSeries.count; i++) {
                // Only include finite values
                var y = functionSeries.at(i).y
                if (isFinite(y) && Math.abs(y) < 1000) {
                    allValues.push(y)
                }
            }
        }
        
        if (derivativeSeries && derivativeSeries.visible) {
            for (var i = 0; i < derivativeSeries.count; i++) {
                var y = derivativeSeries.at(i).y
                if (isFinite(y) && Math.abs(y) < 1000) {
                    allValues.push(y)
                }
            }
        }
        
        if (integralSeries && integralSeries.visible) {
            for (var i = 0; i < integralSeries.count; i++) {
                var y = integralSeries.at(i).y
                if (isFinite(y) && Math.abs(y) < 1000) {
                    allValues.push(y)
                }
            }
        }
        
        // If we have values, adjust the axis
        if (allValues.length > 0) {
            var minY = Math.min(...allValues)
            var maxY = Math.max(...allValues)
            
            // Add some padding to the range
            var padding = (maxY - minY) * 0.1
            if (padding < 1) padding = 1
            
            // Ensure we have reasonable bounds
            axisY.min = Math.max(-100, minY - padding)
            axisY.max = Math.min(100, maxY + padding)
            
            // Ensure min is less than max (in case of extreme values or errors)
            if (axisY.min >= axisY.max) {
                axisY.min = -10
                axisY.max = 10
            }
        } else {
            // Default range if no valid points
            axisY.min = -10
            axisY.max = 10
        }
    }
    
    PopUpText {
        id: popUpText
        parentCard: helpButton
        popupText: "<h3>Calculus Calculator</h3><br>" +
                   "This calculator demonstrates the relationships between functions, their derivatives, and integrals.<br><br>" +
                   "<b>Differentiation:</b><br>" +
                   "The derivative measures the instantaneous rate of change of a function at a point. In electrical engineering, " +
                   "derivatives are used for calculating the rate of change of voltage or current, analyzing circuit transients, " +
                   "and in control systems.<br><br>" +
                   "<b>Integration:</b><br>" +
                   "Integration finds the area under a curve. It's used for determining total energy, calculating total charge, " +
                   "finding average values of waveforms, and solving differential equations in circuit analysis.<br><br>" +
                   "<b>Interactive Features:</b><br>" +
                   "• Select different function types<br>" +
                   "• Adjust function parameters<br>" +
                   "• View the function, its derivative, and integral simultaneously<br>" +
                   "• See practical applications in electrical engineering<br><br>" +
                   "<b>Key Relationships:</b><br>" +
                   "• The derivative of the integral of a function returns the original function<br>" +
                   "• The integral of the derivative of a function returns the original function plus a constant"
        widthFactor: 0.7
        heightFactor: 0.7
    }
    
    PopUpText {
        id: differentiationPopup
        parentCard: differentiationHelpButton
        popupText: "<h3>Differentiation in Electrical Engineering</h3><br>" +
                   "<b>Key Applications:</b><br>" +
                   "• <b>Circuit Analysis:</b> Calculating current through capacitors (I = C·dV/dt)<br>" +
                   "• <b>Control Systems:</b> Rate of change of error signals determines response characteristics<br>" +
                   "• <b>Signal Processing:</b> Finding signal slopes and zero-crossings<br>" +
                   "• <b>Power Systems:</b> Rate of change of voltage/current for fault detection<br>" +
                   "• <b>Transient Analysis:</b> Understanding how quickly circuit variables change<br><br>" +
                   "<b>Mathematical Definition:</b><br>" +
                   "The derivative is defined as: f'(x) = lim<sub>h→0</sub> [f(x+h) - f(x)]/h<br><br>" +
                   "<b>Common Derivatives:</b><br>" +
                   "• d/dx(sin(x)) = cos(x)<br>" +
                   "• d/dx(e^x) = e^x<br>" +
                   "• d/dx(x^n) = n·x^(n-1)<br><br>" +
                   "<b>Applications of the Selected Function:</b><br>" +
                   "The derivative shows the slope of the function at each point."
        widthFactor: 0.6
        heightFactor: 0.6
    }
    
    PopUpText {
        id: integrationPopup
        parentCard: integrationHelpButton
        popupText: "<h3>Integration in Electrical Engineering</h3><br>" +
                   "<b>Key Applications:</b><br>" +
                   "• <b>Energy Calculation:</b> E = ∫P(t)·dt (energy from power over time)<br>" +
                   "• <b>RMS Values:</b> Finding effective values of non-sinusoidal waveforms<br>" +
                   "• <b>Charge Calculation:</b> Q = ∫I(t)·dt (charge from current over time)<br>" +
                   "• <b>Electromagnetic Fields:</b> Finding total magnetic flux<br>" +
                   "• <b>Filter Design:</b> Determining frequency response of circuits<br><br>" +
                   "<b>Mathematical Definition:</b><br>" +
                   "The definite integral is defined as: ∫<sub>a</sub><sup>b</sup> f(x) dx = lim<sub>n→∞</sub> Σ<sub>i=1</sub><sup>n</sup> f(x<sub>i</sub>)·Δx<br><br>" +
                   "<b>Common Integrals:</b><br>" +
                   "• ∫sin(x) dx = -cos(x) + C<br>" +
                   "• ∫e^x dx = e^x + C<br>" +
                   "• ∫x^n dx = x^(n+1)/(n+1) + C (n ≠ -1)<br><br>" +
                   "<b>Applications of the Selected Function:</b><br>" +
                   "The integral represents the accumulation or total area under the function curve."
        widthFactor: 0.6
        heightFactor: 0.6
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        Flickable {
            id: flickableContainer
            contentWidth: parent.width
            contentHeight: mainLayout.height
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            ColumnLayout {
                id: mainLayout
                width: parent.width - 20

                // Header section
                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Calculus Calculator"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    StyledButton {
                        id: integrationHelpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Integration Help"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: integrationPopup.open()
                        text: "Int"
                    }

                    StyledButton {
                        id: differentiationHelpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Differentiation Help"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: differentiationPopup.open()
                        text: "Diff"
                    }
                    
                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Help"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: popUpText.open()
                        text: "Calc"
                    }
                }

                RowLayout {

                    // Parameters section
                    WaveCard {
                        title: "Function Parameters"
                        Layout.minimumWidth: 450
                        Layout.preferredHeight: 280

                        GridLayout {
                            anchors.fill: parent
                            columns: 2
                            columnSpacing: 20
                            
                            Label {
                                text: "Function Type:"
                                font.bold: true
                            }
                            
                            ComboBoxRound {
                                id: functionTypeCombo
                                // Use a direct binding to a standard JavaScript array
                                // instead of relying on the calculator's availableFunctions property
                                model: ["Sine", "Polynomial", "Exponential", "Power", "Gaussian"]
                                Layout.fillWidth: true
                                currentIndex: model.indexOf(calculator.functionType)
                                
                                onCurrentTextChanged: {
                                    calculator.setFunctionType(currentText)
                                }
                            }
                            
                            Label {
                                text: calculator.parameterAName + ":"
                                font.bold: true
                            }
                            
                            SpinBoxRound {
                                id: parameterASpinBox
                                from: -10
                                to: 10
                                stepSize: 1
                                value: calculator.parameterA
                                editable: true
                                Layout.fillWidth: true
                                
                                onValueModified: {
                                    calculator.setParameterA(Number(value))
                                }
                                
                                textFromValue: function(value, locale) {
                                    return Number(value).toLocaleString(locale, 'f', 2)
                                }
                                
                                valueFromText: function(text, locale) {
                                    return Number.fromLocaleString(locale, text)
                                }
                            }
                            
                            Label {
                                text: calculator.parameterBName + ":"
                                font.bold: true
                                visible: calculator.showParameterB
                            }
                            
                            SpinBoxRound {
                                id: parameterBSpinBox
                                from: -100
                                to: 100
                                stepSize: 1
                                value: Math.round(calculator.parameterB * 10)
                                editable: true
                                Layout.fillWidth: true
                                visible: calculator.showParameterB
                                
                                onValueModified: {
                                    calculator.setParameterB(value / 10)
                                }
                                
                                textFromValue: function(value, locale) {
                                    return (value / 10).toLocaleString(locale, 'f', 1)
                                }
                                
                                valueFromText: function(text, locale) {
                                    return Math.round(Number.fromLocaleString(locale, text) * 10)
                                }
                            }
                            
                            Label {
                                text: "Current Function:"
                                font.bold: true
                            }
                            
                            Label {
                                text: "f(x) = " + calculator.functionFormula
                                font.italic: true
                                font.pixelSize: 16
                                Layout.fillWidth: true
                                textFormat: Text.RichText
                            }

                            RowLayout {
                                Layout.columnSpan: 2
                                
                                Label {
                                    text: "Show Curves:"
                                    font.bold: true
                                }
                                
                                CheckBox {
                                    id: functionCheckbox
                                    text: "Function"
                                    checked: true
                                    onCheckedChanged: {
                                        functionSeries.visible = checked
                                        updateYAxisRange()
                                    }
                                }
                                
                                CheckBox {
                                    id: derivativeCheckbox
                                    text: "Derivative"
                                    checked: false
                                    onCheckedChanged: {
                                        derivativeSeries.visible = checked
                                        updateYAxisRange()
                                    }
                                }
                                
                                CheckBox {
                                    id: integralCheckbox
                                    text: "Integral"
                                    checked: false
                                    onCheckedChanged: {
                                        integralSeries.visible = checked
                                        updateYAxisRange()
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {

                        // Practical applications
                        WaveCard {
                            title: "Applications in Electrical Engineering"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 90
                                
                            Label {
                                id: applicationText
                                anchors.fill: parent
                                text: calculator.applicationExample.split('\n\n')[0] || ""
                                wrapMode: Text.WordWrap
                                font.pixelSize: 14
                            }
                        }

                        RowLayout {

                            // Differentiation card
                            WaveCard {
                                title: "Differentiation"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 230

                                ColumnLayout {
                                    id: differentiationCardContent
                                    anchors.fill: parent

                                    Label {
                                        text: "Differentiation finds the rate of change of a function."
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 2
                                        color: "#dddddd"
                                        Layout.bottomMargin: 5
                                    }

                                    Label {
                                        text: "Original function: f(x) = " + calculator.functionFormula
                                        font.italic: true
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.RichText
                                    }

                                    Label {
                                        text: "Derivative: f'(x) = " + calculator.derivativeFormula
                                        font.italic: true
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.RichText
                                    }

                                    

                                    Label {
                                        text: "Practical Application:"
                                        font.bold: true
                                    }

                                    Label {
                                        Layout.minimumHeight: 100
                                        Layout.fillWidth: true
                                        text: calculator.applicationExample.split('\n\n')[1] || ""
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            // Integration card
                            WaveCard {
                                title: "Integration"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 230

                                ColumnLayout {
                                    id: integrationCardContent
                                    anchors.fill: parent

                                    Label {
                                        text: "Integration finds the accumulated value (area under the curve) of a function."
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 2
                                        color: "#dddddd"
                                        Layout.bottomMargin: 5
                                    }

                                    Label {
                                        text: "Original function: f(x) = " + calculator.functionFormula
                                        font.italic: true
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.RichText
                                    }

                                    Label {
                                        text: "Integral: ∫f(x)dx = " + calculator.integralFormula
                                        font.italic: true
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        textFormat: Text.RichText
                                    }

                                    Label {
                                        text: "Practical Application:"
                                        font.bold: true
                                    }

                                    Label {
                                        Layout.minimumHeight: 100
                                        Layout.fillWidth: true
                                        text: calculator.applicationExample.split('\n\n')[2] || ""
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }
                    }
                }

                // Function visualization
                WaveCard {
                    title: "Function Visualization"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 500
                    
                    ChartView {
                        id: functionGraph
                        anchors.fill: parent
                        antialiasing: true
                        legend.visible: true
                        legend.alignment: Qt.AlignTop
                        theme: window.modeToggled ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
                        
                        ValueAxis {
                            id: axisX
                            min: -5
                            max: 5
                            tickCount: 11
                            labelFormat: "%.0f"
                            titleText: "x"
                        }
                        
                        ValueAxis {
                            id: axisY
                            min: -10
                            max: 10
                            tickCount: 5
                            labelFormat: "%.0f"
                            titleText: "y"
                        }
                        
                        LineSeries {
                            id: functionSeries
                            name: "f(x)"
                            color: "#2196F3"
                            width: 2
                            axisX: axisX
                            axisY: axisY
                            visible: functionCheckbox.checked
                        }
                        
                        LineSeries {
                            id: derivativeSeries
                            name: "f'(x)"
                            color: "#FF5722"
                            width: 2
                            axisX: axisX
                            axisY: axisY
                            visible: derivativeCheckbox.checked
                        }
                        
                        LineSeries {
                            id: integralSeries
                            name: "∫f(x)dx"
                            color: "#4CAF50"
                            width: 2
                            axisX: axisX
                            axisY: axisY
                            visible: integralCheckbox.checked
                        }
                    }
                    
                    // Update the chart when data changes
                    Connections {
                        target: calculator
                        function onResultsCalculated() {
                            // Clear existing data
                            functionSeries.removePoints(0, functionSeries.count)
                            derivativeSeries.removePoints(0, derivativeSeries.count)
                            integralSeries.removePoints(0, integralSeries.count)
                            
                            // Add new data points
                            var xValues = calculator.xValues
                            var yValues1 = calculator.functionValues
                            var yValues2 = calculator.derivativeValues
                            var yValues3 = calculator.integralValues
                            
                            // Add points to series, with safety check for each point
                            for (var i = 0; i < xValues.length; i++) {
                                if (isFinite(yValues1[i])) {
                                    functionSeries.append(xValues[i], yValues1[i])
                                }
                                if (isFinite(yValues2[i])) {
                                    derivativeSeries.append(xValues[i], yValues2[i])
                                }
                                if (isFinite(yValues3[i])) {
                                    integralSeries.append(xValues[i], yValues3[i])
                                }
                            }
                            
                            // Update Y-axis range
                            updateYAxisRange()
                        }
                    }
                }
            }
        }
    }
}
