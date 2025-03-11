import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"

WaveCard {
    id: powerFactorCalculator
    title: 'Power Factor Correction'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 250

    info: ""

    RowLayout {
        anchors.fill: parent

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.minimumWidth: 300

            RowLayout {
                spacing: 10
                Label {
                    text: "Active Power (kW):"
                    Layout.preferredWidth: 120
                }
                TextField {
                    id: pfActivePower
                    placeholderText: "Enter Power"
                    onTextChanged: pfCorrection.setActivePower(parseFloat(text))
                    Layout.preferredWidth: 120
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Current PF:"
                    Layout.preferredWidth: 120
                }
                TextField {
                    id: currentPF
                    text: "0.8"
                    onTextChanged: pfCorrection.setCurrentPF(parseFloat(text))
                    Layout.preferredWidth: 120
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Target PF:"
                    Layout.preferredWidth: 120
                }
                TextField {
                    id: targetPF
                    text: "0.95"
                    onTextChanged: pfCorrection.setTargetPF(parseFloat(text))
                    Layout.preferredWidth: 120
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "System Voltage:"
                    Layout.preferredWidth: 120
                }
                TextField {
                    id: systemVoltage
                    text: "400"
                    onTextChanged: pfCorrection.setVoltage(parseFloat(text))
                    Layout.preferredWidth: 120
                }
            }

            GroupBox {
                title: "Results"
                Layout.fillWidth: true

                ColumnLayout {
                    width: parent.width

                    RowLayout {
                        spacing: 10
                        Label {
                            text: "Capacitor Size:"
                            Layout.preferredWidth: 120
                            font.bold: true
                        }
                        Text {
                            text: pfCorrection.capacitorSize.toFixed(1) + " kVAR"
                            Layout.preferredWidth: 120
                            font.bold: true
                        }
                    }

                    RowLayout {
                        spacing: 10
                        Label {
                            text: "Capacitance:"
                            Layout.preferredWidth: 120
                        }
                        Text {
                            text: pfCorrection.capacitance.toFixed(1) + " μF"
                            Layout.preferredWidth: 120
                        }
                    }

                    RowLayout {
                        spacing: 10
                        Label {
                            text: "Annual Savings:"
                            Layout.preferredWidth: 120
                        }
                        Text {
                            text: "$ " + pfCorrection.annualSavings.toFixed(2)
                            Layout.preferredWidth: 120
                            color: pfCorrection.annualSavings > 0 ? "green" : "black"
                        }
                    }
                }
            }
        }

        // Power Triangle Visualization
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Image {
                // source: "../../media/power_triangle_diagram.png"
                Layout.fillWidth: true
                Layout.fillHeight: true
                fillMode: Image.PreserveAspectFit
            }

            Label {
                text: "Before: PF = " + currentPF.text + "\nAfter: PF = " + targetPF.text
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                font.bold: true
            }
        }
    }
}
