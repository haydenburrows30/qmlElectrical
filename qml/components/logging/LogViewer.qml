import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import "../popups"

Rectangle {
    id: logViewer

    // Color setup with null checks for window
    property color textColor: window ? (window.modeToggled ? "white" : "black") : "black"
    property color bgColor: window ? (window.modeToggled ? "#333333" : "#f0f0f0") : "#f0f0f0"
    property color borderColor: window ? (window.modeToggled ? "#555555" : "#cccccc") : "#cccccc"

    color: bgColor
    
    property var logManager: null
    property bool autoScroll: true

    // Function to update statistics text
    function updateStatistics() {
        if (logManager) {
            statusLogCount.text = logManager.count ? "Log count: " + logManager.count : "Log count: 0"
            
            let stats = "";
            if (logManager.getLogStats) {
                stats = logManager.getLogStats();
            }
            if (logManager.getHistoryStats) {
                if (stats) stats += " | ";
                stats += logManager.getHistoryStats();
            }
            statusLogStats.text = stats;
        }
    }

    function openDebugTools() {
        var component = Qt.createComponent("LogDebuggerPopup.qml")
        if (component.status === Component.Ready) {
            var debugPopup = component.createObject(window || logViewer, {
                "logManager": logManager
            })
            if (debugPopup) {
                debugPopup.open()
            } else {
                console.error("Error creating debug popup instance")
            }
        } else {
            console.error("Error loading LogDebuggerPopup:", component.errorString())
        }
    }

    MessagePopup {
        id: messagePopup
    }

    Connections {
        target: logManager

        function onExportDataToFolderCompleted(success, message) {
            if (success) {
                messagePopup.showSuccess(message);
            } else {
                messagePopup.showError(message);
            }
        }
    }

    // Use Item instead of ColumnLayout to avoid recursion
    Item {
        id: mainContainer
        anchors.fill: parent
        anchors.margins: 8

        // Control row at top
        Row {
            id: controlRow
            width: parent.width
            height: 40
            spacing: 10

            CheckBox {
                id: autoScrollCheckbox
                text: "Auto-scroll"
                checked: autoScroll
                anchors.verticalCenter: parent.verticalCenter
                onCheckedChanged: {
                    autoScroll = checked
                }
            }

            Button {
                text: "Clear Logs"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    if (logManager) {
                        logManager.clearLogs()
                        updateStatistics()
                    }
                }
            }
            
            Button {
                text: "Save Logs"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    if (logManager) {
                        logManager.saveCurrentView()
                    }
                }
            }
            
            Button {
                text: "View Log File"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    if (logManager) {
                        logManager.openLogFile()
                    }
                }
            }
            
            Button {
                text: "Debug Tools"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    openDebugTools()
                }
            }
        }

        // Log view area
        Rectangle {
            id: logViewBorder
            anchors.top: controlRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: statusRow.top
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            color: "transparent"
            border.width: 1
            border.color: borderColor
            clip: true

            ListView {
                id: logListView
                anchors.fill: parent
                anchors.margins: 5
                model: logManager ? logManager.model : null
                clip: true
                
                // Add a placeholder text when there are no logs
                Text {
                    anchors.centerIn: parent
                    text: "No log entries to display"
                    visible: logListView.count === 0
                    color: textColor
                    font.pixelSize: 14
                }
                
                delegate: Rectangle {
                    width: logListView.width
                    height: logText.height + 10
                    // Add a property to store the UID for this log entry
                    property string messageUid: uid ? uid : ""
                    
                    color: {
                        if (level === "ERROR" || level === "CRITICAL")
                            return window && window.modeToggled ? "#552222" : "#ffeeee"
                        else if (level === "WARNING")
                            return window && window.modeToggled ? "#554422" : "#fff8e8"
                        else
                            return "transparent"
                    }
                    border.width: 0
                    
                    Text {
                        id: logText
                        text: formatted
                        width: parent.width - 16  // Leave space for padding
                        wrapMode: Text.Wrap
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        font.pixelSize: 12
                        font.family: "Courier New, Courier, monospace"
                        color: {
                            if (level === "ERROR" || level === "CRITICAL")
                                return window && window.modeToggled ? "#ff6666" : "#990000"
                            else if (level === "WARNING")
                                return window && window.modeToggled ? "#ffcc66" : "#996600"
                            else
                                return window && window.modeToggled ? "white" : "black"
                        }
                    }
                }
                
                ScrollBar.vertical: ScrollBar { }
                
                // Auto-scroll to bottom when new logs arrive
                onCountChanged: {
                    if (autoScroll) {
                        positionViewAtEnd()
                    }
                    updateStatistics()
                }
            }
        }

        // Status row at bottom
        RowLayout {
            id: statusRow
            width: parent.width
            height: 20
            anchors.bottom: parent.bottom
            
            Label {
                id: statusLogCount
                text: logManager && logManager.count ? "Log count: " + logManager.count : "Log count: 0"
                color: textColor
                font.pixelSize: 12
                Layout.minimumWidth: 80
            }
            
            Label {
                id: statusLogStats
                text: ""  // Will be set by updateStatistics()
                color: textColor
                font.pixelSize: 12
                Layout.minimumWidth: 200
                Layout.alignment: Qt.AlignRight
            }
        }
    }
    
    Connections {
        target: logManager
        
        function onLogCountChanged(count) {
            updateStatistics()
        }
        
        function onStatisticsChanged() {
            updateStatistics()
        }
        
        function onNewLogMessage(level, message) {
            // Force ListView to re-evaluate count
            logListView.forceLayout()
            if (autoScroll) {
                logListView.positionViewAtEnd()
            }
        }
    }
    
    Component.onCompleted: {
        updateStatistics()
        
        // Force a reload of logs from file
        if (logManager && logManager.reloadLogsFromFile) {
            logManager.reloadLogsFromFile()
        }
    }
}
