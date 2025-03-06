import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    property var model
    spacing: 16

    GridLayout {
        Layout.fillWidth: true
        columns: 6
        columnSpacing: 32
        rowSpacing: 12

        // Headers
        Label { 
            text: "Phase Values" 
            font.weight: Font.DemiBold
            Layout.columnSpan: 2 
        }
        Label { 
            text: "Line Values" 
            font.weight: Font.DemiBold
            Layout.columnSpan: 2 
        }
        Label { 
            text: "Peak Values" 
            font.weight: Font.DemiBold
            Layout.columnSpan: 2 
        }

        // Phase RMS Values
        Label { text: "Phase A:" }
        Label { 
            text: model.rmsA.toFixed(1) + " V"
            color: toolBar.toggle ? "#f44336" : "#d32f2f" 
        }

        // Line RMS Values
        Label { text: "A-B:" }
        Label { 
            text: model.rmsAB.toFixed(1) + " V"
            color: toolBar.toggle ? "#ff9800" : "#f57c00"
        }

        // Peak Values
        Label { text: "Peak A:" }
        Label { 
            text: model.peakA.toFixed(1) + " V"
            color: toolBar.toggle ? "#f44336" : "#d32f2f"
        }

        // Phase B
        Label { text: "Phase B:" }
        Label { 
            text: model.rmsB.toFixed(1) + " V"
            color: toolBar.toggle ? "#4caf50" : "#2e7d32"
        }

        Label { text: "B-C:" }
        Label { 
            text: model.rmsBC.toFixed(1) + " V"
            color: toolBar.toggle ? "#ff9800" : "#f57c00"
        }

        Label { text: "Peak B:" }
        Label { 
            text: model.peakB.toFixed(1) + " V"
            color: toolBar.toggle ? "#4caf50" : "#2e7d32"
        }

        // Phase C
        Label { text: "Phase C:" }
        Label { 
            text: model.rmsC.toFixed(1) + " V"
            color: toolBar.toggle ? "#2196f3" : "#1976d2"
        }

        Label { text: "C-A:" }
        Label { 
            text: model.rmsCA.toFixed(1) + " V"
            color: toolBar.toggle ? "#ff9800" : "#f57c00"
        }

        Label { text: "Peak C:" }
        Label { 
            text: model.peakC.toFixed(1) + " V"
            color: toolBar.toggle ? "#2196f3" : "#1976d2"
        }
//sequence
        Label { 
            text: "Sequence Components" 
            font.weight: Font.DemiBold
            Layout.columnSpan: 2
        }

        Label { 
            text: "Power Flow" 
            font.weight: Font.DemiBold
            Layout.columnSpan: 2
        }

        Label { 
            text: "Harmonics" 
            font.weight: Font.DemiBold
            Layout.columnSpan: 2
        }

        Label {
            text: "Positive: "
        }

        Label { 
            text: (sineModel.positiveSeq !== undefined ? 
                sineModel.positiveSeq.toFixed(1) : "---") + " V"
            color: toolBar.toggle ? "#4caf50" : "#2e7d32"
        }

        Label {
            text: "Active: "
        }

        Label { 
            text: (sineModel.activePower !== undefined ? 
                sineModel.activePower.toFixed(1) : "---") + " kW"
            color: toolBar.toggle ? "#2196f3" : "#1976d2"
        }

        Label {
            text: "THD: "
        }

        Label { 
            text:  (sineModel.thd !== undefined ? 
                sineModel.thd.toFixed(1) : "---") + " %" 
            color: toolBar.toggle ? "#9c27b0" : "#7b1fa2"
        }

        Label {
            text: "Negative: "
        }

        Label { 
            text:  (sineModel.negativeSeq !== undefined ? 
                sineModel.negativeSeq.toFixed(1) : "---") + " V"
            color: toolBar.toggle ? "#ff9800" : "#f57c00"
        }

        Label {
            Layout.columnSpan: 4
        }

        Label {
            text: "Zero: "
        }

        Label { 
            text: (sineModel.zeroSeq !== undefined ? 
                sineModel.zeroSeq.toFixed(1) : "---") + " V"
            color: toolBar.toggle ? "#f44336" : "#d32f2f"
        } 
    }
}
