import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../style"
import HarmonicAnalysis 1.0

GridLayout {
    id: root
    columns: 2
    rowSpacing: 10
    columnSpacing: 20
    
    property HarmonicAnalysisCalculator calculator

    // Add default safe values for when calculator is not available or initialized
    readonly property real safeThd: calculator && calculator.hasOwnProperty("thd") && calculator.thd !== undefined ? calculator.thd : 0.0
    readonly property real safeCf: calculator && calculator.hasOwnProperty("crestFactor") && calculator.crestFactor !== undefined ? calculator.crestFactor : 1.414
    readonly property real safeFf: calculator && calculator.hasOwnProperty("formFactor") && calculator.formFactor !== undefined ? calculator.formFactor : 1.11

    Label { 
        text: "THD:" 
        font.bold: true
    }
    Label { 
        // Use the safe property instead of directly accessing calculator.thd
        text: safeThd.toFixed(2) + "%"
        Layout.fillWidth: true
    }
    
    Label { 
        text: "Crest Factor:" 
        font.bold: true
    }
    Label { 
        // Use the safe property instead of directly accessing calculator.crestFactor
        text: safeCf.toFixed(2)
        Layout.fillWidth: true
    }
    
    Label { 
        text: "Form Factor:" 
        font.bold: true
    }
    Label { 
        // Use the safe property instead of directly accessing calculator.formFactor
        text: safeFf.toFixed(2)
        Layout.fillWidth: true
    }
}
