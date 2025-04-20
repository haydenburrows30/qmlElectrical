import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import OhmsLaw 1.0

Item {
    id: root

    property OhmsLawCalculator calculator: OhmsLawCalculator {}
    property bool calculatorReady: calculator !== null
    property var calculationHistory: []
    property int maxHistoryItems: 10

    function calculateOhmsLaw() {
        if (!calculatorReady) return;
        
        let value1 = parseFloat(param1Value.text);
        let value2 = parseFloat(param2Value.text);
        
        if (isNaN(value1) || isNaN(value2)) {
            // Fix: update text and color properties directly on the statusMessage element
            statusMessageText.text = "Please enter valid numbers";
            statusMessageText.color = "red";
            return;
        }
        
        // Convert values based on selected units
        value1 = convertToBaseUnit(value1, param1Unit.currentText, selectedParam1.currentIndex);
        value2 = convertToBaseUnit(value2, param2Unit.currentText, selectedParam2.currentIndex);

        const calculationMap = {
            "0_1": calculator.calculateFromVI,
            "0_2": calculator.calculateFromVR,
            "0_3": calculator.calculateFromVP,
            "1_2": calculator.calculateFromIR,
            "1_3": calculator.calculateFromIP,
            "2_3": calculator.calculateFromRP
        };
        
        const key = selectedParam1.currentIndex + "_" + selectedParam2.currentIndex;
        const calcFunction = calculationMap[key];
        
        if (calcFunction) {
            try {
                calcFunction(value1, value2);
                // Fix: update text and color properties directly on the statusMessage element
                statusMessageText.text = "Calculation successful";
                statusMessageText.color = "green";
                
                // Add to history
                addToHistory(selectedParam1.currentText, value1, param1Unit.currentText,
                            selectedParam2.currentText, value2, param2Unit.currentText);
            } catch (e) {
                // Fix: update text and color properties directly on the statusMessage element
                statusMessageText.text = "Calculation error: " + e;
                statusMessageText.color = "red";
            }
        }
    }

    function convertToBaseUnit(value, unit, paramType) {
        // Parameter types: 0=V, 1=I, 2=R, 3=P
        if (paramType === 0) { // Voltage
            if (unit === "mV") return value * 0.001;
            if (unit === "kV") return value * 1000;
        } else if (paramType === 1) { // Current
            if (unit === "mA") return value * 0.001;
            if (unit === "μA") return value * 0.000001;
        } else if (paramType === 2) { // Resistance
            if (unit === "kΩ") return value * 1000;
            if (unit === "MΩ") return value * 1000000;
        } else if (paramType === 3) { // Power
            if (unit === "mW") return value * 0.001;
            if (unit === "kW") return value * 1000;
        }
        return value; // Default case for base units
    }
    
    function getFormattedValue(value, unitType) {
        if (isNaN(value) || !calculatorReady) return "N/A";
        
        let unit, formattedValue;
        
        switch(unitType) {
            case "voltage":
                if (value < 1) {
                    formattedValue = (value * 1000).toFixed(2);
                    unit = "mV";
                } else if (value >= 1000) {
                    formattedValue = (value / 1000).toFixed(2);
                    unit = "kV";
                } else {
                    formattedValue = value.toFixed(2);
                    unit = "V";
                }
                break;
            case "current":
                if (value < 0.001) {
                    formattedValue = (value * 1000000).toFixed(2);
                    unit = "μA";
                } else if (value < 1) {
                    formattedValue = (value * 1000).toFixed(2);
                    unit = "mA";
                } else {
                    formattedValue = value.toFixed(2);
                    unit = "A";
                }
                break;
            case "resistance":
                if (value >= 1000000) {
                    formattedValue = (value / 1000000).toFixed(2);
                    unit = "MΩ";
                } else if (value >= 1000) {
                    formattedValue = (value / 1000).toFixed(2);
                    unit = "kΩ";
                } else {
                    formattedValue = value.toFixed(2);
                    unit = "Ω";
                }
                break;
            case "power":
                if (value < 1) {
                    formattedValue = (value * 1000).toFixed(2);
                    unit = "mW";
                } else if (value >= 1000) {
                    formattedValue = (value / 1000).toFixed(2);
                    unit = "kW";
                } else {
                    formattedValue = value.toFixed(2);
                    unit = "W";
                }
                break;
            default:
                return value.toFixed(2);
        }
        
        return formattedValue + " " + unit;
    }
    
    function getUnitModel(paramType) {
        // Parameter types: 0=V, 1=I, 2=R, 3=P
        if (paramType === 0) return ["V", "mV", "kV"];
        if (paramType === 1) return ["A", "mA", "μA"];
        if (paramType === 2) return ["Ω", "kΩ", "MΩ"];
        if (paramType === 3) return ["W", "mW", "kW"];
        return [""];
    }
    
    function addToHistory(param1Name, param1Value, param1Unit, param2Name, param2Value, param2Unit) {
        if (!calculatorReady) return;
        
        let entry = {
            timestamp: new Date(),
            param1: {
                name: param1Name,
                value: param1Value,
                unit: param1Unit
            },
            param2: {
                name: param2Name,
                value: param2Value,
                unit: param2Unit
            },
            results: {
                voltage: calculator.voltage,
                current: calculator.current,
                resistance: calculator.resistance,
                power: calculator.power
            }
        };
        
        calculationHistory.unshift(entry);
        if (calculationHistory.length > maxHistoryItems) {
            calculationHistory.pop();
        }
        
        // Update history model
        historyModel.clear();
        for (let i = 0; i < calculationHistory.length; i++) {
            historyModel.append(calculationHistory[i]);
        }
    }
    
    function getPowerSupplyRecommendation() {
        if (!calculatorReady || calculator.voltage <= 0 || calculator.current <= 0) 
            return "Insufficient data";
            
        // Add safety margin of 20%
        const recommendedVoltage = calculator.voltage * 1.2;
        const recommendedCurrent = calculator.current * 1.2;
        
        return `Recommended power supply: ${recommendedVoltage.toFixed(1)}V @ ${recommendedCurrent.toFixed(1)}A`;
    }

    PopUpText {
        id: popUpText
        widthFactor: 0.3
        heightFactor: 0.4
        parentCard: topHeader
        
        popupText: "<h3>Basic Ohm's Law Equations:</h3><br>" +
                "<h4> Voltage (V): </h4> V = I × R<br>" +
                "<h4> Current (I): </h4> I = V / R <br>" +
                "<h4> Resistance (R): </h4> R = V / I <br>" +
                "<h4> Power (P): </h4> P = V × I = I² × R = V² / R"
    }

    Dialog {
        id: historyDialog
        title: "Calculation History"
        width: 600
        height: 400
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        standardButtons: Dialog.Close
        
        ListView {
            anchors.fill: parent
            clip: true
            model: ListModel { id: historyModel }
            delegate: ItemDelegate {
                height: 80
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2
                    
                    Label {
                        text: Qt.formatDateTime(model.timestamp, "yyyy-MM-dd HH:mm:ss")
                        font.bold: true
                    }
                    Label {
                        text: "Inputs: " + model.param1.name + " = " + model.param1.value + " " + 
                              model.param1.unit + ", " + model.param2.name + " = " + model.param2.value + 
                              " " + model.param2.unit
                    }
                    Label {
                        text: "Results: V=" + getFormattedValue(model.results.voltage, "voltage") + 
                              ", I=" + getFormattedValue(model.results.current, "current") +
                              ", R=" + getFormattedValue(model.results.resistance, "resistance") + 
                              ", P=" + getFormattedValue(model.results.power, "power")
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent

        // Header with title and help button
        RowLayout {
            id: topHeader
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 5

            Label {
                text: "Ohm's Law Calculator"
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
                onClicked: popUpText.open()
            }

            StyledButton {
                text: "View History"
                icon.source: "../../../icons/rounded/history.svg"
                onClicked: historyDialog.open()
                Layout.columnSpan: 2
                Layout.minimumWidth: 100
                Layout.alignment: Qt.AlignLeft
            }
        }

        WaveCard {
            id: results
            title: "Input Parameters"
            Layout.fillWidth: true
            Layout.minimumHeight: 210
            Layout.minimumWidth: 450
            Layout.maximumWidth: 450

            GridLayout {
                anchors.fill: parent
                columns: 4
                
                Label { text: "1:"}
                ComboBoxRound {
                    id: selectedParam1
                    Layout.fillWidth: true
                    model: ["Voltage (V)", "Current (I)", "Resistance (R)", "Power (P)"]
                    currentIndex: 0
                    onActivated: {
                        updateParamUnit(0);
                        param1Unit.model = getUnitModel(selectedParam1.currentIndex);
                        param1Unit.currentIndex = 0;
                    }
                }

                TextFieldRound {
                    id: param1Value
                    Layout.minimumWidth: 100
                    Layout.fillWidth: true
                    placeholderText: "Enter value"
                    text: "12"
                    validator: DoubleValidator {
                        bottom: 0.00001
                        notation: DoubleValidator.StandardNotation
                    }
                    onEditingFinished: calculateOhmsLaw()
                }

                ComboBoxRound {
                    id: param1Unit
                    Layout.maximumWidth: 60
                    model: getUnitModel(selectedParam1.currentIndex)
                    onCurrentTextChanged: calculateOhmsLaw()
                }
                
                Label { text: "2:"}
                ComboBoxRound {
                    id: selectedParam2
                    Layout.fillWidth: true
                    model: ["Voltage (V)", "Current (I)", "Resistance (R)", "Power (P)"]
                    currentIndex: 2
                    onActivated: {
                        updateParamUnit(1);
                        param2Unit.model = getUnitModel(selectedParam2.currentIndex);
                        param2Unit.currentIndex = 0;
                    }
                }

                TextFieldRound {
                    id: param2Value
                    Layout.fillWidth: true
                    placeholderText: "Enter value"
                    text: "100"
                    validator: DoubleValidator {
                        bottom: 0.00001
                        notation: DoubleValidator.StandardNotation
                    }
                    onEditingFinished: calculateOhmsLaw()
                }

                ComboBoxRound {
                    id: param2Unit
                    Layout.maximumWidth: 60
                    model: getUnitModel(selectedParam2.currentIndex)
                    onCurrentTextChanged: calculateOhmsLaw()
                }

                Text {
                    id: statusMessageText
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.italic: true
                }

                StyledButton {
                    text: "Calculate"
                    icon.source: "../../../icons/rounded/calculate.svg"
                    Layout.minimumWidth: 100
                    Layout.columnSpan: 2
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 16
                    
                    onClicked: calculateOhmsLaw()

                }
            }
        }

        WaveCard {
            title: "Results"
            Layout.fillWidth: true
            Layout.minimumHeight: 250
            Layout.minimumWidth: results.height

            GridLayout {
                id: resultGrid
                columns: 2
                anchors.fill: parent
                
                Label { text: "Voltage:" ; Layout.minimumWidth: 100}
                TextFieldBlue { 
                    text: getFormattedValue(calculator.voltage, "voltage")
                    ToolTip.visible: hovered
                    ToolTip.text: "V = I × R = √(P × R)"
                }
                
                Label { text: "Current:" ;}
                TextFieldBlue { 
                    text: getFormattedValue(calculator.current, "current")
                    ToolTip.visible: hovered
                    ToolTip.text: "I = V / R = √(P / R)"
                }
                
                Label { text: "Resistance:" ;}
                TextFieldBlue {
                    text: getFormattedValue(calculator.resistance, "resistance")
                    ToolTip.visible: hovered
                    ToolTip.text: "R = V / I = V² / P"
                }
                
                Label { text: "Power:" ;}
                TextFieldBlue { 
                    text: getFormattedValue(calculator.power, "power")
                    ToolTip.visible: hovered
                    ToolTip.text: "P = V × I = I² × R = V² / R"
                }

                StyledButton {
                    Layout.columnSpan: 2
                    Layout.minimumWidth: 100
                    Layout.alignment: Qt.AlignRight
                    icon.source: "../../../icons/rounded/close.svg"
                    text: "Clear"
                    onClicked: {
                        param1Value.text = ""
                        param2Value.text = ""
                        statusMessageText.text = ""
                    }
                }
            }
        }
    }

    function updateParamUnit(paramIndex) {
        if (selectedParam1.currentIndex === selectedParam2.currentIndex) {
            if (paramIndex === 0) {
                selectedParam2.currentIndex = (selectedParam1.currentIndex + 2) % 4;
            } else {
                selectedParam1.currentIndex = (selectedParam2.currentIndex + 2) % 4;
            }
        }
    }
    
    Component.onCompleted: {
        calculateOhmsLaw()
    }
}
