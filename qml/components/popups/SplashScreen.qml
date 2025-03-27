import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtQuick.Controls.Material
import QtQuick.Effects

import "../style"

Popup {
    id: splashScreen
    modal: true
    visible: true
    closePolicy: Popup.NoAutoClose
    anchors.centerIn: parent
    width: 300
    height: 300
    
    background: Rectangle {
        color: Universal.background
        radius: 10
        border.width: 1
        border.color: Universal.foreground
        
        Column {
            anchors.centerIn: parent
            spacing: Style.spacing

            Image {
                source: "qrc:/icons/gallery/24x24/Calculator.svg"
                width: 64
                height: 64
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            BusyIndicator {
                running: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            ProgressBar {
                width: 200
                value: loadingManager.progress
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Label {
                text: loadingManager.loading ? "Loading..." : "Ready!"
                font.pixelSize: 16
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}