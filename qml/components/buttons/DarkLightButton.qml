import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Effects

RoundButton {
    id: round_button
    implicitWidth: 40
    implicitHeight: 40
    icon.width: 30
    icon.height: 30
    checkable: true

    icon.name: round_button.checked ? icon_name1:icon_name2

    property var icon_name1 : ""
    property var icon_name2 : ""
    property var mode_1 : ""
    property var mode_2 : ""

    ToolTip {
        id: toolTip
        text: round_button.checked ? mode_1:mode_2
        visible: parent.hovered
        x: parent.width
        y: parent.height
        delay: 500
        timeout: 2000
    }

    onClicked: {
        toolTip.hide()
    }

    background: Rectangle {
        id: buttonBlur
        radius: round_button.radius
        border.width: round_button.hovered ? 1 : 0
        border.color: round_button.Universal.baseMediumLowColor
        visible: !round_button.flat || round_button.down || round_button.checked || round_button.highlighted
        color: round_button.down ? round_button.Universal.baseMediumLowColor :
            round_button.enabled && (round_button.highlighted || round_button.checked) ? round_button.Universal.accent : "transparent"
    }

    MultiEffect {
        source: buttonBlur
        anchors.fill: buttonBlur
        visible: window.modeToggled
        autoPaddingEnabled: true
        colorization: window.modeToggled ? 0.7 : 0.5
        colorizationColor: Universal.accent
        shadowBlur: 1 //window.modeToggled ? 2.0 : 1.0
        blurMax: window.modeToggled ? 60 : 20
        shadowEnabled: true
        shadowColor: window.modeToggled ? Qt.rgba(1, 1, 1, 0.12) : "#000000" // Brighter shadow in dark mode
        shadowOpacity: window.modeToggled ? 0.6 : 0.4
    }
}