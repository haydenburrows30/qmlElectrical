import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import Logger 1.0

Rectangle {
    id: root
    color: Universal.theme === Universal.Dark ? "#2d2d2d" : "#f5f5f5"
    border.color: Universal.theme === Universal.Dark ? "#3d3d3d" : "#e0e0e0"
    border.width: 1
    radius: 4

    // Properties that can be set from the parent
    property bool autoScroll: true
    property bool showToolbar: true
    property int maxHeight: 300
    property int maxEntries: 1000
    property bool showTimestamp: true
    
    // Add a required logManager property
    property var logManager: null

    // Internal properties
    property var levelColors: ({
        "DEBUG": Universal.theme === Universal.Dark ? "#9e9e9e" : "#757575",
        "INFO": Universal.theme === Universal.Dark ? "#64b5f6" : "#2196f3",
        "WARNING": Universal.theme === Universal.Dark ? "#ffb74d" : "#ff9800",
        "ERROR": Universal.theme === Universal.Dark ? "#e57373" : "#f44336",
        "CRITICAL": Universal.theme === Universal.Dark ? "#f06292" : "#e91e63"
    })

    // Signal when user requests to copy logs
    signal copyRequested()
    
    // Signal when user clicks on a log entry
    signal logEntryClicked(var logEntry)
    
    // Show a fallback when no logManager is provided
    Rectangle {
        anchors.fill: parent
        visible: !logManager
        color: "transparent"
        
        Text {
            anchors.centerIn: parent
            text: "No log manager provided"
            color: Universal.foreground
            font.italic: true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: logManager !== null

        // Toolbar with controls
        Rectangle {
            id: toolbar
            Layout.fillWidth: true
            height: showToolbar ? 40 : 0
            visible: showToolbar
            color: Universal.theme === Universal.Dark ? "#1d1d1d" : "#e5e5e5"
            radius: 4

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Label {
                    text: "Log Level:"
                    font.pixelSize: 12
                }

                ComboBox {
                    id: logLevelCombo
                    model: ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
                    currentIndex: 1  // Default to INFO
                    font.pixelSize: 12
                    Layout.preferredWidth: 100

                    onCurrentTextChanged: {
                        if (logManager) {
                            logManager.setFilterLevel(currentText)
                        }
                    }

                    Component.onCompleted: {
                        if (logManager) {
                            logManager.setFilterLevel(currentText)
                        }
                    }
                }

                Item { Layout.fillWidth: true }  // Spacer

                ToolButton {
                    text: "Clear"
                    font.pixelSize: 12
                    onClicked: if (logManager) logManager.clearLogs()
                    ToolTip.visible: hovered
                    ToolTip.text: "Clear all logs"
                }

                ToolButton {
                    text: "Copy"
                    font.pixelSize: 12
                    onClicked: copyRequested()
                    ToolTip.visible: hovered
                    ToolTip.text: "Copy logs to clipboard"
                }
                
                // Add a new button to open the log file directly
                ToolButton {
                    text: "Open File"
                    font.pixelSize: 12
                    onClicked: if (logManager) logManager.openLogFile()
                    ToolTip.visible: hovered
                    ToolTip.text: "Open log file in default editor"
                }

                CheckBox {
                    id: autoScrollCheck
                    text: "Auto Scroll"
                    checked: autoScroll
                    font.pixelSize: 12
                    onCheckedChanged: autoScroll = checked
                }
            }
        }

        // Log messages display
        ListView {
            id: logView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            verticalLayoutDirection: ListView.BottomToTop  // Newest at bottom
            model: logManager ? logManager.model : null

            // Make sure we're correctly handling the model properties
            property int count: model ? model.rowCount() : 0
            
            function getLogItem(index) {
                if (!model) return null;
                var idx = model.index(index, 0);
                return {
                    level: model.data(idx, model.LevelRole),
                    message: model.data(idx, model.MessageRole),
                    formatted: model.data(idx, model.FormattedRole)
                };
            }

            // Update scroll position when new items are added
            Connections {
                target: logManager
                // Use the correct signal name
                function onNewLogMessage(level, message) {
                    if (autoScroll && logView.contentHeight > logView.height) {
                        logView.positionViewAtBeginning()
                    }
                }
            }

            // Delegate for log entries
            delegate: Rectangle {
                width: ListView.view.width
                height: logText.contentHeight + 10
                color: index % 2 ? 
                    (Universal.theme === Universal.Dark ? "#333333" : "#f0f0f0") : 
                    "transparent"

                // Hover effect
                Rectangle {
                    anchors.fill: parent
                    color: Universal.theme === Universal.Dark ? "#444444" : "#e0e0e0"
                    visible: mouseArea.containsMouse
                    opacity: 0.5
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 5

                    // Level indicator
                    Rectangle {
                        width: 8
                        Layout.fillHeight: true
                        color: levelColors[level] || "#888888"
                    }

                    // Log message
                    Text {
                        id: logText
                        text: showTimestamp ? formatted : message
                        Layout.fillWidth: true
                        color: levelColors[level] || Universal.foreground
                        font.family: "Consolas, Courier New, monospace"
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        logEntryClicked({
                            level: level,
                            message: message,
                            formatted: formatted
                        })
                    }
                }
            }

            ScrollBar.vertical: ScrollBar { }
        }

        // Status bar showing log count
        Rectangle {
            id: statusBar
            Layout.fillWidth: true
            height: 24
            color: Universal.theme === Universal.Dark ? "#1d1d1d" : "#e5e5e5"

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                text: "Log entries: " + (logManager ? logManager.count : 0)
                font.pixelSize: 11
                color: Universal.foreground
            }
        }
    }

    // Function to programmatically add a log entry
    function log(level, message) {
        if (logManager) {
            logManager.log(level, message)
        }
    }

    // Function to copy visible logs to clipboard
    function copyLogsToClipboard() {
        var logText = ""
        if (!logView.model) return logText;
        
        for (var i = 0; i < logView.count; i++) {
            var item = logView.getLogItem(i);
            if (item) {
                logText += item.formatted + "\n"
            }
        }
        
        // Use application clipboard if available
        if (typeof clipboard !== 'undefined') {
            clipboard.setText(logText)
        } else {
            console.log("Clipboard not available, log text:", logText)
        }
        
        return logText
    }

    // Handle the copy request
    onCopyRequested: {
        var text = copyLogsToClipboard()
        console.log("Copied " + text.split("\n").length + " log entries")
    }
}
