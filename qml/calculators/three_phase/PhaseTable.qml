import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components/style"

GridLayout {
    property var calculator

    Layout.fillWidth: true
    columns: 4
    columnSpacing: 10
    
    // Headers
    Label { text: "Phase"; font.bold: true ; Layout.alignment: Qt.AlignHCenter}
    Label { text: "RMS (V)"; font.bold: true; Layout.fillWidth: true ; Layout.alignment: Qt.AlignHCenter}
    Label { text: "Power Factor"; font.bold: true ; Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter}
    Label { text: "Power (kW)"; font.bold: true ; Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter}

    // Phase A
    Label { text: "A"; color: "#f44336" ; Layout.alignment: Qt.AlignHCenter}
    Label { text: calculator.rmsA.toFixed(1) ; Layout.alignment: Qt.AlignHCenter}
    Label { text: calculator.powerFactorA.toFixed(3) ; Layout.alignment: Qt.AlignHCenter}
    Label { text: (calculator.rmsA * calculator.currentA * calculator.powerFactorA / 1000).toFixed(2) ; Layout.alignment: Qt.AlignHCenter}

    // Phase B
    Label { text: "B"; color: "#4caf50" ; Layout.alignment: Qt.AlignHCenter}
    Label { text: calculator.rmsB.toFixed(1) ; Layout.alignment: Qt.AlignHCenter}
    Label { text: calculator.powerFactorB.toFixed(3) ; Layout.alignment: Qt.AlignHCenter}
    Label { text: (calculator.rmsB * calculator.currentB * calculator.powerFactorB / 1000).toFixed(2) ; Layout.alignment: Qt.AlignHCenter}

    // Phase C
    Label { text: "C"; color: "#2196f3" ; Layout.alignment: Qt.AlignHCenter}
    Label { text: calculator.rmsC.toFixed(1) ; Layout.alignment: Qt.AlignHCenter}
    Label { text: calculator.powerFactorC.toFixed(3) ; Layout.alignment: Qt.AlignHCenter}
    Label { text: (calculator.rmsC * calculator.currentC * calculator.powerFactorC / 1000).toFixed(2) ; Layout.alignment: Qt.AlignHCenter}

    Rectangle {
        Layout.columnSpan: 4
        height: 1
        color: window.modeToggled ? "#404040" : "#e0e0e0"
    }

    Label { text: "VAB" ; Layout.alignment: Qt.AlignHCenter ; color: "#f44336"}
    Label { text: calculator.rmsAB.toFixed(1) ; Layout.alignment: Qt.AlignHCenter}
    Label { Layout.columnSpan: 2}

    Label { text: "VBC" ; Layout.alignment: Qt.AlignHCenter ; color: "#4caf50"}
    Label { text: calculator.rmsBC.toFixed(1) ; Layout.alignment: Qt.AlignHCenter}
    Label { Layout.columnSpan: 2}

    Label { text: "VCA" ; Layout.alignment: Qt.AlignHCenter ; color: "#2196f3"}
    Label { text: calculator.rmsCA.toFixed(1) ; Layout.alignment: Qt.AlignHCenter}
    Label { Layout.columnSpan: 2}
}