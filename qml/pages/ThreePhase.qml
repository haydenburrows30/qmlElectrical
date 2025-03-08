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
        color: toolBar.toggle ? "#1a1a1a" : "#f5f5f5"
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
                            // Layout.fillWidth: true
                            Layout.minimumHeight: 460
                            Layout.minimumWidth: 500
                        }

                        WaveCard {
                            title: "Measurements"
                            Layout.minimumHeight: 460
                            Layout.minimumWidth: 370
                            showInfo: false

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                PhaseTable {
                                    Layout.fillWidth: true
                                    model: sineModel
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: toolBar.toggle ? "#404040" : "#e0e0e0"
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
                            showInfo: false

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10

                                PowerTriangle {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: 200
                                    Layout.minimumWidth: 250
                                    activePower: sineModel.activePower
                                    reactivePower: sineModel.reactivePower
                                    apparentPower: sineModel.apparentPower
                                    powerFactor: sineModel.averagePowerFactor
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
                            showInfo: false
                            
                            WaveChart {
                                anchors.fill: parent
                                model: sineModel
                            }
                        }

                        WaveCard {
                            title: "Phasor Diagram"
                            Layout.minimumWidth: 530
                            Layout.fillHeight: true
                            showInfo: false
                            
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
}
