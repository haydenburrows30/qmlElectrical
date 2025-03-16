import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import Ferroresonance 1.0

Item {
    property FerroresonanceCalculator calculator: FerroresonanceCalculator {}

    ColumnLayout {
        anchors.centerIn: parent
        anchors.margins: 20
        spacing: 10

        Label {
            text: "Ferroresonance Analysis Calculator"
            font.bold: true
            font.pixelSize: 18
        }

        GridLayout {
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            Label { text: "Transformer Inductance (H):" }
            TextField {
                id: inductanceField
                validator: DoubleValidator { bottom: 0 }
                Layout.fillWidth: true
                placeholderText: "Typical range: 0.1 - 100 H"
            }

            Label { 
                text: "(Note: Can be estimated from transformer impedance)" 
                font.italic: true
                font.pixelSize: 12
                color: "#666666"
                Layout.columnSpan: 2
            }

            Label { text: "System Capacitance (μF):" }
            TextField {
                id: capacitanceField
                validator: DoubleValidator { bottom: 0 }
                Layout.fillWidth: true
                placeholderText: "Include cable and system capacitance"
            }

            Label { 
                text: "(Consider cable capacitance: ~0.2-0.3 μF/km)" 
                font.italic: true
                font.pixelSize: 12
                color: "#666666"
                Layout.columnSpan: 2
            }

            Label { text: "System Voltage (kV):" }
            TextField {
                id: voltageField
                validator: DoubleValidator { bottom: 0 }
                Layout.fillWidth: true
            }
        }

        Button {
            text: "Analyze Ferroresonance"
            Layout.fillWidth: true
            onClicked: {
                if (inductanceField.text && capacitanceField.text && voltageField.text) {
                    calculator.calculate(
                        parseFloat(inductanceField.text),
                        parseFloat(capacitanceField.text) * 1e-6, // Convert μF to F
                        parseFloat(voltageField.text) * 1000 // Convert kV to V
                    )
                }
            }
        }

        GroupBox {
            title: "Analysis Results"
            Layout.fillWidth: true
            Layout.topMargin: 20

            ColumnLayout {
                width: parent.width
                spacing: 10

                Label {
                    id: frequencyResult
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Label {
                    id: riskLevel
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Label {
                    text: "Note: Ferroresonance risk factors:\n" +
                          "• Subharmonic (f < 50 Hz): Most severe, can cause core saturation\n" +
                          "• Fundamental (f ≈ 50 Hz): Can cause voltage amplification\n" +
                          "• Harmonic (f > 50 Hz): May affect protection systems\n" +
                          "Consider installing damping resistors if high risk detected"
                    font.pixelSize: 12
                    color: "#666666"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                }
            }
        }
    }

    Connections {
        target: calculator
        function onResonanceCalculated(value) {
            frequencyResult.text = `Resonant Frequency: ${value.toFixed(2)} Hz`
        }
        function onRiskLevelCalculated(value) {
            riskLevel.text = value
        }
    }
}
