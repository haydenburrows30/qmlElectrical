import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../buttons"
import "../style"
import "../backgrounds"

ColumnLayout {
    id: gridConnectionLayout
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.margins: 50
    spacing: Style.spacing

    Label {
        text: "Wind Turbine Grid Integration Requirements"
        font.bold: true
        font.pixelSize: 14
    }
    
    Column {
        Layout.fillWidth: true
        spacing: 8
        
        Label { 
            text: "• Compliance with G59/G99 or equivalent grid connection standards"
            width: parent.width
            wrapMode: Text.WordWrap
            
        }
        Label { 
            text: "• Low Voltage Ride Through (LVRT) capability"
            width: parent.width
            wrapMode: Text.WordWrap
            
        }
        Label { 
            text: "• Active power control for frequency regulation"
            width: parent.width
            wrapMode: Text.WordWrap
            
        }
        Label { 
            text: "• Reactive power capability (power factor control)"
            width: parent.width
            wrapMode: Text.WordWrap
            
        }
        Label { 
            text: "• Harmonics and flicker within acceptable limits"
            width: parent.width
            wrapMode: Text.WordWrap
            
        }
        Label { 
            text: "• Fault level contribution within grid limits"
            width: parent.width
            wrapMode: Text.WordWrap
            
        }
    }
    
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
    }
    
    Label {
        text: "SCADA and Communication"
        font.bold: true
        font.pixelSize: 14
        
    }
    
    Column {
        Layout.fillWidth: true
        spacing: 8
        
        Label { 
            text: "• Remote monitoring and control capabilities"
            width: parent.width
            wrapMode: Text.WordWrap
            
        }
        Label { 
            text: "• Generation forecasting"
            width: parent.width
            wrapMode: Text.WordWrap
            
        }
        Label { 
            text: "• Communication with grid operator (if required)"
            width: parent.width
            wrapMode: Text.WordWrap
            
        }
        Label { 
            text: "• Data logging for regulatory compliance"
            width: parent.width
            wrapMode: Text.WordWrap
            
        }
    }
}