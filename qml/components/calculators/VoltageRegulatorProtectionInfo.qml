import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../"
import "../style"

Item {
    id: root
    
    // Property to receive the calculator instance
    property var calculator
    property bool calculatorReady: calculator !== null
    property var safeValueFunction
    
    ColumnLayout {
        anchors.fill: parent

        WaveCard {
            title: "Eaton VR-32 Voltage Regulator Protection Specifications"
            Layout.fillWidth: true
            Layout.preferredHeight: 500
            
            ColumnLayout {
                anchors.fill: parent

                Label {
                    text: "<b>Key Components for 3× Eaton 185kVA Single-Phase Regulators:</b>"
                    font.pixelSize: 14
                }
                
                GridLayout {
                    columns: 2
                    Layout.fillWidth: true
                    
                    Label { text: "<b>Current Transformers:</b>" }
                    Label { text: "<b>Specifications:</b>" }
                    
                    Label { text: "• Metering CTs:" }
                    Label { text: "300/1A, Class 0.5, 5VA" }
                    
                    Label { text: "• Protection CTs:" }
                    Label { text: "300/1A, 5P20, 10VA" }
                    
                    Label { text: "• Voltage Sensing Circuit Fuses:" }
                    Label { text: "2A, Type D" }
                    
                    Label { text: "• Backup Battery:" }
                    Label { text: "12V, 7Ah, sealed lead-acid" }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: regConfigLayout.implicitHeight + 20
                    color: "#f7f0ff"
                    border.color: "#8a4eef"
                    radius: 5
                    
                    ColumnLayout {
                        id: regConfigLayout
                        anchors.fill: parent
                        anchors.margins: 10

                        Label {
                            text: "<b>Controller Configuration:</b>"
                            font.pixelSize: 13
                        }
                        
                        GridLayout {
                            columns: 2
                            Layout.fillWidth: true

                            Label { text: "• Voltage Regulation Range:" }
                            Label { text: "±10% in 32 steps (0.625% per step)" }
                            
                            Label { text: "• Bandwidth:" }
                            Label { text: calculatorReady ? safeValueFunction(calculator.voltageRegulatorBandwidth, 2.0).toFixed(1) + "%" : "2.0%" }
                            
                            Label { text: "• Time Delay:" }
                            Label { text: "30 seconds (adjustable 15-120s)" }
                            
                            Label { text: "• Line Drop Compensation:" }
                            Label { text: "R=3Ω, X=6Ω (adjustable)" }
                        }
                        
                        Label {
                            text: "<b>Protection & Monitoring Features:</b>"
                            font.pixelSize: 13
                            Layout.topMargin: 10
                        }
                        
                        Label {
                            text: "• Overvoltage cutout: 130% of nominal\n" + 
                                  "• Tap position monitoring and reporting\n" + 
                                  "• Operations counter with maintenance alerts\n" + 
                                  "• Temperature monitoring with automatic shutdown\n" + 
                                  "• Voltage quality recording with event logs\n" + 
                                  "• Automatic bypass on controller failure"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
                
                Label {
                    text: "<b>SCADA Integration:</b>\n" +
                          "• DNP3.0 protocol support\n" +
                          "• Remote tap position monitoring\n" +
                          "• Remote voltage setpoint adjustment\n" +
                          "• Operations count and status monitoring\n" +
                          "• Maintenance alerts via SCADA\n" +
                          "• Event logs with timestamping"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
