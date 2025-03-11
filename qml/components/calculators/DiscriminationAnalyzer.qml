import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../"
import "../../components"

WaveCard {
    id: discriminationAnalyzerCard
    title: 'Discrimination Analysis'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 300

    RowLayout {
        anchors.fill: parent

        // Analysis Controls
        ColumnLayout {
            Layout.preferredWidth: 300

            GroupBox {
                title: "Fault Current Analysis"
                Layout.fillWidth: true

                ColumnLayout {
                    TextField {
                        id: faultCurrent
                        placeholderText: "Add Fault Current Level (A)"
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 0 }
                    }

                    Button {
                        text: "Add Fault Level"
                        Layout.fillWidth: true
                        onClicked: discriminationAnalyzer.addFaultLevel(
                            parseFloat(faultCurrent.text)
                        )
                    }
                }
            }

            // Results Display
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                model: discriminationAnalyzer.results
                delegate: ColumnLayout {
                    width: parent.width
                    Text {
                        text: modelData.primary + " → " + modelData.backup
                        font.bold: true
                    }
                    Repeater {
                        model: modelData.margins
                        Text {
                            text: "  " + modelData.fault_current + "A: " + 
                                  modelData.margin.toFixed(2) + "s"
                            color: modelData.coordinated ? "green" : "red"
                        }
                    }
                }
            }
        }

        // Visualization
        ChartView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true
            
            ValueAxis {
                id: marginAxis
                min: 0
                max: 2
                titleText: "Time Margin (s)"
            }
            
            ValueAxis {
                id: faultAxis
                min: 0
                max: 20000
                titleText: "Fault Current (A)"
            }

            LineSeries {
                name: "Minimum Margin"
                axisX: faultAxis
                axisY: marginAxis
                XYPoint { x: 0; y: 0.3 }
                XYPoint { x: 20000; y: 0.3 }
            }
        }
    }
}
