import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../components"
import RefRgf 1.0  // Import the namespace for our calculator

Item {
    id: calculator
    
    property RefRgfCalculator refCalculator: RefRgfCalculator {}
    property color textColor: Universal.foreground

    Popup {
        id: tipsPopup
        width: 600
        height: 500
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: results.open

        onAboutToHide: {
            results.open = false
        }
        Text {
            anchors.fill: parent
            text: {"REF/RGF Calculator\n\n" +
                "The REF/RGF calculator is used to calculate the REF (Restricted Earth Fault) and RGF (Restricted Ground Fault) values based on transformer parameters and CT ratios. The calculator takes into account the transformer MVA, HV and LV voltages, connection type, impedance, CT phase and neutral ratios, and CT secondary type to calculate the REF and RGF values.\n\n" +
                "The REF/RGF values are used to set the protection relays in the power system to detect and isolate earth faults and ground faults in the system. The REF/RGF values are set based on the transformer parameters and CT ratios to ensure that the protection relays operate correctly and isolate the faulted section of the system.\n\n" +
                "The REF/RGF calculator helps you calculate the REF and RGF values based on the transformer parameters and CT ratios. Simply enter the transformer MVA, HV and LV voltages, connection type, impedance, CT phase and neutral ratios, and CT secondary type, and the calculator will provide you with the REF and RGF values needed to set the protection relays in the power system."}
            wrapMode: Text.WordWrap
        }
    }

    Text {
        anchors.bottom: mainLayout.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: "REF/RGF Calculator"
        font.pixelSize: 24
        font.bold: true
        anchors.bottomMargin: 10
    }
    
    RowLayout {
        id: mainLayout
        anchors.margins: 10
        spacing: 10
        anchors.centerIn: parent

        WaveCard {
            id: results
            Layout.minimumWidth: 250
            Layout.minimumHeight: 540
            title: "Parameters"

            showSettings: true

            ColumnLayout{
                spacing: 10

                GridLayout {
                    id: ctTransformerGrid
                    columns: 2
                    Layout.alignment: Qt.AlignTop

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        Layout.bottomMargin: 10
                        height: 1
                        color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
                    }

                    Label { 
                        text: "Current Transformer" 
                        font.bold: true
                        Layout.columnSpan: 2
                    }
                    Text { 
                        text: "Phase Ratio:"
                        color: textColor
                    }
                    TextField {
                        id: phCtRatio
                        placeholderText: "200"
                        text: "200"
                        Layout.preferredWidth: 100
                        onTextChanged: if(text) refCalculator.setPhCtRatio(parseFloat(text))
                    }
                    Text { 
                        text: "Neutral Ratio:"
                        color: textColor
                    }
                    TextField {
                        id: nCtRatio
                        placeholderText: "200"
                        text: "200"
                        Layout.preferredWidth: 100
                        onTextChanged: if(text) refCalculator.setNCtRatio(parseFloat(text))
                    }
                    Text { 
                        text: "CT Secondary:"
                        color: textColor
                    }
                    ComboBox {
                        id: ctSecondaryType
                        model: ["5A", "1A"]
                        currentIndex: 0
                        onCurrentTextChanged: refCalculator.setCtSecondaryType(currentText)
                        Layout.preferredWidth: 100
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        Layout.margins: 10
                        height: 1
                        color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
                    }
                }

                GridLayout {
                    columns: 2
                    Layout.alignment: Qt.AlignTop
                
                    Label { 
                        text: "Transformer" 
                        font.bold: true
                        Layout.columnSpan: 2
                    }

                    Text { 
                        text: "MVA:"
                        color: textColor
                    }
                    TextField {
                        id: transformerMva
                        placeholderText: "2.5"
                        text: "2.5"
                        validator: DoubleValidator { bottom: 0.1; decimals: 2 }
                        Layout.preferredWidth: 100
                        onTextChanged: if(text) refCalculator.setTransformerMva(parseFloat(text))
                    }
                    
                    Text { 
                        text: "HV Voltage:"
                        color: textColor
                    }
                    TextField {
                        id: hvtransformerVoltage
                        placeholderText: "55"
                        text: "55"
                        Layout.preferredWidth: 100
                        onTextChanged: if(text) refCalculator.setHvTransformerVoltage(parseFloat(text))
                    }

                    Text { 
                        text: "LV Voltage:"
                        color: textColor
                    }
                    TextField {
                        id: lvTransformerVoltage
                        placeholderText: "11"
                        text: "11"
                        Layout.preferredWidth: 100
                        onTextChanged: if(text) refCalculator.setLvTransformerVoltage(parseFloat(text))
                    }
                    Text { 
                        text: "Connection:"
                        color: textColor
                    }
                    ComboBox {
                        id: connectionType
                        model: ["Wye", "Delta"]
                        currentIndex: 0
                        onCurrentTextChanged: refCalculator.setConnectionType(currentText)
                        Layout.preferredWidth: 100
                    }
                    Text { 
                        text: "Impedance (%):"
                        color: textColor
                    }
                    TextField {
                        id: impedances
                        placeholderText: "5.5"
                        text: "5.5"
                        Layout.preferredWidth: 100
                        onTextChanged: if(text) refCalculator.setImpedance(parseFloat(text))
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        Layout.margins: 10
                        height: 1
                        color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
                    }
                }

                GridLayout {
                    columns: 2
                    Layout.alignment: Qt.AlignTop

                    Label { 
                        text: "Fault Point"
                        font.bold: true
                        Layout.columnSpan: 2
                    }

                    Text { 
                        text: "Fault Point (%):"
                        color: textColor
                    }
                    TextField {
                        id: faultPoint
                        placeholderText: "5.0"
                        text: "5.0"
                        Layout.preferredWidth: 100
                        onTextChanged: if(text) refCalculator.setFaultPoint(parseFloat(text))
                    }
                }
            }
        }

        WaveCard {
            Layout.minimumWidth: 300
            Layout.minimumHeight: 230
            Layout.alignment: Qt.AlignTop
            title: "Results"

            GridLayout {
                anchors.fill: parent
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    Layout.bottomMargin: 10
                    height: 1
                    color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
                }

                Text { text: "Load Current"; color: textColor}
                Text { 
                    text: refCalculator.loadCurrent.toFixed(1)
                    font.bold: true
                    color: textColor
                    }
                Text { text: "Fault Current"; color: textColor}
                Text { 
                    text: refCalculator.faultCurrent.toFixed(1)
                    font.bold: true
                    color: textColor
                }
                Text { text: "Fault Point"; color: textColor}
                Text { 
                    text: refCalculator.faultPointFive.toFixed(1)
                    font.bold: true
                    color: textColor
                }
                Text { text: "G Diff Pickup"; color: textColor}
                Text { 
                    text: refCalculator.gDiffPickup.toFixed(2)
                    font.bold: true
                    color: textColor
                }
                Text {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    text: "REF (Restricted Earth Fault) and RGF (Restricted Ground Fault) values based on transformer parameters and CT ratios."
                    wrapMode: Text.WordWrap
                    font.pixelSize: 12
                    color: textColor
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
