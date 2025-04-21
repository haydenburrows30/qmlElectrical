import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: logDebuggerPopup
    
    title: "Log Debugger"
    width: 600
    height: 400
    modal: true
    
    property var logManager: null
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 15
        
        Label {
            text: "Logging System Debug Tools"
            font.bold: true
            font.pixelSize: 16
            Layout.fillWidth: true
        }
        
        GroupBox {
            title: "Debug Options"
            Layout.fillWidth: true
            
            GridLayout {
                columns: 2
                rowSpacing: 10
                columnSpacing: 15
                anchors.fill: parent
                
                Switch {
                    id: debugModeSwitch
                    text: "Debug Mode"
                    checked: logManager && logManager.debugMode === true
                    Layout.columnSpan: 2
                    
                    onCheckedChanged: {
                        if (logManager) {
                            logManager.setDebugMode(checked)
                            if (checked) {
                                logManager.log("INFO", "Debug mode enabled")
                            } else {
                                logManager.log("INFO", "Debug mode disabled")
                            }
                        }
                    }
                }
                
                Button {
                    text: "Get Logger Info"
                    Layout.fillWidth: true
                    onClicked: {
                        if (logManager && logManager.getLoggerDebugInfo) {
                            let debugInfo = logManager.getLoggerDebugInfo()
                            logManager.log("INFO", "Logger Debug Information:\n" + debugInfo)
                        }
                    }
                }
                
                Button {
                    text: "Test Component Logs"
                    Layout.fillWidth: true
                    onClicked: {
                        if (logManager) {
                            logManager.log("INFO", "Test log message from QML")
                            Qt.callLater(function() {
                                logManager.testComponentLogs()
                            })
                        }
                    }
                }
                
                Button {
                    text: "Analyze Logs"
                    Layout.fillWidth: true
                    onClicked: {
                        var component = Qt.createComponent("LogAnalyzerTool.qml")
                        if (component.status === Component.Ready) {
                            var analyzer = component.createObject(window || logDebuggerPopup, {
                                "logManager": logManager
                            })
                            analyzer.open()
                        } else {
                            console.error("Error creating LogAnalyzerTool:", component.errorString())
                        }
                    }
                }
                
                Button {
                    text: "Reload Logs"
                    Layout.fillWidth: true
                    onClicked: {
                        if (logManager && logManager.reloadLogsFromFile) {
                            logManager.reloadLogsFromFile()
                            logManager.log("INFO", "Logs reloaded from file")
                        }
                    }
                }
            }
        }
        
        GroupBox {
            title: "Log Statistics"
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ScrollView {
                anchors.fill: parent
                
                TextArea {
                    id: statsText
                    readOnly: true
                    text: getStatistics()
                    font.family: "Courier New, Courier, monospace"
                    font.pixelSize: 12
                    
                    Connections {
                        target: logManager
                        function onStatisticsChanged() {
                            statsText.text = getStatistics()
                        }
                    }
                }
            }
        }
    }
    
    footer: DialogButtonBox {
        Button {
            text: "Refresh Stats"
            DialogButtonBox.buttonRole: DialogButtonBox.ActionRole
            onClicked: {
                statsText.text = getStatistics()
            }
        }
        
        Button {
            text: "Close"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }
    }
    
    function getStatistics() {
        if (!logManager)
            return "Log manager not available"
            
        let stats = []
        
        // Add logger stats
        if (logManager.getLogStats)
            stats.push(logManager.getLogStats())
            
        // Add history stats
        if (logManager.getHistoryStats)
            stats.push(logManager.getHistoryStats())
            
        // Get count
        stats.push(`Current view count: ${logManager.count}`)
        
        // Get log file path
        if (logManager.getLogFilePath)
            stats.push(`Log file: ${logManager.getLogFilePath()}`)
            
        return stats.join("\n")
    }
}
