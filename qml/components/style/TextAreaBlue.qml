import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

TextArea {
    id: control
    Layout.fillWidth: true

    background: Rectangle {
        radius: 3
        border.width: 2
        border.color: !control.enabled ? control.Universal.baseLowColor :
                       control.activeFocus ? control.Universal.accent :
                       control.hovered ? control.Universal.baseMediumColor : control.Universal.chromeDisabledLowColor
        color: control.enabled ? control.Universal.background : control.Universal.baseLowColor
    }
}