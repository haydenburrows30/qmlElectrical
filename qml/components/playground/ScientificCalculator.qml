import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import "../style"


Item {
    id: calculatorCard
    
    property string displayText: "0"
    property string memory: ""
    property string operation: ""
    property bool clearOnNextInput: true
    property var lastValue: 0
    property bool hasDecimal: false
    
    function evaluate() {
        try {
            let result = Function('"use strict";return (' + displayText + ')')();
            if (isNaN(result) || !isFinite(result)) {
                displayText = "Error";
            } else {
                displayText = result.toString();
            }
        } catch (e) {
            displayText = "Error";
        }
        clearOnNextInput = true;
    }
    
    function handleButtonPress(value) {
        switch(value) {
            case "clear":
                displayText = "0";
                clearOnNextInput = true;
                hasDecimal = false;
                break;
            case "backspace":
                if (displayText.length > 1) {
                    // Check if we're removing a decimal point
                    if (displayText[displayText.length - 1] === '.') {
                        hasDecimal = false;
                    }
                    displayText = displayText.substring(0, displayText.length - 1);
                } else {
                    displayText = "0";
                    clearOnNextInput = true;
                }
                break;
            case "equals":
                evaluate();
                break;
            case "negate":
                if (displayText !== "0" && displayText !== "Error") {
                    if (displayText.startsWith('-')) {
                        displayText = displayText.substring(1);
                    } else {
                        displayText = "-" + displayText;
                    }
                }
                break;
            case "+":
            case "-":
            case "*":
            case "/":
                // If there's already an operation in the display, evaluate it first
                if (displayText.includes('+') || displayText.includes('-') || 
                    displayText.includes('*') || displayText.includes('/')) {
                    evaluate();
                }
                displayText += value;
                clearOnNextInput = false;
                hasDecimal = false;
                break;
            case ".":
                if (!hasDecimal) {
                    if (clearOnNextInput) {
                        displayText = "0.";
                        clearOnNextInput = false;
                    } else {
                        displayText += ".";
                    }
                    hasDecimal = true;
                }
                break;
            default: // Numeric input
                if (clearOnNextInput) {
                    displayText = value;
                    clearOnNextInput = false;
                } else {
                    displayText += value;
                }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        // Top toolbar for common actions
        RowLayout {
            Layout.fillWidth: true
            height: 40
            spacing: 8
            
            ToolButton {
                text: "Reset"
                icon.source: "qrc:/icons/reset.svg"
                ToolTip.text: "Reset calculator"
                ToolTip.visible: hovered
                onClicked: {
                    displayText = "0";
                    clearOnNextInput = true;
                    hasDecimal = false;
                    memory = "";
                    operation = "";
                }
            }
            
            ToolButton {
                text: "MC"
                ToolTip.text: "Memory Clear"
                ToolTip.visible: hovered
                onClicked: memory = ""
            }
            
            ToolButton {
                text: "MR"
                ToolTip.text: "Memory Recall"
                ToolTip.visible: hovered
                enabled: memory !== ""
                onClicked: {
                    if (memory !== "") {
                        displayText = memory;
                        clearOnNextInput = true;
                    }
                }
            }
            
            ToolButton {
                text: "MS"
                ToolTip.text: "Memory Store"
                ToolTip.visible: hovered
                onClicked: memory = displayText
            }
            
            ToolButton {
                text: "M+"
                ToolTip.text: "Memory Add"
                ToolTip.visible: hovered
                onClicked: {
                    if (memory === "") {
                        memory = displayText;
                    } else {
                        let result = parseFloat(memory) + parseFloat(displayText);
                        memory = result.toString();
                    }
                }
            }
            
            Item { Layout.fillWidth: true } // Spacer
            
            ComboBox {
                id: functionMenu
                model: [
                    "Functions", 
                    "sin", "cos", "tan", 
                    "asin", "acos", "atan", 
                    "log", "ln", "exp", 
                    "x²", "√x", "π"
                ]
                
                onActivated: {
                    if (currentIndex !== 0) {
                        let funcName;
                        switch (currentIndex) {
                            case 1: funcName = "sin"; break;
                            case 2: funcName = "cos"; break;
                            case 3: funcName = "tan"; break;
                            case 4: funcName = "asin"; break;
                            case 5: funcName = "acos"; break;
                            case 6: funcName = "atan"; break;
                            case 7: funcName = "log"; break;
                            case 8: funcName = "ln"; break;
                            case 9: funcName = "exp"; break;
                            case 10: funcName = "square"; break;
                            case 11: funcName = "sqrt"; break;
                            case 12: funcName = "pi"; break;
                        }
                        
                        handleSciFunc(funcName);
                        currentIndex = 0; // Reset to "Functions"
                    }
                }
            }
        }
        
        WaveCard {
            Layout.fillWidth: true
            Layout.minimumHeight: 70
            
            Rectangle {
                anchors.fill: parent
                anchors.margins: 8
                color: Universal.theme === Universal.Dark ? "#252525" : "#f8f8f8"
                border.color: Universal.theme === Universal.Dark ? "#444" : "#ddd"
                radius: 4
                
                Text {
                    id: display
                    anchors.fill: parent
                    anchors.margins: 8
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    text: displayText
                    font.pixelSize: 24
                    font.bold: true
                    color: Universal.foreground
                    elide: Text.ElideRight
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 12
                }
            }
        }
        
        WaveCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12
                
                // Scientific functions - can be expanded
                GridLayout {
                    Layout.preferredWidth: parent.width * 0.25
                    Layout.fillHeight: true
                    columns: 1
                    rowSpacing: 8
                    
                    SciFuncButton { text: "sin"; onClicked: handleSciFunc("sin") }
                    SciFuncButton { text: "cos"; onClicked: handleSciFunc("cos") }
                    SciFuncButton { text: "tan"; onClicked: handleSciFunc("tan") }
                    SciFuncButton { text: "log"; onClicked: handleSciFunc("log") }
                    SciFuncButton { text: "ln"; onClicked: handleSciFunc("ln") }
                    SciFuncButton { text: "x²"; onClicked: handleSciFunc("square") }
                    SciFuncButton { text: "π"; onClicked: handleSciFunc("pi") }
                }
                
                // Main calculator pad
                CalculatorPad {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onButtonClicked: handleButtonPress(value)
                }
            }
        }
    }
    
    function handleSciFunc(func) {
        let value = parseFloat(displayText);
        
        if (isNaN(value) || displayText === "Error") {
            displayText = "Error";
            return;
        }
        
        switch(func) {
            case "sin":
                displayText = Math.sin(value).toFixed(6);
                break;
            case "cos":
                displayText = Math.cos(value).toFixed(6);
                break;
            case "tan":
                displayText = Math.tan(value).toFixed(6);
                break;
            case "asin":
                if (value < -1 || value > 1) {
                    displayText = "Error";
                } else {
                    displayText = Math.asin(value).toFixed(6);
                }
                break;
            case "acos":
                if (value < -1 || value > 1) {
                    displayText = "Error";
                } else {
                    displayText = Math.acos(value).toFixed(6);
                }
                break;
            case "atan":
                displayText = Math.atan(value).toFixed(6);
                break;
            case "log":
                if (value <= 0) {
                    displayText = "Error";
                } else {
                    displayText = Math.log10(value).toFixed(6);
                }
                break;
            case "ln":
                if (value <= 0) {
                    displayText = "Error";
                } else {
                    displayText = Math.log(value).toFixed(6);
                }
                break;
            case "exp":
                displayText = Math.exp(value).toString();
                break;
            case "square":
                displayText = (value * value).toString();
                break;
            case "sqrt":
                if (value < 0) {
                    displayText = "Error";
                } else {
                    displayText = Math.sqrt(value).toString();
                }
                break;
            case "pi":
                displayText = Math.PI.toString();
                break;
        }
        
        // Remove trailing zeros after decimal
        if (displayText.includes('.')) {
            displayText = displayText.replace(/\.?0+$/, "");
            // If only the decimal point is left, remove it too
            if (displayText.endsWith('.')) {
                displayText = displayText.slice(0, -1);
            }
        }
        
        clearOnNextInput = true;
    }
    
    component SciFuncButton: Rectangle {
        property string text
        signal clicked
        
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 4
        color: Universal.theme === Universal.Dark ? "#444444" : "#e8e8e8"
        
        Text {
            anchors.centerIn: parent
            text: parent.text
            font.pixelSize: 14
            color: Universal.foreground
        }
        
        MouseArea {
            anchors.fill: parent
            onPressed: parent.color = Universal.theme === Universal.Dark ? "#555555" : "#d0d0d0"
            onReleased: parent.color = Universal.theme === Universal.Dark ? "#444444" : "#e8e8e8"
            onClicked: parent.clicked()
        }
    }
}
