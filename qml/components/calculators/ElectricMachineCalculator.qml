import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import Machine 1.0

Item {
    id: machineCard
    // title: 'Electric Machine Calculator'

    property MachineCalculator calculator: MachineCalculator {}
    property color textColor: Universal.foreground
    property int waveHeight: 200

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 15

        // Left side - Controls and Results
        ColumnLayout {
            Layout.maximumWidth: 300
            Layout.alignment: Qt.AlignTop
            spacing: 10

            // Machine Type Selection
            WaveCard {
                title: "Machine Selection"
                Layout.fillWidth: true
                Layout.minimumHeight: 90
                
                ColumnLayout {
                    spacing: 10
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
                Layout.minimumHeight: waveHeight

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

                    Label { text: "Rated Voltage (V):"; Layout.minimumWidth: 130}
                    TextField {
                        id: ratedVoltageInput
                        placeholderText: "Enter voltage"
                        text: "400"
                        onTextChanged: if(text) calculator.setRatedVoltage(parseFloat(text))
                        Layout.minimumWidth: 130
                    }

                    Label { text: "Rated Current (A):" }
                    TextField {
                        id: ratedCurrentInput
                        placeholderText: "Enter current"
                        text: "10"
                        onTextChanged: if(text) calculator.setRatedCurrent(parseFloat(text))
                        Layout.fillWidth: true
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
                Layout.minimumHeight: 200

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
