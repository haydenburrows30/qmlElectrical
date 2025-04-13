import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal


import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"

import RefRgf 1.0

Item {
    id: calculator
    
    property RefRgfCalculator refCalculator: RefRgfCalculator {}
    property color textColor: Universal.foreground

    PopUpText {
        id: popUpText
        parentCard: topHeader
        popupText: "REF/RGF Calculator\n\n" +
                "The REF/RGF calculator is used to calculate the REF (Restricted Earth Fault) and RGF (Restricted Ground Fault) values based on transformer parameters and CT ratios. The calculator takes into account the transformer MVA, HV and LV voltages, connection type, impedance, CT phase and neutral ratios, and CT secondary type to calculate the REF and RGF values.\n\n" +
                "The REF/RGF values are used to set the protection relays in the power system to detect and isolate earth faults and ground faults in the system. The REF/RGF values are set based on the transformer parameters and CT ratios to ensure that the protection relays operate correctly and isolate the faulted section of the system.\n\n" +
                "The REF/RGF calculator helps you calculate the REF and RGF values based on the transformer parameters and CT ratios. Simply enter the transformer MVA, HV and LV voltages, connection type, impedance, CT phase and neutral ratios, and CT secondary type, and the calculator will provide you with the REF and RGF values needed to set the protection relays in the power system."
        widthFactor: 0.5
        heightFactor: 0.5
    }

    ColumnLayout {
        id: mainLayout
        anchors.centerIn: parent

        // Header with title and help button
        RowLayout {
            id: topHeader
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 5

            Label {
                text: "REF/RGF Calculator"
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            StyledButton {
                id: helpButton
                icon.source: "../../../icons/rounded/info.svg"
                ToolTip.text: "Help"
                onClicked: popUpText.open()
            }
        }

        RowLayout {

            WaveCard {
                id: results
                Layout.minimumWidth: 300
                Layout.minimumHeight: 540
                title: "Parameters"

                GridLayout {
                    id: ctTransformerGrid
                    columns: 2
                    Layout.alignment: Qt.AlignTop

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        Layout.bottomMargin: 10
                        height: 1
                        color: window.modeToggled ? "#404040" : "#e0e0e0"
                    }

                    Label { 
                        text: "Current Transformer" 
                        font.bold: true
                        Layout.columnSpan: 2
                    }
                    Label { 
                        text: "Phase Ratio:"
                        Layout.preferredWidth: 110
                        
                    }
                    TextFieldRound {
                        id: phCtRatio
                        placeholderText: "200"
                        text: "200"
                        Layout.preferredWidth: 140
                        onTextChanged: if(text) refCalculator.setPhCtRatio(parseFloat(text))
                    }
                    Label { 
                        text: "Neutral Ratio:"
                    }
                    TextFieldRound {
                        id: nCtRatio
                        placeholderText: "200"
                        text: "200"
                        Layout.fillWidth: true
                        onTextChanged: if(text) refCalculator.setNCtRatio(parseFloat(text))
                    }
                    Label { 
                        text: "CT Secondary:"
                    }
                    ComboBoxRound {
                        id: ctSecondaryType
                        model: ["5A", "1A"]
                        currentIndex: 0
                        onCurrentTextChanged: refCalculator.setCtSecondaryType(currentText)
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        Layout.margins: 10
                        height: 1
                        color: window.modeToggled ? "#404040" : "#e0e0e0"
                    }

                    Label { 
                        text: "Transformer" 
                        font.bold: true
                        Layout.columnSpan: 2
                    }

                    Label { 
                        text: "MVA:"
                        Layout.fillWidth: true
                        
                    }
                    TextFieldRound {
                        id: transformerMva
                        placeholderText: "2.5"
                        text: "2.5"
                        validator: DoubleValidator { bottom: 0.1; decimals: 2 }
                        Layout.fillWidth: true
                        onTextChanged: if(text) refCalculator.setTransformerMva(parseFloat(text))
                    }
                    
                    Label { 
                        text: "HV Voltage:"
                        
                    }
                    TextFieldRound {
                        id: hvtransformerVoltage
                        placeholderText: "55"
                        text: "55"
                        Layout.fillWidth: true
                        onTextChanged: if(text) refCalculator.setHvTransformerVoltage(parseFloat(text))
                    }

                    Label { 
                        text: "LV Voltage:"
                        
                    }
                    TextFieldRound {
                        id: lvTransformerVoltage
                        placeholderText: "11"
                        text: "11"
                        Layout.fillWidth: true
                        onTextChanged: if(text) refCalculator.setLvTransformerVoltage(parseFloat(text))
                    }
                    Label { 
                        text: "Connection:"
                        
                    }
                    ComboBoxRound {
                        id: connectionType
                        model: ["Wye", "Delta"]
                        currentIndex: 0
                        onCurrentTextChanged: refCalculator.setConnectionType(currentText)
                        Layout.fillWidth: true
                    }
                    Label { 
                        text: "Impedance (%):"
                        
                    }
                    TextFieldRound {
                        id: impedances
                        placeholderText: "5.5"
                        text: "5.5"
                        Layout.fillWidth: true
                        onTextChanged: if(text) refCalculator.setImpedance(parseFloat(text))
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        Layout.margins: 10
                        height: 1
                        color: window.modeToggled ? "#404040" : "#e0e0e0"
                    }

                    Label { 
                        text: "Fault Point"
                        font.bold: true
                        Layout.columnSpan: 2
                    }

                    Label { 
                        text: "Fault Point (%):"
                        
                    }
                    TextFieldRound {
                        id: faultPoint
                        placeholderText: "5.0"
                        text: "5.0"
                        Layout.fillWidth: true
                        onTextChanged: if(text) refCalculator.setFaultPoint(parseFloat(text))
                    }
                }
            }

            WaveCard {
                Layout.minimumWidth: 300
                Layout.minimumHeight: 300
                Layout.alignment: Qt.AlignTop
                title: "Results"

                GridLayout {
                    anchors.fill: parent
                    columns: 2

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        Layout.bottomMargin: 10
                        height: 1
                        color: window.modeToggled ? "#404040" : "#e0e0e0"
                    }

                    Label { text: "Load Current"}
                    TextFieldBlue { 
                        text: refCalculator.loadCurrent.toFixed(1)
                        }
                    Label { text: "Fault Current"}
                    TextFieldBlue { 
                        text: refCalculator.faultCurrent.toFixed(1)
                        
                    }
                    Label { text: "Fault Point"; }
                    TextFieldBlue { 
                        text: refCalculator.faultPointFive.toFixed(1)
                        
                    }
                    Label { text: "G Diff Pickup"; }
                    TextFieldBlue { 
                        text: refCalculator.gDiffPickup.toFixed(2)
                        
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        text: "REF (Restricted Earth Fault) and RGF (Restricted Ground Fault) values based on transformer parameters and CT ratios."
                        wrapMode: Text.WordWrap
                        font.pixelSize: 12
                        
                    }
                }
            }

        }
    }

    Connections {
        target: refCalculator
        function onCalculationsComplete() {
        }
    }

    Component.onCompleted: {
        refCalculator.calculate()
    }
}
