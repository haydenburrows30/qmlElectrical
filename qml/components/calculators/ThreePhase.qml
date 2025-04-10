import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "../"
import "../visualizers/"
import "../charts/"
import "../three_phase/"
import "../popups"

import Sine 1.0

Page {
    id: root

    property color textColorPhase: window.modeToggled ? "#ffffff" : "#000000"
    property ThreePhaseSineWaveModel calculator: ThreePhaseSineWaveModel{}
    background: Rectangle {
        color: window.modeToggled ? "#1a1a1a" : "#f5f5f5"
    }

    PopUpText {
        parentCard: results
        popupText: "<h3>Three-Phase Power</h3><br>Three-phase power is a common method of electric power transmission and distribution" +
        " that is used to power large motors and other heavy loads. It is also used in residential and commercial buildings to power large appliances and lighting systems.<br>" +
        " A three-phase system consists of three conductors carrying alternating current of the same frequency and voltage amplitude relative to a common reference, but with a phase difference of one third of a cycle between each.<br>" +
        " The voltage generated by three-phase power is typically expressed as a line-to-line voltage. The power delivered by a three-phase system is the same as the power in a single-phase system, but the power is distributed across three phases, which reduces the amount of current required to deliver the same amount of power.<br>" +
        " This reduces the size of the conductors and the amount of power lost in transmission. The three-phase system also allows for the use of three-phase motors, which are more efficient and have a higher power-to-weight ratio than single-phase motors.<br>"
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

                ColumnLayout {
                    RowLayout {
                        WaveControls {
                            id: waveControls
                            Layout.minimumHeight: 460
                            Layout.minimumWidth: 500
                            onRequestAutoScale: waveChart.autoScale()
                            calculator: root.calculator //pass calculator to controls
                        }

                        WaveCard {
                            id: results
                            title: "Measurements"
                            Layout.minimumHeight: 460
                            Layout.minimumWidth: 370
                            
                            showSettings: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                

                                PhaseTable {
                                    Layout.fillWidth: true
                                    calculator: root.calculator //pass calculator to chart
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: window.modeToggled ? "#404040" : "#e0e0e0"
                                }

                                GridLayout {
                                    columns: 2
                                    columnSpacing: 20
                                    Layout.fillWidth: true
                                    Layout.topMargin: 10

                                    Label { text: "Line-to-Line RMS"; font.bold: true }
                                    Label { text: "Voltage (V)"; font.bold: true }

                                    Label { text: "VAB" }
                                    Label { text: calculator.rmsAB.toFixed(1) }

                                    Label { text: "VBC" }
                                    Label { text: calculator.rmsBC.toFixed(1) }

                                    Label { text: "VCA" }
                                    Label { text: calculator.rmsCA.toFixed(1) }

                                    Item { Layout.columnSpan: 2; Layout.preferredHeight: 10 }

                                    Label { text: "Average Power Factor"; font.bold: true }
                                    Label { 
                                        text: calculator.averagePowerFactor.toFixed(3)
                                        font.bold: true 
                                    }
                                }
                            }
                        }

                        WaveCard {
                            title: "Sequence Components"
                            Layout.minimumWidth: 400
                            Layout.minimumHeight: 300
                            Layout.alignment: Qt.AlignTop
                            Layout.fillHeight: true
                            
                            GridLayout {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right

                                columns: 3
                                
                                // Headers
                                Label { text: "Component"; font.bold: true }
                                Label { text: "Voltage"; font.bold: true }
                                Label { text: "Current"; font.bold: true }
                                
                                // Positive Sequence
                                Label { text: "Positive:" }
                                Label { 
                                    text: calculator.positiveSeq.toFixed(1) + " V" 
                                    font.bold: true
                                }
                                Label { 
                                    text: calculator.positiveSeqCurrent.toFixed(1) + " A" 
                                    font.bold: true
                                }
                                
                                // Negative Sequence
                                Label { text: "Negative:" }
                                Label { 
                                    text: calculator.negativeSeq.toFixed(1) + " V"
                                    font.bold: true 
                                    color: calculator.negativeSeq > 5 ? "#ff4444" : textColorPhase
                                }
                                Label { 
                                    text: calculator.negativeSeqCurrent.toFixed(1) + " A"
                                    font.bold: true
                                    color: calculator.negativeSeqCurrent / calculator.positiveSeqCurrent > 0.1 ? "#ff4444" : textColorPhase
                                }
                                
                                // Zero Sequence
                                Label { text: "Zero:" }
                                Label { 
                                    text: calculator.zeroSeq.toFixed(1) + " V"
                                    font.bold: true
                                    color: calculator.zeroSeq > 5 ? "#ff4444" : textColorPhase
                                }
                                Label { 
                                    text: calculator.zeroSeqCurrent.toFixed(1) + " A"
                                    font.bold: true
                                    color: calculator.zeroSeqCurrent > 0.1 ? "#ff4444" : textColorPhase
                                }
                                
                                // Unbalance
                                Label { text: "Unbalance (%):" }
                                Label { 
                                    text: (calculator.negativeSeq / calculator.positiveSeq * 100).toFixed(1) + "%"
                                    font.bold: true
                                    color: calculator.negativeSeq / calculator.positiveSeq > 0.02 ? "#ff4444" : textColorPhase
                                }
                                Label { 
                                    text: (calculator.negativeSeqCurrent / calculator.positiveSeqCurrent * 100).toFixed(1) + "%"
                                    font.bold: true
                                    color: calculator.negativeSeqCurrent / calculator.positiveSeqCurrent > 0.1 ? "#ff4444" : textColorPhase
                                }
                            }
                        }

                        WaveCard {
                            title: "Power Analysis"
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 460
                            Layout.minimumWidth: 400

                            ColumnLayout {
                                anchors.fill: parent

                                PowerTriangle {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: 250
                                    Layout.minimumWidth: 250
                                    activePower: calculator.activePower
                                    reactivePower: calculator.reactivePower
                                    apparentPower: calculator.apparentPower
                                    powerFactor: calculator.averagePowerFactor
                                    triangleScale: 100
                                    color: window.modeToggled ? "#1a1a1a" : "#f5f5f5"
                                    textColor: textColorPhase

                                    
                                }

                                GridLayout {
                                    columns: 2
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: 100
                                    
                                    Label { text: "Total Apparent Power (S):" }
                                    Label { text: calculator.apparentPower.toFixed(2) + " kVA" }
                                    
                                    Label { text: "Total Active Power (P):" }
                                    Label { text: calculator.activePower.toFixed(2) + " kW" }
                                    
                                    Label { text: "Total Reactive Power (Q):" }
                                    Label { text: calculator.reactivePower.toFixed(2) + " kVAR" }
                                    
                                    Label { text: "System Power Factor:" }
                                    Label { text: calculator.averagePowerFactor.toFixed(3) }
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

                                calculator: root.calculator //pass calculator to chart
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
                                    calculator.phaseAngleA,
                                    calculator.phaseAngleB,
                                    calculator.phaseAngleC
                                ]
                                // Add current phasor angles
                                currentPhaseAngles: [
                                    calculator.currentAngleA,
                                    calculator.currentAngleB,
                                    calculator.currentAngleC
                                ]
                                // Add current magnitudes to scale the current phasors properly
                                currentMagnitudes: [
                                    calculator.currentA / 100, // Scale down for visibility
                                    calculator.currentB / 100,
                                    calculator.currentC / 100
                                ]
                                showCurrentPhasors: true // Flag to enable current phasors
                                
                                // Handle voltage angle changes
                                onAngleChanged: function(index, angle) {
                                    switch(index) {
                                        case 0: calculator.setPhaseAngleA(angle); break;
                                        case 1: calculator.setPhaseAngleB(angle); break;
                                        case 2: calculator.setPhaseAngleC(angle); break;
                                    }
                                }
                                
                                // Handle current angle changes
                                onCurrentAngleChanged: function(index, angle) {
                                    switch(index) {
                                        case 0: calculator.setCurrentAngleA(angle); break;
                                        case 1: calculator.setCurrentAngleB(angle); break;
                                        case 2: calculator.setCurrentAngleC(angle); break;
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
