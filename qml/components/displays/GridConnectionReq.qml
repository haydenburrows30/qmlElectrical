import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../buttons"

ColumnLayout {
    id: gridConnectionLayout
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.margins: 50
    spacing: 15

    Text {
        text: "Wind Turbine Grid Integration Requirements"
        font.bold: true
        font.pixelSize: 14
        color: sideBar.toggle1 ? "white" : "black"
    }
    
    Column {
        Layout.fillWidth: true
        spacing: 8
        
        Text { 
            text: "• Compliance with G59/G99 or equivalent grid connection standards"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
        Text { 
            text: "• Low Voltage Ride Through (LVRT) capability"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
        Text { 
            text: "• Active power control for frequency regulation"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
        Text { 
            text: "• Reactive power capability (power factor control)"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
        Text { 
            text: "• Harmonics and flicker within acceptable limits"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
        Text { 
            text: "• Fault level contribution within grid limits"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
    }
    
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
    }
    
    Text {
        text: "SCADA and Communication"
        font.bold: true
        font.pixelSize: 14
        color: sideBar.toggle1 ? "white" : "black"
    }
    
    Column {
        Layout.fillWidth: true
        spacing: 8
        
        Text { 
            text: "• Remote monitoring and control capabilities"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
        Text { 
            text: "• Generation forecasting"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
        Text { 
            text: "• Communication with grid operator (if required)"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
        Text { 
            text: "• Data logging for regulatory compliance"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
    }
}