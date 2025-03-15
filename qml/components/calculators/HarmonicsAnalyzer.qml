import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../../components"
import HarmonicAnalysis 1.0

Item {
    id: harmonicsCard
    // title: 'Harmonics Analysis'

    property HarmonicAnalysisCalculator calculator: HarmonicAnalysisCalculator {}

    RowLayout {
        spacing: 10
        anchors.margins: 10
        anchors.fill: parent

        ColumnLayout {
            Layout.maximumWidth: 300
            Layout.alignment: Qt.AlignTop
            spacing: 10

            WaveCard {
                title: "Harmonic Components"
                Layout.fillWidth: true
                Layout.minimumHeight: 290

                ColumnLayout {
                    spacing: 10
                    Repeater {
                        model: [1, 3, 5, 7, 11, 13]
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
            WaveCard {
                title: "Results"
                Layout.fillWidth: true
                Layout.minimumHeight: 100

                GridLayout {
                    columns: 2
                    rowSpacing: 10
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
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Waveform Chart
            WaveCard {
                title: "Waveform"
                Layout.fillHeight: true
                Layout.fillWidth: true

                ChartView {
                    anchors.fill: parent
                    antialiasing: true

                    theme: Universal.theme

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
            }

            WaveCard {
                Layout.fillHeight: true
                Layout.fillWidth: true
                title: "Harmonic Spectrum"

            // Harmonic Spectrum
                ChartView {
                    anchors.fill: parent
                    antialiasing: true

                    theme: Universal.theme

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
}
