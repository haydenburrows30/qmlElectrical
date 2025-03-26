import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../visualizers/"
import "../style"
import "../backgrounds"

import Machine 1.0

Item {
    id: machineCard
    // title: 'Electric Machine Calculator'

    property MachineCalculator calculator: MachineCalculator {}
    property color textColor: Universal.foreground
    property int waveHeight: 300

    Popup {
        id: tipsPopup
        width: parent.width * 0.8
        height: parent.height * 0.8
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: results.open

        onAboutToHide: {
            results.open = false
        }
        ScrollView {
            width: parent.width
            height: parent.height
            
            Text {
                anchors.fill: parent
                text: {"<h3>Electric Machine Calculator</h3><br>" +
                    "This calculator is used to estimate the electrical and mechanical parameters of an electric machine.<br><br>" +
                    "<b>Machine Selection:</b><br>" +
                    "Select the type of machine from the drop-down list.<br><br>" +
                    "<b>Electrical Parameters:</b><br>" +
                    "Select the input mode (V I or V kW) and enter the rated voltage, current, power, power factor, and efficiency.<br><br>" +
                    "<b>Mechanical Parameters:</b><br>" +
                    "Enter the number of poles, frequency, speed, and slip.<br><br>" +
                    "<b>Thermal Parameters:</b><br>" +
                    "Select the temperature class and cooling method.<br><br>" +
                    "<b>Results:</b><br>" +
                    "The calculator will display the rated power, power with derating, torque, losses, and efficiency.<br><br>" +
                    "<b>Visualization:</b><br>" +
                    "The right side of the calculator displays a visualization of the electric machine based on the input parameters.<br>" +
                    "Note: The calculator is for estimation purposes only and may not be accurate for all scenarios."}
                wrapMode: Text.WordWrap
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

                // Left side - Controls and Results
                ColumnLayout {
                    Layout.maximumWidth: 300
                    Layout.alignment: Qt.AlignTop
                    spacing: Style.spacing

                    // Machine Type Selection
                    WaveCard {
                        id: results
                        title: "Machine Selection"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 90

                        showSettings: true
                        
                        ColumnLayout {
                            spacing: Style.spacing
                            ComboBox {
                                id: machineTypeCombo
                                model: calculator.machineTypes
                                onCurrentTextChanged: calculator.setMachineType(currentText)
                                Layout.minimumWidth: 270
                            }
                        }
                    }

                    // Electrical Parameters
                    WaveCard {
                        title: "Electrical Parameters"
                        Layout.fillWidth: true
                        Layout.minimumHeight: waveHeight  // Increased height for the radio buttons

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 5
                            
                            // Input Mode Selection
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 5
                                Layout.leftMargin: 10
                                spacing: Style.spacing

                                RadioButton {
                                    id: vcModeRadio
                                    text: "V I"
                                    checked: true
                                    onCheckedChanged: {
                                        if (checked) {
                                            calculator.setInputMode("VC")
                                            ratedPowerInput.enabled = false
                                            ratedCurrentInput.enabled = true
                                        }
                                    }
                                    Layout.maximumWidth: 150
                                }
                                
                                RadioButton {
                                    id: vpModeRadio
                                    text: "V kW"
                                    onCheckedChanged: {
                                        if (checked) {
                                            calculator.setInputMode("VP")
                                            ratedPowerInput.enabled = true
                                            ratedCurrentInput.enabled = false
                                        }
                                    }
                                    Layout.maximumWidth: 150
                                }
                            }
                            
                            // Parameters Grid
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 10
                                columnSpacing: 15
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10

                                Label { text: "Rated Voltage (V):"; Layout.minimumWidth: 130}
                                TextField {
                                    id: ratedVoltageInput
                                    placeholderText: "Enter voltage"
                                    text: "400"
                                    onTextChanged: if(text) calculator.setRatedVoltage(parseFloat(text))
                                    Layout.minimumWidth: 120
                                    validator: DoubleValidator { bottom: 0.1; decimals: 2 }
                                }

                                Label { text: "Rated Current (A):" }
                                TextField {
                                    id: ratedCurrentInput
                                    placeholderText: "Enter current"
                                    text: "10"
                                    onTextChanged: if(text) calculator.setRatedCurrent(parseFloat(text))
                                    Layout.fillWidth: true
                                    validator: DoubleValidator { bottom: 0.1; decimals: 2 }
                                    // Current will be calculated in VP mode
                                }

                                Label { text: "Rated Power (kW):" }
                                TextField {
                                    id: ratedPowerInput
                                    placeholderText: "Enter power"
                                    text: calculator.ratedPower.toFixed(2)
                                    enabled: false  // Initially disabled in VC mode
                                    onTextChanged: if(text && enabled) calculator.setRatedPower(parseFloat(text))
                                    Layout.fillWidth: true
                                    validator: DoubleValidator { bottom: 0.1; decimals: 2 }
                                }
                                
                                // Bind the text to the calculator values for the calculated fields
                                Connections {
                                    target: calculator
                                    function onRatedPowerChanged() {
                                        if (!ratedPowerInput.enabled) {
                                            ratedPowerInput.text = calculator.ratedPower.toFixed(2)
                                        }
                                    }
                                    function onRatedCurrentChanged() {
                                        if (!ratedCurrentInput.enabled) {
                                            ratedCurrentInput.text = calculator.ratedCurrent.toFixed(2)
                                        }
                                    }
                                }

                                Label { text: "Power Factor:" }
                                TextField {
                                    id: powerFactorInput
                                    placeholderText: "Enter PF"
                                    text: "0.85"
                                    enabled: !machineTypeCombo.currentText.includes("DC")
                                    onTextChanged: if(text) calculator.setPowerFactor(parseFloat(text))
                                    Layout.fillWidth: true
                                }

                                Label { text: "Efficiency (%):" }
                                TextField {
                                    id: efficiencyInput
                                    placeholderText: "Enter efficiency"
                                    text: "90"
                                    onTextChanged: if(text) calculator.setEfficiency(parseFloat(text) / 100)
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    // Mechanical Parameters
                    WaveCard {
                        title: "Mechanical Parameters"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 170

                        GridLayout {
                            id: mechanicalParamsGrid
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 15

                            Label { text: "Number of Poles:" ; Layout.minimumWidth: 130}
                            SpinBox {
                                id: polesSpinBox
                                from: 2
                                to: 12
                                value: 4
                                stepSize: 2
                                enabled: !machineTypeCombo.currentText.includes("DC")
                                onValueChanged: calculator.setPoles(value)
                                Layout.minimumWidth: 130
                            }

                            Label { text: "Frequency (Hz):" }
                            TextField {
                                id: frequencyInput
                                text: "50"
                                enabled: !machineTypeCombo.currentText.includes("DC")
                                onTextChanged: if(text) calculator.setFrequency(parseFloat(text))
                                Layout.fillWidth: true
                            }

                            Label { text: machineTypeCombo.currentText === "Induction Motor" ? "Slip (%):" : "Speed (RPM):" }
                            TextField {
                                id: speedInput
                                text: machineTypeCombo.currentText === "Induction Motor" ? "3.3" : "1500"
                                Layout.fillWidth: true
                                onTextChanged: {
                                    if(!text) return
                                    if(machineTypeCombo.currentText === "Induction Motor") {
                                        calculator.setSlip(parseFloat(text) / 100)
                                    } else {
                                        calculator.setRotationalSpeed(parseFloat(text))
                                    }
                                }
                            }
                        }
                    }

                    // Thermal Parameters
                    WaveCard {
                        title: "Thermal Parameters"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 160

                        GridLayout {
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 15

                            Label { text: "Temperature Class:" ; Layout.minimumWidth: 130}
                            ComboBox {
                                id: tempClassCombo
                                model: calculator.temperatureClasses
                                onCurrentTextChanged: if(currentText) calculator.setTemperatureClass(currentText)
                                Layout.minimumWidth: 130
                            }

                            Label { text: "Cooling Method:" }
                            ComboBox {
                                id: coolingMethodCombo
                                model: calculator.coolingMethods
                                onCurrentTextChanged: if(currentText) calculator.setCoolingMethod(currentText)
                                Layout.fillWidth: true
                            }

                            Label { text: "Temperature Rise:" }
                            Label {
                                text: calculator.temperatureRise.toFixed(1) + " °C"
                                Layout.fillWidth: true
                                color: calculator.temperatureRise > 80 ? 
                                    Universal.theme === Universal.Dark ? "#FF8080" : "red" :
                                    Universal.foreground
                            }
                        }
                    }

                    // Results Section
                    WaveCard {
                        title: "Results"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 220

                        GridLayout {
                            columns: 2
                            rowSpacing: 15
                            columnSpacing: 10

                            Label { text: "Rated Power:" }
                            Label { 
                                text: calculator.ratedPower.toFixed(2) + " kW"
                                color: Universal.foreground
                                Layout.fillWidth: true
                                Layout.minimumWidth: 100
                            }
                            
                            Label { text: "Power with Derating:" }
                            Label { 
                                text: (calculator.ratedPower * calculator.efficiency).toFixed(2) + " kW"
                                Layout.minimumWidth: 100
                                Layout.fillWidth: true
                                color: calculator.temperatureRise > 80 ? 
                                    Universal.theme === Universal.Dark ? "#FF8080" : "red" :
                                    Universal.foreground
                            }

                            Label { text: "Torque:" }
                            Label { 
                                text: calculator.torque.toFixed(2) + " N·m"
                                Layout.minimumWidth: 100
                                Layout.fillWidth: true
                                color: Universal.foreground
                            }

                            Label { text: "Losses:" }
                            Label { 
                                text: calculator.losses.toFixed(2) + " kW"
                                Layout.minimumWidth: 100
                                Layout.fillWidth: true
                                color: Universal.theme === Universal.Dark ? "#FF8080" : "red"
                            }

                            Label { text: "Efficiency:" }
                            Label { 
                                text: (calculator.efficiency * 100).toFixed(1) + "%"
                                Layout.minimumWidth: 100
                                Layout.fillWidth: true
                                color: Universal.theme === Universal.Dark ? "#90EE90" : "green"
                            }
                        }
                    }
                }

                // Right side - Visualization
                WaveCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ElectricMachineViz {
                        anchors.fill: parent
                        anchors.margins: 5
                        
                        machineType: machineTypeCombo.currentText
                        ratedPower: calculator.ratedPower
                        efficiency: calculator.efficiency
                        losses: calculator.losses
                        speedRPM: calculator.rotationalSpeed
                        torque: calculator.torque
                        slip: calculator.slip
                        temperatureRise: calculator.temperatureRise  // Add this binding
                        
                        darkMode: Universal.theme === Universal.Dark
                        textColor: machineCard.textColor
                    }
                }
            }
        }
    }
}
