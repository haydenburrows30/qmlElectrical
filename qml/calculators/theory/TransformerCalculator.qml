import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtQuick.Pdf

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import Transformer 1.0

Item {
    id: transformerCard

    property TransformerCalculator calculator: TransformerCalculator {}

    TransformerPopUp {id: tipsPopup}

    Popup {
        id: pdfPopup
        width: transformerCard.width - 50
        height: transformerCard.height - 50
        anchors.centerIn: Overlay.overlay
        modal: true

        ColumnLayout {
            anchors.fill: parent
            Button {
                action: Action {
                    onTriggered: view.renderScale *= 1.2
                }
                Layout.maximumHeight: 40
                Layout.fillWidth: true
                text: "Zoom In"
            }
            Button {
                action: Action {
                    onTriggered: view.renderScale *= 0.8
                }
                Layout.maximumHeight: 40
                Layout.fillWidth: true
                text: "Zoom Out"
            }

            PdfMultiPageView {
                id: view
                Layout.fillWidth: true
                Layout.fillHeight: true

                document: PdfDocument {          
                    source: "../../../assets/vector_groups.pdf"
                }
            }
        }
    }

    MessagePopup {
        id: messagePopup
        anchors.centerIn: parent
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            id: flickableContainer
            contentWidth: parent.width
            contentHeight: mainLayout.height + 20
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            ColumnLayout {
                id: mainLayout
                width: flickableContainer.width - 20

                // Header with title and help button
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 5
                    Layout.leftMargin: 5

                    Label {
                        text: "Transformer Calculator"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    // Add PDF export button
                    StyledButton {
                        ToolTip.text: "Export report to PDF"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        Layout.alignment: Qt.AlignRight
                        icon.source: "../../../icons/rounded/download.svg"

                        onClicked: {
                            if (calculator) {
                                calculator.exportReport()
                            }
                        }
                    }

                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Information"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: pdfPopup.open()
                    }
                }

                RowLayout {

                    ColumnLayout {
                        Layout.maximumWidth: 400

                        // Inputs
                        WaveCard {
                            title: "Transformer Rating"
                            Layout.minimumHeight: 180
                            Layout.fillWidth: true

                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                uniformCellWidths: true

                                Label {
                                    text: "KVA:"
                                    Layout.fillWidth: true
                                }
                                TextFieldRound {
                                    id: kvaInput
                                    placeholderText: "Enter KVA"
                                    Layout.fillWidth: true
                                    onTextChanged: {
                                        if (text) {
                                            calculator.setApparentPower(parseFloat(text));
                                        } else {
                                            calculator.setApparentPower(0);
                                        }
                                    }
                                }
                                
                                Label { text: "Vector Group:" ; Layout.fillWidth: true }
                                ComboBoxRound {
                                    id: vectorGroupCombo
                                    Layout.fillWidth: true
                                    model: ["Dyn11", "Yyn0", "Dyn1", "Yzn1", "Yd1", "Dd0", "Yy0", 
                                        "Zyn11", "Dzn0", "Zzn0", "Ynzn11"]
                                    onCurrentTextChanged: {
                                        calculator.setVectorGroup(currentText)
                                    }
                                    Component.onCompleted: {
                                        currentIndex = 0 // Default to Dyn11
                                    }
                                }

                                Label {
                                    text: calculator.vectorGroupDescription
                                    wrapMode: Text.WordWrap
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
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
                                anchors.fill: parent
                                uniformCellWidths: true

                                Label { 
                                    text: "Line Voltage (V):"
                                    Layout.fillWidth: true
                                }
                                TextFieldRound {
                                    id: primaryVoltage
                                    Layout.fillWidth: true
                                    placeholderText: "Enter line voltage"
                                    onTextChanged: {
                                        calculator.primaryVoltage = parseFloat(text || "0")
                                        if (kvaInput.text && text) {
                                            calculator.setApparentPower(parseFloat(kvaInput.text))
                                        }
                                    }
                                }

                                Label { text: "Current (A):" ; Layout.fillWidth: true}
                                    
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

                        // Secondary Side
                        WaveCard {
                            title: "Secondary Side"
                            Layout.minimumHeight: 150
                            Layout.fillWidth: true

                            GridLayout {
                                columns: 2
                                uniformCellWidths: true
                                anchors.fill: parent

                                Label { 
                                    text: "Line Voltage (V):"
                                    Layout.fillWidth: true
                                }
                                TextFieldRound {
                                    id: secondaryVoltage
                                    placeholderText: "Enter line voltage"
                                    onTextChanged: {
                                        var value = text ? parseFloat(text) : 0;
                                        calculator.secondaryVoltage = value;
                                        
                                        if (kvaInput.text && text) {
                                            calculator.setApparentPower(parseFloat(kvaInput.text));
                                        }
                                    }
                                    Layout.fillWidth: true
                                }

                                Label { text: "Current (A):" ; Layout.fillWidth: true }
                                TextFieldBlue {
                                    id: secondaryCurrent
                                    text: calculator.secondaryCurrent.toFixed(2)
                                    Layout.fillWidth: true
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
                                anchors.fill: parent
                                uniformCellWidths: true

                                Label { 
                                    text: "Impedance (%):" 
                                    Layout.fillWidth: true
                                }
                                TextFieldRound {
                                    id: impedanceInput
                                    placeholderText: "Enter impedance %"
                                    text: calculator.impedancePercent.toFixed(2)
                                    Layout.fillWidth: true
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

                                Label { text: "Cu Losses (W):" ; Layout.fillWidth: true}
                                TextFieldRound {
                                    id: copperLossesInput
                                    placeholderText: "Enter Cu losses"
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

                                Label { text: "Resistance (%):" ; Layout.fillWidth: true}
                                TextFieldRound {
                                    id: resistanceInput
                                    Layout.fillWidth: true
                                    placeholderText: "Enter resistance %"
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

                                Label { text: "Iron Losses (W):" ; Layout.fillWidth: true}
                                TextFieldRound {
                                    id: ironLossesInput
                                    placeholderText: "Enter Fe losses"
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

                                Label { text: "Reactance (%):" ; Layout.fillWidth: true}
                                TextFieldBlue {
                                    text: calculator.reactancePercent.toFixed(2)
                                    Layout.fillWidth: true
                                }

                                Label { text: "Short-circuit MVA:" ; Layout.fillWidth: true}
                                TextFieldBlue {
                                    text: calculator.shortCircuitPower.toFixed(2)
                                    Layout.fillWidth: true
                                }

                                Label { text: "Voltage Drop (%):" ;Layout.fillWidth: true}
                                    
                                TextFieldBlue {
                                    id: voltageDrop
                                    text: calculator.voltageDrop.toFixed(2)
                                    Layout.fillWidth: true
                                }

                                Label { text: "Temperature Rise:" ; Layout.fillWidth: true}
                                TextFieldBlue {
                                    text: calculator.temperatureRise.toFixed(1) + "°C"
                                    color: calculator.temperatureRise > 60 ? "#e81123" : Universal.foreground
                                    ToolTip.text: "Estimated temperature rise above ambient"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
                                    Layout.fillWidth: true
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
                            Layout.minimumHeight: 380
                            Layout.fillWidth: true
                            showSettings: true

                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                uniformCellWidths: true

                                Label { 
                                    text: "Turns Ratio:"
                                    Layout.fillWidth: true
                                }
                                TextFieldBlue {
                                    Layout.fillWidth: true
                                    text: calculator.turnsRatio.toFixed(1)
                                    ToolTip.text: "Turns ratio"
                                }
                                Label { 
                                    text: "Vector-corrected Ratio:"
                                    Layout.fillWidth: true
                                }
                                TextFieldBlue { 
                                    text: calculator.correctedRatio.toFixed(1)
                                    ToolTip.text: "Vector-corrected turns ratio"
                                    Layout.fillWidth: true
                                }
                                Label { 
                                    text: "Efficiency:"
                                    Layout.fillWidth: true
                                }
                                TextFieldBlue { 
                                    id: efficiencyField
                                    text: calculator.efficiency.toFixed(1) + "%"
                                    ToolTip.text: "Efficiency at rated load, considering copper and iron losses"
                                    Layout.fillWidth: true
                                    color: calculator.efficiency < 92 ? "#e81123" : Universal.foreground
                                }
                                Label {
                                    text: "Vector Group:"
                                    Layout.fillWidth: true
                                }
                                TextFieldBlue {
                                    text: calculator.vectorGroup
                                    ToolTip.text: "Vector Group"
                                    Layout.fillWidth: true
                                }
                                    
                                Label {
                                    text: "Common Applications:"
                                    font.bold: true
                                    color: Universal.accent
                                    Layout.fillWidth: true
                                }
                                
                                Repeater {
                                    model: calculator.vectorGroupApplications
                                    delegate: Label {
                                        text: "• " + modelData
                                        opacity: 0.9
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        Layout.columnSpan: 2
                                    }
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
    }

    Connections {
        target: calculator
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
        function onEfficiencyChanged() {
            efficiencyField.text = calculator.efficiency.toFixed(1) + "%"
        }
        function onCopperLossesChanged() {
            // Only update if the user is not editing
            if (!copperLossesInput.activeFocus) {
                copperLossesInput.text = calculator.copperLosses.toFixed(0)
            }
        }
        function onIronLossesChanged() {
            // Only update if the user is not editing
            if (!ironLossesInput.activeFocus) {
                ironLossesInput.text = calculator.ironLosses.toFixed(0)
            }
        }
        function onExportComplete(success, message) {
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
    }
}