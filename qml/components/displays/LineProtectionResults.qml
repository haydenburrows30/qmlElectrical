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
            text: "11kV Line Protection Settings"
            font.bold: true
            font.pixelSize: 16
            Layout.bottomMargin: 10
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
            
            // Overcurrent
            Label { text: "51 - Overcurrent" }
            Label { text: "200% FLC" }
            Label { text: "Very Inverse" }
            Label { text: "TDS = 0.3" }
            
            // Instantaneous OC
            Label { text: "50 - Instantaneous OC" }
            Label { text: "10× FLC" }
            Label { text: "0.05s" }
            Label { text: "For close-in faults" }
            
            // Earth Fault
            Label { text: "51N - Earth Fault" }
            Label { text: "40A" }
            Label { text: "0.5s" }
            Label { text: "Definite time" }
            
            // Auto-reclose
            Label { text: "79 - Auto-reclose" }
            Label { text: "Single-shot" }
            Label { text: "5s dead time" }
            Label { text: "For transient faults" }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#c0c0c0"
            Layout.margins: 10
        }
        
        Label {
            text: "Coordination Study Results"
            font.bold: true
            font.pixelSize: 14
            Layout.topMargin: 10
        }
        
        GridLayout {
            columns: 2
            Layout.fillWidth: true
            
            Label { text: "Upstream Protection:" }
            Label { text: "11kV Substation Feeder Circuit Breaker" }
            
            Label { text: "Coordination Time Margin:" }
            Label { text: "0.4s" }
            
            Label { text: "Relay Coordination:" }
            Label { text: "Wind turbine protection operates before line protection" }
            
            Label { text: "Pickup Ratio:" }
            Label { text: "2:1 (Line Protection : Transformer Protection)" }
            
            Label { text: "Maximum Fault Current:" }
            Label { text: "1.5kA" }
            
            Label { text: "Minimum Fault Current:" }
            Label { text: "0.2kA" }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#c0c0c0"
            Layout.margins: 10
        }
        
        Label {
            text: "Recommended Relay: ABB REF615"
            font.bold: true
            Layout.topMargin: 10
        }
        
        Label {
            text: "ABB REF615 feeder protection relay provides integrated protection, control, measurement and supervision functions for overhead lines and cable feeders in distribution networks."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}