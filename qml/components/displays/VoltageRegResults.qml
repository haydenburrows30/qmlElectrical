import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../buttons"
import "../style"
import "../backgrounds"

ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.margins: 50
    spacing: Style.spacing

    GridLayout {
        columns: 2
        Layout.fillWidth: true
        Layout.fillHeight: true
        columnSpacing: 15
        rowSpacing: 8
        
        Label { 
            text: "Over/Under Voltage (ANSI 59/27):" 
            
        }
        Label { 
            text: "±15% of nominal voltage" 
            font.bold: true
            
        }
        
        Label { 
            text: "Current-limiting fuses:" 
            
        }
        Label { 
            text: "200A on each phase" 
            font.bold: true
            
        }
        
        Label { 
            text: "Control Power Backup:" 
            
        }
        Label { 
            text: "UPS for microprocessor controller" 
            font.bold: true
            
        }
        
        Label { 
            text: "Motor Control Protection:" 
            
        }
        Label { 
            text: "Circuit breakers for each motor" 
            font.bold: true
            
        }
        
        Label { 
            text: "Position Indication:" 
            
        }
        Label { 
            text: "Tap position indicators & SCADA interface" 
            font.bold: true
            
        }
        
        Label { 
            text: "Inter-phase Coordination:" 
            
        }
        Label { 
            text: "Common controller for all 3 units" 
            font.bold: true
            
        }
        
        Label { 
            text: "Bypass Provision:" 
            
        }
        Label { 
            text: "Manual bypass switches for each phase" 
            font.bold: true
            
        }
        
        Label { 
            text: "Surge Protection:" 
            
        }
        Label { 
            text: "9kV MOV arresters on both sides" 
            font.bold: true
            
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.topMargin: 10
            Layout.bottomMargin: 5
            height: 1
            color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
        }
    }

    Label { 
        text: "Configuration Details:" 
        Layout.columnSpan: 2
        font.bold: true 
        
    }

    Label {
        text: "Delta-connected single-phase 185kVA regulators for 11kV line"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }

    Label {
        text:"32-step voltage regulators with ±10% regulation range"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }
    Label {
        text: "Step voltage change: 0.625% per step (10% ÷ 16 steps)"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }
    Label {
        text: "Suitable for addressing voltage rise during high wind generation periods"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }
    Label {
        text:"Bidirectional power flow capability"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }
    Label {
        text: "Total capacity: 555kVA (3 × 185kVA single-phase units)"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.columnSpan: 2
        Layout.topMargin: 10
        Layout.bottomMargin: 5
        height: 1
        color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
    }

    Label { 
        text: "Control System Specifications:" 
        Layout.columnSpan: 2
        font.bold: true 
        
    }

    Label {
        text: "Cooper CL-6 or Eaton ComPak Plus voltage control system"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }
    Label {
        text: "Line drop compensation with R and X settings"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }
    Label {
        text: "Load balancing capability for the three single-phase units"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }
    Label {
        text: "Remote communications via DNP3.0 protocol" 
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }
    Label {
        text: "Data logging for voltage profiles and operations count"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }
    Label {
        text: "Reverse power detection for bidirectional regulation"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }
}