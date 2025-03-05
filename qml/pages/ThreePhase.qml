import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../components"
import Sine 1.0

Page {
    id: root
    padding: 0  // Remove default Page padding
    
    SineWaveModel {
        id: sineModel
    }

    background: Rectangle {
        color: toolBar.toggle ? "#1a1a1a" : "#f5f5f5"
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height
            
            ColumnLayout {
                id: mainLayout
                width: scrollView.width  // Use ScrollView width
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 5

                RowLayout {

                    WaveCard {
                        title: "Three Phase Control Panel"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 400
                        
                        WaveControls {
                            anchors.fill: parent
                            model: sineModel
                        }
                    }

                    WaveCard {
                        title: "Measurements & Analysis"
                        Layout.minimumHeight: 400
                        Layout.minimumWidth: 500

                        ColumnLayout {
                            anchors.fill: parent

                            Measurements {
                                Layout.fillWidth: true
                                model: sineModel
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                Label {
                                    text: "System Analysis"
                                    font.pixelSize: 16
                                    font.weight: Font.Medium
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 3
                                    columnSpacing: 48
                                    rowSpacing: 16

                                    ColumnLayout {
                                        spacing: 8
                                        Label { 
                                            text: "Sequence Components" 
                                            font.weight: Font.DemiBold
                                        }
                                        Label { 
                                            text: "Positive: " + (sineModel.positiveSeq !== undefined ? 
                                                sineModel.positiveSeq.toFixed(1) : "---") + " V"
                                            color: toolBar.toggle ? "#4caf50" : "#2e7d32"
                                        }
                                        Label { 
                                            text: "Negative: " + (sineModel.negativeSeq !== undefined ? 
                                                sineModel.negativeSeq.toFixed(1) : "---") + " V"
                                            color: toolBar.toggle ? "#ff9800" : "#f57c00"
                                        }
                                        Label { 
                                            text: "Zero: " + (sineModel.zeroSeq !== undefined ? 
                                                sineModel.zeroSeq.toFixed(1) : "---") + " V"
                                            color: toolBar.toggle ? "#f44336" : "#d32f2f"
                                        }
                                    }

                                    ColumnLayout {
                                        spacing: 8
                                        Label { 
                                            text: "Power Flow" 
                                            font.weight: Font.DemiBold
                                        }
                                        Label { 
                                            text: "Active: " + (sineModel.activePower !== undefined ? 
                                                sineModel.activePower.toFixed(1) : "---") + " kW"
                                            color: toolBar.toggle ? "#2196f3" : "#1976d2"
                                        }
                                    }

                                    ColumnLayout {
                                        spacing: 8
                                        Label { 
                                            text: "Harmonics" 
                                            font.weight: Font.DemiBold
                                        }
                                        Label { 
                                            text: "THD: " + (sineModel.thd !== undefined ? 
                                                sineModel.thd.toFixed(1) : "---") + " %" 
                                            color: toolBar.toggle ? "#9c27b0" : "#7b1fa2"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.height * 0.6 
                    
                    WaveCard {
                        title: "Waveform"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 800
                        
                        WaveChart {
                            anchors.fill: parent
                            model: sineModel
                        }
                    }
                    
                    WaveCard {
                        title: "Phasor Diagram"
                        Layout.minimumWidth: 600
                        Layout.fillHeight: true
                        
                        PhasorDiagram {
                            anchors.fill: parent
                            phaseAngles: [
                                sineModel.phaseAngleA,
                                sineModel.phaseAngleB,
                                sineModel.phaseAngleC
                            ]
                            onAngleChanged: function(index, angle) {
                                switch(index) {
                                    case 0: sineModel.setPhaseAngleA(angle); break;
                                    case 1: sineModel.setPhaseAngleB(angle); break;
                                    case 2: sineModel.setPhaseAngleC(angle); break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
