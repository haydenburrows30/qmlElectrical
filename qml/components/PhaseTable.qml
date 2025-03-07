import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    property var model
    spacing: 10

    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 20
        rowSpacing: 10

        // Headers
        Label { text: "Phase"; font.bold: true }
        Label { text: "RMS (V)"; font.bold: true }
        Label { text: "Power Factor"; font.bold: true }
        Label { text: "Power (kW)"; font.bold: true }

        // Phase A
        Label { text: "A"; color: "#f44336" }
        Label { text: model.rmsA.toFixed(1) }
        Label { text: model.powerFactorA.toFixed(3) }
        Label { text: (model.rmsA * model.currentA * model.powerFactorA / 1000).toFixed(2) }

        // Phase B
        Label { text: "B"; color: "#4caf50" }
        Label { text: model.rmsB.toFixed(1) }
        Label { text: model.powerFactorB.toFixed(3) }
        Label { text: (model.rmsB * model.currentB * model.powerFactorB / 1000).toFixed(2) }

        // Phase C
        Label { text: "C"; color: "#2196f3" }
        Label { text: model.rmsC.toFixed(1) }
        Label { text: model.powerFactorC.toFixed(3) }
        Label { text: (model.rmsC * model.currentC * model.powerFactorC / 1000).toFixed(2) }
    }
}
