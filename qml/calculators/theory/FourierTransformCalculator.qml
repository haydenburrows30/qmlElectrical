import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../components"
import "../../components/buttons"
import "../../components/style"
import "../../components/charts"

import TransformCalculator 1.0

Item {
    id: fourierCalculatorCard
    
    property bool darkMode: Universal.theme === Universal.Dark
    
    // TransformCalculator instance
    TransformCalculator {
        id: calculator
        transformType: "Fourier"
    }
    
    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            id: flickableContainer
            contentWidth: parent.width
            contentHeight: mainLayout.height + 20
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5
            
            ColumnLayout {
                id: mainLayout
                width: flickableContainer.width - 20
                
                // Title
                RowLayout {
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Fourier Transform"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    StyledButton {
                        id: infoButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Information about Fourier transforms"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: infoPopup.open()
                    }
                }
                
                // Function selection and parameters
                WaveCard {
                    title: "Function"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 180
                    
                    GridLayout {
                        columns: 2
                        anchors.fill: parent
                        anchors.margins: 10
                        columnSpacing: 10
                        rowSpacing: 10
                        
                        Label {
                            text: "Function Type:"
                            Layout.fillWidth: true
                        }
                        
                        ComboBoxRound {
                            id: functionTypeCombo
                            model: calculator.functionTypes
                            currentIndex: calculator.functionTypes.indexOf(calculator.functionType)
                            Layout.fillWidth: true
                            onCurrentTextChanged: {
                                calculator.setFunctionType(currentText)
                            }
                        }
                        
                        Label {
                            text: "Amplitude (A):"
                            Layout.fillWidth: true
                        }
                        
                        TextFieldRound {
                            id: parameterAInput
                            text: calculator.parameterA.toFixed(2)
                            Layout.fillWidth: true
                            validator: DoubleValidator {
                                bottom: -1000.0
                                top: 1000.0
                                decimals: 2
                                notation: DoubleValidator.StandardNotation
                            }
                            onTextChanged: {
                                if (text) {
                                    calculator.setParameterA(parseFloat(text))
                                }
                            }
                        }
                        
                        Label {
                            text: "Parameter (B):"
                            Layout.fillWidth: true
                        }
                        
                        TextFieldRound {
                            id: parameterBInput
                            text: calculator.parameterB.toFixed(2)
                            Layout.fillWidth: true
                            validator: DoubleValidator {
                                bottom: 0.01
                                top: 1000.0
                                decimals: 2
                                notation: DoubleValidator.StandardNotation
                            }
                            onTextChanged: {
                                if (text) {
                                    calculator.setParameterB(parseFloat(text))
                                }
                            }
                        }
                        
                        Label {
                            text: "Frequency (Hz):"
                            Layout.fillWidth: true
                        }
                        
                        TextFieldRound {
                            id: frequencyInput
                            text: calculator.frequency.toFixed(2)
                            Layout.fillWidth: true
                            validator: DoubleValidator {
                                bottom: 0.1
                                top: 1000.0
                                decimals: 2
                                notation: DoubleValidator.StandardNotation
                            }
                            onTextChanged: {
                                if (text) {
                                    calculator.setFrequency(parseFloat(text))
                                }
                            }
                        }
                        
                        Label {
                            text: "Sample Points:"
                            Layout.fillWidth: true
                        }
                        
                        TextFieldRound {
                            id: samplePointsInput
                            text: calculator.samplePoints
                            Layout.fillWidth: true
                            validator: IntValidator {
                                bottom: 100
                                top: 2000
                            }
                            onTextChanged: {
                                if (text) {
                                    calculator.setSamplePoints(parseInt(text))
                                }
                            }
                        }
                        
                        Label {
                            text: "Window Function:"
                            Layout.fillWidth: true
                        }
                        
                        ComboBoxRound {
                            id: windowTypeCombo
                            model: calculator.windowTypes
                            currentIndex: calculator.windowTypes.indexOf(calculator.windowType)
                            Layout.fillWidth: true
                            onCurrentTextChanged: {
                                calculator.setWindowType(currentText)
                            }
                        }
                    }
                }
                
                // Equation display
                WaveCard {
                    title: "Equations"
                    Layout.fillWidth: true
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10
                        
                        Label {
                            text: "Time Domain Function:"
                            font.bold: true
                        }
                        
                        Label {
                            text: calculator.equationOriginal
                            Layout.fillWidth: true
                            font.family: "Monospace"
                        }
                        
                        Label {
                            text: "Fourier Transform:"
                            font.bold: true
                            Layout.topMargin: 10
                        }
                        
                        Label {
                            text: calculator.equationTransform
                            Layout.fillWidth: true
                            font.family: "Monospace"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
                
                // Transform visualization
                WaveCard {
                    title: "Signal Visualization"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 500
                    
                    TransformChart {
                        anchors.fill: parent
                        anchors.margins: 10
                        timeDomain: calculator.timeDomain
                        transformResult: calculator.transformResult
                        phaseResult: calculator.phaseResult
                        frequencies: calculator.frequencies
                        transformType: calculator.transformType
                        showPhase: true
                        darkMode: fourierCalculatorCard.darkMode
                        isCalculating: calculator.calculating
                    }
                }
            }
        }
    }
    
    // Information popup
    Popup {
        id: infoPopup
        width: parent.width * 0.8
        height: parent.height * 0.7
        anchors.centerIn: Overlay.overlay
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            
            Label {
                text: "Fourier Transform and Window Functions"
                font.bold: true
                font.pixelSize: 16
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                TextArea {
                    text: "The Fourier Transform converts a time domain signal into its frequency domain representation.\n\n" +
                          "Window Functions:\n\n" +
                          "• None (Rectangular): No windowing applied. May cause spectral leakage due to discontinuities at signal edges.\n\n" +
                          "• Hann: Good general-purpose window with moderate spectral leakage reduction.\n\n" +
                          "• Hamming: Modified Hann window with improved sidelobe suppression.\n\n" +
                          "• Blackman: Excellent sidelobe suppression at the cost of a wider main lobe.\n\n" +
                          "• Bartlett: Triangular window with linear tapering to zero at both ends.\n\n" +
                          "• Flattop: Provides excellent amplitude accuracy at the cost of poor frequency resolution.\n\n" +
                          "• Kaiser: Parameterized window with adjustable sidelobe levels.\n\n" +
                          "• Gaussian: Bell-shaped window with minimal time-bandwidth product.\n\n" +
                          "• Tukey: Combines rectangular window with cosine tapered edges."
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    background: null
                }
            }
            
            Button {
                text: "Close"
                Layout.alignment: Qt.AlignHCenter
                onClicked: infoPopup.close()
            }
        }
    }
}
