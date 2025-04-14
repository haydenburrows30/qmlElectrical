import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../buttons"
import "../style"
import "../performance"
import PerformanceMonitor 1.0

Popup {
    id: performancePopup
    modal: true
    focus: true
    width: 500
    height: 600
    
    // Create performance monitor instance directly in QML
    property var systemInfo: PerformanceMonitor {
        id: perfMonitor
    }
    
    // Original content with TabBar added for navigation
    ColumnLayout {
        anchors.fill: parent
        spacing: 5
        
        Label {
            text: "Performance Settings"
            font.bold: true
            font.pixelSize: 16
        }
        
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            
            TabButton {
                text: "Settings"
            }
            
            TabButton {
                text: "Monitoring"
            }
        }
        
        StackLayout {
            currentIndex: tabBar.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // Tab 1: Original performance settings
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    
                    ColumnLayout {
                        width: parent.width
                        
                        // Original GroupBox for Display Settings
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

                                ComboBoxRound {
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

                        // Original GroupBox for Performance Analysis  
                        GroupBox {
                            title: "Performance Analysis"
                            Layout.fillWidth: true
                            
                            ColumnLayout {
                                width: parent.width
                                
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
                                    StyledButton {
                                        text: "Clear Data"
                                        enabled: profilingCheckbox.checked
                                        onClicked: calculator.clearProfilingData()
                                        Layout.fillWidth: true
                                    }
                                    
                                    StyledButton {
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
                    }
                }
            }
            
            // Tab 2: New performance monitoring view
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                PerformanceMonitorView {
                    anchors.fill: parent
                    perfMonitor: performancePopup.systemInfo
                }
            }
        }

        Button {
            text: "Close"
            Layout.alignment: Qt.AlignRight
            onClicked: performancePopup.close()
        }
    }
    
    // Initialize when popup becomes visible
    onVisibleChanged: {
        if (visible) {
            // Force refresh of performance data
            if (systemInfo) {
                systemInfo.getPerformanceReport();
            }
        }
    }
}
