import QtQuick
import QtQuick.Dialogs

FileDialog {
    id: root
    title: "Export"
    fileMode: FileDialog.SaveFile
    currentFolder: Qt.platform.os === "windows" ? "file:///C:" : "file:///home"
    
    // Export types enum
    readonly property int chartExport: 0
    readonly property int tableCsvExport: 1
    readonly property int tablePdfExport: 2
    readonly property int detailsPdfExport: 3
    
    property int exportType: chartExport
    property real currentScale: 2.0
    property var handler: null
    property var details: null
    
    function setup(dialogTitle, filters, suffix, baseFilename, type, callback) {
        title = dialogTitle
        nameFilters = [filters, "All files (*)"]
        defaultSuffix = suffix
        exportType = type
        handler = callback
        
        // Simple timestamp for filename
        let now = new Date()
        let timestamp = now.toISOString().split('.')[0].replace(/[:\-]/g, '')
        currentFile = baseFilename + "_" + timestamp + "." + suffix
    }
    
    onAccepted: {
        if (handler) {
            handler(selectedFile)
        }
    }
}
