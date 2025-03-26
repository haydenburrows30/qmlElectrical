import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../style"
import "../backgrounds"

Popup {
    id: performancePopup
    modal: true
    focus: true
    width: 400
    height: 500
    
    ColumnLayout {
        anchors.fill: parent
        spacing: Style.spacing
        
        Label {
            text: "Performance Settings"
            font.bold: true
            font.pixelSize: 16
        }

        GroupBox {
            title: "Display Settings"
            Layout.fillWidth: true
            
            ColumnLayout {
                width: parent.width
                spacing: 5

                ComboBox {
                    id: performanceMode
                    Layout.fillWidth: true
                    model: ["Maximum Performance", "Balanced", "Maximum Quality"]
                    currentIndex: 0
                    
                    onCurrentIndexChanged: {
                        if (currentIndex === 0) { // Maximum Performance
                            waveformChart.antialiasing = false;
                            updateWaveformTimer.interval = 50;
                            updateHarmonicsTimer.interval = 50;
                            resolutionSelector.currentIndex = 2;
                        }
                        else if (currentIndex === 1) { // Balanced
                            waveformChart.antialiasing = false;
                            updateWaveformTimer.interval = 25;
                            updateHarmonicsTimer.interval = 25;
                            resolutionSelector.currentIndex = 1;
                        }
                        else { // Maximum Quality
                            waveformChart.antialiasing = true;
                            updateWaveformTimer.interval = 5;
                            updateHarmonicsTimer.interval = 5;
                            resolutionSelector.currentIndex = 0;
                        }
                        // Update both charts
                        waveformChart.update();
                        harmonicChart.update();
                    }
                    
                    ToolTip.text: "Select overall performance mode"
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                }

                ComboBox {
                    id: resolutionSelector
                    Layout.fillWidth: true
                    model: ["High (500 points)", "Medium (250 points)", "Low (100 points)"]
                    currentIndex: 0
                    
                    onCurrentIndexChanged: {
                        let resolutions = [500, 250, 100];
                        calculator.updateResolution(resolutions[currentIndex]);
                    }
                    
                    ToolTip.text: "Adjust resolution for performance"
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                }
            }
        }

        GroupBox {
            title: "Performance Analysis"
            Layout.fillWidth: true
            
            ColumnLayout {
                width: parent.width
                spacing: 5
                
                CheckBox {
                    id: profilingCheckbox
                    text: "Enable Performance Profiling"
                    checked: calculator.profilingEnabled
                    onCheckedChanged: calculator.enableProfiling(checked)
                }
                
                CheckBox {
                    id: detailedLoggingCheckbox
                    text: "Detailed Performance Logging"
                    checked: false
                    onCheckedChanged: calculator.setDetailedLogging(checked)
                }

                RowLayout {
                    Button {
                        text: "Clear Data"
                        enabled: profilingCheckbox.checked
                        onClicked: calculator.clearProfilingData()
                        Layout.fillWidth: true
                    }
                    
                    Button {
                        text: "Show Report"
                        enabled: profilingCheckbox.checked
                        onClicked: calculator.printProfilingSummary()
                        Layout.fillWidth: true
                    }
                }
                
                Label {
                    text: "Performance data will be printed to console"
                    font.italic: true
                    font.pixelSize: 10
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }

        Item { Layout.fillHeight: true } // Spacer

        Button {
            text: "Close"
            Layout.alignment: Qt.AlignRight
            onClicked: performancePopup.close()
        }
    }
}
