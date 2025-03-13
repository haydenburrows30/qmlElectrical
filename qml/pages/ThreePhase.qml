import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import Sine 1.0
import components 1.0

import "../components"

Page {
    id: root

    background: Rectangle {
        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5
            
            RowLayout {
                id: mainLayout
                width: scrollView.width
                anchors.left: parent.left
                spacing: 5

                ColumnLayout {
                    RowLayout {
                        WaveControls {
                            id: waveControls
                            Layout.minimumHeight: 460
                            Layout.minimumWidth: 500
                            onRequestAutoScale: waveChart.autoScale()
                        }

                        WaveCard {
                            title: "Measurements"
                            Layout.minimumHeight: 460
                            Layout.minimumWidth: 370

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                PhaseTable {
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
                                }

                                GridLayout {
                                    columns: 2
                                    columnSpacing: 20
                                    Layout.fillWidth: true
                                    Layout.topMargin: 10

                                    Label { text: "Line-to-Line RMS"; font.bold: true }
                                    Label { text: "Voltage (V)"; font.bold: true }

                                    Label { text: "VAB" }
                                    Label { text: sineModel.rmsAB.toFixed(1) }

                                    Label { text: "VBC" }
                                    Label { text: sineModel.rmsBC.toFixed(1) }

                                    Label { text: "VCA" }
                                    Label { text: sineModel.rmsCA.toFixed(1) }

                                    Item { Layout.columnSpan: 2; Layout.preferredHeight: 10 }

                                    Label { text: "Average Power Factor"; font.bold: true }
                                    Label { 
                                        text: sineModel.averagePowerFactor.toFixed(3)
                                        font.bold: true 
                                    }
                                }
                            }
                        }

                        WaveCard {
                            title: "Power Analysis"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 460
                            Layout.minimumWidth: 400

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10

                                Item {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: 200
                                    Layout.minimumWidth: 250

                                    PowerTriangle {
                                        anchors.fill: parent
                                        activePower: sineModel.activePower
                                        reactivePower: sineModel.reactivePower
                                        apparentPower: sineModel.apparentPower
                                        powerFactor: sineModel.averagePowerFactor
                                        triangleScale: 100
                                        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
                                        textColor: sideBar.toggle1 ? "#ffffff" : "#000000"
                                    }
                                }

                                GridLayout {
                                    columns: 2
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: 100
                                    
                                    Label { text: "Total Apparent Power (S):" }
                                    Label { text: sineModel.apparentPower.toFixed(2) + " kVA" }
                                    
                                    Label { text: "Total Active Power (P):" }
                                    Label { text: sineModel.activePower.toFixed(2) + " kW" }
                                    
                                    Label { text: "Total Reactive Power (Q):" }
                                    Label { text: sineModel.reactivePower.toFixed(2) + " kVAR" }
                                    
                                    Label { text: "System Power Factor:" }
                                    Label { text: sineModel.averagePowerFactor.toFixed(3) }
                                }
                            }
                        }
                    }

                    RowLayout {
                        WaveCard {
                            title: "Waveform"
                            Layout.minimumWidth: 620
                            Layout.minimumHeight: 400
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            WaveChart {
                                id: waveChart
                                anchors.fill: parent
                            }
                        }

                        WaveCard {
                            title: "Phasor Diagram"
                            Layout.minimumWidth: 530
                            Layout.minimumHeight: 530
                            Layout.fillHeight: true
                            
                            PhasorDiagram {
                                anchors.fill: parent
                                // Update to include both voltage and current phasors
                                phaseAngles: [
                                    sineModel.phaseAngleA,
                                    sineModel.phaseAngleB,
                                    sineModel.phaseAngleC
                                ]
                                // Add current phasor angles
                                currentPhaseAngles: [
                                    sineModel.currentAngleA,
                                    sineModel.currentAngleB,
                                    sineModel.currentAngleC
                                ]
                                // Add current magnitudes to scale the current phasors properly
                                currentMagnitudes: [
                                    sineModel.currentA / 100, // Scale down for visibility
                                    sineModel.currentB / 100,
                                    sineModel.currentC / 100
                                ]
                                showCurrentPhasors: true // Flag to enable current phasors
                                
                                // Handle voltage angle changes
                                onAngleChanged: function(index, angle) {
                                    switch(index) {
                                        case 0: sineModel.setPhaseAngleA(angle); break;
                                        case 1: sineModel.setPhaseAngleB(angle); break;
                                        case 2: sineModel.setPhaseAngleC(angle); break;
                                    }
                                }
                                
                                // Handle current angle changes
                                onCurrentAngleChanged: function(index, angle) {
                                    switch(index) {
                                        case 0: sineModel.setCurrentAngleA(angle); break;
                                        case 1: sineModel.setCurrentAngleB(angle); break;
                                        case 2: sineModel.setCurrentAngleC(angle); break;
                                    }
                                }
                            }
                        }
                    }                   
                }                
            }
        }
    }
}
