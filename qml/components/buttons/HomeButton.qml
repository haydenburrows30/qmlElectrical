import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Effects

Button {
    id: control

    icon.width: 60
    icon.height: 60
    Layout.minimumWidth: 150
    Layout.minimumHeight: 150

    property string tooltip_text: ""

    display: AbstractButton.TextUnderIcon

    background: Item {

        Rectangle {
            id: backgroundID
            anchors.fill: parent
            radius: window.modeToggled ? 3 : 0
        }

        MultiEffect {
            source: backgroundID
            anchors.fill: backgroundID
            autoPaddingEnabled: true
            colorization: 0.7
            colorizationColor: Universal.accent
            shadowBlur: 1 //window.modeToggled ? 2.0 : 1.0
            blurMax: window.modeToggled ? 60 : 20
            shadowEnabled: true
            shadowColor: window.modeToggled ? Qt.rgba(1, 1, 1, 0.12) : "#000000" // Brighter shadow in dark mode
            shadowOpacity: 0.4 //window.modeToggled ? 0.4 : 0.4
        }
    }
}