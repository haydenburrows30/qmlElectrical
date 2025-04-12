import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../"
import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import CableAmpacity 1.0

Item {
    id: cableAmpacityCard

    property AmpacityCalculator calculator: AmpacityCalculator {}
    property color textColor: Universal.foreground

    PopUpText {
        parentCard: results
        popupText: "<h3>Cable Ampacity Calculator</h3><br>" +
                            "This calculator estimates the current carrying capacity of a cable based on various parameters.<br><br>" +
                            "<b>Cable Size:</b> The cross-sectional area of the cable in mm².<br>" +
                            "<b>Insulation Type:</b> The type of insulation used in the cable.<br>" +
                            "<b>Installation Method:</b> The method of cable installation.<br>" +
                            "<b>Ambient Temperature:</b> The temperature of the surrounding environment in °C.<br>" +
                            "<b>Number of Circuits:</b> The number of cables or circuits in the installation.<br>" +
                            "<b>Conductor Material:</b> The material used for the cable conductor.<br><br>" +
                            "The calculator provides the base ampacity, derated ampacity, voltage drop per 100m, and recommended cable size.<br><br>" +
                            "The visualization shows the current carrying capacity of the cable based on the selected parameters.<br><br>" +
                            "Developed by <b>Wave</b>."
    }

    RowLayout {
        anchors.fill: parent
        
        // Left side - inputs and results
        ColumnLayout {
            id: leftColumn
            Layout.maximumWidth: 350
            Layout.alignment: Qt.AlignTop

            WaveCard {
                title: "System Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 290

                id: results
                showSettings: true

                GridLayout {
                    columns: 2

                    Label { text: "Cable Size (mm²):" ;Layout.minimumWidth: 180}
                    ComboBoxRound {
                        id: cableSizeCombo
                        model: [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240]
                        onCurrentTextChanged: calculator.cableSize = parseFloat(currentText)
                        Layout.minimumWidth: 100
                    }

                    Label { text: "Insulation Type:" }
                    ComboBoxRound {
                        id: insulationCombo
                        model: ["PVC", "XLPE"]
                        onCurrentTextChanged: calculator.insulationType = currentText
                        Layout.fillWidth: true
                    }

                    Label { text: "Installation Method:" }
                    ComboBoxRound {
                        id: installMethodCombo
                        model: ["Conduit", "Tray", "Direct Buried", "Free Air", "Wall Surface"]
                        onCurrentTextChanged: calculator.installMethod = currentText
                        Layout.fillWidth: true
                    }

                    Label { text: "Ambient Temperature (°C):" }
                    SpinBoxRound {
                        id: ambientTemp
                        from: 25
                        to: 55
                        value: 30
                        stepSize: 5
                        onValueChanged: calculator.ambientTemp = value
                        Layout.fillWidth: true
                    }

                    Label { text: "Number of Circuits:" }
                    SpinBoxRound {
                        id: groupingNumber
                        from: 1
                        to: 20
                        value: 1
                        onValueChanged: calculator.groupingNumber = value
                        Layout.fillWidth: true
                    }

                    Label { text: "Conductor Material:" }
                    ComboBoxRound {
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
                Layout.minimumHeight: 220

                GridLayout {
                    columns: 2

                    Label { text: "Base Ampacity:" ;Layout.minimumWidth: 180}
                    TextFieldBlue { 
                        text: calculator.baseAmpacity.toFixed(1) + " A" 
                        Layout.minimumWidth: 100
                    }

                    Label { text: "Derated Ampacity:" }
                    TextFieldBlue { 
                        text: calculator.deratedAmpacity.toFixed(1) + " A" 
                        Layout.fillWidth: true
                    }

                    Label { text: "Voltage Drop per 100m:" }
                    TextFieldBlue { 
                        text: calculator.voltageDropPer100m.toFixed(1) + " V" 
                        Layout.fillWidth: true
                    }

                    Label { text: "Economic Size:" }
                    TextFieldBlue { 
                        text: calculator.recommendedSize.toFixed(1) + " mm²" 
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