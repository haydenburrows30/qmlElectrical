import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RefRgf 1.0  // Import the namespace for our calculator

Item {
    id: calculator
    
    property RefRgfCalculator refCalculator: RefRgfCalculator {}
    property bool darkMode: false
    property color textColor: darkMode ? "#FFFFFF" : "#000000"
    property color inputBgColor: darkMode ? "#3a3a3a" : "#FFFFFF"
    property color borderColor: darkMode ? "#555555" : "#CCCCCC"
    property color resultColor: darkMode ? "#90EE90" : "#006400"

            
    Text {
        anchors.bottom: mainLayout.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: "REF/RGF Calculator"
        font.pixelSize: 24
        font.bold: true
        color: textColor
        anchors.bottomMargin: 10
    }
    
    RowLayout {
        id: mainLayout
        anchors.margins: 10
        spacing: 10
        anchors.centerIn: parent

        WaveCard {
            Layout.minimumWidth: 250
            Layout.minimumHeight: 450
            title: "Parameters"

            ColumnLayout{
                spacing: 10

                GridLayout {
                    id: ctTransformerGrid
                    columns: 2
                    Layout.alignment: Qt.AlignTop

                    Label { 
                        text: "Current Transformer" 
                        color: textColor
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
                        color: textColor
                        background: Rectangle { color: inputBgColor; border.color: borderColor }
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
                        color: textColor
                        background: Rectangle { color: inputBgColor; border.color: borderColor }
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
                }

                GridLayout {
                    columns: 2
                    Layout.alignment: Qt.AlignTop
                
                    Label { 
                        text: "Transformer" 
                        color: textColor
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
                        color: textColor
                        background: Rectangle { color: inputBgColor; border.color: borderColor }
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
                        color: textColor
                        background: Rectangle { color: inputBgColor; border.color: borderColor }
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
                        color: textColor
                        background: Rectangle { color: inputBgColor; border.color: borderColor }
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
                        color: textColor
                        background: Rectangle { color: inputBgColor; border.color: borderColor }
                        Layout.preferredWidth: 100
                        onTextChanged: if(text) refCalculator.setImpedance(parseFloat(text))
                    }
                }

                GridLayout {
                    columns: 2
                    Layout.alignment: Qt.AlignTop

                    Label { 
                        text: "Fault Point" 
                        color: textColor
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
                        color: textColor
                        background: Rectangle { color: inputBgColor; border.color: borderColor }
                        Layout.preferredWidth: 100
                        onTextChanged: if(text) refCalculator.setFaultPoint(parseFloat(text))
                    }
                }
            }
        }

        WaveCard {
            Layout.minimumWidth: 300
            Layout.minimumHeight: 200
            Layout.alignment: Qt.AlignTop
            title: "Results"

            GridLayout {
                anchors.fill: parent
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                Text { text: "Load Current"; color: textColor }
                Text { 
                    text: refCalculator.loadCurrent.toFixed(1)
                    color: resultColor 
                    font.bold: true
                    }
                Text { text: "Fault Current"; color: textColor }
                Text { 
                    text: refCalculator.faultCurrent.toFixed(1)
                    color: resultColor 
                    font.bold: true
                }
                Text { text: "Fault Point"; color: textColor }
                Text { 
                    text: refCalculator.faultPointFive.toFixed(1)
                    color: resultColor 
                    font.bold: true
                }
                Text { text: "G Diff Pickup"; color: textColor }
                Text { 
                    text: refCalculator.gDiffPickup.toFixed(2)
                    color: resultColor 
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    text: "REF (Restricted Earth Fault) and RGF (Restricted Ground Fault) values based on transformer parameters and CT ratios."
                    wrapMode: Text.WordWrap
                    color: textColor
                    font.pixelSize: 12
                }
            }
        }

    }

    Connections {
        target: refCalculator
        function onCalculationsComplete() {
            console.log("Calculations completed")
        }
    }

    Component.onCompleted: {
        refCalculator.calculate()
    }
}
