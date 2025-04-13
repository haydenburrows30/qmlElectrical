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
            text: "ABB REF615 Relay Configuration"
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
                text: "I/O Configuration"
            }
            TabButton {
                text: "Communication"
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
                        text: "Function" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Label { 
                        text: "Stage" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Label { 
                        text: "Setting" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Label { 
                        text: "Time" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    // Phase Overcurrent
                    Label { text: "Non-directional OC (PHLPTOC)" }
                    Label { text: "Low" }
                    Label { text: "1.25 × In" }
                    Label { text: "0.3s - VI curve" }
                    
                    Label { text: "Non-directional OC (PHHPTOC)" }
                    Label { text: "High" }
                    Label { text: "8.0 × In" }
                    Label { text: "0.05s" }
                    
                    // Earth Fault
                    Label { text: "Earth Fault (EFLPTOC)" }
                    Label { text: "Low" }
                    Label { text: "0.2 × In" }
                    Label { text: "0.5s" }
                    
                    Label { text: "Earth Fault (EFHPTOC)" }
                    Label { text: "High" }
                    Label { text: "0.8 × In" }
                    Label { text: "0.1s" }
                    
                    // Auto-reclose
                    Label { text: "Auto-Reclosing (DARREC)" }
                    Label { text: "-" }
                    Label { text: "1 shot" }
                    Label { text: "5s dead time" }
                    
                    // Circuit Breaker Failure
                    Label { text: "CB Failure (CCBRBRF)" }
                    Label { text: "-" }
                    Label { text: "0.2 × In" }
                    Label { text: "0.15s" }
                }
            }
            
            // Tab 2: I/O Configuration
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
                        text: "I/O Point" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Label { 
                        text: "Signal" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Label { 
                        text: "Notes" 
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    // Digital Inputs
                    Label { text: "X110-DI1" }
                    Label { text: "CB Status (52a)" }
                    Label { text: "Normally open contact" }
                    
                    Label { text: "X110-DI2" }
                    Label { text: "CB Status (52b)" }
                    Label { text: "Normally closed contact" }
                    
                    Label { text: "X110-DI3" }
                    Label { text: "Manual Close" }
                    Label { text: "From local panel" }
                    
                    Label { text: "X110-DI4" }
                    Label { text: "External Trip" }
                    Label { text: "From transformer relay" }
                    
                    // Digital Outputs
                    Label { text: "X100-PO1" }
                    Label { text: "CB Trip" }
                    Label { text: "Trip coil 1" }
                    
                    Label { text: "X100-PO2" }
                    Label { text: "CB Close" }
                    Label { text: "Close coil" }
                    
                    Label { text: "X100-SO1" }
                    Label { text: "Alarm" }
                    Label { text: "General alarm" }
                    
                    Label { text: "X100-SO2" }
                    Label { text: "Trip Lockout" }
                    Label { text: "After final trip" }
                }
            }
            
            // Tab 3: Communication
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                
                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    
                    Label { text: "Communication Protocol:" }
                    Label { text: "IEC 61850" }
                    
                    Label { text: "IP Address:" }
                    Label { text: "192.168.1.10" }
                    
                    Label { text: "Subnet Mask:" }
                    Label { text: "255.255.255.0" }
                    
                    Label { text: "Gateway:" }
                    Label { text: "192.168.1.1" }
                    
                    Label { text: "GOOSE Configuration:" }
                    Label { text: "Enabled for interlocking" }
                    
                    Label { text: "MMS Services:" }
                    Label { text: "Enabled" }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        height: 1
                        color: "#c0c0c0"
                        Layout.margins: 10
                    }
                    
                    Label { 
                        text: "GOOSE Message Configuration:" 
                        font.bold: true
                        Layout.columnSpan: 2
                    }
                    
                    Label { text: "Publisher GOOSE 1:" }
                    Label { text: "CB status" }
                    
                    Label { text: "Publisher GOOSE 2:" }
                    Label { text: "Protection trip" }
                    
                    Label { text: "Subscriber GOOSE 1:" }
                    Label { text: "From transformer relay" }
                    
                    Label { text: "Subscriber GOOSE 2:" }
                    Label { text: "From voltage regulator" }
                }
            }
        }
    }
}