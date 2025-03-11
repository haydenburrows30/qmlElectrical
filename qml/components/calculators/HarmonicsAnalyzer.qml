import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../../components"
import HarmonicAnalysis 1.0

WaveCard {
    id: harmonicsCard
    title: 'Harmonics Analysis'

    property HarmonicAnalysisCalculator calculator: HarmonicAnalysisCalculator {}

    RowLayout {
        spacing: 10
        anchors.centerIn: parent

        ColumnLayout {
            Layout.preferredWidth: 300

            GroupBox {
                title: "Harmonic Components"
                Layout.fillWidth: true

                ColumnLayout {
                    Repeater {
                        model: [1, 3, 5, 7, 11, 13]  // Common harmonics
                        delegate: RowLayout {
                            Label { text: `${modelData}${modelData === 1 ? "st" : "th"} Harmonic:` }
                            TextField {
                                placeholderText: modelData === 1 ? "100%" : "0%"
                                enabled: modelData !== 1
                                validator: DoubleValidator { bottom: 0; top: 100 }
                                onTextChanged: if(text) {
                                    calculator.setHarmonic(modelData, parseFloat(text), 0)
                                }
                                Layout.preferredWidth: 80
                            }
                        }
                    }
                }
            }

            // Results
            GroupBox {
                title: "Results"
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 5
                    columnSpacing: 10

                    Label { text: "THD:" }
                    Label { text: calculator.thd.toFixed(2) + "%" }

                    Label { text: "Crest Factor:" }
                    Label { text: calculator.crestFactor.toFixed(2) }
                }
            }
        }

        // Right Panel - Visualizations
        ColumnLayout {
            // Layout.fillWidth: true
            // Layout.fillHeight: true
            Layout.preferredWidth: 600
            Layout.preferredHeight: 600

            // Waveform Chart
            ChartView {
                title: "Waveform"
                Layout.fillWidth: true
                Layout.fillHeight: true
                antialiasing: true

                ValueAxis {
                    id: axisX
                    min: 0
                    max: 360
                    titleText: "Angle (degrees)"
                }

                ValueAxis {
                    id: axisY
                    min: -1.5
                    max: 1.5
                    titleText: "Magnitude (pu)"
                }

                LineSeries {
                    name: "Combined Waveform"
                    axisX: axisX
                    axisY: axisY
                    XYPoint { x: 0; y: 0 }  // Initial point
                }
            }

            // Harmonic Spectrum
            ChartView {
                title: "Harmonic Spectrum"
                Layout.fillWidth: true
                Layout.fillHeight: true
                antialiasing: true

                BarSeries {
                    axisX: BarCategoryAxis {
                        categories: ["1st", "3rd", "5th", "7th", "11th", "13th"]
                    }
                    axisY: ValueAxis {
                        min: 0
                        max: 100
                        titleText: "Magnitude (%)"
                    }
                }
            }
        }
    }
}
