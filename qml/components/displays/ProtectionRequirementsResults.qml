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
            text: "Transformer Protection Requirements"
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
            Label { text: "125% FLC" }
            Label { text: "Very Inverse" }
            Label { text: "TDS = 0.3" }
            
            // Instantaneous OC
            Label { text: "50 - Instantaneous OC" }
            Label { text: "8× FLC" }
            Label { text: "0.05s" }
            Label { text: "For transformer faults" }
            
            // Earth Fault
            Label { text: "51G - Restricted Earth Fault" }
            Label { text: "20% FLC" }
            Label { text: "0.1s" }
            Label { text: "High impedance REF" }
            
            // Thermal Overload
            Label { text: "49 - Thermal Overload" }
            Label { text: "105% FLC" }
            Label { text: "Inverse time" }
            Label { text: "With cooling status" }
            
            // Differential
            Label { text: "87T - Differential" }
            Label { text: "20% pickup, 30% slope" }
            Label { text: "Instantaneous" }
            Label { text: "For internal faults" }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#c0c0c0"
            Layout.margins: 10
        }
        
        Label {
            text: "CT Requirements"
            font.bold: true
            font.pixelSize: 14
            Layout.topMargin: 10
        }
        
        GridLayout {
            columns: 2
            Layout.fillWidth: true
            
            Label { text: "HV CT Ratio:" }
            Label { text: "300/1A" }
            
            Label { text: "LV CT Ratio:" }
            Label { text: "2000/1A" }
            
            Label { text: "Protection Class:" }
            Label { text: "5P20" }
            
            Label { text: "REF CT:" }
            Label { text: "100/1A, Class PX" }
            
            Label { text: "Burden:" }
            Label { text: "15VA" }
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#c0c0c0"
            Layout.margins: 10
        }
        
        Label {
            text: "Recommended Relay: ABB RET615"
            font.bold: true
            Layout.topMargin: 10
        }
        
        Label {
            text: "ABB RET615 transformer protection relay provides differential protection along with backup overcurrent and earth fault protection for power transformers, unit transformers, and generator-transformer blocks."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}