import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../buttons"

GridLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columns: 2
    Layout.margins: 50
    columnSpacing: 15
    rowSpacing: 8

    Text { text: "Transformer Protection:" ; Layout.columnSpan: 2; font.bold: true ; Layout.topMargin: 5}
    
    Text { text: "Differential Protection (ANSI 87T)" }
    Text { text: ">5 MVA" ; font.bold: true}
    
    Text { text: "Overcurrent (ANSI 50/51)" }
    Text { 
        text: safeValueFunction(transformerCalculator.relayPickupCurrent, 0).toFixed(0) + "A"
        font.bold: true
    }
    
    Text { text: "Restricted Earth Fault (ANSI 64)" }
    Text { text: "Y-connected winding" ; font.bold: true}

    Text { text: "Buchholz Relay" }
    Text { text: "For oil-filled transformers" ; font.bold: true}
    
    Text { text: "Pressure Relief Device" }
    Text { text: "Opens at excessive pressure" ; font.bold: true}
    
    Text { text: "Winding Temperature" }
    Text { text: "Alarm at 100°C, Trip at 120°C" ; font.bold: true}
}