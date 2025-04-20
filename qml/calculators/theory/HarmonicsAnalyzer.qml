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

    FolderDialog {
        id: folderDialog
        title: "Choose Export Directory"
        onAccepted: {
            var folderPath = folderDialog.selectedFolder.toString();
            if (folderPath.startsWith("file://")) {
                folderPath = folderPath.substring(7);
                if (Qt.platform.os === "windows" && folderPath.startsWith("/") && folderPath.charAt(2) === ":") {
                    folderPath = folderPath.substring(1);
                }
            }
            var success = calculator.exportDataToFolder(folderPath);
            if (success) {
                exportStatusPopup.status = "success";
                exportStatusPopup.message = "Export successful!";
            } else {
                exportStatusPopup.status = "error";
                exportStatusPopup.message = "Export failed. Check console for details.";
            }
            exportStatusPopup.open();
        }
    }
    
    Popup {
        id: exportStatusPopup
        width: 300
        height: 100
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        property string status: "success"
        property string message: ""
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            
            Label {
                text: exportStatusPopup.message
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: exportStatusPopup.status === "success" ? "green" : "red"
                font.bold: true
            }
            
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                onClicked: exportStatusPopup.close()
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
                        text: "Quick Export"
                        icon.source: "../../../icons/rounded/download.svg"
                        Layout.fillWidth: true
                        onClicked: {
                            var success = calculator.exportData();
                            if (success) {
                                exportStatusPopup.status = "success";
                                exportStatusPopup.message = "Export successful to Documents folder!";
                                exportStatusPopup.open();
                            } else {
                                exportStatusPopup.status = "error";
                                exportStatusPopup.message = "Export failed. Check console for details.";
                                exportStatusPopup.open();
                            }
                        }
                        ToolTip.text: "Export to default location (~/Documents/harmonics_export)"
                        ToolTip.visible: quickExportMouseArea.containsMouse
                        ToolTip.delay: 500
                        
                        MouseArea {
                            id: quickExportMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onPressed: function(mouse) { mouse.accepted = false }
                        }
                    }
                    
                    StyledButton {
                        text: "Browse..."
                        icon.source: "../../../icons/rounded/folder_open.svg"
                        Layout.fillWidth: true
                        onClicked: folderDialog.open()
                        ToolTip.text: "Choose folder to export data"
                        ToolTip.visible: browseMouseArea.containsMouse
                        ToolTip.delay: 500
                        
                        MouseArea {
                            id: browseMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onPressed: function(mouse) { mouse.accepted = false }
                        }
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

    Connections {
        target: calculator
        
        function onCalculationsComplete() {
            updateWaveformTimer.start();
            updateHarmonicsTimer.start();
        }
    }
}
