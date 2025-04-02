import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import "../visualizers"
import "../style"
import "../backgrounds"
import "../popups"

import MotorStarting 1.0

Item {
    id: motorStartingCard

    property MotorStartingCalculator calculator: MotorStartingCalculator {}
    property real cachedStartingMultiplier: calculator ? calculator.startingMultiplier : 7.0
    property bool hasValidInputs: motorPower.text.length > 0 && 
                                 parseFloat(motorPower.text) > 0 &&
                                 parseFloat(motorVoltage.text) > 0 &&
                                 parseFloat(motorEfficiency.text) > 0 &&
                                 parseFloat(motorPowerFactor.text) > 0
    
    function getStartingMultiplier() {
        return calculator ? calculator.startingMultiplier : 7.0
    }

    Connections {
        target: calculator
        function onStartingMultiplierChanged() {
            cachedStartingMultiplier = calculator.startingMultiplier
        }
        
        function onMotorTypeChanged() {
            motorEfficiency.text = (calculator.efficiency * 100).toFixed(0)
            motorPowerFactor.text = calculator.powerFactor.toFixed(2)

            updateMethodAvailability()
        }
    }
    
    function updateMethodAvailability() {
        for (let i = 0; i < startingMethod.model.length; i++) {
            let method = startingMethod.model[i]
            let applicable = calculator.isMethodApplicable(method)
        }
    }

    function showMessage(title, message) {
        messagePopup.title = title
        messagePopup.message = message
        messagePopup.open()
    }

    function showMotorInfo() {
        showMessage("Motor Type Info", calculator.motorDescription)
    }

    PopUpText {
        parentCard: results
        popupText: "<h3>Motor Starting Calculator </h3><br>" +
                "This calculator helps you determine the starting current and torque of an electric motor based on its power, efficiency, and power factor. <br>" +
                "You can also select the starting method to see how the current profile changes. <br>" +
                "The starting current profile is displayed below the results."
    }

    Popup {
        id: messagePopup
        width: parent.width * 0.6
        height: parent.height * 0.3
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        property string title: "Message"
        property string message: ""
        
        ColumnLayout {
            anchors.fill: parent
            
            Text {
                text: messagePopup.title
                font.bold: true
                font.pixelSize: 16
            }
            
            Text {
                text: messagePopup.message
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            Item { Layout.fillHeight: true }
            
            Button {
                text: "Close"
                Layout.alignment: Qt.AlignRight
                onClicked: messagePopup.close()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        
        anchors.margins: 10

        RowLayout {

            // Inputs
            WaveCard {
                id: results
                title: "Motor Parameters"
                Layout.minimumHeight: 330
                Layout.minimumWidth: 410

                showSettings: true
            
                GridLayout {
                    columns: 2

                    Label {
                        text: "Motor Type:"
                        Layout.preferredWidth: 150
                    }
                    
                    RowLayout {
                        Layout.preferredWidth: 200
                        
                        ComboBox {
                            id: motorType
                            model: ["Induction Motor", "Synchronous Motor", "Wound Rotor Motor", 
                                    "Permanent Magnet Motor", "Single Phase Motor"]
                            Layout.fillWidth: true
                            onCurrentTextChanged: {
                                if (currentText) {
                                    calculator.setMotorType(currentText)
                                }
                            }
                        }
                        
                        Button {
                            text: "ⓘ"
                            implicitWidth: 30
                            onClicked: showMotorInfo()
                        }
                    }

                    Label {
                        text: "Motor Power (kW):"
                        Layout.preferredWidth: 150
                    }

                    TextField {
                        id: motorPower
                        placeholderText: "Enter Power"
                        onTextChanged: if(text.length > 0) calculator.setMotorPower(parseFloat(text))
                        Layout.preferredWidth: 200
                        Layout.alignment: Qt.AlignRight
                        validator: DoubleValidator { bottom: 0 ; top: 999 }
                        maximumLength: 4
                    }
                    
                    Label {
                        text: "Voltage (V):"
                        Layout.preferredWidth: 150
                    }

                    TextField {
                        id: motorVoltage
                        placeholderText: "Enter Voltage"
                        text: "400"
                        onTextChanged: if(text.length > 0) calculator.setVoltage(parseFloat(text))
                        Layout.preferredWidth: 200
                        Layout.alignment: Qt.AlignRight
                        validator: DoubleValidator { bottom: 0; top: 15000 }
                    }
                    
                    Label {
                        text: "Efficiency (%):"
                        Layout.preferredWidth: 150
                    }

                    TextField {
                        id: motorEfficiency
                        placeholderText: "Enter Efficiency"
                        text: "90"
                        onTextChanged: if(text.length > 0) calculator.setEfficiency(parseFloat(text) / 100)
                        Layout.preferredWidth: 200
                        Layout.alignment: Qt.AlignRight
                        validator: DoubleValidator { bottom: 0 ; top: 99 }
                        maximumLength: 2
                    }

                    Label {
                        text: "Power Factor:"
                        Layout.preferredWidth: 150
                    }

                    TextField {
                        id: motorPowerFactor
                        placeholderText: "Enter PF"
                        text: "0.85"
                        onTextChanged: {
                            if(text.length > 0) calculator.setPowerFactor(parseFloat(text))
                        }
                        Layout.preferredWidth: 200
                        Layout.alignment: Qt.AlignRight
                        validator: DoubleValidator { bottom: 0 ; top: 1.0 }
                    }
                    
                    Label {
                        text: "Starting Method:"
                        Layout.preferredWidth: 150
                    }

                    RowLayout {
                        Layout.preferredWidth: 200
                        
                        ComboBox {
                            id: startingMethod
                            model: ["DOL", "Star-Delta", "Soft Starter", "VFD"]
                            Layout.fillWidth: true
                            
                            delegate: ItemDelegate {
                                width: startingMethod.width
                                text: modelData
                                highlighted: startingMethod.highlightedIndex === index
                                enabled: calculator.isMethodApplicable(modelData)
                                
                                contentItem: Text {
                                    text: modelData
                                    color: enabled ? Universal.foreground : Universal.foreground + "80" // 50% opacity
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                            
                            onCurrentTextChanged: {
                                if (currentText && calculator.isMethodApplicable(currentText)) {
                                    console.log("Selecting starting method:", currentText)
                                    calculator.startingMethod = currentText
                                }
                            }
                        }
                    }
                    
                    Button {
                        text: "Calculate"
                        Layout.columnSpan: 2
                        Layout.alignment: Qt.AlignRight
                        Layout.topMargin: 5
                        enabled: hasValidInputs
                        
                        onClicked: {
                            if (hasValidInputs) {
                                calculator.setMotorPower(parseFloat(motorPower.text))
                                calculator.setVoltage(parseFloat(motorVoltage.text))
                                calculator.setEfficiency(parseFloat(motorEfficiency.text) / 100)
                                calculator.setPowerFactor(parseFloat(motorPowerFactor.text))
                            } else {
                                showMessage("Input Error", "Please ensure all fields have valid values")
                            }
                        }
                    }
                }
            }

            // Results
            WaveCard {
                title: "Results"
                Layout.minimumWidth: 350
                Layout.minimumHeight: results.height

                GridLayout {
                    columns: 2

                    Label {
                        text: "Motor Type:"
                        Layout.preferredWidth: 150
                    }
                    
                    TextFieldBlue {
                        text: motorType.currentText
                        Layout.preferredWidth: 150
                        font.bold: true
                    }
                    
                    Label {
                        text: "Full Load Current:"
                        Layout.fillWidth: true
                    }
                    
                    TextFieldBlue {
                        text: !isNaN(calculator.startingCurrent / getStartingMultiplier()) ? 
                                (calculator.startingCurrent / getStartingMultiplier()).toFixed(1) + " A" : "0.0 A"
                        Layout.fillWidth: true
                    }
                
                    Label {
                        text: "Starting Current:"
                        Layout.fillWidth: true
                    }
                    
                    TextFieldBlue {
                        text: !isNaN(calculator.startingCurrent) ? 
                                calculator.startingCurrent.toFixed(1) + " A" : "0.0 A"
                        color: "red"
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: "Current Multiplier:"
                        Layout.fillWidth: true
                    }
                    
                    TextFieldBlue {
                        text: getStartingMultiplier().toFixed(1) + "x"
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: "Starting Torque:"
                        Layout.fillWidth: true
                    }
                    
                    TextFieldBlue {
                        text: !isNaN(calculator.startingTorque) ? 
                                (calculator.startingTorque * 100).toFixed(0) + "% FLT" : "0% FLT"
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: "Nominal Torque:"
                        Layout.fillWidth: true
                    }
                    
                    TextFieldBlue {
                        text: !isNaN(calculator.startingTorque) ? 
                                (calculator.startingTorque / (calculator.startingTorque * 100 / 100)).toFixed(1) + " Nm" : "0.0 Nm"
                        Layout.fillWidth: true
                    }
                }
            }
        }

        MotorStartingViz {}

    }
}
