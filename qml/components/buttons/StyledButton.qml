import QtQuick
import QtQuick.Controls.Universal
import QtQuick.Effects

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
            id: buttonBackground
            width: parent.width
            height: parent.height
            color: "transparent"
            visible: enabled && control.hovered
            border.width: 2
            border.color: control.Universal.accent

            radius: 3
        }

        // MultiEffect {
        //     source: buttonBackground
        //     anchors.fill: buttonBackground
        //     autoPaddingEnabled: true
        //     shadowBlur: 1.0
        //     shadowEnabled: true
        //     shadowVerticalOffset: 3
        //     shadowHorizontalOffset: 1
        //     opacity: control.pressed ? 0.75 : 1.0
        // }
    }
}