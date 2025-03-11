import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import CableAmpacity 1.0  // Import the correct namespace

WaveCard {
    id: cableAmpacityCalculator
    title: 'Cable Ampacity'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 300

    info: ""

    // Create a local instance of our calculator
    property CableAmpacity calculator: CableAmpacity {}

    RowLayout {
        anchors.fill: parent

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.minimumWidth: 300

            RowLayout {
                spacing: 10
                Label {
                    text: "Cable Size:"
                    Layout.preferredWidth: 120
                }
                ComboBox {
                    id: cableSize
                    model: ["1.5", "2.5", "4", "6", "10", "16", "25", "35", "50", "70", "95", "120"]
                    onCurrentTextChanged: {
                        if (calculator) {
                            calculator.cableSize = parseFloat(currentText)
                        }
                    }
                    Layout.preferredWidth: 120
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Insulation:"
                    Layout.preferredWidth: 120
                }
                ComboBox {
                    id: insulationType
                    model: ["PVC", "XLPE"]
                    onCurrentTextChanged: {
                        if (calculator) {
                            calculator.insulationType = currentText
                        }
                    }
                    Layout.preferredWidth: 120
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Installation:"
                    Layout.preferredWidth: 120
                }
                ComboBox {
                    id: installMethod
                    model: ["Conduit", "Tray", "Direct Buried", "Free Air", "Wall Surface"]
                    onCurrentTextChanged: {
                        if (calculator) {
                            calculator.installMethod = currentText
                        }
                    }
                    Layout.preferredWidth: 120
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Ambient Temp (°C):"
                    Layout.preferredWidth: 120
                }
                SpinBox {
                    id: ambientTemp
                    from: 25
                    to: 55
                    stepSize: 5
                    value: 30
                    onValueChanged: {
                        if (calculator) {
                            calculator.ambientTemp = value
                        }
                    }
                    Layout.preferredWidth: 120
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Grouping:"
                    Layout.preferredWidth: 120
                }
                SpinBox {
                    id: groupingNumber
                    from: 1
                    to: 20
                    value: 1
                    onValueChanged: {
                        if (calculator) {
                            calculator.groupingNumber = value
                        }
                    }
                    Layout.preferredWidth: 120
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Base Ampacity:"
                    Layout.preferredWidth: 120
                    font.bold: true
                }
                Text {
                    text: calculator && !isNaN(calculator.baseAmpacity) ? 
                          calculator.baseAmpacity.toFixed(1) + " A" : "0.0 A"
                    Layout.preferredWidth: 120
                    font.bold: true
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Derated Ampacity:"
                    Layout.preferredWidth: 120
                }
                Text {
                    text: calculator && !isNaN(calculator.deratedAmpacity) ? 
                          calculator.deratedAmpacity.toFixed(1) + " A" : "0.0 A"
                    Layout.preferredWidth: 120
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Recommended Size:"
                    Layout.preferredWidth: 120
                }
                Text {
                    text: calculator && !isNaN(calculator.recommendedSize) ? 
                          calculator.recommendedSize.toFixed(1) + " mm²" : "0.0 mm²"
                    Layout.preferredWidth: 120
                    color: calculator && !isNaN(calculator.recommendedSize) && 
                           calculator.recommendedSize > parseFloat(cableSize.currentText) ? 
                           "red" : "green"
                }
            }
        }

        // Ampacity Chart
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            Image {
                source: "../../../media/cable_ampacity_chart.png"
                anchors.centerIn: parent
                width: parent.width * 0.9
                height: parent.height * 0.9
                fillMode: Image.PreserveAspectFit
            }
        }
    }
}