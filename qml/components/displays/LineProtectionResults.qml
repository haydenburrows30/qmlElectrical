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
    
    Text { 
        text: "Overcurrent Protection:" 
        font.bold: true
        font.pixelSize: 14
        Layout.columnSpan: 2
        color: sideBar.toggle1 ? "white" : "black"
    }
    
    Text { 
        text: "Overcurrent (50/51):"
        leftPadding: 10
        color: sideBar.toggle1 ? "white" : "black"
    }
    Text { 
        text: transformerReady ? 
                "Very Inverse curve, TMS: " + safeValueFunction(transformerCalculator.relayTimeDial, 0.3).toFixed(2) : 
                "Very Inverse curve, TMS: 0.30"
        font.bold: true
        color: sideBar.toggle1 ? "white" : "black"
    }
    
    Text { 
        text: "Earth Fault (50N/51N):"
        leftPadding: 10
        color: sideBar.toggle1 ? "white" : "black"
    }
    Text { 
        text: "Pickup: 10-20% of CT primary rating"
        font.bold: true
        color: sideBar.toggle1 ? "white" : "black"
    }
    
    Text { 
        text: "CT Ratio:"
        leftPadding: 10
        color: sideBar.toggle1 ? "white" : "black"
    }
    Text { 
        font.bold: true
        text: transformerReady ? 
                transformerCalculator.relayCtRatio : 
                "300/1"
        color: sideBar.toggle1 ? "white" : "black"
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.columnSpan: 2
        Layout.topMargin: 5
        Layout.bottomMargin: 5
        height: 1
        color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
    }
    
    Text { 
        text: "Additional Protection Functions:" 
        font.bold: true
        font.pixelSize: 14
        Layout.columnSpan: 2
        color: sideBar.toggle1 ? "white" : "black"
    }
    
    Column {
        Layout.columnSpan: 2
        Layout.fillWidth: true
        Layout.leftMargin: 10
        spacing: 8
        
        Text { 
            text: "• Loss of Mains: (Islanding)"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
        Text { 
            text: "• Synchronization Check (25): Reconnection to the grid"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
        Text { 
            text: "• Power Quality Monitoring"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
        Text { 
            text: "• Directional Overcurrent (67): Bidirectional power flow"
            width: parent.width
            wrapMode: Text.WordWrap
            color: sideBar.toggle1 ? "white" : "black"
        }
    }
}