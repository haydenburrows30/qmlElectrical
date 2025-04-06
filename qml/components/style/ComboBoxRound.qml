import QtQuick
import QtQuick.Controls

ComboBox {
    id: control

    background: Rectangle {
        implicitWidth: 120
        implicitHeight: 32

        radius: 3

        border.width: control.flat ? 0 : 2 // ComboBoxBorderThemeThickness
        border.color: !control.enabled ? control.Universal.baseLowColor :
                       control.editable && control.activeFocus ? control.Universal.accent :
                       control.down ? control.Universal.baseMediumLowColor :
                       control.hovered ? control.Universal.baseMediumColor : control.Universal.baseMediumLowColor
        color: !control.enabled ? control.Universal.baseLowColor :
                control.down ? control.Universal.listMediumColor :
                control.flat && control.hovered ? control.Universal.listLowColor :
                control.editable && control.activeFocus ? control.Universal.background : control.Universal.altMediumLowColor
        visible: !control.flat || control.pressed || control.hovered || control.visualFocus

        Rectangle {
            x: 2
            y: 2
            width: parent.width - 4
            height: parent.height - 4

            visible: control.visualFocus && !control.editable
            color: control.Universal.accent
            opacity: control.Universal.theme === Universal.Light ? 0.4 : 0.6
        }
    }
}