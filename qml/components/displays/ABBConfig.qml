import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../buttons"

ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.margins: 50
    spacing: 5

    GridLayout {
        columns: 2
        Layout.fillWidth: true
        columnSpacing: 20
        rowSpacing: 8

            // Phase Overcurrent Section
        Text { 
            text: "Phase Overcurrent (ANSI 51P)"
            font.bold: true
            font.pixelSize: 14
            Layout.columnSpan: 2
            Layout.topMargin: 5
        }
        
        Text { 
            text: "Operating Mode:"
            leftPadding: 10
        }
        Text { 
            text: "3-phase, IEC Very Inverse (VI)"
            font.bold: true
        }
        
        Text { 
            text: "Startup Value:"
            leftPadding: 10
        }
        Text { 
            text: (safeValueFunction(transformerCalculator.relayPickupCurrent, 0) * 1.1).toFixed(1) + " A"
            font.bold: true
        }
        
        Text { 
            text: "Time Multiplier:"
            leftPadding: 10
        }
        Text { 
            text: "0.4 (coordinate with downstream)"
            font.bold: true
        }

            // Earth Fault Section
        Rectangle {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.topMargin: 10
            Layout.bottomMargin: 5
            height: 1
            color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
        }
        
        Text { 
            text: "Earth Fault (ANSI 51N)" 
            font.bold: true
            font.pixelSize: 14
            Layout.columnSpan: 2
        }
        
        Text { 
            text: "Operating Mode:"
            leftPadding: 10
        }
        Text { 
            text: "IEC Extremely Inverse (EI)"
            font.bold: true
        }
        
        Text { 
            text: "Startup Value:"
            leftPadding: 10
        }
        Text { 
            text: (safeValueFunction(transformerCalculator.relayPickupCurrent, 0) * 0.2).toFixed(1) + " A (20% of rated)"
            font.bold: true
        }
        
        Text { 
            text: "Time Multiplier:"
            leftPadding: 10
        }
        Text { 
            text: "0.5"
            font.bold: true
        }

            // Instantaneous Overcurrent
        Rectangle {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.topMargin: 10
            Layout.bottomMargin: 5
            height: 1
            color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
        }
        
        Text { 
            text: "Instantaneous Overcurrent (ANSI 50P)" 
            font.bold: true
            font.pixelSize: 14
            Layout.columnSpan: 2
        }
        
        Text { 
            text: "Startup Value:"
            leftPadding: 10
        }
        Text { 
            text: (safeValueFunction(transformerCalculator.faultCurrentHV, 0) * 0.8).toFixed(1) + " A (80% of fault current)"
            font.bold: true
        }
        
        Text { 
            text: "Operating Delay:"
            leftPadding: 10
        }
        Text { 
            text: "100 ms"
            font.bold: true
        }
        
            // Directional Overcurrent
        Rectangle {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.topMargin: 10
            Layout.bottomMargin: 5
            height: 1
            color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
        }
        
        Text { 
            text: "Directional Overcurrent (ANSI 67)" 
            font.bold: true
            font.pixelSize: 14
            Layout.columnSpan: 2
        }
        
        Text { 
            text: "Direction Mode:"
            leftPadding: 10
        }
        Text { 
            text: "Forward (from wind turbine to grid)"
            font.bold: true
        }
        
        Text { 
            text: "Characteristic Angle:"
            leftPadding: 10
        }
        Text { 
            text: "60°"
            font.bold: true
        }

            // Additional Functions
        Rectangle {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.topMargin: 10
            Layout.bottomMargin: 5
            height: 1
            color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
        }
        
        Text { 
            text: "Additional Functions:" 
            font.bold: true
            font.pixelSize: 14
            Layout.columnSpan: 2
        }
        
        Text { 
            text: "Auto-Reclosing (ANSI 79):"
            leftPadding: 10
        }
        Text { 
            text: "Enabled with 1 fast + 1 delayed cycle"
            font.bold: true
        }
        
        Text { 
            text: "Undervoltage (ANSI 27):"
            leftPadding: 10
        }
        Text { 
            text: "0.8 × Un, delay 3.0s"
            font.bold: true
        }
        
        Text { 
            text: "Overvoltage (ANSI 59):"
            leftPadding: 10
        }
        Text { 
            text: "1.1 × Un, delay 2.0s"
            font.bold: true
        }
        
        Text { 
            text: "Breaker Failure (ANSI 50BF):"
            leftPadding: 10
        }
        Text { 
            text: "Enabled, operate time 150ms"
            font.bold: true
        }

            // Ring Main Unit Configuration
        Rectangle {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Layout.topMargin: 15
            Layout.bottomMargin: 5
            height: 1
            color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
        }

        Text {
            text: "ABB Ring Main Unit Configuration"
            font.pixelSize: 14
            Layout.columnSpan: 2
            font.bold: true
        }
        
        Text {
            text: "Equipment:"
            leftPadding: 10
        }
        Text {
            text: "SafeRing/SafePlus with vacuum circuit breaker module (V)"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            font.bold: true
        }

        Text {
            text: "CT Ratio: "
            leftPadding: 10
        }
        Text {
            text: (transformerReady ? transformerCalculator.relayCtRatio : "300/1")
            wrapMode: Text.WordWrap
            font.bold: true
        }

        Text {
            text: "VT Ratio: "
            leftPadding: 10
        }
        Text {
            text: "11000/110V"
            wrapMode: Text.WordWrap
            font.bold: true
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
            text: "Installation Requirements:"
            font.bold: true
            Layout.columnSpan: 2
        }
        
        Column {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.leftMargin: 10
            spacing: 5
            
            Text {
                text: "• Ensure SF6 gas pressure monitoring is connected to alarm"
                wrapMode: Text.WordWrap
                width: parent.width
            }
            Text {
                text: "• Configure local/remote control mode selection"
                wrapMode: Text.WordWrap
                width: parent.width
            }
            Text {
                text: "• Connect motor operators for remote circuit breaker control"
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }
    }
}