import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../buttons"
import "../style"

Popup {
    id: performancePopup
    modal: true
    focus: true
    width: 400
    height: 300
    
    // Add properties to access parent elements
    property var waveformVisualizer
    property var harmonicSpectrum
    property var updateWaveformTimer
    property var updateHarmonicsTimer
    property var calculator
    
    // Store resolution values
    property var resolutionValues: [500, 250, 100]
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 5
        
        Label {
            text: "Performance Settings"
            font.bold: true
            font.pixelSize: 16
        }
        
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            
            ColumnLayout {
                width: parent.width
                
                // Display Settings
                GroupBox {
                    title: "Display Settings"
                    Layout.fillWidth: true
                    
                    ColumnLayout {
                        width: parent.width
                        
                        ComboBoxRound {
                            id: performanceMode
                            Layout.fillWidth: true
                            model: ["Maximum Performance", "Balanced", "Maximum Quality"]
                            currentIndex: 0
                            
                            onCurrentIndexChanged: {
                                if (currentIndex === 0) { // Maximum Performance
                                    // Use waveformVisualizer instead of waveformChart
                                    if (waveformVisualizer) {
                                        waveformVisualizer.antialiasing = false;
                                    }
                                    if (updateWaveformTimer) updateWaveformTimer.interval = 50;
                                    if (updateHarmonicsTimer) updateHarmonicsTimer.interval = 50;
                                    resolutionSelector.currentIndex = 2;
                                }
                                else if (currentIndex === 1) { // Balanced
                                    if (waveformVisualizer) {
                                        waveformVisualizer.antialiasing = false;
                                    }
                                    if (updateWaveformTimer) updateWaveformTimer.interval = 25;
                                    if (updateHarmonicsTimer) updateHarmonicsTimer.interval = 25;
                                    resolutionSelector.currentIndex = 1;
                                }
                                else { // Maximum Quality
                                    if (waveformVisualizer) {
                                        waveformVisualizer.antialiasing = true;
                                    }
                                    if (updateWaveformTimer) updateWaveformTimer.interval = 5;
                                    if (updateHarmonicsTimer) updateHarmonicsTimer.interval = 5;
                                    resolutionSelector.currentIndex = 0;
                                }
                                
                                // Update visualizers
                                if (waveformVisualizer) waveformVisualizer.update();
                                if (harmonicSpectrum) harmonicSpectrum.update();
                            }
                            
                            ToolTip.text: "Select overall performance mode"
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                        }

                        ComboBoxRound {
                            id: resolutionSelector
                            Layout.fillWidth: true
                            model: ["High (500 points)", "Medium (250 points)", "Low (100 points)"]
                            currentIndex: 0
                            
                            onCurrentIndexChanged: {
                                let resolutions = [500, 250, 100];
                                if (calculator) {
                                    // Use the new resolution update method
                                    calculator.updateResolution(resolutions[currentIndex]);
                                    
                                    // Also trigger the updates
                                    if (updateWaveformTimer) updateWaveformTimer.start();
                                    if (updateHarmonicsTimer) updateHarmonicsTimer.start();
                                }
                            }
                            
                            ToolTip.text: "Adjust resolution for performance"
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                        }
                    }
                }
            }
        }

        Button {
            text: "Close"
            Layout.alignment: Qt.AlignRight
            onClicked: performancePopup.close()
        }
    }
}
