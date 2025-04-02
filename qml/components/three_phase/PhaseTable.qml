import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../style"
import "../backgrounds"

ColumnLayout {
    

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
        Label { text: sineModel.rmsA.toFixed(1) }
        Label { text: sineModel.powerFactorA.toFixed(3) }
        Label { text: (sineModel.rmsA * sineModel.currentA * sineModel.powerFactorA / 1000).toFixed(2) }

        // Phase B
        Label { text: "B"; color: "#4caf50" }
        Label { text: sineModel.rmsB.toFixed(1) }
        Label { text: sineModel.powerFactorB.toFixed(3) }
        Label { text: (sineModel.rmsB * sineModel.currentB * sineModel.powerFactorB / 1000).toFixed(2) }

        // Phase C
        Label { text: "C"; color: "#2196f3" }
        Label { text: sineModel.rmsC.toFixed(1) }
        Label { text: sineModel.powerFactorC.toFixed(3) }
        Label { text: (sineModel.rmsC * sineModel.currentC * sineModel.powerFactorC / 1000).toFixed(2) }
    }
}
