import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"
import "../../components"
import "../style"
import "../visualizers"
import "../popups"

import Battery 1.0

Item {
    id: batteryCalculator

    property BatteryCalculator calculator: BatteryCalculator {}

    PopUpText {
        parentCard: results
        popupText: "<h3>Battery Calculator</h3><br>" +
                "This calculator estimates the battery capacity required for a given load and backup time.<br><br>" +
                "<b>Load:</b> The power consumption in watts.<br>" +
                "<b>System Voltage:</b> The voltage of the battery system.<br>" +
                "<b>Backup Time:</b> The duration for which the battery should provide power.<br>" +
                "<b>Depth of Discharge:</b> The percentage of battery capacity that can be used.<br>" +
                "<b>Battery Type:</b> The type of battery used.<br><br>" +
                "The calculator estimates the current draw, required capacity, recommended capacity, and energy storage.<br>" +
                "The battery visualization shows the depth of discharge and recommended capacity."
    }
        
    RowLayout {
        anchors.centerIn: parent

        ColumnLayout {
            id: inputLayout
            Layout.preferredWidth: 410
            Layout.alignment: Qt.AlignTop

            //Inputs
            WaveCard {
                id: results
                title: "System Parameters"
                Layout.fillWidth: true
                Layout.minimumHeight: 260

                showSettings: true
                    
                GridLayout {
                    columns: 2
                    
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
                Layout.minimumHeight: 210
                title: "Results"
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    Layout.fillWidth: true

                    Label { text: "Current Draw:" }
                    TextFieldBlue { 
                        text: calculator.currentDraw.toFixed(2) + " A"
                        Layout.minimumWidth: 180
                    }

                    Label { text: "Required Capacity:" }
                    TextFieldBlue { 
                        text: calculator.requiredCapacity.toFixed(1) + " Ah"
                    }
                    
                    Label { text: "Recommended Capacity:" }
                    TextFieldBlue { 
                        text: calculator.recommendedCapacity.toFixed(1) + " Ah"
                        color: Universal.theme === Universal.Dark ? "#90EE90" : "green"
                    }
                    
                    Label { text: "Energy Storage:" }
                    TextFieldBlue { 
                        text: calculator.energyStorage.toFixed(2) + " kWh"
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
