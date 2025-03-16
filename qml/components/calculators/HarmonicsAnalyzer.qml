import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../../components"
import "../visualizers"
import "../inputs"
import "../displays"
import "../monitors"
import HarmonicAnalysis 1.0
import SeriesHelper 1.0

Item {
    id: harmonicsCard

    property HarmonicAnalysisCalculator calculator: HarmonicAnalysisCalculator {}
    property SeriesHelper seriesHelper: SeriesHelper {}

    // Use a timer to batch UI updates and defer them slightly
    Timer {
        id: updateWaveformTimer
        interval: Qt.platform.os === "windows" ? 100 : 50  // Increase interval on Windows
        running: false
        repeat: false
        onTriggered: {
            if (waveformVisualizer) {
                waveformVisualizer.updateWaveform();
            }
        }
    }
    
    // Timer for harmonics updates
    Timer {
        id: updateHarmonicsTimer
        interval: 50  // Increase to 50ms for less frequent updates
        running: false
        repeat: false
        onTriggered: {
            if (harmonicSpectrum) {
                harmonicSpectrum.updateHarmonics();
            }
        }
    }

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
                    
                    // Use the new HarmonicInputForm component
                    HarmonicInputForm {
                        id: harmonicForm
                        calculator: harmonicsCard.calculator
                        Layout.fillWidth: true
                        
                        onResetTriggered: {
                            // Additional reset actions if needed
                        }
                    }

                    // Use the new ResultsDisplay component
                    ResultsDisplay {
                        id: resultsDisplay
                        calculator: harmonicsCard.calculator
                        Layout.fillWidth: true
                        Layout.topMargin: 10
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
            
        } // Close ColumnLayout

        // Right Panel - Visualizations
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Waveform Chart
            WaveCard {
                id: waveformCard
                title: "Waveform"
                Layout.fillHeight: true
                Layout.fillWidth: true

                // Use the WaveformVisualizer component
                WaveformVisualizer {
                    id: waveformVisualizer
                    anchors.fill: parent
                    calculator: harmonicsCard.calculator
                    seriesHelper: harmonicsCard.seriesHelper
                }
                
                // Add visibility control - Fix binding loop
                CheckBox {
                    id: showLabels
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 5
                    text: "Show degree labels"
                    checked: true
                    z: 10

                    onCheckedChanged: {
                        // Update axis labels directly using the visualizer function
                        if (waveformVisualizer) {
                            waveformVisualizer.setLabelsVisible(checked);
                        }
                    }
                }
                
                // Add performance settings button
                Button {
                    id: performanceButton
                    anchors {
                        right: parent.right
                        top: parent.top
                        margins: 10
                    }
                    text: "Performance Settings"
                    onClicked: performancePopup.open()
                }

                // Keep fundamental checkbox
                CheckBox {
                    id: fundamentalCheckbox
                    text: "Show Fundamental"
                    checked: false
                    anchors {
                        right: performanceButton.left
                        top: parent.top
                        margins: 10
                    }
                    
                    onCheckedChanged: {
                        if (waveformVisualizer) {
                            waveformVisualizer.showFundamental = checked;
                        }
                    }
                }

                // Add performance popup
                PerformancePopup {
                    id: performancePopup
                    x: Math.round((parent.width - width) / 2)
                    y: Math.round((parent.height - height) / 2)
                }

                // Add the calculation monitor
                CalculationMonitor {
                    id: calculationMonitor
                    anchors.fill: parent
                    calculator: harmonicsCard.calculator
                    profilingEnabled: true
                }
            }

            WaveCard {
                id: harmonicSpectrumCard
                Layout.fillHeight: true
                Layout.fillWidth: true
                title: "Harmonic Spectrum"

                // Use our HarmonicSpectrum component
                HarmonicSpectrum {
                    id: harmonicSpectrum
                    anchors.fill: parent
                    calculator: harmonicsCard.calculator
                    showPhaseAngles: showPhaseCheckbox.checked
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
                        if (harmonicSpectrum) {
                            harmonicSpectrum.showPhaseAngles = checked;
                        }
                    }
                }
            }
        }

    } // Close main RowLayout

    // Connect to calculator signal to trigger updates
    Connections {
        target: calculator
        
        function onCalculationsComplete() {
            updateWaveformTimer.start();
            updateHarmonicsTimer.start();
        }
    }
} // Close root Item
