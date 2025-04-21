import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import TransformerNamingGuide 1.0

Item {
    id: transformerNamingCard

    property color textColor: Universal.foreground

    property TransformerNamingGuide calculator : TransformerNamingGuide {}

    PopUpText {
        id: helpPopup
        parentCard: helpButton
        popupText: "<h3>Transformer Naming Guide</h3><br>" +
                   "This tool explains the naming conventions for current transformers (CTs) and voltage transformers (VTs).<br><br>" +
                   "Select the transformer parameters to see how the naming works according to different standards and manufacturers.<br><br>" +
                   "The diagram shows the physical representation of the transformer and its key parameters.<br><br>" +
                   "Understanding the naming conventions helps in selecting the right transformer for your application."
        widthFactor: 0.5
        heightFactor: 0.5
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentHeight: mainLayout.height + 20
            contentWidth: parent.width
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            ColumnLayout {
                id: mainLayout
                width: scrollView.width - 10
                spacing: 10

                // Header with title and help button
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 5
                    Layout.leftMargin: 5

                    Label {
                        text: "Instrument Transformer Naming Guide"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Information"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500

                        onClicked: helpPopup.open()
                    }
                }

                // Main content layout
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    // Left side - Inputs
                    WaveCard {
                        title: "Transformer Parameters"
                        Layout.minimumWidth: 350
                        Layout.fillHeight: true
                        
                        GridLayout {
                            columns: 2
                            columnSpacing: 10
                            rowSpacing: 10
                            width: parent.width

                            Label { 
                                text: "Transformer Type:" 
                                Layout.minimumWidth: 150
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                StyledButton {
                                    text: "CT"
                                    checkable: true
                                    checked: calculator.transformerType === "CT"
                                    Layout.fillWidth: true
                                    onClicked: calculator.transformerType = "CT"
                                }
                                StyledButton {
                                    text: "VT"
                                    checkable: true
                                    checked: calculator.transformerType === "VT"
                                    Layout.fillWidth: true
                                    onClicked: calculator.transformerType = "VT"
                                }
                            }

                            // Primary rating - different label for CT vs VT
                            Label { 
                                text: calculator.transformerType === "CT" ? 
                                      "Primary Current (A):" : 
                                      "Primary Voltage (V):" 
                            }
                            ComboBoxRound {
                                id: primaryRating
                                model: calculator.transformerType === "CT" ? 
                                       calculator.getRatedCurrents() : 
                                       calculator.getRatedVoltages()
                                currentIndex: model.indexOf(calculator.transformerType === "CT" ? 
                                              calculator.ratedCurrent : 
                                              calculator.ratedVoltage)
                                Layout.fillWidth: true
                                onCurrentTextChanged: {
                                    if (calculator.transformerType === "CT") {
                                        calculator.ratedCurrent = currentText
                                    } else {
                                        calculator.ratedVoltage = currentText
                                    }
                                }
                            }

                            // Secondary rating
                            Label { 
                                text: calculator.transformerType === "CT" ? 
                                      "Secondary Current (A):" : 
                                      "Secondary Voltage (V):" 
                            }
                            ComboBoxRound {
                                id: secondaryRating
                                model: calculator.getSecondaryRatings()
                                currentIndex: model.indexOf(calculator.secondaryRating)
                                Layout.fillWidth: true
                                onCurrentTextChanged: calculator.secondaryRating = currentText
                            }

                            // Accuracy class
                            Label { text: "Accuracy Class:" }
                            ComboBoxRound {
                                id: accuracyClass
                                model: calculator.getAccuracyClasses()
                                currentIndex: model.indexOf(calculator.accuracyClass)
                                Layout.fillWidth: true
                                onCurrentTextChanged: calculator.accuracyClass = currentText
                            }

                            // Burden
                            Label { text: "Burden (VA):" }
                            TextFieldRound {
                                id: burden
                                text: calculator.burden
                                Layout.fillWidth: true
                                validator: DoubleValidator {
                                    bottom: 1.0
                                    top: 100.0
                                    notation: DoubleValidator.StandardNotation
                                }
                                onTextChanged: {
                                    if (acceptableInput) {
                                        calculator.burden = text
                                    }
                                }
                            }

                            // Insulation level
                            Label { text: "Insulation Level (kV):" }
                            ComboBoxRound {
                                id: insulation
                                model: calculator.getInsulationLevels()
                                currentIndex: model.indexOf(calculator.insulationLevel)
                                Layout.fillWidth: true
                                onCurrentTextChanged: calculator.insulationLevel = currentText
                            }

                            // Application
                            Label { text: "Application:" }
                            ComboBoxRound {
                                id: application
                                model: calculator.getApplications()
                                currentIndex: model.indexOf(calculator.application)
                                Layout.fillWidth: true
                                onCurrentTextChanged: calculator.application = currentText
                            }

                            // Installation
                            Label { text: "Installation:" }
                            ComboBoxRound {
                                id: installation
                                model: calculator.getInstallations()
                                currentIndex: model.indexOf(calculator.installation)
                                Layout.fillWidth: true
                                onCurrentTextChanged: calculator.installation = currentText
                            }

                            // Frequency
                            Label { text: "Frequency (Hz):" }
                            ComboBoxRound {
                                id: frequency
                                model: calculator.getFrequencies()
                                currentIndex: model.indexOf(calculator.frequency)
                                Layout.fillWidth: true
                                onCurrentTextChanged: calculator.frequency = currentText
                            }

                            // Thermal rating
                            Label { text: "Thermal Rating Factor:" }
                            ComboBoxRound {
                                id: thermal
                                model: calculator.getThermalRatings()
                                currentIndex: model.indexOf(calculator.thermalRating)
                                Layout.fillWidth: true
                                onCurrentTextChanged: calculator.thermalRating = currentText
                            }
                        }
                    }

                    // Right side - Results and visualization
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Naming results
                        WaveCard {
                            title: "Transformer Name"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 230
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                ScrollView {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: 100
                                    clip: true

                                    Rectangle {
                                        anchors.fill: parent
                                        color: darkMode ? "#2a2a2a" : "#f0f0f0"
                                        border.width: 1
                                        border.color: darkMode ? "#404040" : "#d0d0d0"
                                        radius: 4

                                        TextEdit {
                                            id: outputText
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            text: calculator.outputName
                                            color: textColor
                                            readOnly: true
                                            wrapMode: TextEdit.WordWrap
                                            selectByMouse: true
                                            font.family: "Monospace"
                                            font.pixelSize: 14
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignRight
                                    StyledButton {
                                        text: "Copy"
                                        icon.source: "../../../icons/rounded/copy_all.svg"
                                        onClicked: {
                                            outputText.selectAll()
                                            outputText.copy()
                                            outputText.deselect()
                                        }
                                    }
                                }
                            }
                        }

                        // Visual representation
                        WaveCard {
                            title: "Transformer Visualization " + (calculator.transformerType === "CT" ? "Current Transformer" : "Voltage Transformer")
                            Layout.fillWidth: true
                            Layout.minimumHeight: 400

                            // CT or VT visualization based on selected type
                            InstrumentTxViz {
                                id: visualizationContainer
                                anchors.fill: parent

                                transformerType: calculator.transformerType
                                primaryRating: calculator.transformerType === "CT" ? 
                                                calculator.ratedCurrent : calculator.ratedVoltage
                                secondaryRating: calculator.secondaryRating
                                accuracyClass: calculator.accuracyClass
                                burden: calculator.burden
                                insulationLevel: calculator.insulationLevel
                                application: calculator.application
                                darkMode: transformerNamingCard.darkMode
                            }
                        }

                        // Explanation of naming parts
                        WaveCard {
                            title: "Naming Convention Explanation"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 250
                            
                            ScrollView {
                                anchors.fill: parent
                                anchors.margins: 10
                                clip: true

                                Text {
                                    width: parent.width
                                    text: calculator.description
                                    color: textColor
                                    wrapMode: Text.WordWrap
                                    textFormat: Text.RichText
                                    font.pixelSize: 14
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
