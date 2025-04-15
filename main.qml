import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    visible: true
    width: 360
    height: 500
    title: "QML Calculator"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        // Display for the result
        Rectangle {
            Layout.fillWidth: true
            height: 80
            color: "#f0f0f0"
            border.color: "#cccccc"
            
            TextInput {
                id: display
                anchors.fill: parent
                anchors.margins: 10
                font.pixelSize: 24
                horizontalAlignment: TextInput.AlignRight
                verticalAlignment: TextInput.AlignVCenter
                text: "0"
                readOnly: true
            }
        }
        
        // Input field for expressions
        TextField {
            id: expressionInput
            Layout.fillWidth: true
            placeholderText: "Enter expression (e.g., 5+3*2)"
            font.pixelSize: 18
            onAccepted: calculateBtn.clicked()
        }
        
        // Buttons
        RowLayout {
            Layout.fillWidth: true
            
            Button {
                id: calculateBtn
                text: "Calculate"
                Layout.fillWidth: true
                onClicked: {
                    if (expressionInput.text.trim() !== "") {
                        display.text = calculator.calculate(expressionInput.text)
                    }
                }
            }
            
            Button {
                text: "Clear"
                Layout.fillWidth: true
                onClicked: {
                    expressionInput.text = ""
                    display.text = "0"
                }
            }
        }
        
        // Example of using the fast computation
        RowLayout {
            Layout.fillWidth: true
            
            Slider {
                id: inputSlider
                from: 0
                to: 10
                value: 1
                Layout.fillWidth: true
            }
            
            Button {
                text: "Compute"
                onClicked: {
                    display.text = calculator.fastComputation(inputSlider.value)
                }
            }
        }
        
        // Keypad grid for calculator
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 5
            columnSpacing: 5
            
            // Define a component for calculator buttons
            Component {
                id: calcButton
                Button {
                    required property string label
                    text: label
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    onClicked: expressionInput.text += label
                }
            }
            
            // Numbers and operations
            Repeater {
                model: ["7", "8", "9", "/", "4", "5", "6", "*", "1", "2", "3", "-", "0", ".", "=", "+"]
                delegate: calcButton {
                    label: modelData
                    onClicked: {
                        if (label === "=") {
                            calculateBtn.clicked()
                        } else {
                            expressionInput.text += label
                        }
                    }
                }
            }
        }
    }
}
