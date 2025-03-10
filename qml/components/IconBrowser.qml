import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    title: "Available Icons"
    width: Math.min(800, parent.width * 0.9)
    height: Math.min(600, parent.height * 0.9)
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: parent
    
    // Standard icon names from freedesktop.org specification
    property var iconNames: [
        // Document icons
        "document-new", "document-open", "document-save", "document-save-as", 
        "document-print", "document-print-preview", "document-properties",
        "document-close", "document-edit", "document-export", "document-import",
        
        // Edit icons
        "edit-undo", "edit-redo", "edit-cut", "edit-copy", "edit-paste", 
        "edit-delete", "edit-clear", "edit-find", "edit-select-all",
        
        // View icons
        "view-refresh", "view-fullscreen", "view-restore", "view-sort-ascending", 
        "view-sort-descending", "view-list-details", "view-grid",
        
        // Navigation icons
        "go-home", "go-up", "go-down", "go-next", "go-previous", 
        "go-top", "go-bottom", "go-first", "go-last", "go-jump",
        
        // Format icons
        "format-text-bold", "format-text-italic", "format-text-underline",
        "format-justify-left", "format-justify-center", "format-justify-right", 
        "format-justify-fill",
        
        // Object icons
        "object-rotate-left", "object-rotate-right", "object-flip-horizontal", 
        "object-flip-vertical",
        
        // List icons
        "list-add", "list-remove",
        
        // Dialog icons
        "dialog-ok", "dialog-cancel", "dialog-close", "dialog-yes", 
        "dialog-no", "dialog-warning", "dialog-error", "dialog-information",
        "dialog-question", "dialog-password", "dialog-apply",
        
        // Category icons
        "preferences-system", "preferences-desktop", "preferences-desktop-theme",
        "preferences-desktop-font", "preferences-desktop-keyboard",
        
        // Status icons
        "emblem-default", "emblem-important", "emblem-system", 
        "security-high", "security-medium", "security-low",
        
        // Application icons
        "applications-system", "applications-office", "applications-graphics",
        "applications-internet", "applications-development", "applications-games",
        "applications-utilities", "accessories-calculator",
        
        // Device icons
        "drive-harddisk", "drive-optical", "drive-removable-media",
        "media-floppy", "media-optical", "media-tape", "media-flash",
        
        // Action icons
        "system-run", "system-search", "system-reboot", "system-shutdown", 
        "system-log-out", "system-lock-screen",
        
        // Misc icons
        "help-browser", "help-contents", "help-about", "application-exit",
        "user-home", "user-desktop", "folder", "folder-open", "network-server",
        "mail-send", "mail-message-new", "mail-attachment", "mail-mark-important",
        "appointment-new", "contact-new", "call-start", "call-stop",
        "camera-photo", "audio-volume-high", "audio-volume-muted"
    ]
    
    // Search functionality
    property string searchText: ""
    
    function filterIcons() {
        if (!searchText) return iconNames
        return iconNames.filter(name => name.toLowerCase().includes(searchText.toLowerCase()))
    }
    
    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            
            Label {
                text: "Search icons:"
                Layout.alignment: Qt.AlignVCenter
            }
            
            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Type to filter icons"
                onTextChanged: {
                    searchText = text
                    iconRepeater.model = filterIcons()
                }
            }
            
            Button {
                text: "Clear"
                onClicked: searchField.text = ""
            }
        }
    }
    
    contentItem: ColumnLayout {
        spacing: 10
        
        Label {
            text: "Click on an icon to copy its name"
            Layout.alignment: Qt.AlignHCenter
            font.italic: true
        }
        
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            GridLayout {
                width: parent.width
                columns: Math.max(1, Math.floor(root.width / 120))
                
                Repeater {
                    id: iconRepeater
                    model: root.iconNames
                    
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        Layout.alignment: Qt.AlignCenter
                        
                        Button {
                            icon.name: modelData
                            icon.width: 32
                            icon.height: 32
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            
                            onClicked: {
                                iconNameText.text = modelData
                                iconNameText.selectAll()
                                iconNameText.copy()
                                
                                copyMessage.text = `"${modelData}" copied to clipboard`
                                copyMessage.visible = true
                                hideTimer.restart()
                            }
                            
                            ToolTip.visible: hovered
                            ToolTip.text: modelData
                        }
                        
                        Text {
                            text: modelData
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
        
        Rectangle {
            id: copyMessage
            color: "#4CAF50"
            radius: 5
            height: 40
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: messageText.width + 40
            visible: false
            
            property alias text: messageText.text
            
            Text {
                id: messageText
                anchors.centerIn: parent
                color: "white"
                font.bold: true
            }
            
            Timer {
                id: hideTimer
                interval: 2000
                onTriggered: copyMessage.visible = false
            }
        }
        
        TextEdit {
            id: iconNameText
            visible: false
        }
    }
    
    footer: DialogButtonBox {
        Button {
            text: "Close"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: root.close()
        }
    }
    
    Component.onCompleted: {
        iconRepeater.model = root.iconNames
    }
}