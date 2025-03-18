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

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            RowLayout {
                id: mainLayout
                width: scrollView.width

                ColumnLayout {
                    Layout.maximumWidth: 350
                    spacing: 10
                    Layout.alignment: Qt.AlignTop

                    WaveCard {
                        title: "Transformer Rating"
                        Layout.minimumHeight: 120
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
                        Layout.minimumHeight: 120
                        Layout.fillWidth: true

                        GridLayout {
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 10

                            Label { text: "Line Voltage (V):" }
                            TextField {
                                id: primaryVoltage
                                Layout.minimumWidth: 150
                                placeholderText: "Enter line voltage"
                                onTextChanged: {
                                    calculator.primaryVoltage = parseFloat(text || "0")
                                    if (kvaInput.text && text) {
                                        calculator.setApparentPower(parseFloat(kvaInput.text))
                                    }
                                }
                            }

                            Label { text: "Current (A):" }
                            RowLayout {
                                Layout.minimumWidth: 150
                                
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

                            Label { text: "Line Voltage (V):" }
                            TextField {
                                id: secondaryVoltage
                                placeholderText: "Enter line voltage"
                                onTextChanged: {
                                    var value = text ? parseFloat(text) : 0;
                                    calculator.secondaryVoltage = value;
                                    console.log("Setting secondary voltage to: " + value);
                                    
                                    if (kvaInput.text && text) {
                                        calculator.setApparentPower(parseFloat(kvaInput.text));
                                    }
                                }
                                Layout.minimumWidth: 150
                            }

                            Label { text: "Current (A):" }
                            Label {
                                id: secondaryCurrent
                                text: calculator.secondaryCurrent.toFixed(2)
                                color: Universal.foreground
                            }
                        }
                    }

                    WaveCard {
                        title: "Impedance & Construction"
                        Layout.minimumHeight: 380
                        Layout.fillWidth: true

                        GridLayout {
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 10

                            Label { text: "Impedance (%):" }
                            TextField {
                                id: impedanceInput
                                placeholderText: "Enter impedance %"
                                text: calculator.impedancePercent.toFixed(2)
                                Layout.minimumWidth: 150
                                onTextChanged: {
                                    if (text) {
                                        calculator.setImpedancePercent(parseFloat(text))
                                    }
                                }
                            }

                            Label { text: "Copper Losses (W):" }
                            TextField {
                                id: copperLossesInput
                                placeholderText: "Enter copper losses"
                                Layout.minimumWidth: 150
                                Layout.fillWidth: true
                                onTextChanged: {
                                    if (text) {
                                        calculator.setCopperLosses(parseFloat(text))
                                    }
                                }
                            }
                            
                            Item {
                                Layout.columnSpan: 2
                                Layout.preferredHeight: 30
                                Layout.fillWidth: true
                                
                                Label {
                                    anchors.fill: parent
                                    text: "Tip: Copper losses can be found as 'Load losses' or 'Cu losses' on nameplate"
                                    font.italic: true
                                    font.pixelSize: 10
                                    color: Universal.accent
                                    wrapMode: Text.Wrap
                                }
                            }

                            Label { text: "Resistance (%):" }
                            TextField {
                                id: resistanceInput
                                placeholderText: "Enter resistance %"
                                text: calculator.resistancePercent.toFixed(2)
                                Layout.minimumWidth: 150
                                onTextChanged: {
                                    if (text) {
                                        calculator.setResistancePercent(parseFloat(text))
                                    }
                                }
                            }

                            Label {
                                text: "Finding R% on nameplate:"
                                font.bold: true
                                Layout.columnSpan: 2
                                Layout.topMargin: 5
                            }
                            
                            Label {
                                text: "• Listed as R%, resistance, or copper losses (W)\n• Can be calculated from Z% and X/R ratio\n• Or from copper losses: R% = (PCu × 100) / (kVA × 1000)"
                                Layout.columnSpan: 2
                                font.pixelSize: 10
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }

                            Label { text: "Reactance (%):" }
                            Label {
                                text: calculator.reactancePercent.toFixed(2)
                                color: Universal.foreground
                                Layout.minimumWidth: 150
                            }

                            Label { text: "Short-circuit MVA:" }
                            Label {
                                text: calculator.shortCircuitPower.toFixed(2)
                                color: Universal.foreground
                                Layout.minimumWidth: 150
                            }

                            Label { text: "Voltage Drop (%):" }
                                
                            Label {
                                id: voltageDrop
                                text: calculator.voltageDrop.toFixed(2)
                                color: Universal.foreground
                            }
                        }
                    }

                    // Results
                    WaveCard {
                        title: "Results"
                        Layout.minimumHeight: 300
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 5
                            anchors.fill: parent

                            // Results values section
                            Label { 
                                text: "Phase-Phase Turns Ratio: " + calculator.turnsRatio.toFixed(2)
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
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                            Label {
                                text: "Note: All voltages are 3-phase line-to-line values"
                                color: Universal.accent
                                font.pixelSize: 11
                                font.italic: true
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            
                            // Tips button
                            Button {
                                text: "Tips & Explanations"
                                icon.name: "help-about"
                                Layout.alignment: Qt.AlignCenter
                                Layout.topMargin: 10
                                onClicked: tipsPopup.open()
                            }
                            
                            Item { 
                                // Spacer
                                Layout.fillHeight: true 
                            }
                        }
                    }
                }

                WaveCard {
                    // title: "Transformer Visualization"
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    PowerTransformerVisualization {
                        anchors.fill: parent
                        anchors.margins: 5
                        
                        primaryVoltage: parseFloat(primaryVoltage.text || "0")
                        primaryCurrent: calculator.primaryCurrent || parseFloat(primaryCurrentInput.text || "0")
                        secondaryVoltage: parseFloat(secondaryVoltage.text || "0")
                        secondaryCurrent: calculator.secondaryCurrent
                        turnsRatio: calculator ? calculator.turnsRatio : 1
                        correctedRatio: calculator ? calculator.correctedRatio : 1
                        efficiency: calculator ? calculator.efficiency : 0
                        vectorGroup: calculator ? calculator.vectorGroup : "Dyn11"
                        
                        darkMode: Universal.theme === Universal.Dark
                        textColor: transformerCard.textColor
                    }
                }
            }
        }
    }

    Connections {
        target: calculator
        function onPrimaryCurrentChanged() {
        }
        function onSecondaryCurrentChanged() {
        }
        function onCorrectedRatioChanged() {
            console.log("Corrected ratio changed to:", calculator.correctedRatio)
        }
        function onVectorGroupChanged() {
            console.log("Vector group changed to:", calculator.vectorGroup)
        }
    }

    Popup {
        id: tipsPopup
        width: Math.min(parent.width * 0.8, 500)
        height: Math.min(parent.height * 0.8, 600)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        // Add background for the popup to capture mouse clicks
        Rectangle {
            anchors.fill: parent
            color: Universal.theme === Universal.Dark ? "#333333" : "#FFFFFF"
            border.color: Universal.accent
            border.width: 1
            
            // Add close button in top-right corner
            Button {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 5
                text: "✕"
                width: 30
                height: 30
                onClicked: tipsPopup.close()
                background: Rectangle {
                    color: "transparent"
                }
            }
        }
        
        ScrollView {
            anchors.fill: parent
            anchors.margins: 20
            clip: true
            
            ColumnLayout {
                width: tipsPopup.width - 40
                spacing: 15
                
                Label {
                    text: "Transformer Tips & Explanations"
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                }
                
                // Vector Group Section
                Label {
                    text: "Vector Group"
                    font.bold: true
                    font.pixelSize: 14
                    Layout.topMargin: 10
                }
                
                Label {
                    text: "• First letter: Primary connection (D = Delta, Y = Wye/Star)\n" +
                          "• Second letter: Secondary connection (d = Delta, y = Wye/Star, z = Zigzag)\n" +
                          "• Number: Phase shift in clock position (e.g., 11 = 330°, 1 = 30°)"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                
                // Impedance Section
                Label {
                    text: "Impedance"
                    font.bold: true
                    font.pixelSize: 14
                    Layout.topMargin: 10
                }
                
                Label {
                    text: "Impedance is affected by:"
                    font.bold: true
                }
                
                Label {
                    text: "• Winding resistance: copper losses, conductor size\n" +
                          "• Leakage flux: winding geometry, spacing\n" +
                          "• Core design: material, cross-section\n\n" +
                          "Higher Z%: ↑ mechanical strength, ↓ fault current, ↑ voltage drop"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "Finding R% on nameplate:"
                    font.bold: true
                    Layout.topMargin: 10
                }
                
                Label {
                    text: "• Listed as R%, resistance, or copper losses (W)\n" +
                          "• Can be calculated from Z% and X/R ratio\n" +
                          "• Or from copper losses: R% = (PCu × 100) / (kVA × 1000)"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                
                // Current and Voltage Section
                Label {
                    text: "Current & Voltage"
                    font.bold: true
                    font.pixelSize: 14
                    Layout.topMargin: 10
                }
                
                Label {
                    text: "• All voltages are 3-phase line-to-line values\n" +
                          "• Vector group affects both voltage ratio and current distribution\n" +
                          "• Delta: Line voltage = Phase voltage × √3\n" +
                          "• Wye: Line voltage = Phase voltage\n" +
                          "• For Dyn11, turns ratio is corrected by factor of √3"
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                
                Button {
                    text: "Close"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    onClicked: tipsPopup.close()
                }
                
                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
