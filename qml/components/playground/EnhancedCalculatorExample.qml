import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"
import "../../components"
import "../style"
import "../buttons"

Item {
    id: calculatorCard
    
    // Example calculator that leverages the numeric keypad
    
    property var parameters: []  // Store multiple parameters
    property int currentParamIndex: 0 // Currently selected parameter
    
    Component.onCompleted: {
        // Initialize with default parameters
        parameters = [
            { name: "Param 1", value: "0" },
            { name: "Param 2", value: "0" }
        ];
        updateParameterFields();
    }
    
    function updateParameterFields() {
        // Clear existing grid items except headers and result row
        while (paramGrid.children.length > 5) {
            paramGrid.children[5].destroy();
        }
        
        // Add parameter fields dynamically
        for (let i = 0; i < parameters.length; i++) {
            let param = parameters[i];
            
            // Add label
            let labelComponent = Qt.createComponent("../style/StyledLabel.qml");
            if (labelComponent.status === Component.Ready) {
                let labelObject = labelComponent.createObject(paramGrid, {
                    "text": param.name + ":",
                    "Layout.row": i + 1,
                    "Layout.column": 0
                });
            }
            
            // Add text field
            let fieldComponent = Qt.createComponent("QtQuick.Controls/TextField");
            if (fieldComponent.status === Component.Ready) {
                let fieldObject = fieldComponent.createObject(paramGrid, {
                    "text": param.value,
                    "readOnly": true,
                    "Layout.fillWidth": true,
                    "Layout.row": i + 1,
                    "Layout.column": 1,
                    "objectName": "paramField" + i
                });
                
                fieldObject.onFocused = function() {
                    numericKeypad.currentInput = this.text;
                    numericKeypad.clearOnNextDigit = true;
                    currentParamIndex = i;
                    numericKeypad.activeField = this;
                };
            }
        }
        
        // Update the result row position
        resultLabel.Layout.row = parameters.length + 1;
        resultField.Layout.row = parameters.length + 1;
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        // Toolbar with parameter management
        ToolBar {
            Layout.fillWidth: true
            background: Rectangle {
                color: Universal.theme === Universal.Dark ? "#2d2d2d" : "#f2f2f2"
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                
                Label {
                    text: "Parameter Management"
                    font.bold: true
                }
                
                Item { Layout.fillWidth: true }
                
                StyledButton {
                    text: "Add"
                    icon.name: "add"
                    ToolTip.text: "Add new parameter"
                    ToolTip.visible: hovered
                    onClicked: {
                        let newParam = { 
                            name: "Param " + (parameters.length + 1), 
                            value: "0" 
                        };
                        parameters.push(newParam);
                        updateParameterFields();
                    }
                }
                
                StyledButton {
                    text: "Remove"
                    icon.name: "remove"
                    enabled: parameters.length > 1
                    ToolTip.text: "Remove last parameter"
                    ToolTip.visible: hovered
                    onClicked: {
                        if (parameters.length > 1) {
                            parameters.pop();
                            if (currentParamIndex >= parameters.length) {
                                currentParamIndex = parameters.length - 1;
                                numericKeypad.activeField = paramGrid.children[currentParamIndex * 2 + 1];
                            }
                            updateParameterFields();
                        }
                    }
                }
                
                StyledButton {
                    text: "Reset"
                    icon.name: "refresh"
                    ToolTip.text: "Reset all parameters to zero"
                    ToolTip.visible: hovered
                    onClicked: {
                        for (let i = 0; i < parameters.length; i++) {
                            parameters[i].value = "0";
                        }
                        resultField.text = "0";
                        updateParameterFields();
                    }
                }
            }
        }
        
        // Input display and parameter selection area
        WaveCard {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(160 + (parameters.length - 2) * 40, 300)
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                
                Label {
                    text: "Enhanced Calculator Example"
                    font.bold: true
                    font.pixelSize: 16
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    GridLayout {
                        id: paramGrid
                        width: parent.width
                        columns: 2
                        
                        rowSpacing: 8
                        
                        // The parameter fields will be created dynamically
                        
                        Label { 
                            id: resultLabel
                            text: "Result:" 
                            Layout.row: 3
                            Layout.column: 0
                        }
                        
                        TextField {
                            id: resultField
                            Layout.fillWidth: true
                            Layout.row: 3
                            Layout.column: 1
                            readOnly: true
                            text: "0"
                            font.bold: true
                            background: Rectangle {
                                color: Universal.theme === Universal.Dark ? "#383838" : "#f5f5f5"
                                border.color: Universal.theme === Universal.Dark ? "#555" : "#ddd"
                            }
                        }
                    }
                }
            }
        }
        
        // Keypad and Action Buttons
        WaveCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 15
                
                // Left side: Numeric keypad
                NumericKeypad {
                    id: numericKeypad
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.width * 0.7
                    allowDecimals: true
                    
                    property TextField activeField: null
                    
                    Component.onCompleted: {
                        // Find the first parameter field
                        for(let i = 0; i < paramGrid.children.length; i++) {
                            let child = paramGrid.children[i];
                            if (child.objectName === "paramField0") {
                                activeField = child;
                                break;
                            }
                        }
                    }
                    
                    onValueEntered: function(finalValue) {
                        if (activeField) {
                            activeField.text = finalValue;
                            parameters[currentParamIndex].value = finalValue;
                        }
                    }
                }
                
                // Right side: Operation buttons
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    
                    // Function dropdown
                    ComboBox {
                        id: functionSelector
                        Layout.fillWidth: true
                        model: ["Select function...", "Sum All", "Average", "Max", "Min", "Multiply All"]
                        onActivated: {
                            if (currentIndex > 0) {
                                calculateFunction(currentIndex);
                                currentIndex = 0;
                            }
                        }
                    }
                    
                    Rectangle { 
                        height: 1 
                        Layout.fillWidth: true
                        color: "gray"
                        opacity: 0.5
                    }
                    
                    // Basic operations
                    OperationButton {
                        text: "+"
                        onClicked: calculate("add")
                        Layout.fillWidth: true
                    }
                    
                    OperationButton {
                        text: "−"
                        onClicked: calculate("subtract")
                        Layout.fillWidth: true
                    }
                    
                    OperationButton {
                        text: "×"
                        onClicked: calculate("multiply")
                        Layout.fillWidth: true
                    }
                    
                    OperationButton {
                        text: "÷"
                        onClicked: calculate("divide")
                        Layout.fillWidth: true
                    }
                    
                    Rectangle { 
                        height: 1 
                        Layout.fillWidth: true
                        color: "gray"
                        opacity: 0.5
                    }
                    
                    StyledButton {
                        text: "Clear All"
                        Layout.fillWidth: true
                        onClicked: {
                            for (let i = 0; i < parameters.length; i++) {
                                parameters[i].value = "0";
                            }
                            updateParameterFields();
                            resultField.text = "0";
                        }
                    }
                }
            }
        }
    }
    
    function calculate(operation) {
        if (parameters.length < 2) {
            resultField.text = "Need at least 2 parameters";
            return;
        }
        
        let param1 = parseFloat(parameters[0].value);
        let param2 = parseFloat(parameters[1].value);
        
        if (isNaN(param1) || isNaN(param2)) {
            resultField.text = "Error";
            return;
        }
        
        switch(operation) {
            case "add":
                resultField.text = (param1 + param2).toString();
                break;
            case "subtract":
                resultField.text = (param1 - param2).toString();
                break;
            case "multiply":
                resultField.text = (param1 * param2).toString();
                break;
            case "divide":
                if (param2 === 0) {
                    resultField.text = "Error: Div by 0";
                } else {
                    resultField.text = (param1 / param2).toString();
                }
                break;
        }
    }
    
    function calculateFunction(funcIndex) {
        if (parameters.length === 0) {
            resultField.text = "No parameters";
            return;
        }
        
        let values = [];
        for (let i = 0; i < parameters.length; i++) {
            let val = parseFloat(parameters[i].value);
            if (!isNaN(val)) {
                values.push(val);
            }
        }
        
        if (values.length === 0) {
            resultField.text = "No valid values";
            return;
        }
        
        switch(funcIndex) {
            case 1: // Sum All
                resultField.text = values.reduce((a, b) => a + b, 0).toString();
                break;
            case 2: // Average
                resultField.text = (values.reduce((a, b) => a + b, 0) / values.length).toString();
                break;
            case 3: // Max
                resultField.text = Math.max(...values).toString();
                break;
            case 4: // Min
                resultField.text = Math.min(...values).toString();
                break;
            case 5: // Multiply All
                resultField.text = values.reduce((a, b) => a * b, 1).toString();
                break;
        }
    }
    
    component OperationButton: Rectangle {
        property string text: ""
        signal clicked
        
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: 4
        color: Universal.theme === Universal.Dark ? "#505050" : "#e0e0e0"
        
        Text {
            anchors.centerIn: parent
            text: parent.text
            font.pixelSize: 20
            font.bold: true
            color: Universal.foreground
        }
        
        MouseArea {
            anchors.fill: parent
            onPressed: parent.color = Universal.theme === Universal.Dark ? "#606060" : "#d0d0d0"
            onReleased: parent.color = Universal.theme === Universal.Dark ? "#505050" : "#e0e0e0"
            onClicked: parent.clicked()
        }
    }
}
