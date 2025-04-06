import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../buttons"

Item {
    id: root
    
    property var tableModel
    property var headerLabels: [
        "Size (mm²)", 
        "Material", 
        "Cores", 
        "mV/A/m", 
        "Rating (A)", 
        "V-Drop (V)", 
        "Drop %", 
        "Status"
    ]
    property bool darkMode: false
    property var onExportRequest: null
    
    function getColumnWidth(column) {
        switch(column) {
            case 0: return 100  // Size
            case 1: return 100  // Material
            case 2: return 100  // Cores
            case 3: return 100  // mV/A/m
            case 4: return 120  // Rating
            case 5: return 120  // V-Drop
            case 6: return 100  // Drop %
            case 7: return 100  // Status
            default: return 100
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Header row that syncs with table
        Item {
            Layout.fillWidth: true
            height: 40
            clip: true

            Rectangle {
                width: tableView.width
                height: parent.height
                color: darkMode ? "#424242" : "#e0e0e0"
                x: -tableView.contentX  // Sync with table horizontal scroll
                
                Row {
                    anchors.fill: parent
                    Repeater {
                        model: root.headerLabels
                        
                        Rectangle {
                            width: root.getColumnWidth(index)
                            height: parent.height
                            color: "transparent"
                            
                            Label {
                                anchors.fill: parent
                                anchors.margins: 8
                                text: modelData
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                color: darkMode ? "#ffffff" : "#000000"
                            }
                        }
                    }
                }
            }
        }

        // Table content
        ScrollView {
            id: tableScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            clip: true

            TableView {
                id: tableView
                anchors.fill: parent
                model: root.tableModel
                boundsMovement: Flickable.StopAtBounds

                // Mouse handling for table
                MouseArea {
                    z: -1  // Place behind TableView so delegates can still receive events
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    
                    onWheel: function(wheelEvent) {
                        if (wheelEvent.modifiers & Qt.ShiftModifier) {
                            // Shift+wheel for horizontal scrolling
                            tableView.contentX -= wheelEvent.angleDelta.y
                            wheelEvent.accepted = true
                        } else {
                            // Regular wheel for vertical scrolling
                            tableView.contentY -= wheelEvent.angleDelta.y
                            wheelEvent.accepted = true
                        }
                    }

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            tableContextMenu.popup()
                        }
                    }
                }

                // Context menu for table
                Menu {
                    id: tableContextMenu
                    
                    MenuItem {
                        text: "Export as CSV"
                        onTriggered: {
                            if (root.onExportRequest) {
                                root.onExportRequest("csv")
                            }
                        }
                    }

                    MenuItem {
                        text: "Export as PDF"
                        onTriggered: {
                            if (root.onExportRequest) {
                                root.onExportRequest("pdf")
                            }
                        }
                    }
                    
                    MenuSeparator {}
                    
                    MenuItem {
                        text: "Reset Scroll Position"
                        onTriggered: {
                            tableView.contentX = 0
                            tableView.contentY = 0
                        }
                    }
                }

                // Table cell delegate
                delegate: Rectangle {
                    implicitWidth: root.getColumnWidth(column)
                    implicitHeight: 40
                    color: {
                        if (column === 7) {  // Status column
                            switch(model.display) {
                                case "SEVERE": return "#ffebee"  // Red background
                                case "WARNING": return "#fff3e0"  // Orange background
                                case "SUBMAIN": return "#e3f2fd"  // Blue background
                                case "OK": return "#e8f5e9"      // Green background
                                default: return "transparent"
                            }
                        }
                        return row % 2 ? (darkMode ? "#2d2d2d" : "#f5f5f5") 
                                    : (darkMode ? "#1d1d1d" : "#ffffff")
                    }

                    Text {
                        anchors.fill: parent
                        anchors.margins: 8
                        text: model.display
                        color: {
                            if (column === 7) {  // Status column
                                switch(model.display) {
                                    case "SEVERE": return "#c62828"  // Dark red
                                    case "WARNING": return "#ef6c00"  // Dark orange
                                    case "SUBMAIN": return "#1565c0"  // Dark blue
                                    case "OK": return "#2e7d32"      // Dark green
                                    default: return darkMode ? "#ffffff" : "#000000"
                                }
                            }
                            return darkMode ? "#ffffff" : "#000000"
                        }
                        font.bold: column === 7  // Status column
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        StyledButton {
            text: "Export Table"
            icon.source: "../../../icons/svg/file_download/baseline.svg"
            enabled: root.tableModel && root.tableModel.rowCount && root.tableModel.rowCount() > 0
            Layout.alignment: Qt.AlignRight
            Layout.margins: 5
            
            onClicked: {
                if (root.onExportRequest) {
                    root.onExportRequest("menu")
                }
            }
            
            ToolTip.visible: hovered
            ToolTip.text: "Export cable comparison data"
        }
    }
}
