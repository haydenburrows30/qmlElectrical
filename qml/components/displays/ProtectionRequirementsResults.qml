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

    Text { 
        text: "Transformer Protection:" 
        Layout.columnSpan: 2
        font.bold: true 
        Layout.topMargin: 5
        color: sideBar.toggle1 ? "white" : "black"
    }
    
    Text { 
        text: "Differential Protection (ANSI 87T)"
        color: sideBar.toggle1 ? "white" : "black"
    }
    Text { 
        text: ">5 MVA" 
        font.bold: true
        color: sideBar.toggle1 ? "white" : "black"
    }
    
    Text { 
        text: "Overcurrent (ANSI 50/51)"
        color: sideBar.toggle1 ? "white" : "black"
    }
    Text { 
        text: safeValueFunction(transformerCalculator.relayPickupCurrent, 0).toFixed(0) + "A"
        font.bold: true
        color: sideBar.toggle1 ? "white" : "black"
    }
    
    Text { 
        text: "Restricted Earth Fault (ANSI 64)"
        color: sideBar.toggle1 ? "white" : "black"
    }
    Text { 
        text: "Y-connected winding"
        font.bold: true
        color: sideBar.toggle1 ? "white" : "black"
    }

    Text { 
        text: "Buchholz Relay"
        color: sideBar.toggle1 ? "white" : "black"
    }
    Text { 
        text: "For oil-filled transformers"
        font.bold: true
        color: sideBar.toggle1 ? "white" : "black"
    }
    
    Text { 
        text: "Pressure Relief Device"
        color: sideBar.toggle1 ? "white" : "black"
    }
    Text { 
        text: "Opens at excessive pressure"
        font.bold: true
        color: sideBar.toggle1 ? "white" : "black"
    }
    
    Text { 
        text: "Winding Temperature"
        color: sideBar.toggle1 ? "white" : "black"
    }
    Text { 
        text: "Alarm at 100°C, Trip at 120°C"
        font.bold: true
        color: sideBar.toggle1 ? "white" : "black"
    }
}