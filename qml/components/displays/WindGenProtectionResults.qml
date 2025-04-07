import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../"
import "../buttons"

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