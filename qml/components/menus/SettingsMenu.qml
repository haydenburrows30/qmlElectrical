import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCore

Popup {
    id: settingsPopup
    
    width: 400
    height: contentColumn.implicitHeight + 40
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    Component.onCompleted: {
        // Apply saved setting when component loads
        if (typeof perfMonitor !== 'undefined' && typeof appConfig !== 'undefined') {
            var enabled = appConfig.get_setting("performance_monitor_enabled", true);
            perfMonitor.enabled = enabled;
            perfMonitorSwitch.checked = enabled;
        }
    }
    
    Rectangle {
        anchors.fill: parent
        color: Universal.theme === Universal.Dark ? "#2c2c2c" : "#f0f0f0"
        border.color: Universal.theme === Universal.Dark ? "#444444" : "#cccccc"
        border.width: 1
        radius: 5
        
        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
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
            
            Item { 
                Layout.fillHeight: true 
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                Button {
                    text: "Close"
                    onClicked: settingsPopup.close()
                }
            }
        }
    }
}
