import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtQuick.Dialogs
import Qt.labs.platform as Platform

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
    property real cachedStartingTorque: calculator ? calculator.startingTorque : 1.0
    property bool hasValidInputs: motorPower.text.length > 0 && 
                                 parseFloat(motorPower.text) > 0 &&
                                 parseFloat(motorVoltage.text) > 0 &&
                                 parseFloat(motorEfficiency.text) > 0 &&
                                 parseFloat(motorPowerFactor.text) > 0 &&
                                 parseFloat(startingDuration.text) > 0 &&
                                 calculator.isMethodApplicable(startingMethod.currentText)

    property bool compareMode: false
    property var comparisonMethods: []
    property int activeComparisonTab: 0
    
    function getStartingMultiplier() {
        return calculator ? calculator.startingMultiplier : 7.0
    }
    
    function addComparisonMethod(methodName) {
        if (comparisonMethods.indexOf(methodName) === -1 && 
            calculator.isMethodApplicable(methodName)) {
            comparisonMethods.push(methodName)
            return true
        }
        return false
    }
    
    function removeComparisonMethod(index) {
        if (index >= 0 && index < comparisonMethods.length) {
            comparisonMethods.splice(index, 1)
            if (activeComparisonTab >= comparisonMethods.length) {
                activeComparisonTab = Math.max(0, comparisonMethods.length - 1)
            }
            return true
        }
        return false
    }
    
    function clearComparison() {
        comparisonMethods = []
        compareMode = false
    }

    Connections {
        target: calculator
        function onStartingMultiplierChanged() {
            cachedStartingMultiplier = calculator.startingMultiplier
        }
        
        function onStartingTorqueChanged() {
            cachedStartingTorque = calculator.startingTorque
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

    Component {
        id: methodComparisonDialog
        Dialog {
            id: comparisonDialog
            title: "Compare Starting Methods"
            standardButtons: Dialog.Ok | Dialog.Cancel
            width: 400
            height: 300
            
            onAccepted: {
                let selectedMethods = []
                for (let i = 0; i < methodModel.count; i++) {
                    if (methodModel.get(i).checked && 
                        calculator.isMethodApplicable(methodModel.get(i).name)) {
                        selectedMethods.push(methodModel.get(i).name)
                    }
                }
                
                if (selectedMethods.length > 0) {
                    comparisonMethods = selectedMethods
                    compareMode = true
                }
            }
            
            ListModel {
                id: methodModel
                
                Component.onCompleted: {
                    append({ name: "DOL", checked: false })
                    append({ name: "Star-Delta", checked: false })
                    append({ name: "Soft Starter", checked: false })
                    append({ name: "VFD", checked: false })
                }
            }
            
            ColumnLayout {
                anchors.fill: parent
                
                Text {
                    text: "Select methods to compare:"
                    font.bold: true
                }
                
                ListView {
                    id: methodList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: methodModel
                    
                    delegate: RowLayout {
                        width: parent.width
                        CheckBox {
                            checked: model.checked
                            text: model.name
                            enabled: calculator.isMethodApplicable(model.name)
                            onCheckedChanged: methodModel.setProperty(index, "checked", checked)
                        }
                        
                        Text {
                            visible: !calculator.isMethodApplicable(model.name)
                            text: "(Not applicable for this motor)"
                            color: "gray"
                            font.italic: true
                        }
                    }
                }
            }
        }
    }

    PopUpText {
        id: popUpText
        parentCard: helpButton
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

    FileDialog {
        id: fileDialog
        title: "Export Results"
        fileMode: FileDialog.SaveFile
        nameFilters: ["CSV files (*.csv)"]
        defaultSuffix: "csv"
        currentFolder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation)
        
        onAccepted: {
            let filePath = fileDialog.selectedFile.toString()
            
            if (filePath.startsWith("file://")) {
                filePath = filePath.substring(7)
            }
            
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

    // main layout
    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        Flickable {
            id: flickableContainer
            contentWidth: parent.width
            contentHeight: parent.height + 20
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            ColumnLayout {
                id: mainLayout
                width: flickableContainer.width - 20

                // buttons
                RowLayout {
                    // Layout.fillWidth: true
                    Layout.maximumWidth: inputResultsLayout.width
                    Layout.alignment: Qt.AlignHCenter
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
                    
                    StyledButton {
                        id: exportButton
                        icon.source: "../../../icons/rounded/download.svg"
                        ToolTip.text: "Export Results"
                        enabled: hasValidInputs && calculator.startingCurrent > 0
                        onClicked: fileDialog.open()
                    }
                    
                    StyledButton {
                        id: compareButton
                        icon.source: "../../../icons/rounded/compare.svg"
                        ToolTip.text: "Compare Methods"
                        enabled: hasValidInputs
                        onClicked: {
                            var dialog = methodComparisonDialog.createObject(motorStartingCard)
                            dialog.open()
                        }
                    }
                }
                // comparison tabbar
                TabBar {
                    id: comparisonTabBar
                    Layout.fillWidth: true
                    visible: compareMode && comparisonMethods.length > 0
                    
                    // Initialize tab width when component completes
                    Component.onCompleted: updateTabWidths()
                    
                    // Update tab widths explicitly when needed
                    function updateTabWidths() {
                        if (comparisonMethods.length > 0) {
                            let buttonWidth = Math.max(100, width / comparisonMethods.length)
                            for (let i = 0; i < comparisonTabBar.contentChildren.length; i++) {
                                if (comparisonTabBar.contentChildren[i] instanceof TabButton) {
                                    comparisonTabBar.contentChildren[i].width = buttonWidth
                                }
                            }
                        }
                    }
                    
                    onWidthChanged: Qt.callLater(updateTabWidths)
                    onVisibleChanged: if (visible) Qt.callLater(updateTabWidths)
                    
                    Repeater {
                        model: comparisonMethods
                        TabButton {
                            text: modelData
                            // Don't set width here - it will be set by updateTabWidths()
                        }
                    }

                    onCurrentIndexChanged: {
                        if (compareMode) {
                            activeComparisonTab = currentIndex
                            calculator.setStartingMethod(comparisonMethods[currentIndex])
                        }
                    }
                }

                // Comparison mode button
                RowLayout {
                    visible: compareMode
                    Layout.alignment: Qt.AlignHCenter
                    Layout.minimumWidth: inputResultsLayout.width

                    StyledButton {
                        text: "Exit Comparison Mode"
                        onClicked: clearComparison()
                    }
                }

                // Inputs and results
                RowLayout {
                    id: inputResultsLayout
                    Layout.alignment: Qt.AlignHCenter

                    WaveCard {
                        id: input
                        title: "Motor Parameters"
                        Layout.minimumHeight: 600
                        Layout.minimumWidth: 500

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
                                validator: 
                                    DoubleValidator { bottom: 0; top: 15000 }
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
                                            color: enabled ? Universal.foreground : Universal.foreground + "80"
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    onCurrentTextChanged: {
                                        if (currentText && calculator.isMethodApplicable(currentText)) {
                                            console.log("Selecting starting method:", currentText)
                                            calculator.setStartingMethod(currentText)
                                        }
                                    }
                                }
                            }

                            Label {
                                text: "Starting Duration (s):"
                                Layout.fillWidth: true
                            }

                            TextFieldRound {
                                id: startingDuration
                                placeholderText: "Enter Duration"
                                text: "5"
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignRight
                                validator: DoubleValidator { bottom: 0.1; top: 60 }
                                ToolTip.text: "Duration of the starting sequence in seconds"
                                ToolTip.visible: hovered
                                onTextChanged: {
                                    if(text.length > 0) calculator.setStartingDuration(parseFloat(text))
                                }
                            }

                            Label {
                                text: "Ambient Temp (°C):"
                                Layout.fillWidth: true
                            }

                            TextFieldRound {
                                id: ambientTemperature
                                placeholderText: "Enter Temperature"
                                text: "25"
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignRight
                                validator: IntValidator { bottom: -20; top: 50 }
                                ToolTip.text: "Ambient temperature around the motor"
                                ToolTip.visible: hovered
                                onTextChanged: {
                                    if(text.length > 0) calculator.setAmbientTemperature(parseFloat(text))
                                }
                            }

                            Label {
                                text: "Duty Cycle:"
                                Layout.fillWidth: true
                            }

                            ComboBoxRound {
                                id: dutyCycle
                                model: ["S1 (Continuous)", "S2 (Short-time)", "S3 (Intermittent)", 
                                        "S4 (Intermittent with starting)", "S5 (Intermittent with braking)"]
                                Layout.fillWidth: true
                                ToolTip.text: "Operating duty cycle affects thermal calculations"
                                ToolTip.visible: hovered
                                onCurrentTextChanged: {
                                    calculator.setDutyCycle(currentText)
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

                    WaveCard {
                        title: "Results"
                        Layout.minimumWidth: 500
                        Layout.minimumHeight: input.height

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
                                text: "Temp Rise (est.):"
                                Layout.fillWidth: true
                            }
                            
                            TextFieldBlue {
                                text: hasValidInputs ? calculator.estimateTemperatureRise().toFixed(1) + " °C" : "0.0 °C"
                                color: {
                                    let level = calculator.getTemperatureRiseLevel()
                                    if (level === "normal") return "green"
                                    else if (level === "warning") return "orange"
                                    else return "red"
                                }
                                Layout.fillWidth: true
                            }
                            
                            Label {
                                text: "Cable Size (min.):"
                                Layout.fillWidth: true
                            }
                            
                            TextFieldBlue {
                                text: calculator.recommendCableSize()
                                Layout.fillWidth: true
                            }
                            
                            Label {
                                text: "Start Duration (est.):"
                                Layout.fillWidth: true
                            }
                            
                            TextFieldBlue {
                                text: hasValidInputs ? 
                                    (calculator.estimateStartDuration ? calculator.estimateStartDuration().toFixed(1) : "5.0") + " s" : "0.0 s"
                                Layout.fillWidth: true
                            }
                            
                            Label {
                                text: "Energy Usage:"
                                Layout.fillWidth: true
                            }
                            
                            TextFieldBlue {
                                text: hasValidInputs ? 
                                    (calculator.calculateStartingEnergy ? calculator.calculateStartingEnergy().toFixed(1) : "0.0") + " kWh" : "0.0 kWh"
                                Layout.fillWidth: true
                            }
                            
                            Label {
                                text: "Recommendations:"
                                Layout.columnSpan: 2
                                font.bold: true
                                Layout.topMargin: 10
                            }

                            TextArea {
                                id: recommendationsText
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                Layout.preferredHeight: 120
                                readOnly: true
                                wrapMode: TextArea.Wrap
                                text: calculator.startingRecommendations
                                background: Rectangle {
                                    color: Universal.background
                                    border.color: Universal.foreground
                                    border.width: 1
                                    radius: 5
                                }
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
                    Layout.minimumWidth: inputResultsLayout.width
                    Layout.alignment: Qt.AlignHCenter
                    Layout.minimumHeight: 400

                    darkMode: window.modeToggled
                }
            }
        }
    }
}
