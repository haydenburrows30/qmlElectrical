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
    property SeriesHelper seriesHelper: SeriesHelper {}  // Add the helper

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
                                onTextChanged: if(text) {
                                    calculator.setHarmonic(modelData, parseFloat(text), phaseField.text ? parseFloat(phaseField.text) : 0)
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
                                onTextChanged: if(text) {
                                    calculator.setHarmonic(modelData, magnitudeField.text ? parseFloat(magnitudeField.text) : 0, parseFloat(text))
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
        }

        // Right Panel - Visualizations
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Waveform Chart
            WaveCard {
                title: "Waveform"
                Layout.fillHeight: true
                Layout.fillWidth: true

                ChartView {
                    anchors.fill: parent
                    antialiasing: true
                    legend.visible: true
                    legend.alignment: Qt.AlignBottom

                    theme: Universal.theme

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
                    }
                    
                    LineSeries {
                        id: fundamentalSeries
                        name: "Fundamental"
                        axisX: axisX
                        axisY: axisY
                        color: "lightblue"
                        width: 1.5
                        visible: showFundamentalCheckbox.checked
                    }

                    // Update waveform when it changes - optimize updates using the helper
                    Connections {
                        target: calculator
                        function onWaveformChanged() {
                            var points = calculator.waveform
                            var fundamentalData = calculator.fundamentalWaveform
                            var maxY = 0
                            
                            // Find maximum magnitude for scaling
                            for (var i = 0; i < points.length; i++) {
                                maxY = Math.max(maxY, Math.abs(points[i]))
                                if (fundamentalData && i < fundamentalData.length) {
                                    maxY = Math.max(maxY, Math.abs(fundamentalData[i]))
                                }
                            }
                            
                            // Set axis range with 20% padding
                            axisY.min = -Math.ceil(maxY * 1.2)
                            axisY.max = Math.ceil(maxY * 1.2)
                            
                            // Use the efficient series filling methods
                            var xValues = []
                            for (var i = 0; i < points.length; i++) {
                                xValues.push(i * (360/points.length))
                            }
                            
                            // Fill both series efficiently
                            seriesHelper.fillSeriesFromArrays(waveformSeries, xValues, points)
                            seriesHelper.fillSeriesFromArrays(fundamentalSeries, xValues, fundamentalData)
                        }
                    }
                    
                    // Control for showing fundamental component
                    CheckBox {
                        id: showFundamentalCheckbox
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
                }
            }

            WaveCard {
                Layout.fillHeight: true
                Layout.fillWidth: true
                title: "Harmonic Spectrum"

            // Harmonic Spectrum
                ChartView {
                    anchors.fill: parent
                    antialiasing: true
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
                        pointsVisible: true
                    }

                    // Optimize spectrum updates
                    Connections {
                        target: calculator
                        function onHarmonicsChanged() {
                            harmonicSeries.clear()
                            phaseAngleSeries.clear()
                            
                            var data = calculator.individualDistortion
                            var phaseData = calculator.harmonicPhases
                            var maxY = 0
                            
                            // Find maximum magnitude for scaling
                            for (var i = 0; i < data.length; i++) {
                                maxY = Math.max(maxY, data[i])
                            }
                            
                            // Set axis range with 20% padding
                            spectrumAxisY.max = Math.ceil(maxY * 1.2)
                            
                            // Update bar series
                            harmonicSeries.append("Magnitude", data)
                            
                            // Update phase series
                            if (phaseData && phaseData.length > 0) {
                                var harmOrder = [1, 3, 5, 7, 11, 13]
                                
                                for (var i = 0; i < harmOrder.length && i < phaseData.length; i++) {
                                    // Plot in the middle of each bar
                                    phaseAngleSeries.append(i + 0.5, phaseData[i])
                                }
                            }
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
                }
            }
        }
    }
}
