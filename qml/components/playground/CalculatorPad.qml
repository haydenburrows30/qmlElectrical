import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../style"

Item {
    id: root
    
    // Customizable properties
    property color buttonColor: Universal.theme === Universal.Dark ? "#333333" : "#f0f0f0"
    property color buttonPressedColor: Universal.theme === Universal.Dark ? "#444444" : "#d0d0d0"
    property color operatorColor: Universal.theme === Universal.Dark ? "#505050" : "#e0e0e0"
    property color accentColor: Universal.accent
    property color textColor: Universal.foreground
    property real buttonRadius: 4
    property real buttonSpacing: 8
    
    // Function that will be called when buttons are pressed
    signal buttonClicked(string value)
    
    // Grid layout for the calculator buttons
    GridLayout {
        id: buttonGrid
        anchors.fill: parent
        columns: 4
        rowSpacing: buttonSpacing
        columnSpacing: buttonSpacing
        
        // Numeric buttons 7-9
        CalcButton { text: "7"; onClicked: buttonClicked(text) }
        CalcButton { text: "8"; onClicked: buttonClicked(text) }
        CalcButton { text: "9"; onClicked: buttonClicked(text) }
        CalcButton { text: "÷"; isOperator: true; onClicked: buttonClicked("/") }
        
        // Numeric buttons 4-6
        CalcButton { text: "4"; onClicked: buttonClicked(text) }
        CalcButton { text: "5"; onClicked: buttonClicked(text) }
        CalcButton { text: "6"; onClicked: buttonClicked(text) }
        CalcButton { text: "×"; isOperator: true; onClicked: buttonClicked("*") }
        
        // Numeric buttons 1-3
        CalcButton { text: "1"; onClicked: buttonClicked(text) }
        CalcButton { text: "2"; onClicked: buttonClicked(text) }
        CalcButton { text: "3"; onClicked: buttonClicked(text) }
        CalcButton { text: "-"; isOperator: true; onClicked: buttonClicked(text) }
        
        // Bottom row
        CalcButton { text: "0"; onClicked: buttonClicked(text) }
        CalcButton { text: "."; onClicked: buttonClicked(text) }
        CalcButton { text: "C"; isOperator: true; onClicked: buttonClicked("clear") }
        CalcButton { text: "+"; isOperator: true; onClicked: buttonClicked(text) }
        
        // Last row with special buttons
        CalcButton { 
            text: "±"; 
            isOperator: true; 
            Layout.columnSpan: 1; 
            onClicked: buttonClicked("negate") 
        }
        CalcButton { 
            text: "⌫"; 
            isOperator: true; 
            Layout.columnSpan: 1; 
            onClicked: buttonClicked("backspace") 
        }
        CalcButton { 
            text: "="; 
            isAccent: true; 
            Layout.columnSpan: 2; 
            onClicked: buttonClicked("equals") 
        }
    }
    
    // Component for calculator buttons
    component CalcButton: Rectangle {
        id: button
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 45
        Layout.minimumWidth: 45
        
        property string text: ""
        property bool isOperator: false
        property bool isAccent: false
        signal clicked
        
        radius: buttonRadius
        color: isAccent ? accentColor : (isOperator ? operatorColor : buttonColor)
        
        Text {
            anchors.centerIn: parent
            text: button.text
            font.pixelSize: 18
            font.bold: isAccent
            color: isAccent ? "white" : textColor
        }
        
        MouseArea {
            anchors.fill: parent
            onPressed: button.color = buttonPressedColor
            onReleased: button.color = isAccent ? accentColor : (isOperator ? operatorColor : buttonColor)
            onClicked: button.clicked()
        }
    }
}
