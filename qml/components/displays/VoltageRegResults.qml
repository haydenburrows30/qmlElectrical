import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../style"

Item {
    id: root
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        
        Label {
            text: "Voltage Regulator Protection Settings"
            font.bold: true
            font.pixelSize: 16
            Layout.bottomMargin: 10
        }
        
        GridLayout {
            columns: 4
            Layout.fillWidth: true
            
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
                text: "Range" 
                font.bold: true
                Layout.fillWidth: true
            }
            Label { 
                text: "Notes" 
                font.bold: true
                Layout.fillWidth: true
            }
            
            // Bandwidth
            Label { text: "Bandwidth" }
            Label { text: "2.0%" }
            Label { text: "1.0% - 3.0%" }
            Label { text: "±1.0% around target voltage" }
            
            // Time delay
            Label { text: "Time Delay" }
            Label { text: "30s" }
            Label { text: "15s - 120s" }
            Label { text: "Prevents hunting" }
            
            // Line Drop Compensation
            Label { text: "Line Drop Comp." }
            Label { text: "R=3Ω, X=6Ω" }
            Label { text: "0-20Ω" }
            Label { text: "Simulates remote voltage" }
            
            // Tap Range
            Label { text: "Tap Range" }
            Label { text: "±10%" }
            Label { text: "32 steps" }
            Label { text: "0.625% per step" }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#c0c0c0"
            Layout.margins: 10
        }
        
        Label {
            text: "Protection Features"
            font.bold: true
            font.pixelSize: 14
            Layout.topMargin: 10
        }
        
        GridLayout {
            columns: 2
            Layout.fillWidth: true
            
            Label { text: "Overvoltage Cutout:" }
            Label { text: "130% of nominal voltage" }
            
            Label { text: "Operations Counter Limit:" }
            Label { text: "500,000 operations" }
            
            Label { text: "Maximum Temperature:" }
            Label { text: "120°C with alarm at 100°C" }
            
            Label { text: "Control Power Monitoring:" }
            Label { text: "With backup battery" }
            
            Label { text: "Tap Position Monitoring:" }
            Label { text: "Real-time position reporting" }
            
            Label { text: "Overcurrent Protection:" }
            Label { text: "200% of rated current" }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#c0c0c0"
            Layout.margins: 10
        }
        
        Label {
            text: "Maintenance Requirements"
            font.bold: true
            font.pixelSize: 14
            Layout.topMargin: 10
        }
        
        Label {
            text: "• Annual visual inspection\n• Oil sampling and testing every 2 years\n• Operations counter check every 6 months\n• Controller calibration every 3 years\n• Battery replacement every 5 years"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}