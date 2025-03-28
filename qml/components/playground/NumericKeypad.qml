import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

Item {
    id: keypad
    
    property color buttonColor: Universal.theme === Universal.Dark ? "#333333" : "#f0f0f0"
    property color buttonPressedColor: Universal.theme === Universal.Dark ? "#444444" : "#d0d0d0"
    property color accentColor: Universal.accent
    property color textColor: Universal.foreground
    property string currentInput: "0"
    property bool clearOnNextDigit: true
    property bool allowDecimals: true
    
    signal valueEntered(string finalValue)
    
    function appendDigit(digit) {
        if (clearOnNextDigit) {
            currentInput = digit;
            clearOnNextDigit = false;
        } else {
            currentInput += digit;
        }
    }
    
    function appendDecimal() {
        if (!allowDecimals) return;
        
        if (clearOnNextDigit) {
            currentInput = "0.";
            clearOnNextDigit = false;
        } else if (!currentInput.includes(".")) {
            currentInput += ".";
        }
    }
    
    function backspace() {
        if (currentInput.length > 1) {
            currentInput = currentInput.substring(0, currentInput.length - 1);
        } else {
            currentInput = "0";
            clearOnNextDigit = true;
        }
    }
    
    function clearInput() {
        currentInput = "0";
        clearOnNextDigit = true;
    }
    
    function negateInput() {
        if (currentInput === "0") return;
        
        if (currentInput.startsWith("-")) {
            currentInput = currentInput.substring(1);
        } else {
            currentInput = "-" + currentInput;
        }
    }
    
    function submitValue() {
        valueEntered(currentInput);
        clearOnNextDigit = true;
    }
    
    GridLayout {
        anchors.fill: parent
        columns: 3
        rowSpacing: 8
        columnSpacing: 8
        
        // Row 1
        KeypadButton { text: "7"; onClicked: appendDigit("7") }
        KeypadButton { text: "8"; onClicked: appendDigit("8") }
        KeypadButton { text: "9"; onClicked: appendDigit("9") }
        
        // Row 2
        KeypadButton { text: "4"; onClicked: appendDigit("4") }
        KeypadButton { text: "5"; onClicked: appendDigit("5") }
        KeypadButton { text: "6"; onClicked: appendDigit("6") }
        
        // Row 3
        KeypadButton { text: "1"; onClicked: appendDigit("1") }
        KeypadButton { text: "2"; onClicked: appendDigit("2") }
        KeypadButton { text: "3"; onClicked: appendDigit("3") }
        
        // Row 4
        KeypadButton { text: "±"; onClicked: negateInput() }
        KeypadButton { text: "0"; onClicked: appendDigit("0") }
        KeypadButton { text: "."; onClicked: appendDecimal(); enabled: allowDecimals }
        
        // Row 5
        KeypadButton { text: "⌫"; onClicked: backspace() }
        KeypadButton { text: "C"; onClicked: clearInput() }
        KeypadButton { 
            text: "✓"; 
            color: accentColor; 
            textColor: "white"; 
            onClicked: submitValue() 
        }
    }
    
    component KeypadButton: Rectangle {
        property string text: ""
        property alias enabled: mouseArea.enabled
        property color color: buttonColor
        property color pressedColor: buttonPressedColor
        property color textColor: keypad.textColor
        
        signal clicked
        
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 40
        Layout.minimumWidth: 40
        
        radius: 4
        // color: enabled ? (mouseArea.pressed ? pressedColor : color) : Qt.lighter(color, 1.3)
        
        Text {
            anchors.centerIn: parent
            text: parent.text
            font.pixelSize: 18
            opacity: parent.enabled ? 1.0 : 0.5
            color: parent.textColor
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onPressed: parent.color = parent.enabled ? pressedColor : Qt.lighter(color, 1.3)
            onReleased: parent.color = parent.enabled ? 
                (parent.text === "✓" ? accentColor : color) : 
                Qt.lighter(color, 1.3)
            onClicked: parent.clicked()
        }
    }
}
