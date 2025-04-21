import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    id: logViewer

    // Color setup with null checks for window
    property color textColor: window ? (window.modeToggled ? "white" : "black") : "black"
    property color bgColor: window ? (window.modeToggled ? "#333333" : "#f0f0f0") : "#f0f0f0"
    property color borderColor: window ? (window.modeToggled ? "#555555" : "#cccccc") : "#cccccc"

    color: bgColor
    
    property var logManager: null
    property bool autoScroll: true
    property var filterModel: ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
    property string currentFilter: "INFO"

    function refreshLogView() {
        if (logManager) {
            logManager.setFilterLevel(currentFilter)
        }
    }

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

            Label {
                text: "Filter Level:"
                color: textColor
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 14
            }

            ComboBox {
                id: filterCombo
                model: filterModel
                currentIndex: filterModel.indexOf(currentFilter)
                width: 120
                anchors.verticalCenter: parent.verticalCenter
                
                onCurrentTextChanged: {
                    if (currentText !== currentFilter) {
                        currentFilter = currentText
                        refreshLogView()
                    }
                }
            }

            Item { 
                width: 10
                height: 1 
            }

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
                onClicked: saveFileDialog.open()
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
                text: "Debug Loggers"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    if (logManager && logManager.getLoggerDebugInfo) {
                        // Display the logger debug info as a log entry
                        let debugInfo = logManager.getLoggerDebugInfo()
                        logManager.log("INFO", "Logger Debug Information:\n" + debugInfo)
                    }
                }
            }

            Button {
                id: debugModeButton
                text: "Debug Mode: Off"
                property bool debugModeEnabled: false
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    debugModeEnabled = !debugModeEnabled
                    text = "Debug Mode: " + (debugModeEnabled ? "On" : "Off")
                    
                    if (logManager) {
                        logManager.setDebugMode(debugModeEnabled)
                        if (debugModeEnabled) {
                            logManager.log("INFO", "Debug mode enabled")
                        }
                    }
                }
            }

            Button {
                text: "Analyze Logs"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    var component = Qt.createComponent("LogAnalyzerTool.qml")
                    if (component.status === Component.Ready) {
                        var analyzer = component.createObject(window || logViewer, {
                            "logManager": logManager
                        })
                        analyzer.open()
                    } else {
                        console.error("Error creating LogAnalyzerTool:", component.errorString())
                    }
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
    
    FileDialog {
        id: saveFileDialog
        title: "Save Log File"
        nameFilters: ["Text files (*.txt)", "All files (*)"]
        fileMode: FileDialog.SaveFile
        
        onAccepted: {
            // Collect all log data
            let logContent = "";
            if (logManager && logManager.model) {
                let model = logManager.model;
                
                for (let i = 0; i < model.rowCount; i++) {
                    let index = model.index(i, 0);
                    let formatted = model.data(index, 3); // FormattedRole
                    logContent += formatted + "\n";
                }
                
                if (logManager.saveLogsToFile(selectedFile, logContent)) {
                    console.log("Logs saved successfully");
                } else {
                    console.error("Failed to save logs");
                }
            }
        }
    }
    
    FileDialog {
        id: exportFileDialog
        title: "Export All Log History"
        nameFilters: ["Text files (*.txt)", "All files (*)"]
        fileMode: FileDialog.SaveFile
        
        onAccepted: {
            if (logManager && logManager.exportAllLogs) {
                if (logManager.exportAllLogs(selectedFile)) {
                    console.log("Full log history exported successfully");
                } else {
                    console.error("Failed to export log history");
                }
            }
        }
    }
    
    Connections {
        target: logManager
        
        function onLogCountChanged(count) {
            updateStatistics()
        }
        
        function onFilterLevelChanged(level) {
            if (level !== currentFilter) {
                currentFilter = level
                filterCombo.currentIndex = filterModel.indexOf(level)
                refreshLogView()
            }
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
