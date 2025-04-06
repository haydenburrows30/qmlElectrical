import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"
import "../visualizers/"
import "../style"
import "../popups"

import Transformer 1.0

Item {
    id: transformerCard

    property TransformerCalculator calculator: TransformerCalculator {}

    TransformerPopUp {id: tipsPopup}

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
                    Layout.maximumWidth: 330

                    // Inputs
                    WaveCard {
                        title: "Transformer Rating"
                        Layout.minimumHeight: 140
                        Layout.fillWidth: true

                        GridLayout {
                            columns: 2

                            Label {
                                text: "KVA:" 
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
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
                        Layout.minimumHeight: 140
                        Layout.fillWidth: true

                        GridLayout {
                            columns: 2

                            Label { 
                                text: "Line Voltage (V):"
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
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
                                
                                TextFieldRound {
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
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    // Secondary Side
                    WaveCard {
                        title: "Secondary Side"
                        Layout.minimumHeight: 150
                        Layout.fillWidth: true

                        GridLayout {
                            columns: 2

                            Label { 
                                text: "Line Voltage (V):"
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
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
                            TextFieldBlue {
                                id: secondaryCurrent
                                text: calculator.secondaryCurrent.toFixed(2)
                            }
                        }
                    }

                    //Impedance
                    WaveCard {
                        title: "Impedance & Construction"
                        Layout.minimumHeight: 350
                        Layout.fillWidth: true

                        GridLayout {
                            columns: 2

                            Label { 
                                text: "Impedance (%):" 
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
                                id: impedanceInput
                                placeholderText: "Enter impedance %"
                                text: calculator.impedancePercent.toFixed(2)
                                Layout.minimumWidth: 150
                                onTextChanged: {
                                    if (text) {
                                        calculator.setImpedancePercent(parseFloat(text))
                                    }
                                }

                                validator: DoubleValidator {
                                    bottom: 0.0
                                    decimals: 2
                                    notation: DoubleValidator.StandardNotation
                                }

                                Component.onCompleted: {
                                    text = calculator.impedancePercent.toFixed(2)
                                }
                            }

                            Label { text: "Cu Losses (W):" }
                            TextFieldRound {
                                id: copperLossesInput
                                placeholderText: "Enter Cu losses"
                                Layout.minimumWidth: 150
                                Layout.fillWidth: true
                                onTextChanged: {
                                    if (text) {
                                        calculator.setCopperLosses(parseFloat(text))
                                    }
                                }
                                validator: DoubleValidator {
                                    bottom: 0.0
                                    decimals: 1
                                    notation: DoubleValidator.StandardNotation
                                }
                            }

                            Label { text: "Resistance (%):" }
                            TextFieldRound {
                                id: resistanceInput
                                placeholderText: "Enter resistance %"
                                Layout.minimumWidth: 150
                                onTextChanged: {
                                    if (text) {
                                        calculator.setResistancePercent(parseFloat(text))
                                    }
                                }
                                validator: DoubleValidator {
                                    bottom: 0.0
                                    decimals: 2
                                    notation: DoubleValidator.StandardNotation
                                }
                                Component.onCompleted: {
                                    text = calculator.resistancePercent.toFixed(2)
                                }
                            }

                            Label { text: "Iron Losses (W):" }
                            TextFieldRound {
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
                            TextFieldBlue {
                                text: calculator.reactancePercent.toFixed(2)
                            }

                            Label { text: "Short-circuit MVA:" }
                            TextFieldBlue {
                                text: calculator.shortCircuitPower.toFixed(2)
                            }

                            Label { text: "Voltage Drop (%):" }
                                
                            TextFieldBlue {
                                id: voltageDrop
                                text: calculator.voltageDrop.toFixed(2)
                            }

                            Label { text: "Temperature Rise:" }
                            TextFieldBlue {
                                text: calculator.temperatureRise.toFixed(1) + "°C"
                                color: calculator.temperatureRise > 60 ? Universal.error : Universal.foreground
                                ToolTip.text: "Estimated temperature rise above ambient"
                                ToolTip.visible: hovered
                                ToolTip.delay: 500
                            }

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
                        Layout.minimumHeight: 260
                        Layout.fillWidth: true
                        showSettings: true

                        GridLayout {
                            columns: 2

                            Label { 
                                text: "Turns Ratio:"
                                Layout.minimumWidth: 120
                            }
                            TextFieldBlue {
                                Layout.minimumWidth: 120
                                text: calculator.turnsRatio.toFixed(1)
                                ToolTip.text: "Turns ratio"
                            }
                            Label { 
                                text: "Vector-corrected Ratio:"
                            }
                            TextFieldBlue { 
                                text: calculator.correctedRatio.toFixed(1)
                                ToolTip.text: "Vector-corrected turns ratio"
                            }
                            Label { 
                                text: "Efficiency:"
                            }
                            TextFieldBlue { 
                                text: calculator.efficiency.toFixed(0) + "%"
                                ToolTip.text: "Efficiency"
                            }
                            Label {
                                text: "Vector Group:"
                            }
                            TextFieldBlue {
                                text: calculator.vectorGroup
                                ToolTip.text: "Vector Group"
                            }
                            Label {
                                text: calculator.vectorGroupDescription
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
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
        function onImpedancePercentChanged() {
            // Only update if the user is not editing
            if (!impedanceInput.activeFocus) {
                impedanceInput.text = calculator.impedancePercent.toFixed(2)
            }
        }
        function onResistancePercentChanged() {
            // Only update if the user is not editing
            if (!resistanceInput.activeFocus) {
                resistanceInput.text = calculator.resistancePercent.toFixed(2)
            }
        }
    }
}