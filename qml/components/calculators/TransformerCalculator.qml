import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import "../visualizers/"
import "../style"
import "../backgrounds"

import Transformer 1.0

Item {
    id: transformerCard

    property TransformerCalculator calculator: TransformerCalculator {}

    Popup {
        id: tipsPopup
        width: Math.min(parent.width * 0.8, 500)
        height: Math.min(parent.height * 0.8, 650)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: results.open

        onAboutToHide: {
            results.open = false
        }
            
        ColumnLayout {
            spacing: Style.spacing
            
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
        }
    }

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
                    Layout.maximumWidth: 300
                    spacing: Style.spacing
                    Layout.alignment: Qt.AlignTop

                    WaveCard {
                        title: "Transformer Rating"
                        Layout.minimumHeight: 120
                        Layout.fillWidth: true

                        GridLayout {
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 10
                            
                            Label {
                                text: "KVA:" 
                                Layout.minimumWidth: 120
                            }
                            TextField {
                                id: kvaInput
                                placeholderText: "Enter KVA"
                                Layout.minimumWidth: 150
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
                                Layout.minimumWidth: 150
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

                            Label { 
                                text: "Line Voltage (V):"
                                Layout.minimumWidth: 120
                            }
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
                        Layout.minimumHeight: 130
                        Layout.fillWidth: true

                        GridLayout {
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 10

                            Label { 
                                text: "Line Voltage (V):"
                                Layout.minimumWidth: 120
                            }
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
                            TextField {
                                id: secondaryCurrent
                                text: calculator.secondaryCurrent.toFixed(2)
                                Layout.fillWidth: true
                                readOnly: true
                                background: ProtectionRectangle {}
                            }
                        }
                    }

                    //Impedance
                    WaveCard {
                        title: "Impedance & Construction"
                        Layout.minimumHeight: 360
                        Layout.fillWidth: true

                        GridLayout {
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 10

                            Label { 
                                text: "Impedance (%):" 
                                Layout.minimumWidth: 120
                            }
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
                                // Add validator to allow decimal input
                                validator: DoubleValidator {
                                    bottom: 0.0
                                    decimals: 2
                                    notation: DoubleValidator.StandardNotation
                                }
                                // Add the same connection pattern for impedance as used for resistance
                                Component.onCompleted: {
                                    text = calculator.impedancePercent.toFixed(2)
                                }
                                
                                Connections {
                                    target: calculator
                                    function onImpedancePercentChanged() {
                                        // Only update if the user is not editing
                                        if (!impedanceInput.activeFocus) {
                                            impedanceInput.text = calculator.impedancePercent.toFixed(2)
                                        }
                                    }
                                }
                            }

                            Label { text: "Cu Losses (W):" }
                            TextField {
                                id: copperLossesInput
                                placeholderText: "Enter Cu losses"
                                Layout.minimumWidth: 150
                                Layout.fillWidth: true
                                onTextChanged: {
                                    if (text) {
                                        calculator.setCopperLosses(parseFloat(text))
                                    }
                                }
                                // Add validator to allow decimal input
                                validator: DoubleValidator {
                                    bottom: 0.0
                                    decimals: 1
                                    notation: DoubleValidator.StandardNotation
                                }
                            }

                            Label { text: "Resistance (%):" }
                            TextField {
                                id: resistanceInput
                                placeholderText: "Enter resistance %"
                                Layout.minimumWidth: 150
                                onTextChanged: {
                                    if (text) {
                                        calculator.setResistancePercent(parseFloat(text))
                                    }
                                }
                                // Add validator to allow decimal input
                                validator: DoubleValidator {
                                    bottom: 0.0
                                    decimals: 2
                                    notation: DoubleValidator.StandardNotation
                                }
                                Component.onCompleted: {
                                    text = calculator.resistancePercent.toFixed(2)
                                }
                                
                                Connections {
                                    target: calculator
                                    function onResistancePercentChanged() {
                                        // Only update if the user is not editing
                                        if (!resistanceInput.activeFocus) {
                                            resistanceInput.text = calculator.resistancePercent.toFixed(2)
                                        }
                                    }
                                }
                            }

                            Label { text: "Iron Losses (W):" }
                            TextField {
                                id: ironLossesInput
                                placeholderText: "Enter Fe losses"
                                Layout.minimumWidth: 150
                                Layout.fillWidth: true
                                onTextChanged: {
                                    if (text) {
                                        calculator.setIronLosses(parseFloat(text))
                                    }
                                }
                                ToolTip.text: "Core losses due to hysteresis and eddy currents"
                                ToolTip.visible: hovered
                                ToolTip.delay: 500
                            }

                            Label { text: "Reactance (%):" }
                            TextField {
                                text: calculator.reactancePercent.toFixed(2)
                                Layout.fillWidth: true
                                readOnly: true
                                background: ProtectionRectangle {}
                            }

                            Label { text: "Short-circuit MVA:" }
                            TextField {
                                text: calculator.shortCircuitPower.toFixed(2)
                                Layout.fillWidth: true
                                readOnly: true
                                background: ProtectionRectangle {}
                            }

                            Label { text: "Voltage Drop (%):" }
                                
                            TextField {
                                id: voltageDrop
                                text: calculator.voltageDrop.toFixed(2)
                                readOnly: true
                                Layout.fillWidth: true
                                background: ProtectionRectangle {}
                            }

                            Label { text: "Temperature Rise:" }
                            TextField {
                                text: calculator.temperatureRise.toFixed(1) + "°C"
                                color: calculator.temperatureRise > 60 ? Universal.error : Universal.foreground
                                ToolTip.text: "Estimated temperature rise above ambient"
                                ToolTip.visible: hovered
                                Layout.fillWidth: true
                                ToolTip.delay: 500
                                readOnly: true
                                background: ProtectionRectangle {}
                            }

                            // Add warnings section
                            Rectangle {
                                visible: calculator.warnings.length > 0
                                color: Universal.accent
                                opacity: 0.1
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                Layout.preferredHeight: warningColumn.height + 20

                                ColumnLayout {
                                    id: warningColumn
                                    width: parent.width
                                    anchors.centerIn: parent

                                    Repeater {
                                        model: calculator.warnings
                                        Label {
                                            text: "⚠️ " + modelData
                                            color: Universal.accent
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Results
                    WaveCard {
                        id: results
                        title: "Results"
                        Layout.minimumHeight: 220
                        Layout.fillWidth: true
                        showSettings: true

                        GridLayout {
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 10

                            Label { 
                                text: "Turns Ratio:"
                                Layout.minimumWidth: 120
                            }
                            Label { 
                                text: calculator.turnsRatio.toFixed(1)
                                color: Universal.foreground
                                Layout.minimumWidth: 150
                            }
                            Label { 
                                text: "Vector-corrected Ratio:"
                                color: Universal.foreground
                            }
                            Label { 
                                text: calculator.correctedRatio.toFixed(1)
                                color: Universal.foreground
                                font.italic: true
                            }
                            Label { 
                                text: "Efficiency:"
                                color: Universal.foreground
                            }
                            Label { 
                                text: calculator.efficiency.toFixed(0) + "%"
                                color: Universal.foreground
                            }
                            Label {
                                text: "Vector Group:"
                                color: Universal.foreground
                            }
                            Label {
                                text: calculator.vectorGroup
                                color: Universal.foreground
                            }
                            Label {
                                text: calculator.vectorGroupDescription
                                color: Universal.foreground
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                Layout.columnSpan: 2
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
                                Layout.columnSpan: 2
                            }
                        }
                    }
                }

                WaveCard {
                    title: "Transformer Visualization"
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
}