import QtQuick
import QtQuick.Controls

Menu {
    id: root
    title: "Export Format"
    
    property var onCsvExport: null
    property var onPdfExport: null
    
    MenuItem {
        text: "Export as CSV"
        onTriggered: {
            if (root.onCsvExport) {
                root.onCsvExport()
            }
        }
    }

    MenuItem {
        text: "Export as PDF"
        onTriggered: {
            if (root.onPdfExport) {
                root.onPdfExport()
            }
        }
    }
}
