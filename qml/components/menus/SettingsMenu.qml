import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCore

Popup {
    id: settingsPopup

    width: 350
    height: contentColumn.implicitHeight + 50
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0
    anchors.centerIn: Overlay.overlay

    property bool componentInit: false
    
    Component.onCompleted: {
        // Apply saved setting when component loads
        if (typeof perfMonitor !== 'undefined' && typeof appConfig !== 'undefined') {
            var enabled = appConfig.get_setting("performance_monitor_enabled", false);
            perfMonitor.enabled = enabled;
            perfMonitorSwitch.checked = enabled;
            
            // Load voltage default
            var defaultVoltage = appConfig.get_setting("default_voltage", "415V");
            if (defaultVoltage === "415V") {
                voltageComboBox.currentIndex = 1
            } else voltageComboBox.currentIndex = 0

            componentInit = true
        }
    }
    
    Rectangle {
        anchors.fill: parent
        anchors.margins: -5 // cover popup window border
        color: Universal.theme === Universal.Dark ? "#2c2c2c" : "#f0f0f0"
        border.color: Universal.theme === Universal.Dark ? "#444444" : "#cccccc"
        border.width: 1
        radius: 5

        
        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10
            
            Label {
                text: "Settings"
                font.pixelSize: 20
                font.bold: true
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Universal.theme === Universal.Dark ? "#444444" : "#dddddd"
            }
            
            // Performance section
            Label {
                text: "Performance"
                font.pixelSize: 16
                font.bold: true
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Label {
                    text: "Performance Monitor"
                    Layout.fillWidth: true
                }
                
                Switch {
                    id: perfMonitorSwitch
                    checked: true // Will be updated in Component.onCompleted
                    
                    onCheckedChanged: {
                        if (typeof perfMonitor !== 'undefined' && typeof appConfig !== 'undefined') {
                            perfMonitor.enabled = checked;
                            appConfig.save_setting("performance_monitor_enabled", checked);
                        }
                    }
                }
            }
            
            // Calculation defaults section
            Label {
                text: "Calculation Defaults"
                font.pixelSize: 16
                font.bold: true
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Label {
                    text: "Default Voltage"
                    Layout.fillWidth: true
                }
                
                ComboBox {
                    id: voltageComboBox
                    model: ["230V", "415V"]
                    
                    // make sure the setting is loaded from the database and combobox index is set
                    // before saving the setting
                    onCurrentTextChanged: {
                        if (typeof appConfig !== 'undefined' && componentInit == true) {
                            appConfig.save_setting("default_voltage", currentText);
                            console.log("default voltage changed to:" + currentText)
                        }
                    }
                }
            }
            
            Item { 
                Layout.fillHeight: true 
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                Button {
                    text: "Reset All Settings"
                    onClicked: {
                        resetConfirmDialog.open();
                    }
                }
                
                Button {
                    text: "Close"
                    onClicked: settingsPopup.close()
                }
            }
        }
    }
    
    Dialog {
        id: resetConfirmDialog
        title: "Reset Settings"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        
        Label {
            text: "Are you sure you want to reset all settings to default values?"
            width: parent.width
            wrapMode: Text.WordWrap
        }
        
        onAccepted: {
            // Reset all settings to default
            if (typeof appConfig !== 'undefined') {
                appConfig.save_setting("performance_monitor_enabled", false);
                appConfig.save_setting("default_voltage", "415V");
                
                // Update UI
                perfMonitorSwitch.checked = false;
                voltageComboBox.currentIndex = 1;
                
                // Apply settings where needed
                if (typeof perfMonitor !== 'undefined') {
                    perfMonitor.enabled = false;
                }
            }
        }
    }
}
