import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../../components"
import HarmonicAnalysis 1.0

WaveCard {
    id: harmonicAnalyzerCard
    title: 'Harmonic Analysis'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 300

    property HarmonicAnalysisCalculator calculator: HarmonicAnalysisCalculator {}

    RowLayout {
        anchors.fill: parent

        // Input controls
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.minimumWidth: 300

            GroupBox {
                title: "Harmonic Input"
                Layout.fillWidth: true

                GridLayout {
                    columns: 3
                    Layout.fillWidth: true

                    Label { text: "Order" }
                    Label { text: "Magnitude (%)" }
                    Label { text: "Angle (°)" }

                    // Fundamental
                    SpinBox {
                        value: 1
                        enabled: false
                    }
                    TextField {
                        placeholderText: "100%"
                        text: "100"
                    }
                    TextField {
                        placeholderText: "0°"
                        text: "0"
                    }

                    // 3rd Harmonic
                    SpinBox {
                        value: 3
                        enabled: false
                    }
                    TextField {
                        placeholderText: "Magnitude"
                    }
                    TextField {
                        placeholderText: "Angle"
                    }

                    // 5th Harmonic
                    SpinBox {
                        value: 5
                        enabled: false
                    }
                    TextField {
                        placeholderText: "Magnitude"
                    }
                    TextField {
                        placeholderText: "Angle"
                    }
                }
            }

            GroupBox {
                title: "Results"
                Layout.fillWidth: true

                ColumnLayout {
                    Label { text: "THD: " + "0.00%" }
                    Label { text: "CF: " + "0.00" }
                }
            }
        }

        // Waveform and spectrum visualization
        ChartView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true

            LineSeries {
                name: "Waveform"
                axisX: ValueAxis {
                    min: 0
                    max: 360
                    titleText: "Angle (°)"
                }
                axisY: ValueAxis {
                    min: -1.5
                    max: 1.5
                    titleText: "Magnitude (pu)"
                }
            }
        }
    }
}
