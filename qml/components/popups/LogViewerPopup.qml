import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"

Popup {
    id: root
    width: 800
    height: 500
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    // Add property for log manager
    property var logManager: null
    
    // Center in parent
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    
    background: Rectangle {
        color: Universal.theme === Universal.Dark ? "#2d2d2d" : "#f5f5f5"
        border.color: Universal.theme === Universal.Dark ? "#3d3d3d" : "#e0e0e0"
        border.width: 1
        radius: 4
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: Universal.theme === Universal.Dark ? "#1d1d1d" : "#e5e5e5"
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                
                Label {
                    text: "Application Logs"
                    font.bold: true
                    font.pixelSize: 16
                }
                
                Item { Layout.fillWidth: true }
                
                Button {
                    text: "Close"
                    onClicked: root.close()
                }
            }
        }
        
        // Log viewer
        LogViewer {
            id: logViewer
            Layout.fillWidth: true
            Layout.fillHeight: true
            showToolbar: true
            autoScroll: true
            logManager: root.logManager  // Pass the logManager to the LogViewer
            
            // Handle log entry clicks
            onLogEntryClicked: function(logEntry) {
                detailsArea.text = logEntry.formatted
                detailsPopup.open()
            }
        }
    }
    
    // Popup for showing log details
    Popup {
        id: detailsPopup
        width: 600
        height: 200
        modal: true
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        
        background: Rectangle {
            color: Universal.theme === Universal.Dark ? "#2d2d2d" : "#f5f5f5"
            border.color: Universal.theme === Universal.Dark ? "#3d3d3d" : "#e0e0e0"
            border.width: 1
            radius: 4
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            
            Label {
                text: "Log Details"
                font.bold: true
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                TextArea {
                    id: detailsArea
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                }
            }
            
            Button {
                text: "Close"
                onClicked: detailsPopup.close()
                Layout.alignment: Qt.AlignRight
            }
        }
    }
    
    // Methods to allow direct access to the log viewer
    function log(level, message) {
        logViewer.log(level, message)
    }
    
    function copyLogs() {
        logViewer.copyRequested()
    }
}
