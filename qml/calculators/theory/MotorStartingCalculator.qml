import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtQuick.Dialogs
import Qt.labs.platform as Platform  // Add this for StandardPaths

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import MotorStarting 1.0

Item {
    id: motorStartingCard

    property MotorStartingCalculator calculator: MotorStartingCalculator {}
    property real cachedStartingMultiplier: calculator ? calculator.startingMultiplier : 7.0
    property bool hasValidInputs: motorPower.text.length > 0 && 
                                 parseFloat(motorPower.text) > 0 &&
                                 parseFloat(motorVoltage.text) > 0 &&
                                 parseFloat(motorEfficiency.text) > 0 &&
                                 parseFloat(motorPowerFactor.text) > 0 &&
                                 calculator.isMethodApplicable(startingMethod.currentText)
    
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
        showMessage("Motor Type Info", (calculator.motorDescription))
    }

    PopUpText {
        id: popUpText
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
            
            StyledButton {
                text: "Close"
                icon.source: "../../../icons/rounded/close.svg"
                Layout.alignment: Qt.AlignRight
                onClicked: messagePopup.close()
            }
        }
    }

    // Add file dialog for exporting results
    FileDialog {
        id: fileDialog
        title: "Export Results"
        fileMode: FileDialog.SaveFile
        nameFilters: ["CSV files (*.csv)"]
        defaultSuffix: "csv"
        currentFolder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation)
        
        onAccepted: {
            // Convert the URL to a local file path and ensure it has the .csv extension
            let filePath = fileDialog.selectedFile.toString()
            
            // Remove the "file://" prefix if present
            if (filePath.startsWith("file://")) {
                filePath = filePath.substring(7)
            }
            
            // Add .csv extension if not present
            if (!filePath.toLowerCase().endsWith(".csv")) {
                filePath += ".csv"
            }
            
            console.log("Attempting to save to:", filePath)
            
            if (calculator.exportResults(filePath)) {
                showMessage("Export Successful", "Results have been exported to: " + filePath)
            } else {
                showMessage("Export Failed", "An error occurred while exporting results to: " + filePath)
            }
        }
    }

    // Main layout
    ColumnLayout {
        anchors.centerIn: parent
        anchors.margins: 10

        // Header with title and help button
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 5

            Label {
                text: "Motor Starting Calculator"
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            StyledButton {
                id: helpButton
                icon.source: "../../../icons/rounded/info.svg"
                ToolTip.text: "Help"
                onClicked: popUpText.open()
            }
            
            // Add export button next to help button
            StyledButton {
                id: exportButton
                icon.source: "../../../icons/rounded/download.svg"
                ToolTip.text: "Export Results"
                enabled: hasValidInputs && calculator.startingCurrent > 0
                onClicked: fileDialog.open()
            }
        }

        RowLayout {
            id: mainLayout
            Layout.minimumWidth: 800

            // Inputs
            WaveCard {
                id: results
                title: "Motor Parameters"
                Layout.minimumHeight: 360
                Layout.fillWidth: true
            
                GridLayout {
                    columns: 2
                    anchors.fill: parent
                    uniformCellWidths: true

                    Label {text: "Motor Type:" ; Layout.fillWidth: true}

                    RowLayout {
                        Layout.fillWidth: true
                        
                        ComboBoxRound {
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
                        
                        StyledButton {
                            text: "ⓘ"
                            implicitWidth: 30
                            onClicked: showMotorInfo()
                        }
                    }

                    Label {
                        text: "Motor Power (kW):"
                        Layout.fillWidth: true
                    }

                    TextFieldRound {
                        id: motorPower
                        placeholderText: "Enter Power"
                        onTextChanged: if(text.length > 0) calculator.setMotorPower(parseFloat(text))
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        validator: DoubleValidator { bottom: 0 ; top: 999 }
                        maximumLength: 4
                    }
                    
                    Label {
                        text: "Voltage (V):"
                        Layout.fillWidth: true
                    }

                    TextFieldRound {
                        id: motorVoltage
                        placeholderText: "Enter Voltage"
                        text: "400"
                        onTextChanged: if(text.length > 0) calculator.setVoltage(parseFloat(text))
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        validator: DoubleValidator { bottom: 0; top: 15000 }
                    }
                    
                    Label {
                        text: "Efficiency (%):"
                        Layout.fillWidth: true
                    }

                    TextFieldRound {
                        id: motorEfficiency
                        placeholderText: "Enter Efficiency"
                        text: "90"
                        onTextChanged: if(text.length > 0) calculator.setEfficiency(parseFloat(text) / 100)
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        validator: DoubleValidator { bottom: 0 ; top: 99 }
                        maximumLength: 2
                    }

                    Label {
                        text: "Power Factor:"
                        Layout.fillWidth: true
                    }

                    TextFieldRound {
                        id: motorPowerFactor
                        placeholderText: "Enter PF"
                        text: "0.85"
                        onTextChanged: {
                            if(text.length > 0) calculator.setPowerFactor(parseFloat(text))
                        }
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        validator: DoubleValidator { bottom: 0 ; top: 1.0 }
                    }

                    // Add motor speed selection
                    Label {
                        text: "Motor Speed:"
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        
                        ComboBoxRound {
                            id: motorSpeed
                            model: ["1500 RPM (4 Pole 50Hz)", "3000 RPM (2 Pole 50Hz)", 
                                    "1000 RPM (6 Pole 50Hz)", "750 RPM (8 Pole 50Hz)"]
                            Layout.fillWidth: true
                            
                            Component.onCompleted: currentIndex = 0
                            
                            onCurrentTextChanged: {
                                if (currentText) {
                                    // Extract RPM value from the text
                                    let rpm = parseInt(currentText.match(/\d+/)[0])
                                    calculator.setMotorSpeed(rpm)
                                }
                            }
                        }
                    }
                    
                    Label {
                        text: "Starting Method:"
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        
                        ComboBoxRound {
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
                    
                    StyledButton {
                        text: "Calculate"
                        Layout.columnSpan: 2
                        Layout.alignment: Qt.AlignRight
                        Layout.topMargin: 5
                        enabled: hasValidInputs
                        icon.source: "../../../icons/rounded/calculate.svg"
                        
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
                Layout.fillWidth: true
                Layout.minimumHeight: results.height

                GridLayout {
                    columns: 2
                    anchors.fill: parent

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
                        text: !isNaN(calculator.nominalTorque) ? 
                                calculator.nominalTorque.toFixed(1) + " Nm" : "0.0 Nm"
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        visible: !calculator.isMethodApplicable(startingMethod.currentText)
                        text: "⚠️ Selected starting method is not recommended for this motor type"
                        color: "orange"
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        MotorStartingViz {
            Layout.minimumWidth: mainLayout.width
            Layout.minimumHeight: 400
        }
    }
}
