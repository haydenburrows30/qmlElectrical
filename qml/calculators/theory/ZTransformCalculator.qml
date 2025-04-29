import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/charts"

import ZTransformCalculator 1.0

Item {
    id: zTransformCard

    property ZTransformCalculator z_calculator: ZTransformCalculator {}

    property color textColor: Universal.foreground
    property int waveHeight: 310
    property int calculationThrottleMs: 300
    property var throttleTimer: null

    // Z-transform popup
    PopUpText {
        id: zTransformInfoPopup
        parentCard: results
        popupText: "<h3>Z-Transform Information</h3><br>" + 
                   "The Z-transform is a cornerstone of digital signal processing:<br><br>" +
                   "• It converts discrete-time signals into complex frequency domain representation<br>" +
                   "• It's the digital equivalent of the Laplace transform<br>" +
                   "• Z = e^(sT) where T is the sampling period<br>" +
                   "• The unit circle |z| = 1 corresponds to the frequency response<br>" +
                   "• Poles and zeros in the z-plane define system stability and response<br><br>" +
                   "<h4>Mathematical Definition</h4>" +
                   "For a discrete signal x[n], the Z-transform is:<br>" +
                   "<p style='text-align: center'>X(z) = ∑<sub>n=-∞</sub><sup>∞</sup> x[n]·z<sup>-n</sup></p>" +
                   "The transform exists when this sum converges, generally within an annular region of the complex z-plane."
        widthFactor: 0.6
        heightFactor: 0.6
    }
    
    // Wavelet popup
    PopUpText {
        id: waveletInfoPopup
        parentCard: results
        popupText: "<h3>Wavelet Transform Visualization</h3><br>" + 
                   "The wavelet transform provides time-frequency analysis with these properties:<br><br>" +
                   "• Unlike Fourier transforms, wavelets have limited duration<br>" +
                   "• They provide better time resolution at high frequencies<br>" +
                   "• Multiple scales reveal different signal features<br>" +
                   "• They're used for signal denoising, compression, and feature extraction<br>" +
                   "• The transform shows signal energy distribution in time-scale space<br><br>" +
                   "<h4>Mathematical Basis</h4>" +
                   "The continuous wavelet transform is defined as:<br>" +
                   "<p style='text-align: center'>W(a,b) = (1/√a)∫f(t)·ψ*((t-b)/a)dt</p>" +
                   "where ψ is the mother wavelet, a is scale, and b is translation."
        widthFactor: 0.6
        heightFactor: 0.6
    }
    
    // Hilbert popup
    PopUpText {
        id: hilbertInfoPopup
        parentCard: results
        popupText: "<h3>Hilbert Transform Visualization</h3><br>" + 
                   "The Hilbert transform enables complex signal analysis:<br><br>" +
                   "• Creates the analytic signal from a real signal<br>" +
                   "• Enables extraction of signal envelope (amplitude)<br>" +
                   "• Reveals instantaneous phase and frequency<br>" +
                   "• Produces a 90° phase shift across all frequencies<br>" +
                   "• Essential for demodulation and signal analysis<br><br>" +
                   "<h4>Mathematical Definition</h4>" +
                   "For a signal x(t), the Hilbert transform is:<br>" +
                   "<p style='text-align: center'>H{x(t)} = (1/π) P.V. ∫ x(τ)/(t-τ) dτ</p>" +
                   "where P.V. denotes the Cauchy principal value of the integral."
        widthFactor: 0.6
        heightFactor: 0.6
    }
    
    PopUpText {
        id: popUpText
        parentCard: results
        popupText: "<h3>Digital and Specialized Transforms Calculator</h3><br>" +
                    "This calculator demonstrates digital and specialized transforms essential in modern signal processing and electrical engineering.<br><br>" +
                    "<b>Z-Transform:</b><br>" +
                    "The fundamental transform for digital signal processing, difference equations, and digital filter design.<br><br>" +
                    "<b>Wavelet Transform:</b><br>" +
                    "Provides multi-resolution analysis of signals, useful for transient detection and non-stationary signal analysis.<br><br>" +
                    "<b>Hilbert Transform:</b><br>" +
                    "Creates the analytic signal and envelope detection, critical for modulation analysis and instantaneous frequency calculation.<br><br>" +
                    "<b>Function Selection:</b><br>" +
                    "Choose from common discrete sequences to see their transforms.<br><br>" +
                    "<b>Parameters:</b><br>" +
                    "Adjust amplitude, sampling rate, sequence length, and other parameters.<br><br>" +
                    "<b>Applications:</b><br>" +
                    "These transforms are crucial for digital filtering, communications, audio/image processing, and power quality analysis."
        widthFactor: 0.7
        heightFactor: 0.7
    }

    // Loading indicator
    BusyIndicator {
        id: calculationIndicator
        anchors.centerIn: parent
        running: z_calculator ? z_calculator.calculating : false
        visible: running
        z: 10
        width: 100
        height: 100
        
        // Optional background
        Rectangle {
            visible: parent.visible
            anchors.fill: parent
            anchors.margins: -20
            color: "#80000000"
            radius: 10
            
            // Add label to show calculation is in progress
            Text {
                anchors.centerIn: parent
                text: "Calculating..."
                color: "white"
                font.pixelSize: 12
                y: 30
            }
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            id: flickableContainer
            contentWidth: parent.width - 10
            contentHeight: mainLayout.height
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            ColumnLayout {
                id: mainLayout
                width: parent.width - 10

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Digital Transforms Calculator"
                        font.pixelSize: 26
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Information"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: popUpText.open()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    // Left column - inputs
                    ColumnLayout {
                        id: leftColumn
                        Layout.preferredWidth: 400
                        Layout.fillWidth: false

                        // Transform selection
                        WaveCard {
                            title: "Transform Type"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 240

                            ColumnLayout {
                                anchors.fill: parent
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 5
                                    
                                    RadioButton {
                                        id: zTransformRadio
                                        text: "Z"
                                        checked: true
                                        onCheckedChanged: {
                                            if (checked) {
                                                z_calculator.setTransformType("Z-Transform")
                                            }
                                        }
                                    }
                                    
                                    RadioButton {
                                        id: waveletRadio
                                        text: "Wavelet"
                                        onCheckedChanged: {
                                            if (checked) {
                                                z_calculator.setTransformType("Wavelet")
                                            }
                                        }
                                    }
                                    
                                    RadioButton {
                                        id: hilbertRadio
                                        text: "Hilbert"
                                        onCheckedChanged: {
                                            if (checked) {
                                                z_calculator.setTransformType("Hilbert")
                                            }
                                        }
                                    }

                                    Label {Layout.fillWidth: true}

                                    // Information buttons
                                    StyledButton {
                                        id: transformInfoButton
                                        text: zTransformRadio.checked ? "Z-Transform" : 
                                            waveletRadio.checked ? "Wavelet" : 
                                            "Hilbert"
                                        icon.source: "../../../icons/rounded/info.svg"
                                        Layout.alignment: Qt.AlignRight

                                        ToolTip.visible: transformInfoButton.hovered
                                        ToolTip.delay: 500
                                        ToolTip.text: zTransformRadio.checked ? "Z-Transform info" : 
                                            waveletRadio.checked ? "Wavelet info" : 
                                            "Hilbert info"

                                        onClicked: {
                                            if (zTransformRadio.checked) {
                                                zTransformInfoPopup.open()
                                            } else if (waveletRadio.checked) {
                                                waveletInfoPopup.open()
                                            } else {
                                                hilbertInfoPopup.open()
                                            }
                                        }
                                    }
                                }

                                Label { 
                                    text: "Sequence Selection"
                                    Layout.fillWidth: true
                                    font.bold: true
                                    font.pixelSize: 16
                                }

                                ComboBoxRound {
                                    id: functionTypeCombo
                                    model: z_calculator.functionTypes
                                    onCurrentTextChanged: z_calculator.setFunctionType(currentText)
                                    Layout.fillWidth: true
                                }
                                
                                TextFieldBlue {
                                    id: equationField
                                    text: z_calculator ? z_calculator.equationOriginal : ""
                                    readOnly: true
                                    Layout.fillWidth: true
                                    font.italic: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        // Function parameters
                        WaveCard {
                            title: "Sequence Parameters"
                            Layout.fillWidth: true
                            Layout.minimumHeight: waveletRadio.checked ? 350: 280

                            GridLayout {
                                id: parametersGrid
                                columns: 2
                                anchors.fill: parent

                                Label { 
                                    text: "Amplitude:"
                                    Layout.minimumWidth: 150
                                }
                                
                                SpinBoxRound {
                                    id: amplitudeSpinBox
                                    from: -50
                                    to: 50
                                    value: z_calculator.amplitude * 10
                                    stepSize: 1
                                    editable: true
                                    Layout.fillWidth: true
                                    
                                    property real realValue: value / 10.0
                                    
                                    onValueModified: z_calculator.setAmplitude(realValue)
                                    
                                    textFromValue: function(value) {
                                        return (value / 10.0).toFixed(1);
                                    }
                                    
                                    valueFromText: function(text) {
                                        return Math.round(parseFloat(text) * 10);
                                    }

                                    validator: RegularExpressionValidator {
                                        regularExpression: /[0-9]*\.?[0-9]*/
                                    }
                                }

                                Label { 
                                    text: "Decay Factor:"
                                    Layout.minimumWidth: 150
                                    visible: needsDecayFactor()
                                }
                                
                                SpinBoxRound {
                                    id: decayFactorSpinBox
                                    from: 1
                                    to: 100
                                    value: z_calculator.decayFactor * 10
                                    stepSize: 1
                                    editable: true
                                    Layout.fillWidth: true
                                    visible: needsDecayFactor()
                                    
                                    property real realValue: value / 10.0
                                    
                                    onValueModified: z_calculator.setDecayFactor(realValue)
                                    
                                    textFromValue: function(value) {
                                        return (value / 10.0).toFixed(1);
                                    }
                                    
                                    valueFromText: function(text) {
                                        return Math.round(parseFloat(text) * 10);
                                    }

                                    validator: RegularExpressionValidator {
                                        regularExpression: /[0-9]*\.?[0-9]*/
                                    }
                                }

                                Label { 
                                    text: "Frequency (Hz):" 
                                    Layout.minimumWidth: 150
                                    visible: needsFrequency()
                                }
                                
                                SpinBoxRound {
                                    id: frequencySpinBox
                                    from: 1
                                    to: 1000
                                    value: z_calculator.frequency * 10
                                    stepSize: 1
                                    editable: true
                                    Layout.fillWidth: true
                                    visible: needsFrequency()
                                    
                                    property real realValue: value / 10.0
                                    
                                    onValueModified: z_calculator.setFrequency(realValue)
                                    
                                    textFromValue: function(value) {
                                        return (value / 10.0).toFixed(1);
                                    }
                                    
                                    valueFromText: function(text) {
                                        return Math.round(parseFloat(text) * 10);
                                    }

                                    validator: RegularExpressionValidator {
                                        regularExpression: /[0-9]*\.?[0-9]*/
                                    }
                                }
                                
                                Label { 
                                    text: "Sampling Rate (Hz):" 
                                    Layout.minimumWidth: 150
                                }
                                
                                SpinBoxRound {
                                    id: samplingRateSpinBox
                                    from: 1
                                    to: 2000
                                    value: z_calculator.samplingRate
                                    stepSize: 1
                                    editable: true
                                    Layout.fillWidth: true

                                    property real realValue: value

                                    textFromValue: function(value) {
                                        return value.toFixed(0);
                                    }

                                    valueFromText: function(text) {
                                        return Math.round(parseFloat(text));
                                    }

                                    validator: RegularExpressionValidator {
                                        regularExpression: /[0-9]*\.?[0-9]*/
                                    }
                                    
                                    ToolTip.visible: hilbertRadio.checked && hovered
                                    ToolTip.text: "Sampling rates between 1-100 Hz often show more pronounced Hilbert transform features"
                                    ToolTip.delay: 500
                                    
                                    onValueModified: z_calculator.setSamplingRate(realValue)
                                }

                                Label { 
                                    text: "Sequence Length:" 
                                    Layout.minimumWidth: 150
                                }
                                
                                SpinBoxRound {
                                    id: sequenceLengthSpinBox
                                    from: 10
                                    to: 500
                                    value: z_calculator.sequenceLength
                                    stepSize: 10
                                    editable: true
                                    Layout.fillWidth: true
                                    
                                    onValueChanged: z_calculator.setSequenceLength(value)
                                }
                                
                                Label { 
                                    text: waveletRadio.checked ? "Wavelet Type:" : "Display Options:" 
                                    Layout.minimumWidth: 150
                                }
                                
                                ComboBoxRound {
                                    id: displayOptionsCombo
                                    model: waveletRadio.checked ? 
                                          (z_calculator.pywaveletAvailable ? 
                                           ["db1", "db2", "db4", "sym2", "coif1"] : 
                                           ["Basic"]) : 
                                          hilbertRadio.checked ?
                                          ["Envelope", "Phase", "Envelope & Phase"] :
                                          ["Magnitude & Phase", "Poles/Zeros"]
                                    Layout.fillWidth: true
                                    onCurrentTextChanged: {
                                        if (waveletRadio.checked) {
                                            z_calculator.setWaveletType(currentText)
                                        } else {
                                            z_calculator.setDisplayOption(currentText)
                                            // Update chart properties when display option changes
                                            if (transformChart) {
                                                transformChart.showPoleZero = displayOptionsCombo.currentText.includes("Poles") && zTransformRadio.checked
                                                
                                                // Check if the properties exist before setting them
                                                if (transformChart.hasOwnProperty("showHilbertEnvelope"))
                                                    transformChart.showHilbertEnvelope = currentText.includes("Envelope") && hilbertRadio.checked
                                                
                                                if (transformChart.hasOwnProperty("showHilbertPhase"))
                                                    transformChart.showHilbertPhase = currentText.includes("Phase") && hilbertRadio.checked
                                            }
                                        }
                                    }
                                }
                                
                                // Add information about available wavelets
                                Rectangle {
                                    visible: waveletRadio.checked && z_calculator.pywaveletAvailable
                                    color: "#E3F2FD"  // Light blue info color
                                    border.color: "#BBDEFB"
                                    border.width: 1
                                    radius: 4
                                    Layout.fillWidth: true
                                    Layout.columnSpan: 2
                                    Layout.preferredHeight: waveletInfo.height + 16
                                    
                                    Text {
                                        id: waveletInfo
                                        anchors.centerIn: parent
                                        width: parent.width - 16
                                        text: "Using PyWavelet discrete wavelets. db1 = Haar, db# = Daubechies, sym# = Symlets, coif# = Coiflets"
                                        wrapMode: Text.Wrap
                                        color: "#0D47A1"  // Dark blue text color
                                        font.pixelSize: 12
                                    }
                                }

                                // Add information about pole-zero plot when selected
                                Rectangle {
                                    visible: zTransformRadio.checked && displayOptionsCombo.currentText.includes("Poles")
                                    color: "#E3F2FD"  // Light blue info color
                                    border.color: "#BBDEFB"
                                    border.width: 1
                                    radius: 4
                                    Layout.fillWidth: true
                                    Layout.columnSpan: 2
                                    Layout.preferredHeight: poleZeroInfo.height + 16
                                    
                                    Text {
                                        id: poleZeroInfo
                                        anchors.centerIn: parent
                                        width: parent.width - 16
                                        text: "Pole-Zero Plot: Poles (×) determine system resonances, zeros (○) determine notches. For stability, all poles must be inside the unit circle (|z| < 1)."
                                        wrapMode: Text.Wrap
                                        color: "#0D47A1"  // Dark blue text color
                                        font.pixelSize: 12
                                    }
                                }

                                // Add information about Hilbert transform visualization
                                Rectangle {
                                    visible: hilbertRadio.checked
                                    color: "#E3F2FD"  // Light blue info color
                                    border.color: "#BBDEFB"
                                    border.width: 1
                                    radius: 4
                                    Layout.fillWidth: true
                                    Layout.columnSpan: 2
                                    Layout.preferredHeight: hilbertInfo.height + 16
                                    
                                    Text {
                                        id: hilbertInfo
                                        anchors.centerIn: parent
                                        width: parent.width - 16
                                        text: "For best Hilbert transform visualization, try Chirp or Sinusoidal signals. Lower sampling rates (10-100 Hz) often show more pronounced features. The envelope shows instantaneous amplitude, and phase shows frequency variations."
                                        wrapMode: Text.Wrap
                                        color: "#0D47A1"  // Dark blue text color
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }

                        // Notes
                        WaveCard {
                            title: "Applications in Electrical Engineering"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 350
                            
                            ScrollView {
                                anchors.fill: parent
                                clip: true
                                
                                TextArea {
                                    id: educationalText
                                    readOnly: true
                                    wrapMode: TextEdit.Wrap
                                    textFormat: TextEdit.RichText
                                    text: getApplicationContent()

                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                }
                            }
                        }
                    }

                    // Right column - results
                    WaveCard {
                        id: results
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 800
                        
                        title: "Transform Results"
                        showSettings: false

                        ColumnLayout {
                            anchors.fill: parent

                            Label {
                                text: "Chart Information:"
                                font.bold: true
                                Layout.columnSpan: 2
                            }

                            TextArea {
                                readOnly: true
                                text: getChartInfoText()
                                wrapMode: TextEdit.Wrap
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                background: Rectangle {
                                    color: "transparent"
                                }
                            }

                            TextFieldBlue {
                                text: getKeyParametersText()
                                font.pixelSize: 14
                                font.bold: true
                            }

                            TextFieldBlue {
                                id: transformEquationField
                                text: z_calculator ? z_calculator.equationTransform : ""
                                font.italic: true
                                horizontalAlignment: Text.AlignHCenter
                                ToolTip.text: "Transform equation"
                                ToolTip.visible: hovered
                                ToolTip.delay: 500
                            }

                            TransformChart {
                                id: transformChart
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: !waveletRadio.checked

                                timeDomain: z_calculator.timeDomain ? z_calculator.timeDomain : []
                                transformResult: z_calculator.transformResult ? z_calculator.transformResult : []
                                phaseResult: z_calculator.phaseResult ? z_calculator.phaseResult : []
                                frequencies: z_calculator.frequencies ? z_calculator.frequencies : []
                                transformType: z_calculator.transformType
                                showPoleZero: displayOptionsCombo.currentText.includes("Poles") && zTransformRadio.checked
                                
                                poleLocations: z_calculator.poleLocations ? z_calculator.poleLocations : []
                                zeroLocations: z_calculator.zeroLocations ? z_calculator.zeroLocations : []
                                darkMode: Universal.theme === Universal.Dark
                                textColor: zTransformCard.textColor

                                calculator: z_calculator
                                
                                // After component is loaded, set the Hilbert properties if they exist
                                Component.onCompleted: {
                                    if (transformChart.hasOwnProperty("showHilbertEnvelope"))
                                        transformChart.showHilbertEnvelope = (displayOptionsCombo.currentText.includes("Envelope") || 
                                                                             displayOptionsCombo.currentIndex === 0) && hilbertRadio.checked
                                    
                                    if (transformChart.hasOwnProperty("showHilbertPhase"))
                                        transformChart.showHilbertPhase = displayOptionsCombo.currentText.includes("Phase") && hilbertRadio.checked
                                }
                            }

                            WaveletChart {
                                id: waveletChart
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: waveletRadio.checked

                                waveLetEnabled: waveletRadio.checked

                                timeDomain: z_calculator.timeDomain ? z_calculator.timeDomain : []
                                scaleData: z_calculator.frequencies ? z_calculator.frequencies : []
                                magnitudeData: z_calculator.waveletMagnitude2D ? z_calculator.waveletMagnitude2D : []
                                phaseData: z_calculator.waveletPhase2D ? z_calculator.waveletPhase2D : []
                                waveletType: displayOptionsCombo.currentText
                                darkMode: Universal.theme === Universal.Dark
                                textColor: zTransformCard.textColor
                            }
                        }
                    }
                }
            }
        }
    }

    // Watch for display option changes
    Connections {
        target: displayOptionsCombo
        function onCurrentTextChanged() {
            if (transformChart) {
                transformChart.showPoleZero = displayOptionsCombo.currentText.includes("Poles") && zTransformRadio.checked
                
                if (transformChart.hasOwnProperty("showHilbertEnvelope"))
                    transformChart.showHilbertEnvelope = displayOptionsCombo.currentText.includes("Envelope") && hilbertRadio.checked
                
                if (transformChart.hasOwnProperty("showHilbertPhase"))
                    transformChart.showHilbertPhase = displayOptionsCombo.currentText.includes("Phase") && hilbertRadio.checked
            }
        }
    }

    // Connections for transform type radio buttons
    Connections {
        target: zTransformRadio
        function onCheckedChanged() {
            if (transformChart && zTransformRadio.checked) {
                transformChart.transformType = "Z-Transform"
            }
        }
    }
    
    Connections {
        target: waveletRadio
        function onCheckedChanged() {
            if (transformChart && waveletRadio.checked) {
                transformChart.transformType = "Wavelet"
            }
        }
    }
    
    Connections {
        target: hilbertRadio
        function onCheckedChanged() {
            if (transformChart && hilbertRadio.checked) {
                transformChart.transformType = "Hilbert"
            }
        }
    }
    
    // z_calculator updates
    Connections {
        target: z_calculator
        
        function onResultsCalculated() {
            if (transformChart) {
                transformChart.timeDomain = z_calculator.timeDomain ? z_calculator.timeDomain : []
                transformChart.transformResult = z_calculator.transformResult ? z_calculator.transformResult : []
                transformChart.phaseResult = z_calculator.phaseResult ? z_calculator.phaseResult : []
                transformChart.frequencies = z_calculator.frequencies ? z_calculator.frequencies : []
                transformChart.poleLocations = z_calculator.poleLocations ? z_calculator.poleLocations : []
                transformChart.zeroLocations = z_calculator.zeroLocations ? z_calculator.zeroLocations : []
            }
            
            // Update wavelet chart when new results are calculated
            if (waveletChart && waveletRadio.checked) {
                waveletChart.timeDomain = z_calculator.timeDomain ? z_calculator.timeDomain : []
                waveletChart.scaleData = z_calculator.frequencies ? z_calculator.frequencies : []
                waveletChart.magnitudeData = z_calculator.waveletMagnitude2D ? z_calculator.waveletMagnitude2D : []
                waveletChart.phaseData = z_calculator.waveletPhase2D ? z_calculator.waveletPhase2D : []
                waveletChart.waveletType = displayOptionsCombo.currentText
                waveletChart.refresh()
            }
        }
    }
    
    function needsDecayFactor() {
        switch(functionTypeCombo.currentText) {
            case "Unit Step":
            case "Unit Impulse":
            case "Sinusoidal":
            case "Rectangular Pulse":
            case "Random Sequence":
                return false;
            default:
                return true;
        }
    }
    
    function needsFrequency() {
        switch(functionTypeCombo.currentText) {
            case "Sinusoidal":
            case "Exponentially Damped Sine":
            case "Chirp Sequence":
                return true;
            default:
                return false;
        }
    }
    
    function getChartInfoText() {
        if (zTransformRadio.checked) {
            if (displayOptionsCombo.currentText.includes("Poles")) {
                return "• Unit circle (|z| = 1)\n• Poles (×) create resonances/instability\n• Zeros (○) create notches/nulls\n• Stability requires poles inside the unit circle";
            }
            return "• Top chart: Discrete-time sequence\n• Bottom chart: Z-transform representation in the selected format (magnitude, phase, or pole-zero plot)";
        } else if (waveletRadio.checked) {
            return "• Top chart: Original signal\n• Bottom chart: " + "2D wavelet coefficient map with scales and translations";
        } else {
            if (displayOptionsCombo.currentText.includes("Envelope") && !displayOptionsCombo.currentText.includes("Phase")) {
                return "• Top chart: Original signal\n• Bottom chart: Hilbert transform envelope (magnitude of analytic signal)\n• Tip: Try Chirp or Sinusoidal signals with sampling rates 10-100 Hz for best results";
            } else if (displayOptionsCombo.currentText.includes("Phase") && !displayOptionsCombo.currentText.includes("Envelope")) {
                return "• Top chart: Original signal\n• Bottom chart: Instantaneous phase of analytic signal\n• Tip: Lower sampling rates show more pronounced phase variations";
            } else {
                return "• Top chart: Original signal\n• Bottom chart: Hilbert transform with envelope (red) and original signal (blue)\n• The difference between the two shows the transform effect\n• For best results, try sampling rates between 10-100 Hz";
            }
        }
    }
    
    function getKeyParametersText() {
        if (zTransformRadio.checked) {
            return "Sampling Rate: " + z_calculator.samplingRate + " Hz | Nyquist Frequency: " + (z_calculator.samplingRate/2) + " Hz | Region of Convergence: " + z_calculator.rocText;
        } else if (waveletRadio.checked) {
            return "Wavelet: " + displayOptionsCombo.currentText + " | Decomposition Levels: " + z_calculator.waveletLevels + " | Edge Effects: " + z_calculator.edgeHandling;
        } else {
            return "Instantaneous Frequency Range: " + z_calculator.minFrequency.toFixed(1) + " - " + z_calculator.maxFrequency.toFixed(1) + " Hz | Analytic Signal Type";
        }
    }
    
    function getApplicationContent() {
        if (zTransformRadio.checked) {
            return "<h3>Z-Transform Applications</h3>" +
                   "<p>The Z-transform is essential in digital signal processing with applications including:</p>" +
                   "<ul>" +
                   "<li><b>Digital filter design</b> for power quality monitoring</li>" +
                   "<li><b>Control systems</b> for motor drives and power electronics</li>" +
                   "<li><b>Signal processing</b> in protection relays</li>" +
                   "<li><b>Stability analysis</b> of digital systems</li>" +
                   "<li><b>Difference equation solutions</b> for discrete systems modeling</li>" +
                   "</ul>" +
                   "<p>Engineers use Z-transforms to analyze the frequency response and stability of digital systems by examining pole and zero locations.</p>";
        } else if (waveletRadio.checked) {
            return "<h3>Wavelet Transform Applications</h3>" +
                   "<p>Wavelet transforms provide multi-resolution analysis useful in:</p>" +
                   "<ul>" +
                   "<li><b>Power quality analysis</b> for detecting transients</li>" +
                   "<li><b>Fault detection</b> in transmission lines</li>" +
                   "<li><b>Non-stationary signal analysis</b> for variable speed drives</li>" +
                   "<li><b>De-noising</b> of sensor measurements</li>" +
                   "<li><b>Feature extraction</b> for machine condition monitoring</li>" +
                   "</ul>" +
                   "<p>Unlike Fourier analysis, wavelets excel at localizing both time and frequency information, making them ideal for analyzing sudden changes in signals.</p>";
        } else {
            return "<h3>Hilbert Transform Applications</h3>" +
                   "<p>The Hilbert transform has specialized applications in:</p>" +
                   "<ul>" +
                   "<li><b>Envelope detection</b> for AM demodulation</li>" +
                   "<li><b>Instantaneous frequency calculation</b> for FM signals</li>" +
                   "<li><b>Analytic signal generation</b> for complex signal analysis</li>" +
                   "<li><b>Phase and amplitude extraction</b> from modulated signals</li>" +
                   "<li><b>Single-sideband modulation</b> in communications</li>" +
                   "</ul>" +
                   "<p>Electrical engineers use Hilbert transforms to separate amplitude and phase information from signals, particularly in communications and power systems analysis.</p>";
        }
    }
}
