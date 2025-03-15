import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"

import CableAmpacity 1.0

Item {
    id: cableAmpacityCard
    // title: 'Cable Ampacity Calculator'

    property AmpacityCalculator calculator: AmpacityCalculator {}
    property color textColor: Universal.foreground

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        // Left side - inputs and results
        ColumnLayout {
            Layout.maximumWidth: 350
            spacing: 10
            Layout.alignment: Qt.AlignTop

            WaveCard {
                title: "System Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 300

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

                    Label { text: "Cable Size (mm²):" ;Layout.minimumWidth: 180}
                    ComboBox {
                        id: cableSizeCombo
                        model: [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240]
                        onCurrentTextChanged: calculator.cableSize = parseFloat(currentText)
                        Layout.minimumWidth: 100
                    }

                    Label { text: "Insulation Type:" }
                    ComboBox {
                        id: insulationCombo
                        model: ["PVC", "XLPE"]
                        onCurrentTextChanged: calculator.insulationType = currentText
                        Layout.fillWidth: true
                    }

                    Label { text: "Installation Method:" }
                    ComboBox {
                        id: installMethodCombo
                        model: ["Conduit", "Tray", "Direct Buried", "Free Air", "Wall Surface"]
                        onCurrentTextChanged: calculator.installMethod = currentText
                        Layout.fillWidth: true
                    }

                    Label { text: "Ambient Temperature (°C):" }
                    SpinBox {
                        id: ambientTemp
                        from: 25
                        to: 55
                        value: 30
                        stepSize: 5
                        onValueChanged: calculator.ambientTemp = value
                        Layout.fillWidth: true
                    }

                    Label { text: "Number of Circuits:" }
                    SpinBox {
                        id: groupingNumber
                        from: 1
                        to: 20
                        value: 1
                        onValueChanged: calculator.groupingNumber = value
                        Layout.fillWidth: true
                    }

                    Label { text: "Conductor Material:" }
                    ComboBox {
                        id: conductorMaterial
                        model: ["Copper", "Aluminum"]
                        onCurrentTextChanged: calculator.conductorMaterial = currentText
                        Layout.fillWidth: true
                    }
                }
            }

            WaveCard {
                title: "Results"
                Layout.fillWidth: true
                Layout.minimumHeight: 200

                GridLayout {
                    columns: 2
                    rowSpacing: 20
                    columnSpacing: 10

                    Label { text: "Base Ampacity:" ;Layout.minimumWidth: 180}
                    Label { 
                        text: calculator.baseAmpacity.toFixed(1) + " A" 
                        color: Universal.foreground
                        font.bold: true
                        Layout.minimumWidth: 100
                    }

                    Label { text: "Derated Ampacity:" }
                    Label { 
                        text: calculator.deratedAmpacity.toFixed(1) + " A" 
                        color: Universal.foreground
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Label { text: "Voltage Drop per 100m:" }
                    Label { 
                        text: calculator.voltageDropPer100m.toFixed(1) + " V" 
                        color: Universal.foreground
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Label { text: "Economic Size:" }
                    Label { 
                        text: calculator.recommendedSize.toFixed(1) + " mm²" 
                        color: Universal.foreground
                        font.bold: true
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // Right side - visualization
        WaveCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            CableAmpacityViz {
                anchors.fill: parent
                anchors.margins: 5
                
                cableSize: parseFloat(cableSizeCombo.currentText || "0")
                insulationType: insulationCombo.currentText || "PVC"
                installMethod: installMethodCombo.currentText || "Conduit"
                ambientTemp: ambientTemp.value || 30
                groupingNumber: groupingNumber.value || 1
                conductorMaterial: conductorMaterial.currentText || "Copper"
                
                baseAmpacity: calculator.baseAmpacity
                deratedAmpacity: calculator.deratedAmpacity
                
                darkMode: Universal.theme === Universal.Dark
                textColor: cableAmpacityCard.textColor
            }
        }
    }
}