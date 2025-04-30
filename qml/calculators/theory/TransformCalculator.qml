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

Item {
    id: transformCard

    property TransformCalculator t_calculator: TransformCalculator {}
    property color textColor: Universal.foreground
    property int waveHeight: 310
    property int calculationThrottleMs: 300
    property var throttleTimer: null

    // Message popup for notifications
    MessagePopup {
        id: messagePopup
        anchors.centerIn: parent
    }

    // Use a simple toast notification system
    function showToast(message, type = "info") {
        console.log(message);  // Simple fallback logging
        
        // Create a temporary notification element
        var component = Qt.createComponent("qrc:/qml/components/SimpleToast.qml");
        if (component.status === Component.Ready) {
            var toast = component.createObject(transformCard, {
                "message": message,
                "type": type
            });
            toast.show();
        }
    }

    // phase info
    PopUpText {
        id: phaseInfoPopup
        parentCard: functionParams
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
    
    // Laplace transform
    PopUpText {
        id: laplaceInfoPopup
        parentCard: functionParams
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
    
    // window function
    PopUpText {
        id: windowInfoPopup
        parentCard: functionParams
        popupText: "<h3>Window Functions in Fourier Transform</h3><br>" +
                   "Window functions help reduce spectral leakage when computing the Fourier transform of a signal:<br><br>" +
                   "<b>• None (Rectangular):</b> No windowing, may cause spectral leakage.<br>" +
                   "<b>• Hann:</b> Good all-purpose window with moderate leakage reduction.<br>" +
                   "<b>• Hamming:</b> Modified Hann with better sidelobe suppression.<br>" +
                   "<b>• Blackman:</b> Excellent sidelobe suppression, wider main lobe.<br>" +
                   "<b>• Bartlett:</b> Triangular window with linear tapering.<br>" +
                   "<b>• Flattop:</b> Excellent amplitude accuracy, poor frequency resolution.<br>" +
                   "<b>• Kaiser:</b> Parameterized window with adjustable sidelobe levels.<br>" +
                   "<b>• Gaussian:</b> Bell-shaped curve with minimal time-bandwidth product.<br>" +
                   "<b>• Tukey:</b> Combines rectangular with cosine-tapered edges.<br><br>" +
                   "<h4>Why Use Window Functions?</h4>" +
                   "• Reduces spectral leakage from discontinuities at signal edges<br>" +
                   "• Improves frequency resolution for some signal types<br>" +
                   "• Enhances detection of weaker spectral components<br>" +
                   "• Trade-off between spectral resolution and amplitude accuracy"
        widthFactor: 0.6
        heightFactor: 0.7
    }
    
    // main info
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

    // custom formula
    PopUpText {
        id: customFormulaHelpPopup
        parentCard: functionParams
        popupText: "<h3>Custom Waveform Formula Syntax</h3><br>" + 
                   "Enter a mathematical formula to create custom waveforms. You can combine multiple harmonics.<br><br>" +
                   "<b>Basic sine wave:</b><br>" +
                   "• sin(2*pi*f*t) - Sine wave at base frequency<br><br>" +
                   "<b>Adding harmonics:</b><br>" +
                   "• sin(2*pi*f*t) + 0.5*sin(2*2*pi*f*t) - Sine plus 2nd harmonic<br>" +
                   "• sin(1*w*t) + 0.3*sin(3*w*t) - First and third harmonic<br><br>" +
                   "<b>Shorthand:</b><br>" +
                   "• sin(t) - Sine at 1 Hz<br>" +
                   "• sin(w*t) - Sine at base frequency<br>" +
                   "• -0.5*sin(3*w*t) - Negative amplitude harmonic<br><br>" +
                   "<b>Variables:</b><br>" +
                   "• t - Time variable<br>" +
                   "• f - Base frequency value<br>" +
                   "• w - Angular frequency (w = 2*pi*f)<br>" +
                   "• pi - π constant (3.14159...)<br><br>" +
                   "<b>Examples:</b><br>" +
                   "• sin(w*t) + 0.5*sin(2*w*t) + 0.33*sin(3*w*t) + 0.25*sin(4*w*t)<br>" +
                   "• sin(2*pi*10*t) - 10 Hz sine wave<br>" +
                   "• sin(w*t) + 0.5*sin(3*w*t) - 0.25*sin(5*w*t) - Odd harmonics"
        widthFactor: 0.7
        heightFactor: 0.7
    }

    // loading indicator
    BusyIndicator {
        id: calculationIndicator
        anchors.centerIn: parent
        running: t_calculator ? t_calculator.calculating : false
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

                    // Left column - inputs
                    ColumnLayout {
                        Layout.preferredWidth: 400
                        Layout.fillWidth: false

                        // Transform selection
                        WaveCard {
                            title: "Transform Type"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 250

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
                                                t_calculator.setTransformType("Fourier")
                                            }
                                        }
                                    }
                                    
                                    RadioButton {
                                        id: laplaceRadio
                                        text: "Laplace Transform"
                                        onCheckedChanged: {
                                            if (checked) {
                                                t_calculator.setTransformType("Laplace")
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

                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    ComboBoxRound {
                                        id: functionTypeCombo
                                        model: t_calculator.functionTypes
                                        onCurrentTextChanged: t_calculator.setFunctionType(currentText)
                                        Layout.fillWidth: true
                                    }

                                    // Phase information button - update to show for both Fourier and Laplace
                                    StyledButton {
                                        id: phaseInfoButton
                                        ToolTip.text: fourierRadio.checked ? "Phase Info" : "Laplace Info"
                                        ToolTip.visible: hovered
                                        ToolTip.delay: 500
                                        
                                        icon.source: "../../../icons/rounded/info.svg"
                                        // Make visible for both Fourier sine waves and any Laplace transform
                                        Layout.alignment: Qt.AlignRight
                                        visible: (functionTypeCombo.currentText === "Sine" && fourierRadio.checked) || 
                                                laplaceRadio.checked
                                        
                                        onClicked: {
                                            if (fourierRadio.checked) {
                                                phaseInfoPopup.open()
                                            } else {
                                                laplaceInfoPopup.open()
                                            }
                                        }
                                    }

                                    StyledButton {
                                        icon.source: "../../../icons/rounded/refresh.svg"
                                        ToolTip.text: "Refresh charts"
                                        ToolTip.visible: hovered
                                        ToolTip.delay: 500

                                        onClicked: {
                                            t_calculator.calculate()
                                        }
                                    }
                                }

                                TextFieldBlue {
                                    id: equationField
                                    text: t_calculator ? t_calculator.equationOriginal : ""
                                    Layout.fillWidth: true
                                    font.italic: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        // Function parameters
                        WaveCard {
                            id: functionParams
                            title: "Function Parameters"
                            Layout.fillWidth: true
                            Layout.minimumHeight: functionTypeCombo.currentText === "Custom" ? 440 : 250

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
                                    value: t_calculator.parameterA * 10
                                    stepSize: 1
                                    editable: true
                                    Layout.fillWidth: true
                                    
                                    property real realValue: value / 10.0

                                    onValueModified: t_calculator.setParameterA(realValue)
                                    
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
                                    text: getFunctionParameterBLabel()
                                    Layout.minimumWidth: 150
                                    visible: needsParameterB()
                                }
                                
                                SpinBoxRound {
                                    id: parameterBSpinBox
                                    from: 1
                                    to: 200
                                    value: t_calculator.parameterB * 10
                                    stepSize: 1
                                    editable: true
                                    Layout.fillWidth: true
                                    visible: needsParameterB()

                                    property real realValue: value / 10.0

                                    onValueModified: t_calculator.setParameterB(realValue)

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
                                    visible: needsFrequency() || functionTypeCombo.currentText === "Custom"
                                }
                                
                                SpinBoxRound {
                                    id: frequencySpinBox
                                    from: 1
                                    to: 1000
                                    value: t_calculator.frequency * 10
                                    stepSize: 1
                                    editable: true
                                    Layout.fillWidth: true
                                    visible: needsFrequency() || functionTypeCombo.currentText === "Custom"

                                    property real realValue: value / 10.0

                                    onValueModified: t_calculator.setFrequency(realValue)

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
                                    text: "Sample Points:" 
                                    Layout.minimumWidth: 150
                                }
                                
                                SpinBoxRound {
                                    id: samplePointsSpinBox
                                    from: 100
                                    to: 1000
                                    value: 500
                                    stepSize: 50
                                    editable: true
                                    Layout.fillWidth: true

                                    property real realValue: value

                                    onValueModified: t_calculator.setSamplePoints(value)

                                    textFromValue: function(value) {
                                        return value.toFixed(1);
                                    }
                                    
                                    valueFromText: function(text) {
                                        return Math.round(parseFloat(text));
                                    }

                                    validator: RegularExpressionValidator {
                                        regularExpression: /[0-9]*\.?[0-9]*/
                                    }
                                }
                                
                                // Window function selection - only visible for Fourier transform
                                Label { 
                                    text: "Window Function:" 
                                    Layout.minimumWidth: 150
                                    visible: fourierRadio.checked
                                }
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: fourierRadio.checked
                                    
                                    ComboBoxRound {
                                        id: windowTypeCombo
                                        model: t_calculator.windowTypes
                                        currentIndex: t_calculator.windowTypes.indexOf(t_calculator.windowType)
                                        Layout.fillWidth: true
                                        onCurrentTextChanged: {
                                            t_calculator.setWindowType(currentText)
                                        }
                                    }
                                    
                                    StyledButton {
                                        icon.source: "../../../icons/rounded/info.svg"
                                        ToolTip.text: "Window Function Information"
                                        ToolTip.visible: hovered
                                        ToolTip.delay: 500
                                        onClicked: windowInfoPopup.open()
                                    }
                                }

                                // Custom formula editor (only visible for Custom function type)
                                Label { 
                                    text: "Custom Formula:" 
                                    font.bold: true
                                    Layout.columnSpan: 2
                                    visible: functionTypeCombo.currentText === "Custom"
                                    Layout.topMargin: 10
                                }
                                
                                RowLayout {
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    visible: functionTypeCombo.currentText === "Custom"
                                    
                                    TextArea {
                                        id: customFormulaEditor
                                        text: t_calculator.customFormula
                                        placeholderText: "Enter formula (e.g., sin(w*t) + 0.5*sin(2*w*t))"
                                        wrapMode: TextEdit.Wrap
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 60
                                        font.family: "Courier"
                                        
                                        onTextChanged: {
                                            // Use a timer to avoid updating during typing
                                            updateFormulaTimer.restart()
                                        }
                                    }
                                    
                                    Timer {
                                        id: updateFormulaTimer
                                        interval: 500  // Half-second delay
                                        onTriggered: {
                                            t_calculator.setCustomFormula(customFormulaEditor.text)
                                        }
                                    }
                                    
                                    StyledButton {
                                        icon.source: "../../../icons/rounded/help.svg"
                                        ToolTip.text: "Custom Formula Help"
                                        ToolTip.visible: hovered
                                        ToolTip.delay: 500
                                        onClicked: customFormulaHelpPopup.open()
                                    }
                                }
                                
                                // Add preset formulas for custom waveforms
                                Label {
                                    text: "Preset Formulas:"
                                    visible: functionTypeCombo.currentText === "Custom"
                                    Layout.columnSpan: 2
                                }
                                
                                GridLayout {
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    visible: functionTypeCombo.currentText === "Custom"
                                    columns: 2
                                    columnSpacing: 5
                                    rowSpacing: 5
                                    
                                    Button {
                                        text: "Fundamental + 3 Harmonics"
                                        Layout.fillWidth: true
                                        onClicked: {
                                            customFormulaEditor.text = "sin(w*t) + 0.5*sin(2*w*t) + 0.33*sin(3*w*t) + 0.25*sin(4*w*t)"
                                            t_calculator.setCustomFormula(customFormulaEditor.text)
                                        }
                                    }
                                    
                                    Button {
                                        text: "Odd Harmonics Only"
                                        Layout.fillWidth: true
                                        onClicked: {
                                            customFormulaEditor.text = "sin(w*t) + 0.33*sin(3*w*t) + 0.2*sin(5*w*t) + 0.14*sin(7*w*t)"
                                            t_calculator.setCustomFormula(customFormulaEditor.text)
                                        }
                                    }
                                    
                                    Button {
                                        text: "Square Wave Approx."
                                        Layout.fillWidth: true
                                        onClicked: {
                                            customFormulaEditor.text = "sin(w*t) + sin(3*w*t)/3 + sin(5*w*t)/5 + sin(7*w*t)/7 + sin(9*w*t)/9"
                                            t_calculator.setCustomFormula(customFormulaEditor.text)
                                        }
                                    }
                                    
                                    Button {
                                        text: "Sawtooth Approx."
                                        Layout.fillWidth: true
                                        onClicked: {
                                            customFormulaEditor.text = "sin(w*t) - sin(2*w*t)/2 + sin(3*w*t)/3 - sin(4*w*t)/4 + sin(5*w*t)/5"
                                            t_calculator.setCustomFormula(customFormulaEditor.text)
                                        }
                                    }
                                }

                                Label {Layout.fillHeight: true}
                            }
                        }

                        WaveCard {
                            title: "Mathematical Background"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 300
                            
                            ScrollView {
                                anchors.fill: parent
                                clip: true
                                
                                TextArea {
                                    id: educationalText
                                    readOnly: true
                                    wrapMode: TextEdit.Wrap
                                    textFormat: TextEdit.RichText
                                    text: getEducationalContent()

                                    activeFocusOnPress: false

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

                            RowLayout {
                                Layout.fillWidth: true
                            
                                Label {
                                    text: "• Top chart: Time domain signal\n• Bottom chart: " + 
                                            (t_calculator.transformType === "Fourier" ? 
                                            "Frequency domain with magnitude and phase" : 
                                            "s-domain with magnitude and phase")
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                }

                                // Export PDF Button
                                Button {
                                    text: "Export PDF"
                                    icon.source: "../../../icons/rounded/download.svg"
                                    ToolTip.text: "Export results to PDF"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
                                    
                                    onClicked: {
                                        // Call export_to_pdf directly on the calculator instance
                                        t_calculator.export_to_pdf()
                                    }
                                }
                                
                                // Export Plot Button
                                Button {
                                    text: "Export Plot"
                                    icon.source: "../../../icons/rounded/image.svg"
                                    ToolTip.text: "Export plot as image"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
                                    
                                    onClicked: {
                                        // Use the calculator's plot export function directly
                                        t_calculator.generate_plot_for_file_saver()
                                    }
                                }

                                // Add a prominent display of the resonant frequency
                                Rectangle {
                                    id: resonanceDisplay
                                    Layout.minimumWidth: 350
                                    Layout.preferredHeight: 30
                                    radius: 5
                                    color: "#1A2196F3"  // Light blue background
                                    border.color: "#2196F3"
                                    border.width: 1
                                    visible: t_calculator && t_calculator.transformType === "Laplace" && t_calculator.resonantFrequency > 0
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: {
                                            if (t_calculator && t_calculator.resonantFrequency > 0) {
                                                let omega = t_calculator.resonantFrequency;
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

                                // Add window function info display
                                Rectangle {
                                    id: windowDisplay
                                    Layout.minimumWidth: 200
                                    Layout.preferredHeight: 30
                                    radius: 5
                                    color: "#1A4CAF50"  // Light green background
                                    border.color: "#4CAF50"
                                    border.width: 1
                                    visible: t_calculator && 
                                            t_calculator.transformType === "Fourier" && 
                                            t_calculator.windowType !== "None"
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: t_calculator && t_calculator.windowType !== "None" ? 
                                            "Window Function: " + t_calculator.windowType : ""
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: textColor
                                    }
                                }
                            }

                            TextAreaBlue {
                                id: transformEquationField
                                text: t_calculator ? t_calculator.equationTransform : ""
                                font.italic: true
                                horizontalAlignment: Text.AlignHCenter
                                ToolTip.text: "Transform equation"
                                ToolTip.visible: hovered
                                ToolTip.delay: 500
                                Layout.minimumHeight: 30
                                readOnly: true
                                activeFocusOnPress: false
                            }

                            TransformChart {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                
                                timeDomain: t_calculator.timeDomain ? t_calculator.timeDomain : []
                                transformResult: t_calculator.transformResult ? t_calculator.transformResult : []
                                phaseResult: t_calculator.phaseResult ? t_calculator.phaseResult : []
                                frequencies: t_calculator.frequencies ? t_calculator.frequencies : []
                                
                                transformType: t_calculator.transformType
                                resonantFrequency: t_calculator.resonantFrequency
                                windowType: t_calculator.windowType
                                
                                darkMode: Universal.theme === Universal.Dark
                                textColor: transformCard.textColor

                                calculator: t_calculator
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
            case "Custom":  // Add custom type to the frequency-needing functions
                return true;
            default:
                return false;
        }
    }
    
    function getEducationalContent() {
        if (t_calculator.transformType === "Fourier") {
            let baseContent = "<h3>Fourier Transform</h3>" +
                   "<p>The Fourier Transform decomposes a signal into its frequency components:</p>" +
                   "<p style='text-align: center'><b>F(ω) = ∫<sub>-∞</sub><sup>∞</sup> f(t)·e<sup>-jωt</sup> dt</b></p>" +
                   "<p>It is used in:</p>" +
                   "<ul>" +
                   "<li>Signal analysis and processing</li>" +
                   "<li>Electronic filter design</li>" +
                   "<li>Communications systems</li>" +
                   "<li>Audio processing and analysis</li>" +
                   "</ul>";
            
            // Add custom information when using Custom function type
            if (functionTypeCombo.currentText === "Custom") {
                baseContent += "<h4>Custom Waveforms & Harmonics</h4>" +
                    "<p>In a Fourier transform, harmonics appear as distinct peaks at multiples of the fundamental frequency:</p>" +
                    "<ul>" +
                    "<li>A pure sine wave has only one frequency component</li>" +
                    "<li>Complex periodic waves contain multiple harmonic components</li>" +
                    "<li>The shape of a waveform is determined by its harmonic content</li>" +
                    "<li>Even harmonics (2f, 4f, 6f...) create symmetry around y-axis</li>" +
                    "<li>Odd harmonics (3f, 5f, 7f...) create half-wave symmetry</li>" +
                    "</ul>";
            }
                   
            // Add window function explanation when a window is selected
            if (t_calculator.windowType !== "None") {
                baseContent += "<h4>Window Functions</h4>" +
                    "<p>Window functions reduce spectral leakage in the Fourier transform. The current window (" + 
                    t_calculator.windowType + ") applies a shaped envelope to the time domain signal before transformation.</p>" +
                    "<p>Benefits of windowing:</p>" +
                    "<ul>" +
                    "<li>Reduces sidelobe levels in frequency spectrum</li>" +
                    "<li>Improves detection of weaker frequency components</li>" +
                    "<li>Trades frequency resolution for amplitude accuracy</li>" +
                    "</ul>";
            }
            
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
    
    // Connect to PDF export status signals
    Connections {
        target: t_calculator
        function onPdfExportStatusChanged(success, message) {
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
    }

    // Initialize UI with current t_calculator values
    Component.onCompleted: {
        // Get window type if available
        if (t_calculator && t_calculator.windowTypes) {
            windowTypeCombo.model = t_calculator.windowTypes;
            windowTypeCombo.currentIndex = t_calculator.windowTypes.indexOf(t_calculator.windowType);
        }

        // Check if the popup needs to be parented to the Overlay
        if (typeof Overlay !== 'undefined') {
            messagePopup.parent = Overlay.overlay
        }
    }
}
