import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../style"

ColumnLayout {

    property var calculator
    
    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 20
        
        // Headers
        Label { text: "Phase"; font.bold: true }
        Label { text: "RMS (V)"; font.bold: true }
        Label { text: "Power Factor"; font.bold: true }
        Label { text: "Power (kW)"; font.bold: true }

        // Phase A
        Label { text: "A"; color: "#f44336" }
        Label { text: calculator.rmsA.toFixed(1) }
        Label { text: calculator.powerFactorA.toFixed(3) }
        Label { text: (calculator.rmsA * calculator.currentA * calculator.powerFactorA / 1000).toFixed(2) }

        // Phase B
        Label { text: "B"; color: "#4caf50" }
        Label { text: calculator.rmsB.toFixed(1) }
        Label { text: calculator.powerFactorB.toFixed(3) }
        Label { text: (calculator.rmsB * calculator.currentB * calculator.powerFactorB / 1000).toFixed(2) }

        // Phase C
        Label { text: "C"; color: "#2196f3" }
        Label { text: calculator.rmsC.toFixed(1) }
        Label { text: calculator.powerFactorC.toFixed(3) }
        Label { text: (calculator.rmsC * calculator.currentC * calculator.powerFactorC / 1000).toFixed(2) }
    }
}
