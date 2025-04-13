import QtQuick
import QtQuick.Controls
import QtQuick.Layouts


import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/displays"

Item {
    id: root
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        
        Label {
            text: "Grid Connection Requirements (G99)"
            font.bold: true
            font.pixelSize: 16
            Layout.bottomMargin: 10
        }
        
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            
            TabButton {
                text: "Protection Settings"
            }
            TabButton {
                text: "Power Quality"
            }
            TabButton {
                text: "Compliance Tests"
            }
        }
        
        StackLayout {
            currentIndex: tabBar.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // Tab 1: Protection Settings
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                
                GridLayout {
                    anchors.fill: parent
                    columns: 4
                    rowSpacing: 10
                    columnSpacing: 10
                    
                    // Headers
                    Label { 
                        text: "Parameter" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Label { 
                        text: "Setting" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Label { 
                        text: "Trip Time" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Label { 
                        text: "Reference" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    // Voltage protection
                    Label { text: "Under Voltage - Stage 1" }
                    Label { text: "V < 0.8 pu" }
                    Label { text: "2.5s" }
                    Label { text: "G99/1-4" }
                    
                    Label { text: "Under Voltage - Stage 2" }
                    Label { text: "V < 0.87 pu" }
                    Label { text: "5.0s" }
                    Label { text: "G99/1-4" }
                    
                    Label { text: "Over Voltage - Stage 1" }
                    Label { text: "V > 1.1 pu" }
                    Label { text: "1.0s" }
                    Label { text: "G99/1-4" }
                    
                    Label { text: "Over Voltage - Stage 2" }
                    Label { text: "V > 1.14 pu" }
                    Label { text: "0.5s" }
                    Label { text: "G99/1-4" }
                    
                    // Frequency protection
                    Label { text: "Under Frequency" }
                    Label { text: "f < 47.5 Hz" }
                    Label { text: "20s" }
                    Label { text: "G99/1-4" }
                    
                    Label { text: "Over Frequency" }
                    Label { text: "f > 52.0 Hz" }
                    Label { text: "0.5s" }
                    Label { text: "G99/1-4" }
                    
                    // ROCOF protection
                    Label { text: "Rate of Change of Frequency" }
                    Label { text: "1.0 Hz/s" }
                    Label { text: "0.5s" }
                    Label { text: "G99/1-4" }
                    
                    // Loss of Mains
                    Label { text: "Vector Shift" }
                    Label { text: "6 degrees" }
                    Label { text: "0.5s" }
                    Label { text: "G99/1-4" }
                }
            }
            
            // Tab 2: Power Quality
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                
                GridLayout {
                    anchors.fill: parent
                    columns: 3
                    rowSpacing: 10
                    columnSpacing: 10
                    
                    // Headers
                    Label { 
                        text: "Parameter" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Label { 
                        text: "Requirement" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Label { 
                        text: "Reference" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    // Harmonics
                    Label { text: "Total Harmonic Distortion (THD)" }
                    Label { text: "< 5% at PCC" }
                    Label { text: "EN 50160" }
                    
                    Label { text: "Individual Harmonic Limits" }
                    Label { text: "As per EN 50160" }
                    Label { text: "G99/1-4" }
                    
                    // Flicker
                    Label { text: "Short-term Flicker (Pst)" }
                    Label { text: "< 0.5" }
                    Label { text: "EN 50160" }
                    
                    Label { text: "Long-term Flicker (Plt)" }
                    Label { text: "< 0.35" }
                    Label { text: "EN 50160" }
                    
                    // Voltage unbalance
                    Label { text: "Negative Sequence Voltage" }
                    Label { text: "< 1.3% of positive sequence" }
                    Label { text: "G99/1-4" }
                    
                    // Power factor
                    Label { text: "Power Factor" }
                    Label { text: "0.95 leading to 0.95 lagging" }
                    Label { text: "G99/1-4" }
                    
                    // Reactive power
                    Label { text: "Reactive Power Capability" }
                    Label { text: "Q/Pmax: -0.33 to +0.33" }
                    Label { text: "G99/1-4" }
                    
                    // DC injection
                    Label { text: "DC Current Injection" }
                    Label { text: "< 0.25% of rated AC current" }
                    Label { text: "G99/1-4" }
                }
            }
            
            // Tab 3: Compliance Tests
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                
                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    
                    // Headers
                    Label { 
                        text: "Test" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Label { 
                        text: "Requirements" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    // LVRT test
                    Label { text: "Low Voltage Ride Through (LVRT)" }
                    Label { 
                        text: "Must remain connected during voltage dips to 0.8pu for up to 2.5s" 
                        wrapMode: Text.WordWrap
                    }
                    
                    // Frequency Response
                    Label { text: "Frequency Response Test" }
                    Label { 
                        text: "Must adjust active power output in response to frequency deviations as per G99 frequency response curve" 
                        wrapMode: Text.WordWrap
                    }
                    
                    // Active Power Control
                    Label { text: "Active Power Control" }
                    Label { 
                        text: "Must be able to reduce active power output upon instruction from DNO/TSO" 
                        wrapMode: Text.WordWrap
                    }
                    
                    // Reactive Power Control
                    Label { text: "Reactive Power Control" }
                    Label { 
                        text: "Must be able to operate at specified power factor or reactive power setpoint" 
                        wrapMode: Text.WordWrap
                    }
                    
                    // Protection Tests
                    Label { text: "Protection Tests" }
                    Label { 
                        text: "Demonstration of correct operation of all protection functions within required time" 
                        wrapMode: Text.WordWrap
                    }
                    
                    // Power Quality Tests
                    Label { text: "Power Quality Assessment" }
                    Label { 
                        text: "Measurement of THD, flicker, and harmonics to demonstrate compliance with G99/1-4 and EN 50160" 
                        wrapMode: Text.WordWrap
                    }
                    
                    // Anti-Islanding Test
                    Label { text: "Anti-Islanding Test" }
                    Label { 
                        text: "Demonstration that generating unit disconnects within 0.5s when islanded from grid" 
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}