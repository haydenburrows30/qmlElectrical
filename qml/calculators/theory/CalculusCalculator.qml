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
import SeriesHelper 1.0

Item {
    id: root

    property CalculusCalculator calculator: CalculusCalculator {}
    property SeriesHelper seriesHelper: SeriesHelper {}
    property color textColor: Universal.foreground

    function updateChartVisibility() {
        if (scaleToggleButton.isLogScale) {
            functionGraph.visible = false
            logGraph.visible = true
        } else {
            functionGraph.visible = true
            logGraph.visible = false
        }
    }

    Component.onCompleted: {
        if (calculator) {
            // Trigger initial calculation
            calculator.calculate()
        }
    }

    MessagePopup {
        id: messagePopup
        anchors.centerIn: parent
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

                    // Add PDF export button
                    StyledButton {
                        id: exportButton
                        icon.source: "../../../icons/rounded/download.svg"
                        ToolTip.text: "Export to PDF"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        
                        onClicked: {
                            if (calculator) {
                                calculator.exportReport()
                            }
                        }
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
                        Layout.preferredHeight: resultsCard.height

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

                            SliderText {
                                id: parameterASpinBox
                                from: functionTypeCombo.currentText =="Sine" || functionTypeCombo.currentText =="Gaussian" ? -10 : 1
                                to: 10
                                sliderDecimal: 0
                                value: calculator.parameterA
                                stepSize: 1
                                Layout.fillWidth: true

                                property real realValue: value

                                onMoved: calculator.setParameterA(Number(value))
                                onTextChangedSignal: calculator.setParameterA(Number(value))
                            }
                            
                            Label {
                                text: calculator.parameterBName + ":"
                                font.bold: true
                                visible: calculator.showParameterB
                            }

                            SliderText {
                                id: parameterBSpinBox
                                from: functionTypeCombo.currentText =="Sine" || functionTypeCombo.currentText =="Gaussian" ? 1 : 2
                                to: functionTypeCombo.currentText =="Sine" || functionTypeCombo.currentText =="Gaussian" ? 100 : 12
                                sliderDecimal: 0
                                value: calculator.parameterB
                                stepSize: functionTypeCombo.currentText =="Sine" || functionTypeCombo.currentText =="Gaussian" ? 1 : 2
                                Layout.fillWidth: true

                                visible: calculator.showParameterB

                                property real realValue: value

                                onMoved: calculator.setParameterB(value)
                                onTextChangedSignal: calculator.setParameterB(value)
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
                                    }
                                }
                                
                                CheckBox {
                                    id: derivativeCheckbox
                                    text: "Derivative"
                                    checked: false
                                    onCheckedChanged: {
                                        derivativeSeries.visible = checked
                                    }
                                }
                                
                                CheckBox {
                                    id: integralCheckbox
                                    text: "Integral"
                                    checked: false
                                    onCheckedChanged: {
                                        integralSeries.visible = checked
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        id: resultsCard

                        // Practical applications
                        WaveCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50

                            titleVisible: false
                                
                            Label {
                                id: applicationText
                                anchors.verticalCenter: parent.verticalCenter
                                text: "<b>Applications in Electrical Engineering: </b>" + calculator.applicationExample.split('\n\n')[0] || ""
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

                    ChartView {
                        id: logGraph
                        anchors.fill: parent
                        antialiasing: true
                        legend.visible: true
                        legend.alignment: Qt.AlignTop
                        theme: window.modeToggled ? ChartView.ChartThemeDark : ChartView.ChartThemeLight

                        ValueAxis {
                            id: axisX2
                            min: -5
                            max: 5
                            tickCount: 11
                            labelFormat: "%.0f"
                            titleText: "x"
                        }

                        LogValueAxis {
                            id: axisY2
                            base: 10
                            labelFormat: "%.0f"
                            titleText: "y"
                        }
                        
                        LineSeries {
                            id: functionSeries2
                            name: "f(x)"
                            color: "#2196F3"
                            width: 2
                            axisX: axisX2
                            axisY: axisY2
                            visible: functionCheckbox.checked
                        }
                        
                        LineSeries {
                            id: derivativeSeries2
                            name: "f'(x)"
                            color: "#FF5722"
                            width: 2
                            axisX: axisX2
                            axisY: axisY2
                            visible: derivativeCheckbox.checked
                        }
                        
                        LineSeries {
                            id: integralSeries2
                            name: "∫f(x)dx"
                            color: "#4CAF50"
                            width: 2
                            axisX: axisX2
                            axisY: axisY2
                            visible: integralCheckbox.checked
                        }
                    }

                    // Add a toggle button above the charts
                    RowLayout {
                        id: chartControls
                        anchors {
                            right: parent.right
                            top: parent.top
                            topMargin: 10
                            rightMargin: 10
                        }
                        
                        Label {
                            text: "Scale:"
                            font.bold: true
                        }
                        
                        StyledButton {
                            id: scaleToggleButton
                            property bool isLogScale: false
                            text: isLogScale ? "Log" : "Linear"
                            implicitWidth: 80
                            
                            onClicked: {
                                isLogScale = !isLogScale
                                root.updateChartVisibility()
                            }
                            
                            ToolTip.text: "Toggle between linear and logarithmic scale"
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                        }
                        
                        StyledButton {
                            text: "Auto"
                            implicitWidth: 60
                            
                            onClicked: {
                                // Auto-adjust Y axis
                                calculator.autoAdjustYAxis()
                                calculator.resultsCalculated()
                            }
                            
                            ToolTip.text: "Auto-adjust axis scaling"
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                        }
                    }
                    
                    // Update the chart when data changes
                    Connections {
                        target: calculator
                        function onResultsCalculated() {
                            // Clear existing data for both charts
                            functionSeries.removePoints(0, functionSeries.count)
                            derivativeSeries.removePoints(0, derivativeSeries.count)
                            integralSeries.removePoints(0, integralSeries.count)
                            
                            functionSeries2.removePoints(0, functionSeries2.count)
                            derivativeSeries2.removePoints(0, derivativeSeries2.count)
                            integralSeries2.removePoints(0, integralSeries2.count)
                            
                            // Add new data points
                            var xValues = calculator.xValues
                            var yValues1 = calculator.functionValues
                            var yValues2 = calculator.derivativeValues
                            var yValues3 = calculator.integralValues

                            // Fill data for linear chart
                            if (yValues1 && functionCheckbox.checked) {
                                seriesHelper.fillSeriesFromArrays(
                                    functionSeries,
                                    xValues,
                                    yValues1
                                )
                            }
                            if (yValues2 && derivativeCheckbox.checked) {
                                seriesHelper.fillSeriesFromArrays(
                                    derivativeSeries,
                                    xValues,
                                    yValues2
                                )
                            }
                            if (yValues3 && integralCheckbox.checked) {
                                seriesHelper.fillSeriesFromArrays(
                                    integralSeries,
                                    xValues,
                                    yValues3
                                )
                            }
                            
                            // Fill data for logarithmic chart
                            // For log scale, we need positive values only
                            if (yValues1 && functionCheckbox.checked) {
                                var positiveValues1 = calculator.getPositiveValues(yValues1)
                                seriesHelper.fillSeriesFromArrays(
                                    functionSeries2,
                                    xValues,
                                    positiveValues1
                                )
                            }
                            if (yValues2 && derivativeCheckbox.checked) {
                                var positiveValues2 = calculator.getPositiveValues(yValues2)
                                seriesHelper.fillSeriesFromArrays(
                                    derivativeSeries2,
                                    xValues,
                                    positiveValues2
                                )
                            }
                            if (yValues3 && integralCheckbox.checked) {
                                var positiveValues3 = calculator.getPositiveValues(yValues3)
                                seriesHelper.fillSeriesFromArrays(
                                    integralSeries2,
                                    xValues,
                                    positiveValues3
                                )
                            }

                            // Set axis ranges based on function type
                            calculator.setAxisRange(axisY, functionTypeCombo.currentText)
                            
                            // Configure log axis
                            calculator.configureLogAxis(axisY2, functionTypeCombo.currentText)
                            
                            // Decide which chart to show based on function type and toggle state
                            if (functionTypeCombo.currentText === "Exponential") {
                                // For exponential functions, suggest log scale
                                scaleToggleButton.isLogScale = true
                            }
                            
                            // Update chart visibility
                            root.updateChartVisibility()
                        }
                    }
                }
            }
        }
    }

    // Add connections for export status notifications
    Connections {
        target: calculator
        
        function onExportComplete(success, message) {
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
    }
}
