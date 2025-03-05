import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GroupBox {
    property var model
    title: "Measurements"
    
    GridLayout {
        columns: 4
        rowSpacing: 10
        columnSpacing: 20
        
        Label { text: "RMS Values" }
        Label { text: "Phase A: " + model.rmsA.toFixed(1) + " V" }
        Label { text: "Phase B: " + model.rmsB.toFixed(1) + " V" }
        Label { text: "Phase C: " + model.rmsC.toFixed(1) + " V" }
        
        Label { text: "Peak Values" }
        Label { text: "Phase A: " + model.peakA.toFixed(1) + " V" }
        Label { text: "Phase B: " + model.peakB.toFixed(1) + " V" }
        Label { text: "Phase C: " + model.peakC.toFixed(1) + " V" }
        
        Label { text: "Line-to-Line RMS" }
        Label { text: "A-B: " + model.rmsAB.toFixed(1) + " V" }
        Label { text: "B-C: " + model.rmsBC.toFixed(1) + " V" }
        Label { text: "C-A: " + model.rmsCA.toFixed(1) + " V" }
    }
}
