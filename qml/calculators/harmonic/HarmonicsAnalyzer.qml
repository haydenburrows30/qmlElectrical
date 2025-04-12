import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../"
import "../visualizers"
import "../inputs"
import "../displays"
import "../monitors"
import "../popups/"
import "../style"
import "../charts"
import "../buttons"

import HarmonicAnalysis 1.0
import SeriesHelper 1.0

Item {
    id: harmonicsCard

    property HarmonicAnalysisCalculator calculator: HarmonicAnalysisCalculator {}
    property SeriesHelper seriesHelper: SeriesHelper {}

    Timer {
        id: updateWaveformTimer
        interval: Qt.platform.os === "windows" ? 100 : 50
        running: false
        repeat: false
        onTriggered: {
            if (waveformVisualizer) {
                waveformVisualizer.updateWaveform();
            }
        }
    }
    
    Timer {
        id: updateHarmonicsTimer
        interval: 50
        running: false
        repeat: false
        onTriggered: {
            if (harmonicSpectrum) {
                harmonicSpectrum.updateHarmonics();
            }
        }
    }

    PopUpText {
        parentCard: results
        widthFactor: 0.3
        heightFactor: 0.3
        popupText: "<h3>Harmonic Analyzer</h3><br>" +
                "Analyze the harmonic components of a waveform. " +
                "You can adjust the amplitude and phase of each harmonic component to see how it affects the waveform. <br>" +
                "You can also export the harmonic data to a CSV file for further analysis."
    }

    RowLayout {
        anchors.fill: parent

        ColumnLayout {
            Layout.maximumWidth: 400
            Layout.alignment: Qt.AlignTop
            
            WaveCard {
                id: results
                title: "Harmonic Components"
                Layout.fillWidth: true
                Layout.minimumHeight: 480

                showSettings: true

                ColumnLayout {

                    HarmonicInputForm {
                        id: harmonicForm
                        calculator: harmonicsCard.calculator
                        Layout.fillWidth: true
                    }

                    ResultsDisplay {
                        id: resultsDisplay
                        calculator: harmonicsCard.calculator
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                    }
                }
            }
            
            // Export buttons
            StyledButton {
                text: "Export Data"
                icon.source: "../../../icons/rounded/download.svg"
                Layout.fillWidth: true
                onClicked: {
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
            
            // Waveform Chart
            WaveCard {
                id: waveformCard
                title: "Waveform"
                Layout.fillHeight: true
                Layout.fillWidth: true

                WaveformVisualizerChart {
                    id: waveformVisualizer
                    anchors.fill: parent
                    calculator: harmonicsCard.calculator
                    seriesHelper: harmonicsCard.seriesHelper
                }
                
                CheckBox {
                    id: showLabels
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 5
                    text: "Show degree labels"
                    checked: true
                    z: 10

                    onCheckedChanged: {
                        if (waveformVisualizer) {
                            waveformVisualizer.setLabelsVisible(checked);
                        }
                    }
                }
                
                StyledButton {
                    id: performanceButton
                    anchors {
                        right: parent.right
                        top: parent.top
                        margins: 0
                    }
                    text: "Performance Settings"
                    onClicked: performancePopup.open()
                    icon.source: "../../../icons/rounded/speed.svg"
                }

                CheckBox {
                    id: fundamentalCheckbox
                    text: "Show Fundamental"
                    checked: false
                    anchors {
                        right: performanceButton.left
                        top: parent.top
                        margins: 0
                    }
                    
                    onCheckedChanged: {
                        if (waveformVisualizer) {
                            waveformVisualizer.showFundamental = checked;
                        }
                    }
                }

                PerformancePopup {
                    id: performancePopup
                    x: Math.round((parent.width - width) / 2)
                    y: Math.round((parent.height - height) / 2)
                }

                CalculationMonitor {
                    id: calculationMonitor
                    anchors.fill: parent
                    calculator: harmonicsCard.calculator
                    Component.onCompleted: {
                        if (calculator) {
                            calculator.enableProfiling(false);
                        }
                    }
                }
            }

            WaveCard {
                id: harmonicSpectrumCard
                Layout.fillHeight: true
                Layout.fillWidth: true
                title: "Harmonic Spectrum"

                HarmonicSpectrumChart {
                    id: harmonicSpectrum
                    anchors.fill: parent
                    calculator: harmonicsCard.calculator
                    showPhaseAngles: showPhaseCheckbox.checked
                }

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

    }

    Connections {
        target: calculator
        
        function onCalculationsComplete() {
            updateWaveformTimer.start();
            updateHarmonicsTimer.start();
        }
    }
}
