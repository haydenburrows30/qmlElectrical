import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import Calculator 1.0
import Charging 1.0

Page {
    id: home

    MouseArea {
        anchors.fill: parent

        onClicked:  {
            sideBar.close()
        }
    }

    GroupBox {
        id: settings
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

    GroupBox {
        id: charging_current
        title: 'Charging Current'
        width: 270
        anchors.top: settings.bottom
        anchors.left: parent.left
        anchors.topMargin: 10
        anchors.leftMargin: 10

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                spacing: 10

                Label {
                    text: "Voltage:"
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
                    text: "uF/km:"
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
}