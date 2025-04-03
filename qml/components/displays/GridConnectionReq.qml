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
    

    Label {
        text: "Wind Turbine Grid Integration Requirements"
        font.bold: true
        font.pixelSize: 14
    }
    
    Column {
        Layout.fillWidth: true
        spacing: 8
        
        Label { 
            text: "• Compliance with G59/G99 or equivalent grid connection standards<br>" +
            "• Low Voltage Ride Through (LVRT) capability<br>" +
            "• Active power control for frequency regulation<br>" +
            "• Reactive power capability (power factor control)<br>" +
            "• Harmonics and flicker within acceptable limits<br>" +
            "• Fault level contribution within grid limits"
            width: parent.width
            wrapMode: Text.WordWrap
        }
    }
    
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: sideBar.modeToggled ? "#404040" : "#e0e0e0"
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
            text: "• Remote monitoring and control capabilities<br>" +
            "• Generation forecasting<br>" +
            "• Communication with grid operator (if required)<br>" +
            "• Data logging for regulatory compliance"
            width: parent.width
            wrapMode: Text.WordWrap
        }
    }
}