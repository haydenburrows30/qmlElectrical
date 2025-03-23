import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../buttons"

ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.margins: 50
    spacing: 10

    GridLayout {
        columns: 2
        Layout.fillWidth: true
        Layout.fillHeight: true
        columnSpacing: 15
        rowSpacing: 8
        
        Text { text: "Over/Under Voltage (ANSI 59/27):" }
        Text { text: "±15% of nominal voltage" ; font.bold: true}
        
        Text { text: "Current-limiting fuses:" }
        Text { text: "200A on each phase" ; font.bold: true}
        
        Text { text: "Control Power Backup:" }
        Text { text: "UPS for microprocessor controller" ; font.bold: true}
        
        Text { text: "Motor Control Protection:" }
        Text { text: "Circuit breakers for each motor" ; font.bold: true}
        
        Text { text: "Position Indication:" }
        Text { text: "Tap position indicators & SCADA interface" ; font.bold: true}
        
        Text { text: "Inter-phase Coordination:" }
        Text { text: "Common controller for all 3 units" ; font.bold: true}
        
        Text { text: "Bypass Provision:" }
        Text { text: "Manual bypass switches for each phase" ; font.bold: true}
        
        Text { text: "Surge Protection:" }
        Text { text: "9kV MOV arresters on both sides" ; font.bold: true}

        Rectangle {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.topMargin: 10
            Layout.bottomMargin: 5
            height: 1
            color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
        }
    }

    Text { text: "Configuration Details:" ; Layout.columnSpan: 2; font.bold: true }

    Text {
        text: "Delta-connected single-phase 185kVA regulators for 11kV line"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true                         
    }

    Text {
        text:"32-step voltage regulators with ±10% regulation range"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true                         
    }
    Text {
        text: "Step voltage change: 0.625% per step (10% ÷ 16 steps)"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true                         
    }
    Text {
        text: "Suitable for addressing voltage rise during high wind generation periods"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true                         
    }
    Text {
        text:"Bidirectional power flow capability"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true                         
    }
    Text {
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

    Text { text: "Control System Specifications:" ; Layout.columnSpan: 2; font.bold: true }

    Text {
        text: "Cooper CL-6 or Eaton ComPak Plus voltage control system"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Text {
        text: "Line drop compensation with R and X settings"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Text {
        text: "Load balancing capability for the three single-phase units"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Text {
        text: "Remote communications via DNP3.0 protocol" 
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Text {
        text: "Data logging for voltage profiles and operations count"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    Text {
        text: "Reverse power detection for bidirectional regulation"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}