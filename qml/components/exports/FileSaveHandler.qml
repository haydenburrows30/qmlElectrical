import QtQuick
import QtQuick.Controls

import FileSaverUtils 1.0

Item {
    id: root
    
    // Signals
    signal saveCompleted(bool success, string message)
    signal saveRequested(string filePath, var data, string defaultName)
    
    // Properties
    property string title: "Save File"
    property string defaultExtension: "csv"
    property string defaultName: "exported_data"
    property var saveHandler: null
    property string lastSavedPath: ""
    property bool busy: false
    
    // File saver instance
    property FileSaver fileSaver: FileSaver {}
    
    // Public methods for saving different file types
    function saveTextFile(content, fileName = defaultName) {
        busy = true
        var success = fileSaver.save_text_file("", content, fileName)
        return success
    }
    
    function saveJsonData(jsonData, fileName = defaultName) {
        busy = true
        var success = fileSaver.save_json("", jsonData, fileName)
        return success
    }
    
    function saveCsvData(data, metadata = null, fileName = defaultName) {
        busy = true
        var success = fileSaver.save_csv("", data, metadata, fileName)
        return success
    }
    
    function savePdfData(data, fileName = defaultName) {
        busy = true
        var success = fileSaver.save_pdf("", data, fileName)
        return success
    }
    
    function getPath(extension, fileName = defaultName) {
        return fileSaver.get_save_filepath(extension, fileName)
    }
    
    // Internal connections to handle events
    Connections {
        target: fileSaver
        
        function onSaveStatusChanged(success, message) {
            busy = false
            saveCompleted(success, message)
        }
    }
}
