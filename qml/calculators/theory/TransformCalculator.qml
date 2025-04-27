import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/charts"

import TransformCalculator 1.0
import WaveletPlotter 1.0

Item {
    id: transformCard

    property TransformCalculator calculator: TransformCalculator {}
    property color textColor: Universal.foreground
    property int waveHeight: 310
    property int calculationThrottleMs: 300
    property var throttleTimer: null

    // Add the phase information popup
    PopUpText {
        id: phaseInfoPopup
        parentCard: results
        popupText: "<h3>Sine Wave Phase Information</h3><br>" + 
                   "For a sine wave, the phase in the Fourier transform appears jagged because:<br><br>" +
                   "• The phase jumps between -90° and +90° at the fundamental frequency<br>" +
                   "• Phase is mathematically undefined where magnitude is zero<br>" +
                   "• Numerical precision issues occur at very small magnitudes<br>" +
                   "• The discrete FFT algorithm introduces computational artifacts<br><br>" +
                   "<h4>Mathematical Explanation</h4>" +
                   "For a pure sine wave sin(ωt), the Fourier transform is:<br>" +
                   "<p style='text-align: center'>F(ω) = (i/2)[δ(ω-ω₀) - δ(ω+ω₀)]</p>" +
                   "This results in two impulses in the frequency domain:<br>" +
                   "• Positive frequency component has phase = -90°<br>" +
                   "• Negative frequency component has phase = +90°<br><br>" +
                   "Theoretically, a pure sine wave has phase of -90° at its frequency."
        widthFactor: 0.6
        heightFactor: 0.6
    }
    
    // Add Laplace transform information popup
    PopUpText {
        id: laplaceInfoPopup
        parentCard: results
        popupText: "<h3>Laplace Transform Visualization</h3><br>" + 
                   "The Laplace transform shown in this calculator has these characteristics:<br><br>" +
                   "• For sine waves, a resonant peak appears at jω = 2πf rad/s<br>" +
                   "• <b>The resonant frequency is highlighted with an orange vertical line</b><br>" +
                   "• The x-axis represents the imaginary part of s (jω in rad/s)<br>" +
                   "• We're showing a small section of the s-plane (along the jω axis)<br>" +
                   "• The complete s-plane would be 2D with σ and jω axes<br><br>" +
                   "<h4>Mathematical Note</h4>" +
                   "For a sine wave sin(2πft), the Laplace transform is:<br>" +
                   "<p style='text-align: center'>L{sin(2πft)} = 2πf/(s² + (2πf)²)</p>" +
                   "The resonant peak occurs precisely at s = j·2πf, which for a 10Hz signal would be at j·62.8 rad/s."
        widthFactor: 0.6
        heightFactor: 0.6
    }
    
    PopUpText {
        id: popUpText
        parentCard: results
        popupText: "<h3>Fourier and Laplace Transform Calculator</h3><br>" +
                    "This calculator demonstrates Fourier and Laplace transforms, essential mathematical tools in signal processing and electrical engineering.<br><br>" +
                    "<b>Fourier Transforms:</b><br>" +
                    "Converts a time-domain signal into its frequency components. Useful for analyzing signals in terms of sine waves at different frequencies.<br><br>" +
                    "<b>Laplace Transforms:</b><br>" +
                    "Converts a time-domain function into a complex frequency domain representation. Particularly useful for analyzing differential equations and control systems.<br><br>" +
                    "<b>Function Selection:</b><br>" +
                    "Choose from common functions to see their transforms.<br><br>" +
                    "<b>Parameters:</b><br>" +
                    "Adjust the amplitude (A), frequency, damping factor (B), and other parameters specific to each function.<br><br>" +
                    "<b>Visualization:</b><br>" +
                    "The calculator shows both the time-domain signal and its transform in magnitude and phase.<br><br>" +
                    "Developed by <b>Wave</b>."
        widthFactor: 0.7
        heightFactor: 0.7
    }

    // Add loading indicator for calculations
    BusyIndicator {
        id: calculationIndicator
        anchors.centerIn: parent
        running: calculator ? calculator.calculating : false
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
            contentWidth: parent.width
            contentHeight: mainLayout.height
            bottomMargin: 5
            
            ColumnLayout {
                id: mainLayout
                width: parent.width
                
                RowLayout {
                    width: parent.width
                    Layout.leftMargin: 5
                    Layout.rightMargin: 5
                    Layout.topMargin: 5
                    
                    Label {
                        text: "Transform Calculator"
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
                    Layout.leftMargin: 5
                    Layout.rightMargin: 5
                    spacing: 10

                    // Left column - inputs
                    ColumnLayout {
                        Layout.preferredWidth: 400
                        Layout.fillWidth: false

                        // Transform selection
                        WaveCard {
                            title: "Transform Type"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 280

                            ColumnLayout {
                                anchors.fill: parent
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 5
                                    Layout.leftMargin: 10
                                    
                                    RadioButton {
                                        id: fourierRadio
                                        text: "Fourier Transform"
                                        checked: true
                                        onCheckedChanged: {
                                            if (checked) {
                                                calculator.setTransformType("Fourier")
                                            }
                                        }
                                    }
                                    
                                    RadioButton {
                                        id: laplaceRadio
                                        text: "Laplace Transform"
                                        onCheckedChanged: {
                                            if (checked) {
                                                calculator.setTransformType("Laplace")
                                            }
                                        }
                                    }
                                }

                                Label { 
                                    text: "Function Selection"
                                    Layout.fillWidth: true
                                    font.bold: true
                                    font.pixelSize: 16
                                }

                                ComboBoxRound {
                                    id: functionTypeCombo
                                    model: calculator.functionTypes
                                    onCurrentTextChanged: calculator.setFunctionType(currentText)
                                    Layout.minimumWidth: 270
                                    Layout.margins: 10
                                }
                                
                                TextFieldBlue {
                                    id: equationField
                                    text: calculator ? calculator.equationOriginal : ""
                                    readOnly: true
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    Layout.bottomMargin: 10
                                    font.italic: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        // Function parameters
                        WaveCard {
                            title: "Function Parameters"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 500

                            GridLayout {
                                id: parametersGrid
                                columns: 2
                                anchors.fill: parent

                                Label { 
                                    text: getFunctionParameterALabel()
                                    Layout.minimumWidth: 150
                                }
                                
                                SpinBoxRound {
                                    id: parameterASpinBox
                                    from: -50
                                    to: 50
                                    value: calculator.parameterA * 10
                                    stepSize: 1
                                    editable: true
                                    Layout.fillWidth: true
                                    
                                    property real realValue: value / 10.0
                                    
                                    onValueChanged: calculator.setParameterA(realValue)
                                    
                                    onValueModified: {
                                        calculator.setParameterA(realValue)
                                    }
                                    
                                    onRealValueChanged: {
                                        calculator.setParameterA(realValue)
                                    }
                                    
                                    textFromValue: function(value) {
                                        return (value / 10.0).toFixed(1);
                                    }
                                    
                                    valueFromText: function(text) {
                                        return Math.round(parseFloat(text) * 10);
                                    }
                                    
                                    Keys.onPressed: function(event) {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            calculator.setParameterA(realValue)
                                            event.accepted = true
                                        }
                                    }
                                }

                                Label { 
                                    text: getFunctionParameterBLabel()
                                    Layout.minimumWidth: 150
                                    visible: needsParameterB()
                                }
                                
                                SpinBoxRound {
                                    id: parameterBSpinBox
                                    from: 1
                                    to: 200
                                    value: calculator.parameterB * 10
                                    stepSize: 1
                                    editable: true
                                    Layout.fillWidth: true
                                    visible: needsParameterB()
                                    
                                    property real realValue: value / 10.0
                                    
                                    onValueChanged: calculator.setParameterB(realValue)
                                    
                                    onValueModified: {
                                        calculator.setParameterB(realValue)
                                    }
                                    
                                    onRealValueChanged: {
                                        calculator.setParameterB(realValue)
                                    }
                                    
                                    textFromValue: function(value) {
                                        return (value / 10.0).toFixed(1);
                                    }
                                    
                                    valueFromText: function(text) {
                                        return Math.round(parseFloat(text) * 10);
                                    }
                                    
                                    Keys.onPressed: function(event) {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            calculator.setParameterB(realValue)
                                            event.accepted = true
                                        }
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
                                    value: calculator.frequency * 10
                                    stepSize: 1
                                    editable: true
                                    Layout.fillWidth: true
                                    visible: needsFrequency()
                                    
                                    property real realValue: value / 10.0
                                    
                                    // Fix the update behavior
                                    onValueModified: {
                                        // This is called when Enter is pressed or editing is done
                                        calculator.setFrequency(realValue)
                                    }
                                    
                                    onRealValueChanged: {
                                        // Explicitly update values when changed via arrows
                                        calculator.setFrequency(realValue)
                                    }
                                    
                                    // Keep existing formatting functions
                                    textFromValue: function(value) {
                                        return (value / 10.0).toFixed(1);
                                    }
                                    
                                    valueFromText: function(text) {
                                        return Math.round(parseFloat(text) * 10);
                                    }
                                    
                                    // Add key event handling for immediate update on Enter
                                    Keys.onPressed: function(event) {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            calculator.setFrequency(realValue)
                                            event.accepted = true
                                        }
                                    }
                                }

                                Label { 
                                    text: "Sample Points:" 
                                    Layout.minimumWidth: 150
                                }
                                
                                SpinBoxRound {
                                    id: samplePointsSpinBox
                                    from: 100
                                    to: 1000
                                    value: 500
                                    stepSize: 100
                                    editable: true
                                    Layout.fillWidth: true
                                    
                                    onValueChanged: calculator.setSamplePoints(value)
                                    
                                    onValueModified: {
                                        calculator.setSamplePoints(value)
                                    }
                                    
                                    Keys.onPressed: function(event) {
                                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            calculator.setSamplePoints(value)
                                            event.accepted = true
                                        }
                                    }
                                }

                                Label { 
                                    text: "Show phase:" 
                                    Layout.minimumWidth: 150
                                }
                                
                                CheckBox {
                                    id: showPhaseCheckbox
                                    checked: true
                                    Layout.fillWidth: true
                                }

                                // Performance options
                                Label { 
                                    text: "Performance Options:" 
                                    font.bold: true
                                    Layout.columnSpan: 2
                                    Layout.topMargin: 10
                                }
                                
                                CheckBox {
                                    id: performanceModeCheckbox
                                    text: "High performance mode"
                                    checked: true
                                    Layout.columnSpan: 2
                                    
                                    ToolTip.text: "Optimizes rendering for better performance"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
                                }

                                // Phase information button - update to show for both Fourier and Laplace
                                Button {
                                    id: phaseInfoButton
                                    text: fourierRadio.checked ? "Phase Information" : "Laplace Transform Info"
                                    icon.source: "../../../icons/rounded/info.svg"
                                    // Make visible for both Fourier sine waves and any Laplace transform
                                    visible: (functionTypeCombo.currentText === "Sine" && fourierRadio.checked) || 
                                            laplaceRadio.checked
                                    Layout.columnSpan: 2
                                    Layout.topMargin: 10
                                    Layout.alignment: Qt.AlignHCenter
                                    
                                    onClicked: {
                                        if (fourierRadio.checked) {
                                            phaseInfoPopup.open()
                                        } else {
                                            laplaceInfoPopup.open()
                                        }
                                    }
                                }
                                
                                Label {
                                    text: "Chart Information:"
                                    font.bold: true
                                    Layout.columnSpan: 2
                                    Layout.topMargin: 10
                                }
                                
                                TextArea {
                                    readOnly: true
                                    text: "The visualization shows:\n• Top chart: Time domain signal\n• Bottom chart: " + 
                                          (calculator.transformType === "Fourier" ? 
                                           "Frequency domain with magnitude and phase" : 
                                           "s-domain with magnitude and phase")
                                    wrapMode: TextEdit.Wrap
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    background: Rectangle {
                                        color: "transparent"
                                    }
                                }
                                
                                Button {
                                    text: "Refresh Charts"
                                    icon.source: "../../../icons/rounded/refresh.svg"
                                    Layout.columnSpan: 2
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: 10
                                    
                                    onClicked: {
                                        calculator.calculate()
                                    }
                                }
                            }
                        }
                        
                        WaveCard {
                            title: "Mathematical Background"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 200
                            
                            ScrollView {
                                anchors.fill: parent
                                clip: true
                                
                                TextArea {
                                    id: educationalText
                                    readOnly: true
                                    wrapMode: TextEdit.Wrap
                                    textFormat: TextEdit.RichText
                                    text: getEducationalContent()
                                }
                            }
                        }
                    }

                    WaveCard {
                        id: results
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 600
                        
                        title: "Transform Results"
                        showSettings: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10
                            
                            // Add a prominent display of the resonant frequency
                            Rectangle {
                                id: resonanceDisplay
                                Layout.fillWidth: true
                                Layout.margins: 5
                                Layout.preferredHeight: 30
                                radius: 5
                                color: "#1A2196F3"  // Light blue background
                                border.color: "#2196F3"
                                border.width: 1
                                visible: calculator && calculator.transformType === "Laplace" && calculator.resonantFrequency > 0
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (calculator && calculator.resonantFrequency > 0) {
                                            let omega = calculator.resonantFrequency;
                                            let freq = omega/(2*Math.PI);
                                            return "Resonant frequency: " + omega.toFixed(1) + " rad/s (" + freq.toFixed(1) + " Hz)";
                                        }
                                        return "";
                                    }
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: textColor
                                }
                            }
                            
                            TextFieldBlue {
                                id: transformEquationField
                                text: calculator ? calculator.equationTransform : ""
                                readOnly: true
                                Layout.fillWidth: true
                                Layout.margins: 10
                                font.italic: true
                                horizontalAlignment: Text.AlignHCenter
                                ToolTip.text: "Transform equation"
                                ToolTip.visible: hovered
                            }
                            
                            TransformChart {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                
                                timeDomain: calculator.timeDomain ? calculator.timeDomain : []
                                transformResult: calculator.transformResult ? calculator.transformResult : []
                                phaseResult: calculator.phaseResult ? calculator.phaseResult : []
                                frequencies: calculator.frequencies ? calculator.frequencies : []
                                showPhase: showPhaseCheckbox.checked
                                transformType: calculator.transformType
                                resonantFrequency: calculator.resonantFrequency  // Fixed the property
                                
                                // Add performance mode property if supported by the TransformViz component
                                highPerformanceMode: performanceModeCheckbox.checked
                                
                                darkMode: Universal.theme === Universal.Dark
                                textColor: transformCard.textColor
                            }
                        }
                    }
                }
            }
        }
    }
    
    function getFunctionParameterALabel() {
        switch(functionTypeCombo.currentText) {
            case "Sine":
            case "Square":
            case "Sawtooth":
            case "Damped Sine":
                return "Amplitude:"
            case "Exponential":
                return "Magnitude:"
            case "Gaussian":
                return "Peak Height:"
            case "Step":
                return "Step Height:"
            case "Impulse":
                return "Impulse Height:"
            default:
                return "Parameter A:"
        }
    }
    
    function getFunctionParameterBLabel() {
        switch(functionTypeCombo.currentText) {
            case "Exponential":
            case "Damped Sine":
                return "Damping Factor:"
            case "Gaussian":
                return "Center Position:"
            case "Step":
                return "Step Position:"
            case "Impulse":
                return "Impulse Position:"
            default:
                return "Parameter B:"
        }
    }
    
    function needsParameterB() {
        switch(functionTypeCombo.currentText) {
            case "Sine":
            case "Square":
            case "Sawtooth":
                return false;
            default:
                return true;
        }
    }
    
    function needsFrequency() {
        switch(functionTypeCombo.currentText) {
            case "Sine":
            case "Square":
            case "Sawtooth":
            case "Damped Sine":
                return true;
            default:
                return false;
        }
    }
    
    function getEducationalContent() {
        if (calculator.transformType === "Fourier") {
            let baseContent = "<h3>Fourier Transform</h3>" +
                   "<p>The Fourier Transform decomposes a signal into its frequency components:</p>" +
                   "<p style='text-align: center'><b>F(ω) = ∫<sub>-∞</sub><sup>∞</sup> f(t)·e<sup>-jωt</sup> dt</b></p>" +
                   "<p>It is used in:</p>" +
                   "<ul>" +
                   "<li>Signal analysis and processing</li>" +
                   "<li>Electronic filter design</li>" +
                   "<li>Communications systems</li>" +
                   "<li>Audio processing and analysis</li>" +
                   "</ul>" +
                   "<p>For periodic signals, we can also use the Fourier Series:</p>" +
                   "<p style='text-align: center'>f(t) = a<sub>0</sub>/2 + Σ [a<sub>n</sub>·cos(nωt) + b<sub>n</sub>·sin(nωt)]</p>";
            
            if (functionTypeCombo.currentText === "Sine") {
                baseContent += "<h4>Phase of Sine Waves</h4>" +
                    "<p>For a pure sine wave sin(ωt), the Fourier transform is:</p>" +
                    "<p style='text-align: center'>F(ω) = (i/2)[δ(ω-ω₀) - δ(ω+ω₀)]</p>" +
                    "<p>This results in two impulses in the frequency domain:</p>" +
                    "<ul>" +
                    "<li>Positive frequency: phase = -90°</li>" +
                    "<li>Negative frequency: phase = +90°</li>" +
                    "</ul>" +
                    "<p>In practical FFT calculations, the phase appears jagged due to numerical calculation artifacts, especially where magnitude approaches zero.</p>";
            }
            
            return baseContent;
        } else {
            return "<h3>Laplace Transform</h3>" +
                   "<p>The Laplace Transform converts a time-domain function into a complex frequency domain function:</p>" +
                   "<p style='text-align: center'><b>F(s) = ∫<sub>0</sub><sup>∞</sup> f(t)·e<sup>-st</sup> dt</b></p>" +
                   "<p>It is used in:</p>" +
                   "<ul>" +
                   "<li>Solving differential equations</li>" +
                   "<li>Control systems engineering</li>" +
                   "<li>Circuit analysis</li>" +
                   "<li>System stability analysis</li>" +
                   "<li>Transient response analysis</li>" +
                   "</ul>" +
                   "<p>Where s = σ + jω is a complex number. The real part (σ) represents damping, and the imaginary part (ω) represents frequency.</p>";
        }
    }
}
