import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import CableAmpacity 1.0

WaveCard {
    id: cableAmpacityCard
    title: 'Cable Ampacity Calculator'

    property AmpacityCalculator calculator: AmpacityCalculator {}  // Changed type name to match registration

    ColumnLayout {
        spacing: 10
        anchors.centerIn: parent

        GridLayout {
            columns: 2
            rowSpacing: 10
            columnSpacing: 15

            Label { text: "Cable Size (mm²):" }
            ComboBox {
                id: cableSizeCombo
                model: [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240]
                onCurrentTextChanged: calculator.cableSize = parseFloat(currentText)
            }

            Label { text: "Insulation Type:" }
            ComboBox {
                id: insulationCombo
                model: ["PVC", "XLPE"]
                onCurrentTextChanged: calculator.insulationType = currentText
            }

            Label { text: "Installation Method:" }
            ComboBox {
                id: installMethodCombo
                model: ["Conduit", "Tray", "Direct Buried", "Free Air", "Wall Surface"]
                onCurrentTextChanged: calculator.installMethod = currentText
            }

            Label { text: "Ambient Temperature (°C):" }
            SpinBox {
                id: ambientTemp
                from: 25
                to: 55
                value: 30
                stepSize: 5
                onValueChanged: calculator.ambientTemp = value
            }

            Label { text: "Number of Circuits:" }
            SpinBox {
                id: groupingNumber
                from: 1
                to: 20
                value: 1
                onValueChanged: calculator.groupingNumber = value
            }

            Label { text: "Conductor Material:" }
            ComboBox {
                id: conductorMaterial
                model: ["Copper", "Aluminum"]
                onCurrentTextChanged: calculator.conductorMaterial = currentText
                Layout.fillWidth: true
            }
        }

        GroupBox {
            title: "Results"

            GridLayout {
                columns: 2
                rowSpacing: 5
                columnSpacing: 10

                Label { text: "Base Ampacity:" }
                Label { text: calculator.baseAmpacity.toFixed(1) + " A" }

                Label { text: "Derated Ampacity:" }
                Label { text: calculator.deratedAmpacity.toFixed(1) + " A" }

                Label { text: "Voltage Drop per 100m:" }
                Label { text: calculator.voltageDropPer100m.toFixed(1) + " V" }

                Label { text: "Economic Size:" }
                Label { text: calculator.recommendedSize.toFixed(1) + " mm²" }
            }
        }
    }
}