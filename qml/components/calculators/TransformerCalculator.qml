import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"

import Transformer 1.0

Item {
    id: transformerCard

    property TransformerCalculator calculator: TransformerCalculator {}
    property color textColor: Universal.foreground

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Left side - Inputs and results
        ColumnLayout {
            Layout.maximumWidth: 300
            spacing: 10
            Layout.alignment: Qt.AlignTop

            // KVA input at the top
            WaveCard {
                title: "Transformer Rating"
                Layout.minimumHeight: 120 // Increased to accommodate the vector group
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    
                    Label { text: "KVA:" }
                    TextField {
                        id: kvaInput
                        placeholderText: "Enter KVA"
                        Layout.minimumWidth: 120
                        onTextChanged: {
                            if (text) {
                                calculator.setApparentPower(parseFloat(text));
                            } else {
                                calculator.setApparentPower(0);
                            }
                        }
                    }
                    
                    Label { text: "Vector Group:" }
                    ComboBox {
                        id: vectorGroupCombo
                        Layout.minimumWidth: 120
                        model: ["Dyn11", "Yyn0", "Dyn1", "Yzn1", "Yd1", "Dd0", "Yy0"]
                        onCurrentTextChanged: {
                            calculator.setVectorGroup(currentText)
                        }
                        Component.onCompleted: {
                            currentIndex = 0 // Default to Dyn11
                        }
                    }
                }
            }
            
            // Primary Side
            WaveCard {
                title: "Primary Side"
                Layout.minimumHeight: 150
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Label { text: "Voltage (V):" }
                    TextField {
                        id: primaryVoltage
                        Layout.minimumWidth: 150
                        placeholderText: "Enter voltage"
                        onTextChanged: {
                            calculator.primaryVoltage = parseFloat(text || "0")
                            // Recalculate when both KVA and voltage are present
                            if (kvaInput.text && text) {
                                calculator.setApparentPower(parseFloat(kvaInput.text))
                            }
                        }
                    }

                    Label { text: "Current (A):" }
                    RowLayout {
                        Layout.minimumWidth: 150
                        
                        // Show either input field or calculated value
                        TextField {
                            id: primaryCurrentInput
                            placeholderText: "Enter current"
                            Layout.fillWidth: true
                            visible: parseFloat(kvaInput.text || "0") <= 0
                            onTextChanged: {
                                if (text) {
                                    calculator.primaryCurrent = parseFloat(text || "0")
                                }
                            }
                        }
                        
                        Label {
                            text: calculator.primaryCurrent.toFixed(2)
                            visible: parseFloat(kvaInput.text || "0") > 0
                            color: Universal.foreground
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Secondary Side
            WaveCard {
                title: "Secondary Side"
                Layout.minimumHeight: 120
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Label { text: "Voltage (V):" }
                    TextField {
                        id: secondaryVoltage
                        placeholderText: "Enter voltage"
                        onTextChanged: {
                            if(text) {
                                calculator.secondaryVoltage = parseFloat(text)
                                // Recalculate when both KVA and voltage are present
                                if (kvaInput.text && text) {
                                    calculator.setApparentPower(parseFloat(kvaInput.text))
                                }
                            }
                        }
                        Layout.minimumWidth: 150
                    }

                    Label { text: "Current (A):" }
                    Label {
                        id: secondaryCurrent
                        text: calculator.secondaryCurrent.toFixed(2)
                        color: Universal.foreground
                        Layout.minimumWidth: 150
                    }
                }
            }

            // Results
            WaveCard {
                title: "Results"
                Layout.minimumHeight: 180  // Increased to fit the additional information
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 5

                    Label { 
                        text: "Turns Ratio: " + calculator.turnsRatio.toFixed(2)
                        visible: calculator.turnsRatio > 0
                        color: Universal.foreground
                    }
                    Label { 
                        id: correctedRatioLabel
                        text: "Vector-corrected Ratio: " + calculator.correctedRatio.toFixed(2)
                        visible: calculator.correctedRatio > 0
                        color: Universal.foreground
                        font.italic: true
                    }
                    Label { 
                        text: "Power Rating: " + calculator.powerRating.toFixed(2) + " VA"
                        visible: calculator.powerRating > 0
                        color: Universal.foreground
                    }
                    Label { 
                        text: "Efficiency: " + calculator.efficiency.toFixed(2) + "%"
                        color: Universal.foreground
                    }
                    Label {
                        text: "Vector Group: " + calculator.vectorGroup
                        color: Universal.foreground
                    }
                    Label {
                        text: calculator.vectorGroupDescription
                        color: Universal.foreground
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        visible: calculator.vectorGroup.indexOf("D") === 0 || calculator.vectorGroup.indexOf("Y") === 0
                        text: calculator.vectorGroup.indexOf("D") === 0 ? 
                              "Delta primary: Line voltage = Phase voltage × √3" : 
                              "Wye primary: Line voltage = Phase voltage"
                        color: Universal.accent
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // Right side - Visualization
        WaveCard {
            title: "Transformer Visualization"
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter

            PowerTransformerVisualization {
                anchors.fill: parent
                anchors.margins: 5
                
                primaryVoltage: parseFloat(primaryVoltage.text || "0")
                primaryCurrent: calculator.primaryCurrent || parseFloat(primaryCurrentInput.text || "0")
                secondaryVoltage: parseFloat(secondaryVoltage.text || "0")
                secondaryCurrent: calculator.secondaryCurrent
                powerRating: calculator ? calculator.powerRating : 0
                turnsRatio: calculator ? calculator.turnsRatio : 1
                correctedRatio: calculator ? calculator.correctedRatio : 1
                efficiency: calculator ? calculator.efficiency : 0
                vectorGroup: calculator ? calculator.vectorGroup : "Dyn11"
                
                darkMode: Universal.theme === Universal.Dark
                textColor: transformerCard.textColor
            }
        }
    }
    
    // Add connections to ensure UI updates when calculator changes
    Connections {
        target: calculator
        function onPrimaryCurrentChanged() {
            // console.log("Primary current changed to:", calculator.primaryCurrent)
        }
        function onSecondaryCurrentChanged() {
            // console.log("Secondary current changed to:", calculator.secondaryCurrent)
        }
        function onCorrectedRatioChanged() {
            console.log("Corrected ratio changed to:", calculator.correctedRatio)
        }
        function onVectorGroupChanged() {
            console.log("Vector group changed to:", calculator.vectorGroup)
        }
    }
}
