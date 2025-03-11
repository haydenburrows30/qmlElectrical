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
                    min: -200
                    max: 200
                    titleText: "Magnitude (pu)"
                }

                LineSeries {
                    id: waveformSeries
                    name: "Combined Waveform"
                    axisX: axisX
                    axisY: axisY
                }

                // Update waveform when it changes - optimize updates
                Connections {
                    target: calculator
                    function onWaveformChanged() {
                        waveformSeries.clear()
                        var points = calculator.waveform
                        var maxY = 0
                        
                        // Find maximum magnitude for scaling
                        for (var i = 0; i < points.length; i++) {
                            maxY = Math.max(maxY, Math.abs(points[i]))
                        }
                        
                        // Set axis range with 20% padding
                        axisY.min = -Math.ceil(maxY * 1.2)
                        axisY.max = Math.ceil(maxY * 1.2)
                        
                        // Plot points
                        for (var i = 0; i < points.length; i++) {
                            waveformSeries.append(i * (360/points.length), points[i])
                        }
                    }
                }
            }

            // Harmonic Spectrum
            ChartView {
                title: "Harmonic Spectrum"
                Layout.fillWidth: true
                Layout.fillHeight: true
                antialiasing: true

                ValueAxis {
                    id: spectrumAxisY
                    min: 0
                    max: 120  // Allow for harmonics up to 120% of fundamental
                    titleText: "Magnitude (%)"
                }

                BarCategoryAxis {
                    id: spectrumAxisX
                    categories: ["1st", "3rd", "5th", "7th", "11th", "13th"]
                }

                BarSeries {
                    id: harmonicSeries
                    axisX: spectrumAxisX
                    axisY: spectrumAxisY
                    
                    // Remove the BarSet as a child item and handle it in Connections
                }

                // Optimize spectrum updates
                Connections {
                    target: calculator
                    function onHarmonicsChanged() {
                        harmonicSeries.clear()
                        var data = calculator.individualDistortion
                        var maxY = 0
                        
                        // Find maximum magnitude for scaling
                        for (var i = 0; i < data.length; i++) {
                            maxY = Math.max(maxY, data[i])
                        }
                        
                        // Set axis range with 20% padding
                        spectrumAxisY.max = Math.ceil(maxY * 1.2)
                        
                        harmonicSeries.append("Magnitude", data)
                    }
                }

                // Initialize with default values
                Component.onCompleted: {
                    harmonicSeries.append("Magnitude", calculator.individualDistortion)
                }
            }
        }
    }
}
