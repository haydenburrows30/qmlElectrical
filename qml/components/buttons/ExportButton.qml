import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

ModernButton {
    id: control
    
    text: "Export"
    primaryColor: "#673AB7"  // Deep purple for export function
    
    property string defaultFileName: "export.pdf"
    // Only keep one signal declaration - using a name that is not a reserved word
    signal fileSelected(var fileUrl)
    
    // Use a function property instead of an 'export' property
    function _triggerExport(fileUrl) {
        fileSelected(fileUrl)
    }
    
    FileDialog {
        id: saveDialog
        title: "Export Report"
        fileMode: FileDialog.SaveFile
        nameFilters: ["PDF files (*.pdf)"]
        currentFile: "file:///" + defaultFileName
        
        onAccepted: {
            control.fileSelected(selectedFile)
        }
    }
    
    onClicked: {
        saveDialog.open()
    }
    
    // Add dynamically created signal handler for backward compatibility
    Component.onCompleted: {
        // Create a compatible connection for old 'onExport' handler
        if (control.parent && typeof control.parent.onExport === "function") {
            console.log("Found onExport handler, creating compatibility connection")
            control.fileSelected.connect(control.parent.onExport)
        }
    }
}
