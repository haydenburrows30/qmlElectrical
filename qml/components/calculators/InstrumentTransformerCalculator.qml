import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"

WaveCard {
    id: instrumentTransformerCard
    title: 'CT/VT Calculator'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 300

    info: ""

    RowLayout {
        anchors.fill: parent

        // CT Settings Column
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.minimumWidth: 250

            Label {
                text: "Current Transformer (CT)"
                font.bold: true
            }

            RowLayout {
                Label {
                    text: "CT Ratio:"
                    Layout.preferredWidth: 100
                }
                ComboBox {
                    id: ctRatio
                    model: instrumentTransformer.standardCtRatios
                    onCurrentTextChanged: instrumentTransformer.setCtRatio(currentText)
                    Layout.preferredWidth: 120
                }
            }

            RowLayout {
                Label {
                    text: "Burden (VA):"
                    Layout.preferredWidth: 100
                }
                SpinBox {
                    id: ctBurden
                    from: 1
                    to: 100
                    value: 15
                    onValueChanged: instrumentTransformer.setBurden(value)
                    Layout.preferredWidth: 120
                }
            }

            // Results
            GroupBox {
                title: "CT Results"
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 5
                    width: parent.width

                    RowLayout {
                        Label {
                            text: "Knee Point:"
                            Layout.preferredWidth: 100
                        }
                        Text {
                            text: instrumentTransformer.kneePointVoltage.toFixed(1) + "V"
                            Layout.preferredWidth: 120
                            color: "blue"
                        }
                    }

                    RowLayout {
                        Label {
                            text: "Max Fault:"
                            Layout.preferredWidth: 100
                        }
                        Text {
                            text: instrumentTransformer.maxFaultCurrent.toFixed(0) + "A"
                            Layout.preferredWidth: 120
                            color: "red"
                        }
                    }
                }
            }
        }

        // VT Settings Column
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.minimumWidth: 250

            Label {
                text: "Voltage Transformer (VT)"
                font.bold: true
            }

            RowLayout {
                Label {
                    text: "VT Ratio:"
                    Layout.preferredWidth: 100
                }
                ComboBox {
                    id: vtRatio
                    model: instrumentTransformer.standardVtRatios
                    onCurrentTextChanged: instrumentTransformer.setVtRatio(currentText)
                    Layout.preferredWidth: 120
                }
            }

            // VT Results
            GroupBox {
                title: "VT Results"
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 5
                    width: parent.width

                    RowLayout {
                        Label {
                            text: "Burden Factor:"
                            Layout.preferredWidth: 100
                        }
                        Text {
                            text: "0.8"
                            Layout.preferredWidth: 120
                            color: "blue"
                        }
                    }

                    RowLayout {
                        Label {
                            text: "Accuracy Class:"
                            Layout.preferredWidth: 100
                        }
                        ComboBox {
                            id: accuracyClass
                            model: ["0.2", "0.5", "1.0", "3.0"]
                            Layout.preferredWidth: 120
                        }
                    }
                }
            }
        }

        // Visualization
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            Image {
                // source: "../../../media/ct_vt_diagram.png"
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: parent.height * 0.8
                fillMode: Image.PreserveAspectFit
            }
        }
    }
}
