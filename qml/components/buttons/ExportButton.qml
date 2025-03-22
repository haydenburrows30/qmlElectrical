import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtCore

Button {
    id: exportButton
    text: "Export PDF"
    
    property string defaultFileName: "report.pdf"
    property var onExport: null
    
    FileDialog {
        id: saveDialog
        title: "Save PDF Report"
        nameFilters: ["PDF files (*.pdf)"]
        fileMode: FileDialog.SaveFile
        currentFolder: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
        
        onAccepted: {
            if (exportButton.onExport) {
                // Convert URL to local file path
                let path = selectedFile.toString()
                // Remove file:// prefix
                path = path.replace(/^(file:\/{2})/,"")
                // Remove URL encoding
                path = decodeURIComponent(path)
                exportButton.onExport(path)
            }
        }
    }
    
    onClicked: {
        saveDialog.open()
    }
}
