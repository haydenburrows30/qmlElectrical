import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"
import SineCalc 1.0

WaveCard {
    id: sineCalculator
    title: 'Sine Wave Calculator'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 250

    property SineCalculator calculator: SineCalculator {}

    RowLayout {
        anchors.fill: parent

        ColumnLayout {

            RowLayout {
                spacing: 10
                Label {
                    text: "Frequency (Hz):"
                    Layout.preferredWidth: 120
                }
                TextField {
                    id: frequencyInput
                    text: "50"
                    onTextChanged: calculator.setFrequency(parseFloat(text))
                    Layout.preferredWidth: 120
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Amplitude (V):"
                    Layout.preferredWidth: 120
                }
                TextField {
                    id: amplitudeInput
                    text: "230"
                    onTextChanged: calculator.setAmplitude(parseFloat(text))
                    Layout.preferredWidth: 120
                }
            }

            GroupBox {
                title: "Results"
                
                ColumnLayout {
                    Label { text: "RMS Value: " + (calculator.rms).toFixed(1) + " V" }
                    Label { text: "Peak Value: " + (calculator.peak).toFixed(1) + " V" }
                }
            }
        }

        // Waveform visualization
        Canvas {
            id: waveCanvas
            // anchors.fill: parent
            Layout.minimumWidth: 500
            Layout.minimumHeight: 500
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                
                var yValues = calculator.yValues
                if (!yValues || yValues.length === 0) return
                
                var width = waveCanvas.width
                var height = waveCanvas.height
                var yCenter = height/2
                
                ctx.strokeStyle = "blue"
                ctx.lineWidth = 2
                ctx.beginPath()
                
                for (var i = 0; i < yValues.length; i++) {
                    var x = (i/yValues.length) * width
                    var y = yCenter + yValues[i]
                    if (i === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                }
                
                ctx.stroke()
            }
        }
    }
}
