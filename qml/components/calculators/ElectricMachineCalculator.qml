import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import Machine 1.0

WaveCard {
    id: machineCard
    title: 'Electric Machine Calculator'

    property MachineCalculator calculator: MachineCalculator {}
    property color textColor: Universal.foreground

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 15

        // Left side - Controls and Results
        ColumnLayout {
            Layout.preferredWidth: 350
            spacing: 10

            // Machine Type Selection
            GroupBox {
                title: "Machine Selection"
                
                ColumnLayout {
                    spacing: 10
                    ComboBox {
                        id: machineTypeCombo
                        model: calculator.machineTypes
                        onCurrentTextChanged: calculator.setMachineType(currentText)
                    }
                }
            }

            // Electrical Parameters
            GroupBox {
                title: "Electrical Parameters"

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15
                    Layout.fillWidth: true

                    Label { text: "Rated Voltage (V):" }
                    TextField {
                        id: ratedVoltageInput
                        placeholderText: "Enter voltage"
                        text: "400"
                        onTextChanged: if(text) calculator.setRatedVoltage(parseFloat(text))
                    }

                    Label { text: "Rated Current (A):" }
                    TextField {
                        id: ratedCurrentInput
                        placeholderText: "Enter current"
                        text: "10"
                        onTextChanged: if(text) calculator.setRatedCurrent(parseFloat(text))
                    }

                    Label { text: "Power Factor:" }
                    TextField {
                        id: powerFactorInput
                        placeholderText: "Enter PF"
                        text: "0.85"
                        enabled: !machineTypeCombo.currentText.includes("DC")
                        onTextChanged: if(text) calculator.setPowerFactor(parseFloat(text))
                    }

                    Label { text: "Efficiency (%):" }
                    TextField {
                        id: efficiencyInput
                        placeholderText: "Enter efficiency"
                        text: "90"
                        onTextChanged: if(text) calculator.setEfficiency(parseFloat(text) / 100)
                    }
                }
            }

            // Mechanical Parameters
            GroupBox {
                title: "Mechanical Parameters"

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 15

                    Label { text: "Number of Poles:" }
                    SpinBox {
                        id: polesSpinBox
                        from: 2
                        to: 12
                        value: 4
                        stepSize: 2
                        enabled: !machineTypeCombo.currentText.includes("DC")
                        onValueChanged: calculator.setPoles(value)
                    }

                    Label { text: "Frequency (Hz):" }
                    TextField {
                        id: frequencyInput
                        text: "50"
                        enabled: !machineTypeCombo.currentText.includes("DC")
                        onTextChanged: if(text) calculator.setFrequency(parseFloat(text))
                    }

                    Label { text: machineTypeCombo.currentText === "Induction Motor" ? "Slip (%):" : "Speed (RPM):" }
                    TextField {
                        id: speedInput
                        text: machineTypeCombo.currentText === "Induction Motor" ? "3.3" : "1500"
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

            // Results Section
            GroupBox {
                title: "Results"

                GridLayout {
                    columns: 2
                    rowSpacing: 5
                    columnSpacing: 10

                    Label { text: "Rated Power:" }
                    Label { 
                        text: calculator.ratedPower.toFixed(2) + " kW"
                        color: Universal.foreground
                    }

                    Label { text: "Torque:" }
                    Label { 
                        text: calculator.torque.toFixed(2) + " N·m"
                        color: Universal.foreground
                    }

                    Label { text: "Losses:" }
                    Label { 
                        text: calculator.losses.toFixed(2) + " kW"
                        color: Universal.theme === Universal.Dark ? "#FF8080" : "red"
                    }

                    Label { text: "Efficiency:" }
                    Label { 
                        text: (calculator.efficiency * 100).toFixed(1) + "%"
                        color: Universal.theme === Universal.Dark ? "#90EE90" : "green"
                    }
                }
            }
        }

        // Right side - Visualization
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Universal.background
            border.color: Universal.foreground
            border.width: 1

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
                
                darkMode: Universal.theme === Universal.Dark
                textColor: machineCard.textColor
            }
        }
    }
}
