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
    border.width: 1
    border.color: borderColor
    
    property var logManager: null
    property bool autoScroll: true
    property var filterModel: ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
    property string currentFilter: "INFO"

    function refreshLogView() {
        if (logManager) {
            logManager.setFilterLevel(currentFilter)
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
                    currentFilter = currentText
                    refreshLogView()
                }
            }

            Item { 
                width: 20
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
                
                delegate: Rectangle {
                    width: logListView.width
                    height: logText.height + 10
                    color: {
                        if (level === "ERROR" || level === "CRITICAL")
                            return window.modeToggled ? "#552222" : "#ffeeee"
                        else if (level === "WARNING")
                            return window.modeToggled ? "#554422" : "#fff8e8"
                        else
                            return "transparent"
                    }
                    border.width: 0
                    
                    Text {
                        id: logText
                        text: formatted
                        width: parent.width
                        wrapMode: Text.Wrap
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        font.pixelSize: 12
                        font.family: "Courier New, Courier, monospace"
                        color: {
                            if (level === "ERROR" || level === "CRITICAL")
                                return window.modeToggled ? "#ff6666" : "#990000"
                            else if (level === "WARNING")
                                return window.modeToggled ? "#ffcc66" : "#996600"
                            else
                                return window.modeToggled ? "white" : "black"
                        }
                    }
                }
                
                ScrollBar.vertical: ScrollBar { }
                
                // Auto-scroll to bottom when new logs arrive
                onCountChanged: {
                    if (autoScroll) {
                        positionViewAtEnd()
                    }
                }
            }
        }
        
        // Status row at bottom
        Row {
            id: statusRow
            width: parent.width
            height: 20
            anchors.bottom: parent.bottom
            
            Label {
                text: logManager && logManager.count ? "Log count: " + logManager.count : "Log count: 0"
                color: textColor
                font.pixelSize: 12
                width: parent.width / 2
            }
            
            Item { width: 20; height: 1 }
            
            Label {
                text: logManager && logManager.getLogStats ? logManager.getLogStats() : ""
                color: textColor
                font.pixelSize: 12
                elide: Text.ElideRight
                width: parent.width / 2 - 20
                horizontalAlignment: Text.AlignRight
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
    
    Component.onCompleted: {
        refreshLogView()
    }
}
