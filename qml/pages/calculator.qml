import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

import '../components'


//|22/Button|36/Image|41/Content|
//|127/Button|140/Image|145/Content|
//|247/Button|260/Image|265/Content|
//|331/End|

Page {
    id: home

// Power->current info
    CButton {
        id: help_3
        anchors.right: power_current.right
        anchors.bottom: power_current.top
        anchors.bottomMargin: - (help_3.height - 8)
        icon.name: "Info"
        z:5
        width: 40
        height:40
        tooltip_text: "Info"
        onClicked: power_image.visible ? power_image.close() : power_image.show()
    }

    ImageContainer {
        id: power_image
        source: "../../media/powercalc.png"
    }

    GroupBox {
        id: power_current
        title: 'Power -> Current'
        width: 270
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                spacing: 10

                Label {
                    text: "Phase:"
                    Layout.preferredWidth: 80
                }

                ComboBox {
                    id: phaseSelector
                    model: ["Single Phase", "Three Phase"]
                    onCurrentTextChanged: powerCalculator.setPhase(currentText)
                    currentIndex: 1

                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "kVA:"
                    Layout.preferredWidth: 80
                }

                TextField {
                    id: kvaInput
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter kVA"
                    onTextChanged: powerCalculator.setKva(parseFloat(text))
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Voltage:"
                    Layout.preferredWidth: 80
                }

                TextField {
                    id: voltageInput
                    placeholderText: "Enter Voltage"
                    onTextChanged: {
                        powerCalculator.setVoltage(parseFloat(text))
                    }
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Current:"
                    Layout.preferredWidth: 80
                }

                Text {
                    id: currentOutput
                    text: powerCalculator.current.toFixed(2) + "A"
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }

// Charging current info
    CButton {
        id: help_1
        anchors.right: charging_current.right
        anchors.bottom: charging_current.top
        anchors.bottomMargin: - (help_1.height - 8)
        icon.name: "Info"
        z:5
        width: 40
        height:40
        tooltip_text: "Info"
        onClicked: ccc_image.visible ? ccc_image.close() : ccc_image.show()
    }

    ImageContainer {
        id: ccc_image
        source: "../../media/ccc.png"
    }

    GroupBox {
        id: charging_current
        title: 'Cable Charging Current'
        width: 270
        anchors.top: power_current.bottom
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                spacing: 10

                Label {
                    text: "Voltage (kV):"
                    Layout.preferredWidth: 80
                    
                }

                TextField {
                    id: voltage_input
                    placeholderText: "Enter Voltage"
                    onTextChanged: {
                        chargingCalc.setVoltage(parseFloat(text))
                    }
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
            }
        }

            RowLayout {
                spacing: 10

                Label {
                    text: "uF/km (1ph):"
                    Layout.preferredWidth: 80
                }

                TextField {
                    id: capacitanceInput
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Capacitance"
                    onTextChanged: chargingCalc.setCapacitance(parseFloat(text))
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Freq (Hz):"
                    Layout.preferredWidth: 80
                }

                TextField {
                    id: frequencyInput
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Frequency"
                    onTextChanged: chargingCalc.setFrequency(parseFloat(text))
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Length (km):"
                    Layout.preferredWidth: 80
                }

                TextField {
                    id: lengthInput
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Length"
                    onTextChanged: chargingCalc.setLength(parseFloat(text))
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Current:"
                    Layout.preferredWidth: 80
                }

                Text {
                    id: chargingCurrentOutput
                    text: chargingCalc.chargingCurrent.toFixed(2) + "A"
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }

// Impedance info
    CButton {
        id: help_2
        anchors.right: fault_current.right
        anchors.bottom: fault_current.top
        anchors.bottomMargin: - (help_2.height - 8)
        icon.name: "Info"
        z:5
        width: 40
        height:40
        tooltip_text: "Info"
        onClicked: impedance_image.visible ? impedance_image.close() : impedance_image.show()
    }

    ImageContainer {
        id: impedance_image
        source: "../../media/Formel-Impedanz.gif"
    }

    GroupBox {
        id: fault_current
        title: 'Impedance'
        width: 270
        anchors.top: charging_current.bottom
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                spacing: 10

                Label {
                    text: "Resistance(Ω):"
                    Layout.preferredWidth: 100
                }

                TextField {
                    id: rInput
                    placeholderText: "Enter Resistance"
                    onTextChanged: {
                        faultCalc.setResistance(parseFloat(text))
                    }
                    Layout.preferredWidth: 130
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Reactance (Ω):"
                    Layout.preferredWidth: 100
                }

                TextField {
                    id: reactanceInput
                    Layout.preferredWidth: 130
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Reactance"
                    onTextChanged: faultCalc.setReactance(parseFloat(text))
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Impedance (Ω):"
                    Layout.preferredWidth: 100
                }

                Text {
                    id: impedanceOutput
                    text: faultCalc.impedance.toFixed(2) + "A"
                    Layout.preferredWidth: 130
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }

// Electricpy info
    CButton {
        id: help_4
        anchors.right: electricPy.right
        anchors.bottom: electricPy.top
        anchors.bottomMargin: - (help_4.height - 8)
        icon.name: "Info"
        z:5
        width: 40
        height:40
        tooltip_text: "Info"
        onClicked: impedance_image1.visible ? impedance_image1.close() : impedance_image1.show()
    }

    ImageContainer {
        id: impedance_image1
        source: "../../media/Formel-Impedanz.gif"
    }

    GroupBox {
        id: electricPy
        title: 'Frequency'
        width: 270
        anchors.top: fault_current.bottom
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                spacing: 10

                Label {
                    text: "Capacitance(uF):"
                    Layout.preferredWidth: 110
                }

                TextField {
                    id: cInput
                    placeholderText: "Enter Capacitance"
                    onTextChanged: {
                        resonantFreq.setCapacitance(parseFloat(text))
                    }
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Inductance (mH):"
                    Layout.preferredWidth: 110
                }

                TextField {
                    id: inductanceInput
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                    placeholderText: "Enter Inductance"
                    onTextChanged: resonantFreq.setInductance(parseFloat(text))
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Frequency (Hz):"
                    Layout.preferredWidth: 110
                }

                Text {
                    id: freqOutput
                    text: resonantFreq.frequency.toFixed(2) + "Hz"
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }

// Conversion Calculator
    CButton {
        id: help_5
        anchors.right: conversionCalculator.right
        anchors.bottom: conversionCalculator.top
        anchors.bottomMargin: - (help_5.height - 8)
        icon.name: "Info"
        z:5
        width: 40
        height:40
        tooltip_text: "Info"
        onClicked: conversion_image.visible ? conversion_image.close() : conversion_image.show()
    }

    ImageContainer {
        id: conversion_image
        source: "../../media/conversion.png"
    }

    GroupBox {
        id: conversionCalculator
        title: 'Conversion Calculator'
        width: 270
        anchors.top: electricPy.bottom
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                spacing: 10

                Label {
                    text: "Input Value:"
                    Layout.preferredWidth: 110
                }

                TextField {
                    id: inputValue
                    placeholderText: "Enter Value"
                    onTextChanged: {
                        conversionCalc.setInputValue(parseFloat(text))
                    }
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Conversion Type:"
                    Layout.preferredWidth: 110
                }

                ComboBox {
                    id: conversionType
                    model: ["watts_to_dbmw", "dbmw_to_watts", "rad_to_hz", "hp_to_watts", "rpm_to_hz", "radians_to_hz", "hz_to_rpm", "watts_to_hp"]
                    onCurrentTextChanged: conversionCalc.setConversionType(currentText)
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10

                Label {
                    text: "Result:"
                    Layout.preferredWidth: 110
                }

                Text {
                    id: conversionResult
                    text: conversionCalc.result.toFixed(2)
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }
}