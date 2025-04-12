import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../"
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
        
        GridLayout {
            columns: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 50
            columnSpacing: 20
            rowSpacing: 8

            // Circuit Breaker Section
            Label { 
                text: "Circuit Breaker Ratings:"
                font.bold: true
                font.pixelSize: 14
                Layout.columnSpan: 2
            }
            Label { 
                text: "Generator Circuit Breaker:" 
                leftPadding: 10
            }
            Label { 
                text: (((totalGeneratedPower * 1000) / (Math.sqrt(3) * 400)) * 1.25).toFixed(0) + " A (125% of full load current)"
                font.bold: true
            }

            // Protection Functions Section
            Rectangle {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                height: 1
                color: window.modeToggled ? "#404040" : "#e0e0e0"
            }

            Label { 
                text: "Protection Functions:" 
                font.bold: true
                font.pixelSize: 14
                Layout.columnSpan: 2
            }
            Label { 
                text: "Overcurrent (ANSI 50/51):" 
                leftPadding: 10
            }
            Label {
                text: (((totalGeneratedPower * 1000) / (Math.sqrt(3) * 400)) * 1.1).toFixed(0) + " A" 
                font.bold: true
            }
            Label { 
                text: "Earth Fault (ANSI 50N/51N):" 
                leftPadding: 10
            }
            Label { 
                text: "20% of rated current" 
                font.bold: true
            }
            Label { 
                text: "Overvoltage (ANSI 59):" 
                leftPadding: 10
            }
            Label { 
                text: "110% of 400V" 
                font.bold: true
            }
            Label { 
                text: "Undervoltage (ANSI 27):" 
                leftPadding: 10
            }
            Label { 
                text: "80% of 400V" 
                font.bold: true
            }
            Label { 
                text: "Over/Under Frequency (ANSI 81O/U):" 
                leftPadding: 10
            }
            Label { 
                text: "±2% of nominal" 
                font.bold: true
            }
            Label { 
                text: "Reverse Power (ANSI 32):" 
                leftPadding: 10
            }
            Label { 
                text: "5% of rated power" 
                font.bold: true
            }
            Label { 
                text: "Anti-Islanding Protection:" 
                leftPadding: 10
            }
            Label { 
                text: "Rate of Change of Frequency (ROCOF) or Vector Shift"
                font.bold: true
                wrapMode: Text.WordWrap
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#c0c0c0"
            Layout.margins: 10
        }
        
        GridLayout {
            columns: 4
            Layout.fillWidth: true
            
            // Headers
            Label { 
                text: "Protection Function" 
                font.bold: true
                Layout.fillWidth: true
            }
            Label { 
                text: "Setting" 
                font.bold: true
                Layout.fillWidth: true
            }
            Label { 
                text: "Time Delay" 
                font.bold: true
                Layout.fillWidth: true
            }
            Label { 
                text: "Notes" 
                font.bold: true
                Layout.fillWidth: true
            }
            
            // Over/Under Voltage
            Label { text: "27/59 - Under/Over Voltage" }
            Label { text: "±15% (340V-460V)" }
            Label { text: "2s / 0.5s" }
            Label { text: "G99 compliant" }
            
            // Overcurrent
            Label { text: "50/51 - Overcurrent" }
            Label { text: "150% FLC" }
            Label { text: "Inverse time curve" }
            Label { text: "High-set 500% FLC" }
            
            // Earth Fault
            Label { text: "50N/51N - Earth Fault" }
            Label { text: "20% FLC" }
            Label { text: "0.5s" }
            Label { text: "CBCT required" }
            
            // Frequency
            Label { text: "81O/81U - Frequency" }
            Label { text: "47.5Hz-52Hz" }
            Label { text: "0.5s" }
            Label { text: "ROCOF: 1Hz/s" }
            
            // Anti-islanding
            Label { text: "78/81 - Anti-islanding" }
            Label { text: "Vector Shift 12°" }
            Label { text: "0.5s" }
            Label { text: "Mandatory" }
            
            // Reverse Power
            Label { text: "32 - Reverse Power" }
            Label { text: "5% rated capacity" }
            Label { text: "2s" }
            Label { text: "Optional" }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#c0c0c0"
            Layout.margins: 10
        }
        
        Label {
            text: "Recommended Protection Relay: Woodward MCA4"
            font.bold: true
            Layout.topMargin: 10
        }
        
        Label {
            text: "The Woodward MCA4 provides all required protection functions for LV wind generator connection to the grid in compliance with G99 requirements. Includes complete anti-islanding protection and voltage/frequency monitoring."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}