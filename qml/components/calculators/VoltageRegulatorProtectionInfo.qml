import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../style"
import "../backgrounds"

Item {
    id: root
    
    // Property to receive the calculator instance
    property var calculator
    property bool calculatorReady: calculator !== null
    property var safeValueFunction
    
    ColumnLayout {
        anchors.fill: parent
        spacing: Style.spacing
        
        WaveCard {
            title: "Eaton VR-32 Voltage Regulator Protection Specifications"
            Layout.fillWidth: true
            Layout.preferredHeight: 500
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: Style.spacing
                
                Text {
                    text: "<b>Key Components for 3× Eaton 185kVA Single-Phase Regulators:</b>"
                    font.pixelSize: 14
                }
                
                GridLayout {
                    columns: 2
                    Layout.fillWidth: true
                    columnSpacing: 15
                    
                    Text { text: "<b>Current Transformers:</b>" }
                    Text { text: "<b>Specifications:</b>" }
                    
                    Text { text: "• Metering CTs:" }
                    Text { text: "300/1A, Class 0.5, 5VA" }
                    
                    Text { text: "• Protection CTs:" }
                    Text { text: "300/1A, 5P20, 10VA" }
                    
                    Text { text: "• Test Windings:" }
                    Text { text: "3 turns, Class 0.5" }
                    
                    Text { text: "<b>Protective Devices:</b>" }
                    Text { text: "<b>Settings:</b>" }
                    
                    Text { text: "• Current-Limiting Fuses:" }
                    Text { text: "200A, Type K" }
                    
                    Text { text: "• Voltage Sensing Circuit Fuses:" }
                    Text { text: "2A, Type D" }
                    
                    Text { text: "• Backup Battery:" }
                    Text { text: "12V, 7Ah, sealed lead-acid" }
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
                        spacing: 5
                        
                        Text {
                            text: "<b>Controller Configuration:</b>"
                            font.pixelSize: 13
                        }
                        
                        GridLayout {
                            columns: 2
                            Layout.fillWidth: true
                            columnSpacing: 15
                            
                            Text { text: "• Voltage Regulation Range:" }
                            Text { text: "±10% in 32 steps (0.625% per step)" }
                            
                            Text { text: "• Bandwidth:" }
                            Text { text: calculatorReady ? safeValueFunction(calculator.voltageRegulatorBandwidth, 2.0).toFixed(1) + "%" : "2.0%" }
                            
                            Text { text: "• Time Delay:" }
                            Text { text: "30 seconds (adjustable 15-120s)" }
                            
                            Text { text: "• Line Drop Compensation:" }
                            Text { text: "R=3Ω, X=6Ω (adjustable)" }
                        }
                        
                        Text {
                            text: "<b>Protection & Monitoring Features:</b>"
                            font.pixelSize: 13
                            Layout.topMargin: 10
                        }
                        
                        Text {
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
                
                Text {
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
