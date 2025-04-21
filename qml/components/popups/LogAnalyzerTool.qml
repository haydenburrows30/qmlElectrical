import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: logAnalyzerTool
    
    title: "Log Analyzer Tool"
    width: 700
    height: 500
    modal: true
    
    property var logManager: null
    
    Component.onCompleted: {
        analyzeLogs()
    }
    
    function analyzeLogs() {
        if (!logManager || !logManager.model)
            return
            
        let model = logManager.model
        let count = model.rowCount()
        
        // Reset results
        duplicatesTextArea.text = ""
        statsTextArea.text = ""
        
        // Count messages by content
        let messageCounts = {}
        let totalMessages = 0
        
        for (let i = 0; i < count; i++) {
            let index = model.index(i, 0)
            let level = model.data(index, model.LevelRole)
            let message = model.data(index, model.MessageRole)
            let key = level + ": " + message
            
            if (!messageCounts[key])
                messageCounts[key] = 0
                
            messageCounts[key]++
            totalMessages++
        }
        
        // Find duplicates
        let duplicates = []
        let uniqueCount = 0
        
        for (let key in messageCounts) {
            if (messageCounts[key] > 1) {
                duplicates.push({
                    message: key,
                    count: messageCounts[key]
                })
            } else {
                uniqueCount++
            }
        }
        
        // Sort duplicates by count (most frequent first)
        duplicates.sort((a, b) => b.count - a.count)
        
        // Build report
        let duplicateReport = "=== DUPLICATE MESSAGE REPORT ===\n"
        duplicateReport += `Found ${duplicates.length} duplicate message groups out of ${Object.keys(messageCounts).length} unique messages\n`
        duplicateReport += `Total visible messages: ${totalMessages}\n\n`
        
        if (duplicates.length > 0) {
            duplicateReport += "TOP DUPLICATES:\n"
            for (let i = 0; i < Math.min(10, duplicates.length); i++) {
                duplicateReport += `[${duplicates[i].count}x] ${duplicates[i].message}\n`
            }
        } else {
            duplicateReport += "No duplicates found.\n"
        }
        
        duplicatesTextArea.text = duplicateReport
        
        // Build statistics
        let statsReport = "=== LOG VIEW STATISTICS ===\n"
        statsReport += `Total messages in view: ${totalMessages}\n`
        statsReport += `Unique messages: ${Object.keys(messageCounts).length}\n`
        statsReport += `Duplicate groups: ${duplicates.length}\n`
        
        // Count by log level
        let levelCounts = {}
        for (let i = 0; i < count; i++) {
            let index = model.index(i, 0)
            let level = model.data(index, model.LevelRole)
            
            if (!levelCounts[level])
                levelCounts[level] = 0
                
            levelCounts[level]++
        }
        
        statsReport += "\nCOUNT BY LEVEL:\n"
        for (let level in levelCounts) {
            statsReport += `${level}: ${levelCounts[level]}\n`
        }
        
        statsTextArea.text = statsReport
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        Label {
            text: "This tool analyzes the current log view for duplicate messages."
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
        
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            
            TabButton {
                text: "Duplicates"
            }
            
            TabButton {
                text: "Statistics"
            }
        }
        
        StackLayout {
            currentIndex: tabBar.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ScrollView {
                clip: true
                
                TextArea {
                    id: duplicatesTextArea
                    readOnly: true
                    font.family: "Courier New, Courier, monospace"
                    font.pixelSize: 12
                    textFormat: TextEdit.PlainText
                    wrapMode: TextEdit.Wrap
                }
            }
            
            ScrollView {
                clip: true
                
                TextArea {
                    id: statsTextArea
                    readOnly: true
                    font.family: "Courier New, Courier, monospace"
                    font.pixelSize: 12
                    textFormat: TextEdit.PlainText
                    wrapMode: TextEdit.Wrap
                }
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            
            Button {
                text: "Refresh Analysis"
                onClicked: analyzeLogs()
            }
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: "Close"
                onClicked: logAnalyzerTool.close()
            }
        }
    }
}
