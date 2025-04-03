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
    
    GridLayout {
        columns: 2
        Layout.fillWidth: true
        Layout.fillHeight: true
        
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
        text: "Delta-connected single-phase 185kVA regulators for 11kV line<br>" +
        "32-step voltage regulators with ±10% regulation range<br>" +
        "Step voltage change: 0.625% per step (10% ÷ 16 steps)<br>" +
        "Suitable for addressing voltage rise during high wind generation periods<br>" +
        "Bidirectional power flow capability<br>" +
        "Total capacity: 555kVA (3 × 185kVA single-phase units)"
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
        text: "Cooper CL-6 or Eaton ComPak Plus voltage control system<br>" +
        "Line drop compensation with R and X settings<br>" +
        "Load balancing capability for the three single-phase units<br>" +
        "Remote communications via DNP3.0 protocol<br>" +
        "Data logging for voltage profiles and operations count<br>" +
        "Reverse power detection for bidirectional regulation"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        
    }
}