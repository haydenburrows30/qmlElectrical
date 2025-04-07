import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: root
    
    // Add logManager property
    property var logManager: null
    
    // Signal when export completes
    signal exportComplete(bool success, string filePath)
    
    // FileDialog for saving logs
    FileDialog {
        id: saveDialog
        title: "Save Logs"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Log files (*.log *.txt)", "All files (*)"]
        
        onAccepted: {
            var result = exportLogs(selectedFile)
            exportComplete(result.success, result.filePath)
        }
    }
    
    // Function to export logs to file
    function exportLogs(filePath) {
        // Guard against missing logManager
        if (!logManager) {
            console.error("No logManager provided to LogExporter")
            return { success: false, filePath: filePath }
        }
        
        // Get log text from logManager
        var logText = ""
        var model = logManager.model
        
        // Iterate through all logs
        if (model) {
            for (var i = 0; i < model.rowCount(); i++) {
                var idx = model.index(i, 0)
                var formatted = model.data(idx, model.FormattedRole)
                logText += formatted + "\n"
            }
        }
        
        // Save to file using a helper in C++
        var success = logManager.saveLogsToFile(filePath, logText)
        
        return {
            success: success,
            filePath: filePath
        }
    }
    
    // Function to show save dialog
    function showSaveDialog() {
        if (!logManager) {
            console.error("No logManager provided to LogExporter")
            return
        }
        saveDialog.open()
    }
}
