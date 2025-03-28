import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import "../style"
import "../backgrounds"
import "../visualizers"

import Battery 1.0

Item {
    id: batteryCalculator

    property BatteryCalculator calculator: BatteryCalculator {}

    Popup {
        id: tipsPopup
        width: 500
        height: 400
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
            text: { "<h3>Battery Calculator</h3><br>" +
                    "This calculator estimates the battery capacity required for a given load and backup time.<br><br>" +
                    "<b>Load:</b> The power consumption in watts.<br>" +
                    "<b>System Voltage:</b> The voltage of the battery system.<br>" +
                    "<b>Backup Time:</b> The duration for which the battery should provide power.<br>" +
                    "<b>Depth of Discharge:</b> The percentage of battery capacity that can be used.<br>" +
                    "<b>Battery Type:</b> The type of battery used.<br><br>" +
                    "The calculator estimates the current draw, required capacity, recommended capacity, and energy storage.<br>" +
                    "The battery visualization shows the depth of discharge and recommended capacity." }
            wrapMode: Text.WordWrap
        }
    }
        
    RowLayout {
        anchors.centerIn: parent
        spacing: Style.spacing

        ColumnLayout {
            id: inputLayout
            Layout.preferredWidth: 410
            Layout.alignment: Qt.AlignTop
            spacing: Style.spacing

            //Inputs
            WaveCard {
                id: results
                title: "System Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 280

                showSettings: true
                    
                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    
                    Label { text: "Load (watts):" }
                    TextField {
                        id: loadInput
                        placeholderText: "Enter load"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.load = parseFloat(text)
                        Layout.fillWidth: true
                        Layout.minimumWidth: 180
                    }

                    Label { text: "System Voltage (V):" }
                    ComboBox {
                        id: systemVoltageCombo
                        model: [12, 24, 48]
                        onCurrentTextChanged: calculator.systemVoltage = parseInt(currentText)
                        Layout.fillWidth: true
                    }
                    
                    Label { text: "Backup Time (hours):" }
                    TextField {
                        id: backupTimeInput
                        placeholderText: "Enter hours"
                        text: "4"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) calculator.backupTime = parseFloat(text)
                        Layout.fillWidth: true
                    }
                    
                    Label { text: "Depth of Discharge (%):" }

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Slider {
                            id: dodSlider
                            from: 30
                            to: 80
                            value: 50
                            stepSize: 5
                            onValueChanged: calculator.depthOfDischarge = value
                            Layout.maximumWidth: 150
                        }

                        Label { 
                            text: dodSlider.value + "%" 
                            Layout.alignment: Qt.AlignRight
                            Layout.minimumWidth: 50
                            Layout.fillWidth: true
                        }
                    }
                    
                    Label { text: "Battery Type:" }
                    ComboBox {
                        id: batteryType
                        model: ["Lead Acid", "Lithium Ion", "AGM"]
                        onCurrentTextChanged: calculator.batteryType = currentText
                        Layout.fillWidth: true
                    }
                }
            }
            // Results
            WaveCard {
                Layout.minimumHeight: 220
                title: "Results"
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    Layout.fillWidth: true

                    Label { text: "Current Draw:" }
                    TextField { 
                        text: calculator.currentDraw.toFixed(2) + " A"
                        background: ProtectionRectangle {}
                        Layout.fillWidth: true
                        Layout.minimumWidth: 180
                        readOnly: true
                    }

                    Label { text: "Required Capacity:" }
                    TextField { 
                        text: calculator.requiredCapacity.toFixed(1) + " Ah"
                        background: ProtectionRectangle {}
                        Layout.fillWidth: true
                        readOnly: true
                    }
                    
                    Label { text: "Recommended Capacity:" }
                    TextField { 
                        text: calculator.recommendedCapacity.toFixed(1) + " Ah"
                        font.bold: true 
                        color: Universal.theme === Universal.Dark ? "#90EE90" : "green"
                        background: ProtectionRectangle {}
                        Layout.fillWidth: true
                        readOnly: true
                    }
                    
                    Label { text: "Energy Storage:" }
                    TextField { 
                        text: calculator.energyStorage.toFixed(2) + " kWh"
                        background: ProtectionRectangle {}
                        Layout.fillWidth: true
                        readOnly: true
                    }
                }
            }
        }
        WaveCard {
            Layout.minimumHeight: inputLayout.height
            Layout.minimumWidth: 400

            Canvas { 
                anchors.fill: parent
                BatteryViz {id: batteryVizCanvas} 
            }
        }
    }
    
    Connections {
        target: calculator
        function onDepthOfDischargeChanged() { batteryVizCanvas.requestPaint() }
        function onRecommendedCapacityChanged() { batteryVizCanvas.requestPaint() }
    }
}
