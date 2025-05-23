import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components/buttons"
import "../../components/popups"
import "../../components/style"

import HarmonicAnalysis 1.0

ColumnLayout {
    id: harmonicInputForm
    
    property HarmonicAnalysisCalculator calculator
    signal resetTriggered

    function safeSetHarmonic(order, magnitude, angle) {
        if (calculator) {
            calculator.setHarmonic(order, magnitude, angle);
        }
    }

    RowLayout {
        
        Label { text: "Harmonic"; Layout.preferredWidth: 120; font.bold: true }
        Label { text: "Magnitude"; Layout.preferredWidth: 120; font.bold: true }
        Label { text: "Phase"; Layout.preferredWidth: 120; font.bold: true }
    }
    
    Repeater {
        model: [1, 3, 5, 7, 11, 13]
        delegate: RowLayout {
            
            Label { 
                text: `${modelData}${modelData === 1 ? "st" : modelData === 3 ? "rd" : "th"} Harmonic:` 
                Layout.preferredWidth: 120 
                ToolTip.text: "Component frequency = " + modelData + " × fundamental frequency"
                ToolTip.visible: harmonicMouseArea.containsMouse
                ToolTip.delay: 500
                
                MouseArea {
                    id: harmonicMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
            
            TextFieldRound {
                id: magnitudeField
                placeholderText: modelData === 1 ? "100%" : "0%"
                enabled: modelData !== 1
                validator: DoubleValidator { bottom: 0; top: 100 }

                property bool updatePending: false
                onTextChanged: {
                    if(text) {
                        updatePending = true
                        updateTimer.restart()
                    }
                }
                
                Timer {
                    id: updateTimer
                    interval: 300
                    running: false
                    repeat: false
                    onTriggered: {
                        if (magnitudeField.text) {
                            safeSetHarmonic(
                                modelData, 
                                parseFloat(magnitudeField.text), 
                                phaseField.text ? parseFloat(phaseField.text) : 0
                            )
                        }
                        magnitudeField.updatePending = false
                    }
                }
                
                Layout.preferredWidth: 120
                
                ToolTip.text: "Enter magnitude as percentage of fundamental"
                ToolTip.visible: magnitudeMouseArea.containsMouse
                ToolTip.delay: 500
                
                MouseArea {
                    id: magnitudeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onPressed: function(mouse) { mouse.accepted = false }
                }
            }
            
            TextFieldRound {
                id: phaseField
                placeholderText: "0°"
                enabled: modelData !== 1
                validator: DoubleValidator { bottom: -180; top: 180 }

                property bool updatePending: false
                onTextChanged: {
                    if(text) {
                        updatePending = true
                        phaseUpdateTimer.restart()
                    }
                }
                
                Timer {
                    id: phaseUpdateTimer
                    interval: 300
                    running: false
                    repeat: false
                    onTriggered: {
                        if (phaseField.text) {
                            safeSetHarmonic(
                                modelData, 
                                magnitudeField.text ? parseFloat(magnitudeField.text) : 0,
                                parseFloat(phaseField.text)
                            )
                        }
                        phaseField.updatePending = false
                    }
                }
                
                Layout.preferredWidth: 120
                
                ToolTip.text: "Enter phase angle in degrees (-180° to 180°)"
                ToolTip.visible: phaseMouseArea.containsMouse
                ToolTip.delay: 500
                
                MouseArea {
                    id: phaseMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onPressed: function(mouse) { mouse.accepted = false }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.margins: 10
        height: 1
        color: sideBar && window.modeToggled ? "#404040" : "#e0e0e0"
    }

    StyledButton {
        text: "Reset"
        icon.source: "../../../icons/rounded/restart_alt.svg"
        Layout.alignment: Qt.AlignHCenter

        ToolTip.text: "Reset to default values"
        ToolTip.visible: hovered
        ToolTip.delay: 500
        
        onClicked: {
            calculator.resetHarmonics()
            clearAllTextFields()
            resetTriggered()
        }
    }

    function clearAllTextFields() {
        function clearTextFields(parent) {
            for (let i = 0; i < parent.children.length; i++) {
                let child = parent.children[i]
                
                if (child instanceof TextField) {
                    child.text = ""
                }
                
                if (child.children && child.children.length > 0) {
                    clearTextFields(child)
                }
            }
        }
        
        clearTextFields(harmonicInputForm)
    }
}
