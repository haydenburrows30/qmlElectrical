import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import RFreq 1.0  // Import the ResonantFrequencyCalculator namespace

WaveCard {
    id: electricPy
    title: 'Frequency'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 250

    info: ""

    // Create a local instance of the calculator
    property ResonantFrequencyCalculator calculator: ResonantFrequencyCalculator {}

    RowLayout {
        anchors.fill: parent

        ColumnLayout {
            Layout.alignment: Qt.AlignTop

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
                        if (text && calculator) {
                            calculator.setCapacitance(parseFloat(text))
                        }
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
                    onTextChanged: {
                        if (text && calculator) {
                            calculator.setInductance(parseFloat(text))
                        }
                    }
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
                    text: calculator && !isNaN(calculator.frequency) ? 
                          calculator.frequency.toFixed(2) + "Hz" : "0.00Hz"
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }
        }

        SineWaveViz {
            id: sineWaveViz
            Layout.fillWidth: true
            Layout.minimumHeight: 200
            Layout.minimumWidth: 200
            Layout.topMargin: -50
            frequency: calculator && !isNaN(calculator.frequency) ? calculator.frequency : 0
            
            Component.onCompleted: {
                if (sineCalc) {
                    amplitude = 330;
                    frequency = calculator && !isNaN(calculator.frequency) ? 
                                calculator.frequency : 0;
                    sineCalc.setFrequency(frequency);
                    yValues = sineCalc.yValues;
                    rms = sineCalc.rms;
                    peak = sineCalc.peak;
                }
            }
            
            Connections {
                target: calculator
                function onFrequencyCalculated(freq) {
                    if (sineCalc) {
                        sineCalc.setFrequency(freq);
                        sineWaveViz.frequency = freq;
                        sineWaveViz.yValues = sineCalc.yValues;
                        sineWaveViz.rms = sineCalc.rms;
                        sineWaveViz.peak = sineCalc.peak;
                    }
                }
            }
        }
    }
}
