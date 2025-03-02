import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Button {
    id: control

    icon.name: icon_name

    property var icon_name : ""
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

    // onClicked: {toolTip.hide()}
}