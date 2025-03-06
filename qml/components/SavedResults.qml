import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import '../components'

WaveCard {
    id: root
    
    // Add property to receive ResultsManager instance
    required property var resultsManager
    
    title: "Calculation History"
    Layout.fillWidth: true
    Layout.minimumHeight: 300

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Button {
                text: "Refresh"
                icon.name: "Reset"
                onClicked: resultsManager.refresh_results()
            }

            Button {
                text: "Clear All"
                icon.name: "Delete"
                onClicked: confirmClearDialog.open()
            }
        }

        // Add confirmation dialog
        Dialog {
            id: confirmClearDialog
            title: "Clear All Results"
            modal: true
            standardButtons: Dialog.Yes | Dialog.No
            anchors.centerIn: Overlay.overlay
            width: 300

            Label {
                text: "Are you sure you want to delete all saved results?\nThis action cannot be undone."
                wrapMode: Text.WordWrap
                width: parent.width
            }

            onAccepted: {
                resultsManager.clear_all_results()
                resultsManager.refresh_results()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: toolBar.toggle ? "#424242" : "#e0e0e0"

            Row {
                anchors.fill: parent
                Repeater {
                    model: resultsManager.tableModel.columnCount()
                    
                    Rectangle {
                        width: getColumnWidth(index)
                        height: parent.height
                        color: "transparent"
                        
                        Label {
                            anchors.fill: parent
                            anchors.margins: 8
                            text: resultsManager.tableModel.headerData(index, Qt.Horizontal)
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            color: toolBar.toggle ? "#ffffff" : "#000000"
                        }
                    }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            clip: true
            wheelEnabled:true

            TableView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: resultsManager.tableModel
                boundsMovement: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {}

                delegate: Rectangle {
                    implicitWidth: getColumnWidth(column)
                    implicitHeight: 40
                    color: row % 2 ? (toolBar.toggle ? "#2d2d2d" : "#f5f5f5") 
                                 : (toolBar.toggle ? "#1d1d1d" : "#ffffff")

                    Text {
                        anchors.fill: parent
                        anchors.margins: 8
                        text: model.display || ""
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: toolBar.toggle ? "#ffffff" : "#000000"
                    }
                }
            }
        }
    }

    function getColumnWidth(column) {
        switch(column) {
            case 0: return 150  // Date/Time
            case 1: return 80   // System
            case 2: return 100  // Load
            case 3: return 80   // Houses
            case 4: return 200  // Cable
            case 5: return 100  // Length
            case 6: return 100  // Current
            case 7: return 100  // V-Drop
            case 8: return 100  // Drop %
            default: return 100
        }
    }
}
