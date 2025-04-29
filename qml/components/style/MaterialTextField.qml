import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "."

TextField {
    id: control
    
    // Custom properties for Material design
    property bool filled: true
    property color accentColor: Universal.accent
    property color placeholderColor: window.modeToggled ? "white" : "#99000000" // 60% opacity black
    property real placeholderPadding: 8
    
    // Override the default placeholder behavior
    property string _placeholderText: ""  // Internal property to store placeholder text
    
    // Override the default placeholderText property
    placeholderText: ""  // Set to empty to hide the default placeholder
    
    // Handle the placeholder text properly
    Component.onCompleted: {
        _placeholderText = placeholderText !== "" ? placeholderText : _placeholderText
        placeholder.text = _placeholderText
    }

    // Update custom placeholder when public property changes
    onPlaceholderTextChanged: {
        if (placeholderText !== "") {
            _placeholderText = placeholderText
            placeholder.text = _placeholderText
            placeholderText = ""  // Clear it again to prevent the default placeholder
        }
    }

    // Create placeholder text component
    Item {

        width: placeholder.contentWidth + 4
        height: contentHeight
        anchors.fill: undefined

        // The actual text element
        Label {
            id: placeholder
            anchors.fill: parent
            text: "Placeholder"
            color: placeholderColor

            background: Rectangle {
                color: control.background.color
                anchors.fill: parent
                anchors.leftMargin: -5
            }

            // Change color when focused
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        // Position the placeholder text
        y: {
            if (control.activeFocus || control.text.length > 0) {
                return -height / 2;  // Center on the top border
            } else {
                return (control.height - height) / 2;  // Center in the field
            }
        }
        
        x: (control.activeFocus || control.text.length > 0) ? 
           (control.leftPadding + 5) : control.leftPadding

        // Smooth transitions
        Behavior on y {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }
        Behavior on x {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }

        states: [
            State {
                name: "focused"
                when: control.activeFocus
                PropertyChanges {
                    target: placeholder
                    color: accentColor
                }
            }
        ]
    }
}
