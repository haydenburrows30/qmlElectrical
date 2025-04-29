import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components/style"
Page {

    
    ColumnLayout {
        anchors {
            fill: parent
            margins: 20
        }
        spacing: 24
        
        Label {
            text: "Material Design Text Fields"
            font.pixelSize: 24
            font.weight: Font.Medium
            Layout.fillWidth: true
        }
        
        // Filled style (default)
        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: "Full Name"
            Layout.minimumHeight: 100
            // filled: false
        }
        
        // Outlined style
        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: "Email Address"
            // filled: false
        }
        
        // With initial text
        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: "Phone Number"
            text: "+1 555-123-4567"
        }
        
        // With custom accent color
        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: "Password"
            accentColor: "#F44336"  // Red
            echoMode: TextField.Password
        }
        
        // Disabled state
        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: "Disabled Field"
            enabled: false
        }
        
        Item { Layout.fillHeight: true } // Spacer
    }
}