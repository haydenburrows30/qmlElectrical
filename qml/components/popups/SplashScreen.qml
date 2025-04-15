import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtQuick.Controls.Material
import QtQuick.Effects

Popup {
    id: splashScreen
    modal: true
    visible: true
    closePolicy: Popup.NoAutoClose
    anchors.centerIn: parent
    width: 300
    height: 300

    property bool isClosing: false

    Component.onDestruction: {
        splashScreen.isClosing = true
    }

    background: Rectangle {
        color: Universal.background
        radius: 10
        border.width: 1
        border.color: Universal.foreground

        ColumnLayout {
            anchors.fill: parent

            Image {
                source: "qrc:/icons/gallery/24x24/Calculator.svg"
                width: 64
                height: 64
                Layout.alignment: Qt.AlignHCenter
            }

            BusyIndicator {
                running: true
                Layout.alignment: Qt.AlignHCenter
            }

            ProgressBar {
                id: progressBar
                Layout.fillWidth: true
                Layout.margins: 20
                from: 0
                to: 1.0
                value: !splashScreen.isClosing && preloadManager ? preloadManager.progress : 0
            }

            Text {
                id: statusText
                Layout.fillWidth: true
                Layout.margins: 20
                horizontalAlignment: Text.AlignHCenter
                text: !splashScreen.isClosing && preloadManager ? preloadManager.statusMessage : ""
                color: "#ffffff"
            }

            Label {
                text: !splashScreen.isClosing && loadingManager ? (loadingManager.loading ? "Loading..." : "Ready!") : ""
                font.pixelSize: 16
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}