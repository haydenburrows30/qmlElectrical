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
import "../popups/"
import "../style"
import "../backgrounds"

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

    Popup {
        id: tipsPopup
        width: 300
        height: 200
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
            text: {"<h3>Harmonic Analyzer</h3><br>" +
                "Analyze the harmonic components of a waveform. " +
                "You can adjust the amplitude and phase of each harmonic component to see how it affects the waveform. <br>" +
                "You can also export the harmonic data to a CSV file for further analysis."}
            wrapMode: Text.WordWrap
        }
    }

    RowLayout {
        
        anchors.margins: 10
        anchors.fill: parent

        ColumnLayout {
            Layout.maximumWidth: 400
            Layout.alignment: Qt.AlignTop
            

            WaveCard {
                id: results
                title: "Harmonic Components"
                Layout.fillWidth: true
                Layout.minimumHeight: 550

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
            Button {
                text: "Export Data"
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

                WaveformVisualizer {
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

                PerformancePopup {
                    id: performancePopup
                    x: Math.round((parent.width - width) / 2)
                    y: Math.round((parent.height - height) / 2)
                }

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

                HarmonicSpectrum {
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
