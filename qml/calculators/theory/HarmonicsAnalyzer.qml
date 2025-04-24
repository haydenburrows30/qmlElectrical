import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import QtQuick.Dialogs

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"
import "../../components/exports"
import "../../components/charts"
import "../../components/displays"
import "../../components/menus"

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
        id: popUpText
        parentCard: results
        widthFactor: 0.3
        heightFactor: 0.3
        popupText: "<h3>Harmonic Analyzer</h3><br>" +
                "Analyze the harmonic components of a waveform. " +
                "You can adjust the amplitude and phase of each harmonic component to see how it affects the waveform. <br>" +
                "You can also export the harmonic data to a CSV file for further analysis."
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 5

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 5

            Label {
                text: "Harmonics Analyzer"
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            StyledButton {
                id: helpButton
                icon.source: "../../../icons/rounded/info.svg"
                onClicked: popUpText.open()
                ToolTip.text: "Information"
                ToolTip.visible: hovered
                ToolTip.delay: 500
            }
        }

        RowLayout {

            ColumnLayout {
                Layout.maximumWidth: 400
                Layout.alignment: Qt.AlignTop
                
                WaveCard {
                    id: results
                    title: "Harmonic Components"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 480

                    ColumnLayout {

                        HarmonicInputMenu {
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
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    StyledButton {
                        text: "Export to CSV"
                        icon.source: "../../../icons/rounded/download.svg"
                        Layout.fillWidth: true
                        onClicked: calculator.exportDataToCSV()
                        ToolTip.text: "Export harmonic data to CSV file"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
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

                        ToolTip.text: "Show degree labels on chart"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500

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
                        ToolTip.text: "Performance settings for chart"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        
                        onClicked: performancePopup.open()
                        icon.source: "../../../icons/rounded/speed.svg"
                    }

                    CheckBox {
                        id: fundamentalCheckbox
                        text: "Show Fundamental"
                        checked: false

                        ToolTip.text: "Show fundamental frequency in chart"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        
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
                        waveformVisualizer: waveformVisualizer
                        harmonicSpectrum: harmonicSpectrum
                        updateWaveformTimer: updateWaveformTimer
                        updateHarmonicsTimer: updateHarmonicsTimer
                        calculator: harmonicsCard.calculator
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

                        ToolTip.text: "Show phase angles on chart"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500

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
    }

    MessagePopup {
        id: messagePopup
    }

    Connections {
        target: calculator
        
        function onCalculationsComplete() {
            updateWaveformTimer.start();
            updateHarmonicsTimer.start();
        }

        function onExportDataToFolderCompleted(success, message) {
            if (success) {
                messagePopup.showSuccess(message);
            } else {
                messagePopup.showError(message);
            }
        }
    }
}
