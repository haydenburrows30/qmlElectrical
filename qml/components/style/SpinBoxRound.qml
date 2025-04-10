import QtQuick
import QtQuick.Controls

SpinBox {
    id: control

    background: Rectangle {
        implicitWidth: 60 + 28
        implicitHeight: 28

        border.width: 2
        border.color: !control.enabled ? control.Universal.baseLowColor :
                       control.activeFocus ? control.Universal.accent :
                       control.hovered ? control.Universal.baseMediumColor : control.Universal.chromeDisabledLowColor
        color: control.enabled ? control.Universal.background : control.Universal.baseLowColor

        radius: 3
    }
}
