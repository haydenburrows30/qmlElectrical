import QtQuick
import QtQuick.Controls.Universal

Button {
    id: control

    background: Rectangle {
        implicitWidth: 32
        implicitHeight: 32

        radius: 3

        visible: !control.flat || control.down || control.checked || control.highlighted
        color: control.down ? control.Universal.baseMediumLowColor :
               control.enabled && (control.highlighted || control.checked) ? control.Universal.accent :
                                                                             control.Universal.baseLowColor

        Rectangle {
            width: parent.width
            height: parent.height
            color: "transparent"
            visible: enabled && control.hovered
            border.width: 2
            border.color: control.Universal.accent

            radius: 3
        }
    }
}