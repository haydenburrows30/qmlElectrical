import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Button {
    id: control
    text: ""

    icon.width: 80
    icon.height: 80
    Layout.minimumWidth: 150
    Layout.minimumHeight: 150

    display: AbstractButton.TextUnderIcon

    property string tooltip_text: ""

    property color back : Qt.lighter(palette.accent,1.5)
    property color fore : Qt.lighter(palette.accent,1.5)

    background: Rectangle {
        visible: !control.flat || control.down || control.checked || control.highlighted
        color: control.down ? control.Universal.baseMediumLowColor :
            control.enabled && (control.highlighted || control.checked) ? control.Universal.accent :
                                                                            back

        Rectangle {
            width: parent.width
            height: parent.height
            color: fore
            visible: enabled && control.hovered
            border.width: 2
            border.color: control.Universal.baseMediumLowColor
        }
    }
}